// ignore_for_file: unused_element

part of 'carp_services.dart';

/// An abstract base service class for all CARP Services:
///  * [ParticipationService]
///  * [DeploymentService]
///  * [ProtocolService]
///  * [CarpService]
///
/// The (current) assumption is that each Flutter app (using this library) will
/// only connect to one CARP web services backend.
/// Therefore a all all CARP services are singletons and can be used like:
///
/// ```dart
/// await CarpAuthService().configure(authProperties);
///
/// var user = await CarpAuthService().authenticateWithUsernamePassword(
///   username: username,
///   password: password,
/// );
///
///  final app = CarpApp(
///     name: 'CAWS DEV',
///     uri: Uri(
///       scheme: 'https',
///       host: 'dev.carp.dk',
///     ));
///
/// CarpParticipationService().configure(app);
/// ```
///
/// where `authProperties`, `username`, and `password` are parameters for setting up
/// authentication, and `app` is configuring the participation service to use the
/// right CAWS instance.
abstract class CarpBaseService {
  CarpApp? _app;
  String? _endpointName;

  /// The study associated with this service, if available.
  /// Can be set directly or as part of the [configure] methods.
  SmartphoneStudy? study;

  /// The CARP app associated with the CARP Web Service.
  ///
  /// Throws a [CarpServiceException] if this service has not yet been configured via the
  /// [configure] method.
  CarpApp get app {
    if (_app == null) {
      throw CarpServiceException(
        "CARP Service not configured. Call 'configure()' first.",
      );
    } else {
      return _app!;
    }
  }

  /// Has this service been configured?
  bool get isConfigured => (_app != null);

  @override
  String toString() => '$runtimeType - ${app.name} [${app.uri}]';

  /// Configure the this instance of a Carp Service.
  ///
  /// The [app] specifies the CAWS instance used.
  /// If [study] is specified, this service is 'tied' to this study deployment.
  /// This is convenient if the application using this service is only handling
  /// one study deployment (which is often the case).
  void configure(CarpApp app, [SmartphoneStudy? study]) {
    _app = app;
    this.study = study;
  }

  /// Configure from another [service] which has already been configured.
  void configureFrom(CarpBaseService service) {
    _app = service.app;
    study = service.study;
  }

  /// Resolve study ID.
  ///
  /// Returns [studyId] if not null. Otherwise returns the studyId specified in
  /// the [study], if available.
  /// Throws an error if study id cannot be resolved.
  String getStudyId([String? studyId]) {
    if (studyId != null) {
      return studyId;
    } else if (study != null && study?.studyId != null) {
      return study!.studyId!;
    } else {
      throw CarpServiceException('No study ID specified for CAWS endpoint.');
    }
  }

  /// Resolve study deployment ID.
  ///
  /// Returns [studyDeploymentId] if not null. Otherwise returns the study
  /// deployment ID specified in the [study], if available.
  /// Throws an error if study deployment id cannot be resolved.
  String getStudyDeploymentId([String? studyDeploymentId]) {
    if (studyDeploymentId != null) return studyDeploymentId;
    if (study != null) return study!.studyDeploymentId;

    throw CarpServiceException(
      'No study deployment ID specified for CAWS end point.',
    );
  }

  /// Resolve the primary device role name.
  ///
  /// Returns [deviceRoleName] if not null. Otherwise returns the device role
  /// name specified in the [study], if available.
  /// Throws an error if device role name cannot be resolved.
  String getPrimaryDeviceRoleName([String? deviceRoleName]) {
    if (deviceRoleName != null) return deviceRoleName;
    if (study != null) return study!.deviceRoleName;

    throw CarpServiceException(
      'No primary device role name specified for CAWS end point.',
    );
  }

  /// The endpoint name for this service at CARP.
  String get rpcEndpointName;

  /// The URL for this service's endpoint at CARP.
  ///
  /// Typically on the form:
  /// `{{PROTOCOL}}://{{SERVER_HOST}}:{{SERVER_PORT}}/api/...`
  String get rpcEndpointUri => "${app.uri}/api/$_endpointName";

  /// The headers for any authenticated HTTP REST call to a [CarpBaseService].
  Map<String, String> get headers {
    if (CarpAuthService().currentUser.token == null) {
      throw CarpServiceException(
        "OAuth token is null. Call 'CarpAuthService().authenticate()' first.",
      );
    }

    return {
      "Content-Type": "application/json",
      "Authorization":
          "bearer ${CarpAuthService().currentUser.token!.accessToken}",
      "cache-control": "no-cache",
    };
  }

