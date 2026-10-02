/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of 'carp_services.dart';

/// A signed consent document read from the legacy CAWS consent endpoint.
///
/// Returned by the deprecated [CarpService.createConsentDocument] and
/// [CarpService.getConsentDocument]. New code stores informed consent as
/// participant data via [ParticipationReference.setInformedConsent].
///
/// The document can be extracted with the [document] property or by using
/// subscript syntax to access a specific field.
class ConsentDocument {
  ConsentDocument._(this._snapshot);

  final Map<String, dynamic>? _snapshot;

  /// The full data snapshot
  Map<String, dynamic> get snapshot => _snapshot!;

  /// The ID of the snapshot's document
  int get id => snapshot['id'] as int;

  /// The id of the study deployment of this document
  String? get deploymentId => snapshot['deployment_id'].toString();

  /// The id of the user who created this document
  String? get createdBy => snapshot['created_by'].toString();

  /// The timestamp of creation of this document
  DateTime get createdAt => DateTime.parse(snapshot['created_at'].toString());

  /// The timestamp of latest update of this document
  DateTime get updatedAt => DateTime.parse(snapshot['updated_at'].toString());

  /// The actual consent document
  Map<String, dynamic> get document => snapshot['data'] as Map<String, dynamic>;

  /// Reads individual data values from the snapshot
  dynamic operator [](String key) => document[key];

  @override
  String toString() =>
      "ConsentDocument - id : $id, deployment: $deploymentId, document size: ${document.length}";
}
