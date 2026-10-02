part of 'carp_backend.dart';

/// Translations for a Flutter app, loaded from CAWS.
///
/// Add [CarpLocalizations.delegate] to the `localizationsDelegates` of a
/// `MaterialApp` and look up strings with `CarpLocalizations.of(context)`.
/// Translations are fetched (and cached) by [CarpResourceManager.getLocalizations],
/// so [CarpService] must be configured and a study set before the app loads them.
class CarpLocalizations {
  /// The locale these translations are for.
  final Locale locale;

  CarpLocalizations(this.locale);

  /// The [CarpLocalizations] of the closest [Localizations] widget above
  /// [context], or `null` if [delegate] is not registered.
  static CarpLocalizations? of(BuildContext context) {
    return Localizations.of<CarpLocalizations>(context, CarpLocalizations);
  }

  Map<String, String>? _localizedStrings;

  /// Loads the translations for [locale] via [CarpResourceManager].
  ///
  /// Called by [delegate]. Logs a warning if no translations are found.
  Future<void> load() async {
    _localizedStrings = await CarpResourceManager().getLocalizations(locale);
    if (_localizedStrings == null) {
      warning('Could not load localizations for locale: $locale');
    }
  }

  /// The translation of [key] for this [locale].
  ///
  /// Returns [key] itself if it has no translation.
  /// Throws if [load] has not completed or found no translations.
  String? translate(String key) =>
      (_localizedStrings!.containsKey(key)) ? _localizedStrings![key] : key;

  /// The delegate to add to `MaterialApp.localizationsDelegates`.
  ///
  /// Supports every locale (see [CarpResourceManager.isSupported]) and never reloads.
  static const LocalizationsDelegate<CarpLocalizations> delegate =
      _CarpLocalizationsDelegate();
}

class _CarpLocalizationsDelegate
    extends LocalizationsDelegate<CarpLocalizations> {
  // This delegate instance will never change (it doesn't even have fields!)
  // It can provide a constant constructor.
  const _CarpLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => CarpResourceManager().isSupported(locale);

  @override
  Future<CarpLocalizations> load(Locale locale) async {
    CarpLocalizations localizations = CarpLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_CarpLocalizationsDelegate old) => false;
}