  /// A generic RPC [request] to the [endpointName] service endpoint at the
  /// CARP Server.
  ///
  /// If [endpointName] is not specified, the default [rpcEndpointName] is used.
  ///
  /// Returns either a JSON map as `Map<String, dynamic>`or JSON list as
  /// `List<dynamic>`.
  ///
  /// Throws [CarpServiceRequestException] on errors.
  Future<dynamic> _rpc(ServiceRequest request, [String? endpointName]) async {
    _endpointName = endpointName ?? rpcEndpointName;
    final requestBody = toJsonString(request.toJson());

    debug('REQUEST: POST $rpcEndpointUri\n$requestBody');
    http.Response response = await httpr.post(
      Uri.encodeFull(rpcEndpointUri),
      headers: headers,
      body: requestBody,
    );
    // int httpStatusCode = response.statusCode;
    // String responseBody = response.body;
    debug('RESPONSE: ${response.statusCode}\n${response.body}');

    return _handleResponse(response);
  }

  /// Sends an HTTP GET request to the given [url] for this CAWS service.
  Future<http.Response> _get(String url) async {
    debug('REQUEST: GET $url');

    var response = await httpr.get(url, headers: headers);

    debug('RESPONSE: ${response.statusCode}\n${response.body}');

    // If we get a 403 forbidden response try to refresh token and retry once.
    // See issue : https://github.com/cph-cachet/carp.sensing-flutter/issues/392
    if (response.statusCode == HttpStatus.forbidden) {
      await CarpAuthService().refresh();
      response = await httpr.get(url, headers: headers);
    }

    return _clean(response);
  }

  /// Sends an HTTP POST request with [body] to the given [url] for this CAWS service.
  Future<http.Response> _post(String url, {Object? body}) async {
    debug('REQUEST: POST $url\nBODY SIZE: ${body.toString().length}\n$body');

    var response = await httpr.post(url, headers: headers, body: body);

    debug('RESPONSE: ${response.statusCode}\n${response.body}');

    if (response.statusCode == HttpStatus.forbidden) {
      await CarpAuthService().refresh();
      response = await httpr.post(url, headers: headers, body: body);
    }

    return _clean(response);
  }

  /// Sends an HTTP PUT request with [body] to the given [url] for this CAWS service.
  Future<http.Response> _put(String url, {Object? body}) async {
    debug('REQUEST: PUT $url\n$body');

    var response = await httpr.put(url, headers: headers, body: body);

    debug('RESPONSE: ${response.statusCode}\n${response.body}');

    if (response.statusCode == HttpStatus.forbidden) {
      await CarpAuthService().refresh();
      response = await httpr.put(url, headers: headers, body: body);
    }

    return _clean(response);
  }

  /// Sends an generic HTTP SEND request.
  Future<http.Response> _send(http.MultipartRequest request) async {
    debug('REQUEST: SEND $request');

    var status = await httpr.send(request);

    if (status.statusCode == HttpStatus.forbidden) {
      await CarpAuthService().refresh();
      status = await httpr.send(request);
    }

    var response = await http.Response.fromStream(status);
    debug('RESPONSE: ${response.statusCode}\n${response.body}');

    return _clean(response);
  }

  /// Sends an HTTP DELETE request to the given [url] for this CAWS service.
  Future<http.Response> _delete(String url) async {
    debug('REQUEST: DELETE $url');

    var response = await httpr.delete(url, headers: headers);

    debug('RESPONSE: ${response.statusCode}\n${response.body}');

    if (response.statusCode == HttpStatus.forbidden) {
      await CarpAuthService().refresh();
      response = await httpr.delete(url, headers: headers);
    }

    return _clean(response);
  }

  /// Check if we get an Nginx reverse proxy error in HTML format, and if so
  /// convert it to a JSON error message.
  ///
  /// See issue : https://github.com/cph-cachet/carp.sensing-flutter/issues/369
  http.Response _clean(http.Response response) =>
      response.body.startsWith('<html>')
      ? http.Response(
          '{'
          '"statusCode": 502,'
          '"message": "502 Bad Gateway.",'
          '"path": "POST ${response.request?.url}"'
          '}',
          response.statusCode,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
          request: response.request,
        )
      : response;

  /// Handles an HTTP [response].
  ///
  /// Returns the JSON body if the response indicates success.
  /// Note that this can be both a JSON map or a JSON list.
  ///
  /// Throws exceptions based on the status code, if not a success response.
  dynamic _handleResponse(http.Response response) {
    final status = response.statusCode;
    final body = response.body.isEmpty ? '{}' : response.body;
    final responseJson = json.decode(body);
    if (status >= HttpStatus.ok && status < 300) return responseJson;

    // All other cases are treated as an exception
    throw CarpServiceRequestException.fromHttpStatus(status, responseJson);
  }
}
