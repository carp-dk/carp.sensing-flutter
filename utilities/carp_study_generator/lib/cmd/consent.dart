part of '../carp_study_generator.dart';

/// A [Command] that take the informed consent specified in the file
/// `consent/InformedConsent.dart` and uploads it to the CARP server.
class ConsentCommand extends AbstractCommand {
  String? _consentJson;
  RPOrderedTask? _consent;

  ConsentCommand() : super();

  String get consentJson {
    if (_consentJson == null) {
      print('Reading the informed consent from file: $consentPath');
      _consentJson = File(consentPath).readAsStringSync();
    }
    return _consentJson!;
  }

  RPOrderedTask get informedConsent {
    if (_consent == null) {
      print('Checking that this is a valid RP Ordered Task');
      _consent = RPOrderedTask.fromJson(
        json.decode(consentJson) as Map<String, dynamic>,
      );
    }
    return _consent!;
  }

  @override
  Future<void> execute() async {
    await authenticate();
    consentJson;
    informedConsent;
    print('Uploading informed consent to CARP\n study_id: $studyId');
    await CarpResourceManager().setConsentDocument(informedConsent);
    print('Upload successful!');
  }
}
