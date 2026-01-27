part of '../../main.dart';

/// Handling communication to the CARP Web Services infrastructure.
/// Used when running in CAWS deployment modes.
/// Works as a singleton, and can be accessed by `CarpBackend()`.
class CarpBackend {
  /// The URIs of the CARP Web Service (CAWS) host for each [DeploymentMode].
  static const Map<DeploymentMode, String> uris = {
    DeploymentMode.dev: 'dev.carp.dk',
    DeploymentMode.test: 'test.carp.dk',
    DeploymentMode.production: 'carp.computerome.dk',
  };

  static final CarpBackend _instance = CarpBackend._();
  CarpBackend._() : super();
  factory CarpBackend() => _instance;

  /// The signed in user
  CarpUser? get user => CarpAuthService().currentUser;

  /// The username of the signed in user.
  String? get username => CarpAuthService().currentUser.username;

  /// The URI of the CAWS server - depending on deployment mode.
  Uri get _uri => Uri(scheme: 'https', host: uris[bloc.deploymentMode]);

  /// The CAWS app configuration.
  late final CarpApp _app = CarpApp(name: "CAWS @ DTU", uri: _uri);

  CarpApp get app => _app;

  /// The authentication configuration
  CarpAuthProperties get _authProperties => CarpAuthProperties(
    authURL: _uri,
    clientId: 'studies-app',
    redirectURI: Uri.parse('carp-studies-auth://auth'),
    // For authentication at CAWS the path is '/auth/realms/Carp'
    discoveryURL: _uri.replace(pathSegments: ['auth', 'realms', 'Carp']),
  );

  Future<void> initialize() async {
    debug('$runtimeType - initializing...');
    await CarpAuthService().configure(_authProperties);

    // Configure the CAWS services
    CarpService().configure(app);
    CarpParticipationService().configureFrom(CarpService());
    CarpDeploymentService().configureFrom(CarpService());

    // Register CARP as a data backend where data can be uploaded
    DataManagerRegistry().register(CarpDataManagerFactory());

    info('$runtimeType initialized');
  }

  /// Open the web-based authentication screen to ask for username & password.
  Future<CarpUser> authenticate() async =>
      await CarpAuthService().authenticate();

  /// Authenticate to the CAWS host using [username] and [password].
  Future<CarpUser> authenticateWithUsernamePassword(
    String username,
    String password,
  ) async => await CarpAuthService().authenticateWithUsernamePassword(
    username: username,
    password: password,
  );

  /// Get the study invitation by opening the CAWS study invitation page.
  Future<ActiveParticipationInvitation?> getStudyInvitation(
    BuildContext context,
  ) async => await CarpParticipationService().getStudyInvitation(context);
}
