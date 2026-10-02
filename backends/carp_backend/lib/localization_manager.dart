/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_backend.dart';

/// Retrieves and stores translations (key-value maps) per language.
///
/// Implemented by [CarpResourceManager], which keeps them on CAWS. Used by
/// [CarpLocalizations] to translate the app.
abstract class LocalizationManager {
  /// Resets the manager, e.g. when the study changes.
  void initialize() {}

  /// Whether translations for [locale] can be loaded by this manager.
  bool isSupported(Locale locale);

  /// The translations for [locale] as a key-value map.
  ///
  /// Translations are named by the [Locale.languageCode] of [locale];
  /// for example, the Danish translation is named `da`.
  /// If [refresh] is `true`, any local cache is skipped.
  ///
  /// Returns `null` if there are no translations for [locale].
  Future<Map<String, String>?> getLocalizations(Locale locale, {bool refresh = false});

  /// Stores the [localizations] for [locale].
  ///
  /// Translations are named by the [Locale.languageCode] of [locale];
  /// for example, the Danish translation is named `da`.
  ///
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> setLocalizations(Locale locale, Map<String, dynamic> localizations);

  /// Deletes the translations for [locale].
  ///
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> deleteLocalizations(Locale locale);
}
