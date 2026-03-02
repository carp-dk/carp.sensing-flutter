part of '../carp_study_generator.dart';

/// The interface for all CARP Commands.
abstract class Command {
  /// Execute this command.
  Future<void> execute();
}

/// An abstract class for all CARP Commands.
abstract class AbstractCommand implements Command {
  static dynamic _yaml;
  CarpApp? _app;
  CarpAuthProperties? _authProperties;

  Uri? get _uri => Uri.parse(_yaml['server']['uri'] as String);
  Uri get uri {
    if (_uri == null) {
      throw Exception("No URI is provided");
    }
    return _uri!;
  }

  CarpApp get app => _app ??= CarpApp(name: "CAWS @ DTU", uri: uri);

  String get clientId => _yaml['server']['client_id'].toString();
  String get clientSecret => _yaml['server']['client_secret'].toString();
  String get username => _yaml['server']['username'].toString();
  String get password => _yaml['server']['password'].toString();

  String get studyId => _yaml['study']['study_id'].toString();
  String get studyDeploymentId =>
      _yaml['study']['study_deployment_id'].toString();

  String get protocolPath => _yaml['protocol']['path'].toString();
  String get consentPath => _yaml['consent']['path'].toString();

  String get messagesPath => _yaml['message']['path'].toString();
  List<dynamic> get messageIds => _yaml['message']['messages'] as List<dynamic>;

  String get localizationPath => _yaml['localization']['path'].toString();
  List<dynamic> get locales =>
      _yaml['localization']['locales'] as List<dynamic>;

  String get ownerId => CarpAuthService().currentUser.id;

  AbstractCommand() {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialization of serialization
    CarpMobileSensing.ensureInitialized();
    CarpDataManager();
    ResearchPackage.ensureInitialized();
    CognitionPackage.ensureInitialized();

    // make sure not to mess with CAMS
    Settings().saveAppTaskQueue = false;

    _yaml ??= loadYaml(File('carp/carpspec.yaml').readAsStringSync());

    // register the sampling packages
    // this is used to be able to deserialize the json protocol
    SamplingPackageRegistry().register(AppsSamplingPackage());
    SamplingPackageRegistry().register(CommunicationSamplingPackage());
    SamplingPackageRegistry().register(ContextSamplingPackage());
    SamplingPackageRegistry().register(MediaSamplingPackage());
    SamplingPackageRegistry().register(SurveySamplingPackage());
    SamplingPackageRegistry().register(HealthSamplingPackage());
    SamplingPackageRegistry().register(ESenseSamplingPackage());
    SamplingPackageRegistry().register(PolarSamplingPackage());
  }

  /// The configuration of the CARP server app.
  // CarpApp get app {
  void configure() {
    if (studyId.isEmpty) {
      throw Exception("The study ID cannot be empty - '$studyId'");
    }

    CarpService().configure(
      app,
      SmartphoneStudy(
        studyId: studyId,
        studyDeploymentId: studyDeploymentId,
        deviceRoleName:
            'ignored', // this is not used for the command line utilities
      ),
    );
  }

  // The authentication configuration
  CarpAuthProperties get authProperties {
    if (_authProperties == null) {}
    CarpAuthProperties(
      authURL: uri,
      clientId: 'studies-app',
      redirectURI: Uri.parse('carp-studies-auth://auth'),
      // For authentication at CAWS the path is '/auth/realms/Carp'
      discoveryURL: uri.replace(pathSegments: ['auth', 'realms', 'Carp']),
    );
    return _authProperties!;
  }

  /// Authenticate at the CARP server.
  Future<void> authenticate() async {
    configure();
    print('Authenticating to the CARP Server...');
    await CarpAuthService().authenticateWithUsernamePassword(
      username: username,
      password: password,
    );
    print("Authenticated as user: '$username'");
    CarpProtocolService().configureFrom(CarpService());
  }
}
