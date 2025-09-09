part of 'carp_auth.dart';

/// The authentication service for CAWS.
///
/// Used as a singleton.
/// Must be configured using the [configure] method before use, like this:
///
/// ```dart
/// // The authentication configuration
/// late CarpAuthProperties authProperties = CarpAuthProperties(
///   authURL: uri,
///   clientId: 'studies-app',
///   redirectURI: Uri.parse('carp-studies-auth://auth'),
///   // For authentication at CAWS the path is '/auth/realms/Carp'
///   discoveryURL: uri.replace(pathSegments: [
///     'auth',
///     'realms',
///     'Carp',
///   ]),
/// );
///
/// await CarpAuthService().configure(authProperties);
/// ```
///
/// Basic authentication is using the CAWS login web page, which is opened
/// when calling the [authenticate] method:
///
/// ```dart
/// CarpUser user = await CarpAuthService().authenticate();
/// ```
///
class CarpAuthService {
  static final CarpAuthService _instance = CarpAuthService._();
  OidcUserManager? _manager;

  CarpAuthProperties? _authProperties;
  CarpUser? _currentUser;

  final StreamController<AuthEvent> _authEventController =
      StreamController.broadcast();

  CarpAuthService._();

  /// Returns the singleton default instance of the [CarpAuthService].
  /// Before this instance can be used, it must be configured using the
  /// [configure] method.
  factory CarpAuthService() => _instance;

  CarpAuthService.instance() : this._();

  /// Has this service been configured?
  bool get isConfigured => (_authProperties != null);

  /// The [OidcUserManager] handling authentication.
  OidcUserManager? get manager => _manager;

  /// Is a user authenticated?
  /// If `true`, the authenticated user is [currentUser].
  bool get authenticated => (_currentUser != null);

  /// The CARP authentication properties associated with the CARP Web Service.
  /// Returns `null` if this service has not yet been configured via the
  /// [configure] method.
  CarpAuthProperties get authProperties => nonNullAble(_authProperties);

  /// Gets the current user.
  /// Returns `null` if no user is authenticated.
  CarpUser get currentUser => nonNullAble(_currentUser);
  set currentUser(CarpUser? user) => _currentUser = user;

  /// Notifies about changes to the user's authentication state (such as sign-in
  /// or sign-out) as defined in [AuthEvent].
  Stream<AuthEvent> get authStateChanges =>
      _authEventController.stream.asBroadcastStream();

  /// The URI for the authenticated endpoint for this [CarpService].
  Uri get authEndpointUri => authProperties.authURL;

  /// Configure the this instance of a Carp Service.
  Future<void> configure(CarpAuthProperties authProperties) async {
    _authProperties = authProperties;

    _manager = OidcUserManager.lazy(
      discoveryDocumentUri: OidcUtils.getOpenIdConfigWellKnownUri(
        Uri.parse(authProperties.discoveryURL.toString()),
      ),
      clientCredentials: OidcClientAuthentication.none(
        clientId: authProperties.clientId,
      ),
      store: OidcDefaultStore(),
      settings: OidcUserManagerSettings(
        redirectUri: Uri.parse(authProperties.redirectURI.toString()),
        scope: ['openid', 'offline_access'],
        postLogoutRedirectUri: Uri.parse(
            (authProperties.logoutRedirectURI ?? authProperties.redirectURI)
                .toString()),
        options: const OidcPlatformSpecificOptions(
          web: OidcPlatformSpecificOptions_Web(
            navigationMode:
                OidcPlatformSpecificOptions_Web_NavigationMode.newPage,
          ),
        ),
      ),
    );

    await initManager();
  }

  /// Initialize the [manager]. This service must be configured before calling this
  /// method.
  Future<void> initManager() async {
    assert(_manager != null, 'Manager not configured. Call configure() first.');

    await _manager!.init();

    _manager!.userChanges().listen((user) {
      if (user != null) {
        _currentUser = getCurrentUserProfile(user);
        if (_currentUser != null) {
          _authEventController.add(AuthEvent.authenticated);
        } else {
          _authEventController.add(AuthEvent.failed);
        }
      }
    });
  }

  /// Authenticate to this CARP service. This method will opens the authentication page
  /// of the Identity Server using a secure web view from the OS.
  ///
  /// The discovery URL in the [authProperties] is used to find the Identity Server.
  ///
  /// Returns the signed in user (with an [OAuthToken] access token), if successful.
  ///  Throws a [CarpServiceException] if not successful.
  Future<CarpUser> authenticate() async {
    assert(_manager != null, 'Manager not configured. Call configure() first.');
    if (!_manager!.didInit) await initManager();

    OidcUser? response = await manager!.loginAuthorizationCodeFlow();

    if (response != null) {
      _currentUser = getCurrentUserProfile(response);

      if (_currentUser != null) {
        _currentUser!
            .authenticated(OAuthToken.fromTokenResponse(response.token));
        _authEventController.add(AuthEvent.authenticated);
        return currentUser;
      }
    }

    // All other cases are treated as a failed attempt
    _authEventController.add(AuthEvent.failed);

    throw CarpServiceException(
      httpStatus: HTTPStatus(401),
      message: 'Authentication failed.',
    );
  }

