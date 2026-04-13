/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_services.dart';

/// A [ProtocolService] that talks to the CARP Web Services.
///
/// In order to use this service and manage protocols the user must be
/// authenticated as a researcher.
class CarpProtocolService extends CarpBaseService
    implements ProtocolService, ProtocolFactoryService {
  static final CarpProtocolService _instance = CarpProtocolService._();

  CarpProtocolService._();

  /// Returns the singleton default instance of the [CarpProtocolService].
  /// Before this instance can be used, it must be configured using the [configure] method.
  factory CarpProtocolService() => _instance;

  @override
  String get rpcEndpointName => "protocol-service";

  @override
  Future<void> add(StudyProtocol protocol, [String? versionTag]) async =>
      await _rpc(Add(protocol, versionTag));

  @override
  Future<void> addVersion(StudyProtocol protocol, [String? versionTag]) async =>
      await _rpc(AddVersion(protocol, versionTag));

  /// Find all [StudyProtocol]'s owned by the owner with [ownerId].
  /// In the CARP web service, the [ownerId] is the logged in user's [accountId].
  ///
  /// Returns the last version of each [StudyProtocol] owned by the requested owner,
  /// or an empty list when none are found.
  @override
  Future<List<StudyProtocol>> getAllForOwner(String ownerId) async {
    final response = await _rpc(GetAllForOwner(ownerId));
    List<dynamic> items = response['items'] as List<dynamic>;
    return items
        .map((item) => StudyProtocol.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<StudyProtocol> getBy(String protocolId, [String? versionTag]) async =>
      StudyProtocol.fromJson(
        await _rpc(GetBy(protocolId, versionTag)) as Map<String, dynamic>,
      );

  @override
  Future<List<ProtocolVersion>> getVersionHistoryFor(String protocolId) async {
    Map<String, dynamic> responseJson =
        (await _rpc(GetVersionHistoryFor(protocolId)) as Map<String, dynamic>);
    final items = responseJson['items'] as List<dynamic>;
    return items
        .map((item) => ProtocolVersion.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<StudyProtocol> updateParticipantDataConfiguration(
    String protocolId,
    String versionTag,
    List<ExpectedParticipantData> expectedParticipantData,
  ) async => StudyProtocol.fromJson(
    await _rpc(
          UpdateParticipantDataConfiguration(
            protocolId,
            versionTag,
            expectedParticipantData,
          ),
        )
        as Map<String, dynamic>,
  );

  @override
  Future<StudyProtocol> createCustomProtocol(
    String ownerId,
    String name,
    String description,
    String customProtocol,
  ) async => StudyProtocol.fromJson(
    await _rpc(
          CreateCustomProtocol(ownerId, name, description, customProtocol),
          'protocol-factory-service',
        )
        as Map<String, dynamic>,
  );
}
