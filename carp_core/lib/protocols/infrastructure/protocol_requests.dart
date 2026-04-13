/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../protocol.dart';

/// An abstract RPC request to a [ProtocolService].
abstract class ProtocolServiceRequest extends ServiceRequest {
  final String _infrastructurePackageNamespace =
      'dk.cachet.carp.protocols.infrastructure';
  ProtocolServiceRequest() : super();

  @override
  String get apiVersion => ProtocolService.API_VERSION;

  @override
  String get jsonType =>
      '$_infrastructurePackageNamespace.ProtocolServiceRequest.$runtimeType';
}

/// An RPC request for [ProtocolService.add].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class Add extends ProtocolServiceRequest {
  final StudyProtocol protocol;
  String? versionTag;

  /// Create a new add request.
  /// If [versionTag] is `null` the version tag is current timestamp.
  Add(this.protocol, [this.versionTag]) : super() {
    versionTag ??= DateTime.now().toUtc().toString();
  }

  @override
  Function get fromJsonFunction => _$AddFromJson;
  factory Add.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<Add>(json);
  @override
  Map<String, dynamic> toJson() => _$AddToJson(this);
}

/// An RPC request for [ProtocolService.addVersion].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class AddVersion extends Add {
  AddVersion(super.protocol, super.versionTag);

  @override
  Function get fromJsonFunction => _$AddVersionFromJson;
  factory AddVersion.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<AddVersion>(json);
  @override
  Map<String, dynamic> toJson() => _$AddVersionToJson(this);
}

/// An RPC request for [ProtocolService.updateParticipantDataConfiguration].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class UpdateParticipantDataConfiguration extends ProtocolServiceRequest {
  final String protocolId;
  final String? versionTag;
  final List<ExpectedParticipantData>? expectedParticipantData;

  UpdateParticipantDataConfiguration(
    this.protocolId,
    this.versionTag,
    this.expectedParticipantData,
  ) : super();

  @override
  Function get fromJsonFunction => _$UpdateParticipantDataConfigurationFromJson;
  factory UpdateParticipantDataConfiguration.fromJson(
    Map<String, dynamic> json,
  ) => FromJsonFactory().fromJson<UpdateParticipantDataConfiguration>(json);
  @override
  Map<String, dynamic> toJson() =>
      _$UpdateParticipantDataConfigurationToJson(this);
}

/// An RPC request for [ProtocolService.getBy].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GetBy extends ProtocolServiceRequest {
  final String protocolId;

  @JsonKey(includeIfNull: false)
  final String? versionTag;

  GetBy(this.protocolId, this.versionTag) : super();

  @override
  Function get fromJsonFunction => _$GetByFromJson;
  factory GetBy.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<GetBy>(json);
  @override
  Map<String, dynamic> toJson() => _$GetByToJson(this);
}

/// An RPC request for [ProtocolService.getAllForOwner].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GetAllForOwner extends ProtocolServiceRequest {
  final String ownerId;

  GetAllForOwner(this.ownerId) : super();

  @override
  Function get fromJsonFunction => _$GetAllForOwnerFromJson;
  factory GetAllForOwner.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<GetAllForOwner>(json);
  @override
  Map<String, dynamic> toJson() => _$GetAllForOwnerToJson(this);
}

/// An RPC request for [ProtocolService.getVersionHistoryFor].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GetVersionHistoryFor extends ProtocolServiceRequest {
  final String protocolId;

  GetVersionHistoryFor(this.protocolId) : super();

  @override
  Function get fromJsonFunction => _$GetVersionHistoryForFromJson;
  factory GetVersionHistoryFor.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<GetVersionHistoryFor>(json);
  @override
  Map<String, dynamic> toJson() => _$GetVersionHistoryForToJson(this);
}

/// An RPC request for [ProtocolFactoryService.createCustomProtocol].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class CreateCustomProtocol extends ProtocolServiceRequest {
  final String ownerId;
  final String name;
  final String description;
  final String customProtocol;

  CreateCustomProtocol(
    this.ownerId,
    this.name,
    this.description,
    this.customProtocol,
  ) : super();

  @override
  String get jsonType =>
      '$_infrastructurePackageNamespace.ProtocolFactoryServiceRequest.$runtimeType';

  @override
  Function get fromJsonFunction => _$CreateCustomProtocolFromJson;
  factory CreateCustomProtocol.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<CreateCustomProtocol>(json);
  @override
  Map<String, dynamic> toJson() => _$CreateCustomProtocolToJson(this);
}
