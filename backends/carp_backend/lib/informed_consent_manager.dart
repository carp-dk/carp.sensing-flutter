/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_backend.dart';

/// Retrieves and stores the study's consent document as JSON.
///
/// The app decides how to show it, e.g. with `RPOrderedTask.fromJson` from the
/// `research_package`. Implemented by [CarpResourceManager], which keeps it on CAWS.
abstract class InformedConsentManager {
  /// Resets the manager, e.g. when the study changes.
  void initialize() {}

  /// The consent document last set with [setConsentDocument].
  ///
  /// `null` if none has been set. Use [getConsentDocument] to download the
  /// consent document from CAWS.
  Map<String, dynamic>? get informedConsent;

  /// The consent document to show for this study.
  ///
  /// This is the JSON of an `RPOrderedTask`. See [research_package](https://pub.dev/packages/research_package)
  /// for how to create a consent document.
  /// If [refresh] is `true`, any local cache is skipped.
  ///
  /// Returns `null` if there is no consent document for this study.
  Future<Map<String, dynamic>?> getConsentDocument({bool refresh = false});

  /// Sets the consent document to use for this study.
  ///
  /// Note that this method sets the **overall** consent document to be shown to
  /// all participants. Uploading of a specific **signed** consent document for
  /// a participant is done using the [ParticipationReference.setInformedConsent]
  /// method using a [ParticipationReference].
  Future<bool> setConsentDocument(Map<String, dynamic> informedConsent);

  /// Deletes the consent document for this study.
  ///
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> deleteConsentDocument();
}
