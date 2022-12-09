/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of domain;

/// A description of how a study is to be executed on a smartphone.
///
/// A [SmartphoneStudyProtocol] defining the master device ([MasterDeviceDescriptor])
/// responsible for aggregating data (typically this phone), the optional
/// devices ([DeviceDescriptor]) connected to the master device,
/// and the [Trigger]'s which lead to data collection on said devices.
@JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class SmartphoneStudyProtocol extends StudyProtocol {
  /// The description of this study protocol containing the title, description,
  /// purpose, and the responsible researcher for this study.
  StudyDescription? protocolDescription;

  @override
  String get description => protocolDescription?.description ?? '';

  /// The PI responsible for this protocol.
  StudyResponsible? get responsible => protocolDescription?.responsible;

  /// Specifies where and how to stored or upload the data collected from this
  /// deployment. If `null`, the sensed data is not stored, but may still be
  /// used in the app.
  DataEndPoint? dataEndPoint;

  /// Application-specific data to be stored as part of the study protocol
  /// which will be included in all deployments of this study protocol.
  Map<String, dynamic>? applicationData;

  /// Create a new [SmartphoneStudyProtocol].
  SmartphoneStudyProtocol({
    required super.ownerId,
    required super.name,
    this.protocolDescription,
    this.dataEndPoint,
    this.applicationData,
  }) : super(
          description: protocolDescription?.description ?? '',
        );

  factory SmartphoneStudyProtocol.fromJson(Map<String, dynamic> json) =>
      _$SmartphoneStudyProtocolFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$SmartphoneStudyProtocolToJson(this);
}
