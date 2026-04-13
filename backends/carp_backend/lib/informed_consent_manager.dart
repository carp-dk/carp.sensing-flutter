/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_backend.dart';

/// Handles retrieving and storing consent document definitions as [RPOrderedTask]
/// json definitions.
abstract class InformedConsentManager {
  void initialize() {}

  /// The latest downloaded consent document.
  ///
  /// Returns null if no consent has been downloaded yet.
  /// Use the [getConsentDocument] method to get the consent document
  /// from CAWS.
  RPOrderedTask? get informedConsent;

  /// Get the consent document to be shown for this study.
  ///
  /// This method return a [RPOrderedTask] which is an ordered list of [RPStep]
  /// which are shown to the user as the consent document flow.
  /// See [research_package](https://pub.dev/packages/research_package) for a
  /// description on how to create an consent document in the research package
  /// domain model.
  ///
  /// Returns null if there is no consent document available for this study.
  Future<RPOrderedTask?> getConsentDocument({bool refresh = false});

  /// Set the consent document to be used for this study.
  ///
  /// Note that this method sets the **overall** consent document to be shown to
  /// all participants. Uploading of a specific **signed** consent document for
  /// a participant is done using the [ParticipationReference.setInformedConsent]
  /// method using a [ParticipationReference].
  Future<bool> setConsentDocument(RPOrderedTask informedConsent);

  /// Delete the consent document for this study.
  ///
  /// Returns true if delete is successful, false otherwise.
  Future<bool> deleteConsentDocument();
}
