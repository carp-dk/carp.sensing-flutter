import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import '_credentials.dart';

class CarpProperties {
  static final CarpProperties _instance = CarpProperties._();
  CarpProperties._();

  factory CarpProperties() => _instance;
  CarpProperties.instance() : this._();

  Uri get uri => Uri(scheme: 'https', host: cawsUri);

  CarpAuthProperties get authProperties => CarpAuthProperties(
    authURL: uri,
    clientId: 'studies-app',
    redirectURI: Uri.parse('carp-studies-auth://auth'),
    // For authentication at CAWS the path is '/auth/realms/Carp'
    discoveryURL: uri.replace(pathSegments: ['auth', 'realms', 'Carp']),
  );

  CarpApp get app => CarpApp(name: "CAWS @ $cawsUri", uri: uri);

  SmartphoneStudy get study => SmartphoneStudy(
    studyId: testStudyId,
    studyDeploymentId: testDeploymentId,
    deviceRoleName: testPhoneRoleName,
    participantId: testParticipantId,
    participantRoleName: testParticipantRoleName,
  );
}
