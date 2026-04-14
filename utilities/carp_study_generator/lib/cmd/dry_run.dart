part of '../carp_study_generator.dart';

/// A [Command] that makes a dry run of the configuration of a CAMS study.
/// It checks the following:
///
///  * Is there a valid CARP app specification
///  * Is the specified CARP Server accessible
///  * Is authentication possible with the specified credentials
///  * Can the study protocol be loaded and parsed without errors
///  * Can the informed consent be loaded and parsed without errors
///  * Can the language locales be loaded and parsed without errors
///
class DryRunCommand extends AbstractCommand {
  DryRunCommand() : super();

  @override
  Future<void> execute() async {
    int issues = 0;

    try {
      CarpService().configure(app);
      print('\x1B[32m[✓]\x1B[0m CARP App \t\t $app');
    } catch (error) {
      print('\x1B[31m[!]\x1B[0m CARP App \t\t ${errorToString(error)}');
      issues++;
    }

    try {
      await authenticate();
      print('\x1B[32m[✓]\x1B[0m Authenticated \t username: $username');
    } catch (error) {
      print('\x1B[31m[!]\x1B[0m Authenticated \t ${errorToString(error)}');
      issues++;
    }

    String? protocolJson;
    try {
      protocolJson = File(protocolPath).readAsStringSync();
      print('\x1B[32m[✓]\x1B[0m Protocol path \t $protocolPath');
    } catch (error) {
      print(
        '\x1B[31m[!]\x1B[0m Protocol path \t Could not read protocol path from carpspec.yaml - has this been specified?',
      );
      //print('$error');
      issues++;
    }

    if (protocolJson != null) {
      try {
        StudyProtocol protocol = StudyProtocol.fromJson(
          json.decode(protocolJson) as Map<String, dynamic>,
        );
        print('\x1B[32m[✓]\x1B[0m Protocol parse \t name: ${protocol.name}');
      } catch (error) {
        print(
          '\x1B[31m[!]\x1B[0m Protocol parse \t Error parsing protocol json - ${errorToString(error)}',
        );
        issues++;
      }
    } else {
      print('\x1B[31m[!]\x1B[0m Protocol parse \t No protocol to parse');
      issues++;
    }

    String? consentJson;
    try {
      consentJson = File(consentPath).readAsStringSync();
      print('\x1B[32m[✓]\x1B[0m Consent path \t $consentPath');
    } catch (error) {
      print(
        '\x1B[31m[!]\x1B[0m Consent path \t Could not read consent path from carpspec.yaml - has this been specified?',
      );
      issues++;
    }

    if (consentJson != null) {
      try {
        RPOrderedTask consent = RPOrderedTask.fromJson(
          json.decode(consentJson) as Map<String, dynamic>,
        );

        print(
          '\x1B[32m[✓]\x1B[0m Consent \t\t identifier: ${consent.identifier}',
        );
      } catch (error) {
        print(
          '\x1B[31m[!]\x1B[0m Consent parse \t Error parsing consent json - ${errorToString(error)}',
        );
        issues++;
      }
    } else {
      print('\x1B[31m[!]\x1B[0m Consent parse \t No consent to parse');
      issues++;
    }

    String locale = '', path = '';
    try {
      for (var element in locales) {
        locale = element.toString();
        path = '$localizationPath$locale.json';
        String localeJson = File(path).readAsStringSync();
        json.decode(localeJson);
        print('\x1B[32m[✓]\x1B[0m Locale - $locale \t $path');
      }
    } catch (error) {
      print('\x1B[31m[!]\x1B[0m Locale - $locale \t ${errorToString(error)}');
      issues++;
    }

    String id = '';
    try {
      for (var element in messageIds) {
        id = element.toString();
        path = '$messagesPath$id.json';
        String localeJson = File(path).readAsStringSync();
        json.decode(localeJson);
        print('\x1B[32m[✓]\x1B[0m Message - $id \t $path');
      }
    } catch (error) {
      print('\x1B[31m[!]\x1B[0m Message - $id \t ${errorToString(error)}');
      issues++;
    }

    print(
      '${(issues == 0) ? '\x1B[32m • \x1B[0m No' : '\x1B[31m • \x1B[0m $issues'} issues found!',
    );
  }

  /// Transform a multiline error message to one line only.
  String errorToString(dynamic error) {
    int index = error.toString().indexOf('\n');
    return (index > 0)
        ? error.toString().substring(0, index)
        : error.toString();
  }
}
