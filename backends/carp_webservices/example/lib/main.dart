library;

import 'dart:io';
import 'package:flutter/material.dart';

import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:carp_core/carp_core.dart';

import 'package:oidc/oidc.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart' as qr;

part 'qr-scanner.dart';

void main() {
  CarpMobileSensing.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'CARP Backend Demo',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    bloc.init();
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          StreamBuilder(
              stream: CarpAuthService().manager?.userChanges(),
              builder: (BuildContext context, AsyncSnapshot<OidcUser?> event) {
                if (!event.hasData) {
                  return Column(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            builder: (context) => QRViewExample(),
                          );
                        },
                        icon: const Icon(Icons.login),
                        label: const Text(
                          'SCAN',
                          style: TextStyle(fontSize: 35),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async => bloc.currentUser =
                            await CarpAuthService().authenticate(),
                        icon: const Icon(Icons.login),
                        label: const Text(
                          'LOGIN',
                          style: TextStyle(fontSize: 35),
                        ),
                      )
                    ],
                  );
                } else {
                  return TextButton.icon(
                    onPressed: () => CarpAuthService().logout(),
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'LOGOUT',
                      style: TextStyle(fontSize: 35),
                    ),
                  );
                }
              }),
          TextButton.icon(
            onPressed: () => bloc.getStudyInvitation(context),
            icon: const Icon(Icons.mail),
            label: const Text(
              'GET STUDY',
              style: TextStyle(fontSize: 35),
            ),
          ),
          StreamBuilder(
            stream: CarpAuthService().authStateChanges,
            builder: (BuildContext context, AsyncSnapshot<AuthEvent> event) =>
                Padding(
              padding: const EdgeInsets.fromLTRB(10, 30, 10, 0),
              child: Text(
                (CarpAuthService().authenticated)
                    ? 'Authenticated as ${CarpAuthService().currentUser.username} ${CarpAuthService().currentUser.firstName} ${CarpAuthService().currentUser.lastName}'
                    : 'Not authenticated',
                textAlign: TextAlign.center,
              ),
            ),
          )
        ],
      )),
    );
  }
}

class AppBLoC {
  ActiveParticipationInvitation? _invitation;

  // The URI of the CAWS server to connect to.
  final Uri uri = Uri(
    scheme: 'https',
    host: 'dev.carp.dk',
  );

  late CarpApp app = CarpApp(
    name: "CAWS @ DTU [DEV]",
    uri: uri,
  );

  // The authentication configuration
  late CarpAuthProperties authProperties = CarpAuthProperties(
    authURL: uri,
    clientId: 'caws-example-app',
    redirectURI: Uri.parse('caws-example-app-auth://auth'),
    anonymousRedirectURI: Uri.parse('caws-example-app:/anonymous'),
    // For authentication at CAWS the path is '/auth/realms/Carp'
    discoveryURL: uri.replace(pathSegments: [
      'auth',
      'realms',
      'Carp',
    ]),
  );

  CarpUser? currentUser;
  bool get authenticated => currentUser != null;
  String? get studyId => _invitation?.studyId;
  String? get studyDeploymentId => _invitation?.studyDeploymentId;

  Future<void> init() async {
    await CarpAuthService().configure(authProperties);
    CarpService().configure(app);
  }

  void dispose() async {}

  Future<ActiveParticipationInvitation?> getStudyInvitation(
    BuildContext context,
  ) async {
    // configure a participant service based on the carp service already configured
    CarpParticipationService().configureFrom(CarpService());
    _invitation = await CarpParticipationService().getStudyInvitation(context);
    debugPrint('CARP Study Invitation: $_invitation');

    if (_invitation != null) {
      var study = SmartphoneStudy.fromInvitation(_invitation!);
      CarpParticipationService().study = study;
      debugPrint('Study : $study');
    }

    return _invitation;
  }
}

final bloc = AppBLoC();
