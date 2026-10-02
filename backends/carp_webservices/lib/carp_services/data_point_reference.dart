/*
 * Copyright 2018-2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of 'carp_services.dart';

/// A reference to the legacy data point endpoint of one study deployment in
/// CAWS.
///
/// Obtained from the deprecated [CarpService.dataPointReference]. New code
/// uploads data with [CarpDataStreamService] instead.
///
/// Can be used to:
/// - post (upload) a [DataPoint]
/// - batch upload a list or file of [DataPoint]s
/// - get a [DataPoint]
/// - query for [DataPoint]s
/// - delete a [DataPoint]
class DataPointReference extends CarpReference {
  final String _studyDeploymentId;

  /// The study deployment id of this data point reference.
  String get studyDeploymentId => _studyDeploymentId;

  DataPointReference._(CarpService service, this._studyDeploymentId)
    : super._(service);

  /// The URL of the data point endpoint for this [DataPointReference].
  String get dataEndpointUri =>
      "${service.app.uri.toString()}/api/deployments/$studyDeploymentId/data-points";

  /// Uploads [data].
  ///
  /// Returns the server-generated ID for this data point.
  Future<int> post(DataPoint data) async {
    final response = await service._post(
      dataEndpointUri,
      body: json.encode(data),
    );

    // we expect a map with the ID in the response
    Map<String, dynamic> responseJson =
        service._handleResponse(response) as Map<String, dynamic>;
    return responseJson["id"] as int;
  }

  int _counter = 0;
  String? _fileCachePath;

  /// The local folder where [batch] writes files before upload.
  ///
  /// Uses the cache path of [Settings] for this deployment if [Settings] is
  /// initialized, otherwise `cache/upload`. Created if missing.
  Future<String> get fileCachePath async {
    if (_fileCachePath == null) {
      var path = 'cache';

      if (Settings().initialized) {
        final deploymentId = studyDeploymentId;
        path = await Settings().getCacheBasePath(deploymentId);
      }
      final directory = await Directory('$path/upload').create(recursive: true);
      _fileCachePath = directory.path;
    }

    return _fileCachePath!;
  }

  // TODO - Delete cached file when uploaded.
  //
  // Something like:
  //
  //   .then((file) => upload(file).then((_) => file.delete()));
  //
  // But this does not work, since this will delete the file before it is
  // uploaded, especially if there is a long retry cycle.
  // Need to listen to some sort of event that the file is successfully
  // uploaded, and then delete it.

  /// Batch uploads a list of [DataPoint]s.
  ///
  /// The list is written to a JSON file in [fileCachePath] and sent with
  /// [upload]. The file is not deleted afterwards.
  Future<void> batch(List<DataPoint> batch) async {
    if (batch.isEmpty) return;

    await File('${await fileCachePath}/batch-${_counter++}.json')
        .create(recursive: true)
        .then((file) => file.writeAsString(toJsonString(batch), flush: true))
        .then((file) => upload(file));
  }

  /// Batch uploads the [file] containing a list of [DataPoint]s to CAWS.
  ///
  /// The [file] can be created using a [FileDataManager] in `carp_mobile_sensing`.
  /// Note that the file should be raw JSON, and hence _not_ zipped.
  ///
  /// The request is sent in the background with retry; the returned future
  /// completes before the upload does, so upload errors are not passed to
  /// the caller.
  Future<void> upload(File file) async {
    final String url = "$dataEndpointUri/batch";

    var request = http.MultipartRequest("POST", Uri.parse(url));
    request.headers['Authorization'] = headers['Authorization']!;
    request.headers['Content-Type'] = 'multipart/form-data';
    request.headers['cache-control'] = 'no-cache';

    request.files.add(ClonableMultipartFile.fromFileSync(file.path));

    // sending the request using the retry approach
    httpr.send(request).then((response) async {
      final int httpStatusCode = response.statusCode;

      // CARP web service returns 200 or 201 when a file is uploaded to the server
      if ((httpStatusCode == HttpStatus.ok) ||
          (httpStatusCode == HttpStatus.created)) {
        return;
      }

      // everything else is an exception
      response.stream.toStringStream().first.then((body) {
        final Map<String, dynamic> responseJson =
            json.decode(body) as Map<String, dynamic>;
        throw CarpServiceRequestException(
          responseJson["message"].toString(),
          httpStatus: HTTPStatus(httpStatusCode),
          path: responseJson["path"].toString(),
        );
      });
    });
  }

  /// Gets a [DataPoint] based on its [id] from CAWS.
  Future<DataPoint> get(int id) async {
    final url = "$dataEndpointUri/$id";
    final response = await service._get(url);

    // we expect a map with the data point in the response
    Map<String, dynamic> responseJson =
        service._handleResponse(response) as Map<String, dynamic>;
    return DataPoint.fromJson(responseJson);
  }

  /// Gets all [DataPoint]s for this study deployment.
  ///
  /// Be careful using this method - this might potential return an enormous
  /// amount of data.
  Future<List<DataPoint>> getAll() async => query('');

  /// Queries for [DataPoint]s in CAWS using
  /// [REST SQL (RSQL)](https://github.com/jirutka/rsql-parser).
  ///
  /// The [query] string can be build by querying data point _fields_ using
  /// _logical operations_.
  ///
  /// Query fields can be any field in a data point JSON, including nested fields.
  /// Examples include:
  ///
  ///  * Data point fields such as `id`, `study_id` and `created_at`.
  ///  * Header fields such as `carp_header.start_time`, `carp_header.user_id`, and `carp_header.data_format.name`
  ///  * Body fields such as `carp_body.latitude` or `carp_body.connectivity_status`
  ///
  /// Note that field names are nested using the dot-notation.
  ///
  /// See [here](https://github.com/jirutka/rsql-parser) for details on grammar and semantic.
  ///
  /// The logical operations include:
  ///
  ///   * Logical AND : `;` or `and`
  ///   * Logical OR : `,` or `or`
  ///
  /// Comparison operations include.
  ///
  ///   * Equal to : `==`
  ///   * Not equal to : `!=`
  ///   * Less than : `=lt=` or `<`
  ///   * Less than or equal to : `=le=` or `<=`
  ///   * Greater than operator : `=gt=` or `>`
  ///   * Greater than or equal to : `=ge=` or `>=`
  ///   * In : `=in=`
  ///   * Not in : `=out=`
  ///
  /// Examples of query strings include:
  ///
  /// Get all data-points between 2018-05-27T13:28:07 and 2019-05-29T08:55:26
  ///   * `carp_header.created_at>2018-05-27T13:28:07Z;carp_header.created_at<2019-05-29T08:55:26Z`
  ///
  /// Get all where the user id is 1 or 2
  ///   * `carp_header.user_id==1,2`
  ///
  ///
  /// Below is an example of a data point in JSON to see the different fields.
  ///
  /// ````
  /// {
  ///   "id": 24481799,
  ///   "study_id": 2,
  ///   "created_by_user_id": 2,
  ///   "created_at": "2019-06-19T09:50:44.245Z",
  ///   "updated_at": "2019-06-19T09:50:44.245Z",
  ///   "carp_header": {
  ///     "study_id": "8",
  ///     "user_id": "user@dtu.dk",
  ///     "data_format": {
  ///       "name": "location",
  ///       "namepace": "carp"
  ///     },
  ///     "trigger_id": "task1",
  ///     "device_role_name": "Patient's phone",
  ///     "upload_time": "2019-06-19T09:50:43.551Z",
  ///     "start_time": "2018-11-08T15:30:40.721748Z",
  ///     "end_time": "2019-06-19T09:50:43.551Z"
  ///   },
  ///   "carp_body": {
  ///     "altitude": 43.3,
  ///     "device_info": {},
  ///     "classname": "LocationDatum",
  ///     "latitude": 23454.345,
  ///     "accuracy": 12.4,
  ///     "speed_accuracy": 12.3,
  ///     "id": "3fdd1760-bd30-11e8-e209-ef7ee8358d2f",
  ///     "speed": 2.3,
  ///     "timestamp": "2018-11-08T15:30:40.721748Z",
  ///     "longitude": 23.4
  ///   }
  ///  }
  /// ````
  ///
  Future<List<DataPoint>> query(String query) async {
    String url = (query.isEmpty)
        ? dataEndpointUri
        : "$dataEndpointUri?query=$query";

    // GET the data points from the CARP web service
    // TODO - for some reason the CARP web service don't like encoded url's....
    // http.Response response = await httpr.get(Uri.encodeFull(url), headers: restHeaders);
    final response = await service._get(url);

    // we expect a list of data points in the response
    List<dynamic> list = service._handleResponse(response) as List<dynamic>;

    List<DataPoint> datapoints = [];
    for (var item in list) {
      datapoints.add(DataPoint.fromJson(item as Map<String, dynamic>));
    }
    return datapoints;
  }

  /// The number of data points matching the [query] for this deployment.
  ///
  /// A [query] using [REST SQL (RSQL)](https://github.com/jirutka/rsql-parser)
  /// can be provided.
  Future<int> count([String query = '']) async {
    String url = (query.isEmpty)
        ? "$dataEndpointUri/count"
        : "$dataEndpointUri/count?query=$query";

    http.Response response = await service._get(url);

    // we expect a number as a string in the response
    var count = service._handleResponse(response).toString();
    return int.tryParse(count) ?? 0;
  }

  /// Deletes a data point with the given [id].
  ///
  /// Returns on success. Throws a [CarpServiceException] if data point is not
  /// found or otherwise unsuccessful.
  Future<void> delete(int id) async {
    final url = "$dataEndpointUri/$id";

    await service
        ._delete(url)
        .then(
          (response) =>
              // we don't need the response for anything, but check for errors
              service._handleResponse(response),
        );
  }
}
