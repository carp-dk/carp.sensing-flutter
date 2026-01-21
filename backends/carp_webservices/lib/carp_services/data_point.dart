/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_services.dart';

/// A data point storing meta-information and the data.
///
/// CARP DataPoint definition accepted by the server, version 1.2 (example):
///
/// ```
/// {
///  "id": 224038,                                   # set by the server, not used in upload
///  "created_by_user_id": 1,                        # set by the server, not used in upload
///  "study_id": "c9d341ae",                         # set by the server, not used in upload
///  "carp_header": {
///   "study_id": "01cf04a7",                        # required - should be the study_deployment_id
///   "device_role_name": "phone",                   # optional
///   "trigger_id": "1",                             # optional
///   "user_id": "1e828ea0-78f7-11eb-a4c1",          # required - use a UUID and avoid usernames like 'user@dtu.dk'
///   "upload_time": "2021-02-27T12:27:14.933672Z",  # set by the server, not used in upload
///   "start_time": "2021-02-27T12:27:12.902614Z",   # optional
///   "end_time": "2021-02-27T12:27:14.933672Z",     # optional
///   "data_format": {                               # required
///    "namespace": "dk.cachet.carp",
///    "name": "light"
///   }
///  },
///  "carp_body": {                                  # required
///   "id": "1e828ea0-78f7-11eb-a4c1-8518ece21966",
///   "timestamp": "2021-02-27T12:27:12.902614Z"
///   "max_lux": 12,
///   "mean_lux": 23,
///   "min_lux": 0.3,
///   "std_lux": 0.4,
///  }
/// }
/// ```
@JsonSerializable(
  fieldRename: FieldRename.snake,
  includeIfNull: false,
  explicitToJson: true,
)
class DataPoint {
  /// A unique, server-side generated ID for this data point.
  /// `null` if this data point is not yet stored.
  int? id;

  /// The unique id of the user who created / uploaded this data point.
  /// `null` if this data point is not yet stored.
  ///
  /// This user id is the server-side generated user id (an integer), and **NOT**
  /// the user id that this data point belongs to, which is stored in the
  /// [DataPointHeader] as the [userId] (a string, typically the email).
  ///
  /// This [createdByUserId] id may, or may not, be identical to the id of the
  /// user who this data point belongs to.
  /// By being able to separate who uploads a data point and who the data point
  /// belongs to, allows for one user to upload data on behalf of another user.
  /// For example, a parent on behalf of a child.
  int? createdByUserId;

  /// The unique study deployment id that this data point belongs to / is uploaded
  /// as part of. Set by the server. `null` if this data point is not yet stored.
  String? studyId;

  /// The data point header.
  DataPointHeader carpHeader;

  /// The CARP data point body. Can be any payload modelled as a [Data].
  @JsonKey(includeFromJson: false, includeToJson: false)
  Data? data;

  Map<String, dynamic>? _carpBody;

  /// The CARP data point body. Can be any JSON payload.
  ///
  /// When this data point is created locally on the phone, the [carpBody] is
  /// a json serialization of [data].
  /// If this data point is deserialized from json, the [carpBody] is the raw
  /// json.
  ///
  /// Note that we do *not* support type/schema checking in this data pay load.
  /// CARP allow for any json formatted data to be uploaded and stored.
  Map<String, dynamic>? get carpBody =>
      (data != null) ? data!.toJson() : _carpBody;

  set carpBody(Map<String, dynamic>? data) => _carpBody = data;

  /// Create a new [DataPoint].
  DataPoint(this.carpHeader, [this.data]);

  /// Create a [DataPoint] from a [Data] object.
  factory DataPoint.fromData(Data data) => DataPoint(
    DataPointHeader(
      dataFormat: data.dataType,
      startTime: DateTime.now().toUtc(),
    ),
    data,
  );

  /// Create a [DataPoint] from a JSON map.
  factory DataPoint.fromJson(Map<String, dynamic> json) =>
      _$DataPointFromJson(json);

  /// Serialize this [DataPoint] as a JSON map.
  Map<String, dynamic> toJson() => _$DataPointToJson(this);
}

/// The header (meta-data) attached to all [DataPoint]s.
@JsonSerializable(
  fieldRename: FieldRename.snake,
  includeIfNull: false,
  explicitToJson: true,
)
class DataPointHeader {
  /// An ID of this study.
  ///
  /// This is the [studyId] from the [CAMSStudyProtocol], if specified.
  /// If not specified in the [CAMSStudyProtocol], it is the study deployment
  /// id of the [StudyDeployment] from which this data point was generated.
  String? studyId;

  /// The role of the device that collected this data point.
  String? deviceRoleName;

  /// The id of the [Trigger] in the study deployment that generated this data point.
  String? triggerId;

  /// The ID of the user (if known).
  String? userId;

  /// The UTC time stamp of when this data point was uploaded to the server.
  /// Set by the server.
  DateTime? uploadTime;

  /// The UTC start timestamp for this data point.
  DateTime? startTime;

  /// The UTC end timestamp for this data point.
  /// If this data point does not cover a period, [endTime] will be `null`.
  DateTime? endTime;

  /// The data format. See [DataType] and [NameSpace].
  DataType? dataFormat;

  /// Create a new [DataPointHeader].
  DataPointHeader({
    this.studyId,
    this.userId,
    this.dataFormat,
    this.deviceRoleName,
    this.triggerId,
    this.startTime,
    this.endTime,
  }) {
    // make sure that timestamps are in UTC
    if (startTime != null) startTime!.toUtc();
    if (endTime != null) endTime!.toUtc();
  }

  /// Create a [DataPointHeader] from a JSON map.
  factory DataPointHeader.fromJson(Map<String, dynamic> json) =>
      _$DataPointHeaderFromJson(json);

  /// Return a JSON encoding of this object.
  Map<String, dynamic> toJson() => _$DataPointHeaderToJson(this);
}
