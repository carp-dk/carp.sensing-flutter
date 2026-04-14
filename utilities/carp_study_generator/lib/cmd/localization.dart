part of '../carp_study_generator.dart';

class LocalizationCommand extends AbstractCommand {
  LocalizationCommand() : super();

  String getLocaleJson(String locale) {
    print("Reading the locale for: '$locale'");
    return File('$localizationPath$locale.json').readAsStringSync();
  }

  @override
  Future<void> execute() async {
    await authenticate();

    for (var element in locales) {
      String locale = element.toString();
      Map<String, dynamic> upLocalizations =
          json.decode(getLocaleJson(locale)) as Map<String, dynamic>;

      print("Uploading localization for locale: '$locale' to CARP.");
      bool success = await CarpResourceManager().setLocalizations(
        Locale(locale),
        upLocalizations,
      );

      if (success) {
        print('Upload successful - # elements: ${upLocalizations.length}');

        print("Downloading localization for locale: '$locale' from CARP.");
        Map<String, String>? downLocalizations = await CarpResourceManager()
            .getLocalizations(Locale(locale), refresh: true, cache: false);

        (downLocalizations != null)
            ? print(
                'Download successful - # elements: ${downLocalizations.length}',
              )
            : print('Download returned null - something went wrong.');
      } else {
        print('Upload not successful - something went wrong.');
      }
    }
  }
}