  /// Authenticate to this CARP service using a [username] and [password].
  ///
  /// The discovery URL in the [authProperties] is used to find the Identity Server.
  ///
  /// Returns the signed in user (with an [OAuthToken] access token), if successful.
  /// Throws a [CarpServiceException] if not successful.
  Future<CarpUser> authenticateWithUsernamePassword({
    required String username,
    required String password,
  }) async {
    assert(_manager != null, 'Manager not configured. Call configure() first.');
    if (!_manager!.didInit) await initManager();

    final OidcUser? response = await manager?.loginPassword(
      username: username,
      password: password,
    );

    if (response != null) {
      _currentUser = getCurrentUserProfile(response);

      if (_currentUser != null) {
        _currentUser!
            .authenticated(OAuthToken.fromTokenResponse(response.token));
        _authEventController.add(AuthEvent.authenticated);
        return currentUser;
      }
    }

    // All other cases are treated as a failed attempt
    _authEventController.add(AuthEvent.failed);

    throw CarpServiceException(
      httpStatus: HTTPStatus(401),
      message: 'Authentication failed.',
    );
  }

  /// Authenticate to this CARP service using an [access link] URI.
  ///
  /// The access link is typically received via email or QR code,
  /// and contains a one-time token that can be used to authenticate the user.
  Future<CarpUser> authenticateWithAccessLink({
    required String uri,
  }) async {
    final client = http.Client();

    var response = await client.get(Uri.parse(uri));
    print(response.headers);
    print(response.body);

    // assert(_manager != null, 'Manager not configured. Call configure() first.');
    // if (!_manager!.didInit) await initManager();

    // final OidcUser? response = await manager?.loginWithAccessLink(uri);

    // if (response != null) {
    //   _currentUser = getCurrentUserProfile(response);

    //   if (_currentUser != null) {
    //     _currentUser!
    //         .authenticated(OAuthToken.fromTokenResponse(response.token));
    //     _authEventController.add(AuthEvent.authenticated);
    //     return currentUser;
    //   }

    return CarpUser(username: 'access_link_user', id: 'access_link_id');

    // All other cases are treated as a failed attempt
    _authEventController.add(AuthEvent.failed);

    throw CarpServiceException(
      httpStatus: HTTPStatus(401),
      message: 'Authentication failed.',
    );
  }

  /// Get a new access token for the current user based on the
  /// previously granted refresh token, using the Identity Server discovery URL.
  ///
  /// This method is typically used when the access token has expired, and a new
  /// access token is needed to access the CARP web service. The refresh token
  /// expiration date is [OAuthToken.expiresAt].
  ///
  /// Returns the signed in user (with a new [OAuthToken] access token), if successful.
  /// Throws a [CarpServiceException] if not successful.
  Future<CarpUser> refresh() async {
    assert(_manager != null, 'Manager not configured. Call configure() first.');
    if (!_manager!.didInit) await initManager();

    final OidcUser? response = await manager?.refreshToken();

    if (response != null) {
      _currentUser = getCurrentUserProfile(response);

      if (_currentUser != null) {
        _currentUser!
            .authenticated(OAuthToken.fromTokenResponse(response.token));
        _authEventController.add(AuthEvent.authenticated);
        return currentUser;
      }
    }

    // All other cases are treated as a failed attempt
    _authEventController.add(AuthEvent.failed);

    throw CarpServiceException(
      httpStatus: HTTPStatus(401),
      message: 'Authentication failed.',
    );
  }

  /// Log out from this CARP service
  ///
  /// Opens a web view to clear cookies and end the session on the Identity Server.
  ///
  /// Only use this method if you used [authenticate] to authenticate.
  Future<void> logout() async {
    assert(_manager != null, 'Manager not configured. Call configure() first.');

    if (!_manager!.didInit) {
      await initManager();
    }

    await manager!.logout();
    _authEventController.add(AuthEvent.unauthenticated);
    _currentUser = null;
  }

  /// Log out of this [CarpService], by clearing the current user.
  ///
  /// Use this if you used [authenticateWithUsernamePassword] to authenticate,
  /// or when you want to log out without opening a web browser
  Future<void> logoutNoContext() async {
    await manager?.forgetUser();
    _authEventController.add(AuthEvent.unauthenticated);
    _currentUser = null;
  }

  // --------------------------------------------------------------------------
  // USERS
  // --------------------------------------------------------------------------

  /// Gets the CARP profile of the current user from the JWT token of [user].
  /// Returns null if the the [user] don't have an access token.
  CarpUser? getCurrentUserProfile(OidcUser user) {
    if (user.token.accessToken == null) return null;

    var jwt = JwtDecoder.decode(user.token.accessToken!);
    return CarpUser.fromJWT(jwt, user.token);
  }

  /// Makes sure that the [CarpApp] or [CarpUser] is configured, by throwing a
  /// [CarpServiceException] if they are null.
  /// Otherwise, returns the non-null value.
  T nonNullAble<T>(T? argument) {
    if (argument == null && argument is CarpApp) {
      throw CarpServiceException(
          message:
              "CARP Service not initialized. Call 'CarpAuthService().configure()' first.");
    } else if (argument == null && argument is CarpUser) {
      throw CarpServiceException(
          message:
              "CARP User not authenticated. Call 'CarpAuthService().authenticate()' first.");
    } else {
      return argument!;
    }
  }
}

/// Authentication state change events.
enum AuthEvent {
  /// The user has successfully been authenticated (signed in).
  authenticated,

  /// The user has been unauthenticated (signed out).
  unauthenticated,

  /// Authentication failed.
  failed,

  /// The user's token has successfully been refreshed.
  refreshed,
}
