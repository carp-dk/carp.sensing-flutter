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
              .toString(),
        ),
        options: const OidcPlatformSpecificOptions(
          web: OidcPlatformSpecificOptions_Web(
            navigationMode:
                OidcPlatformSpecificOptions_Web_NavigationMode.newPage,
          ),
        ),
      ),
    );

    await initManager();
    info('$runtimeType configured with $authProperties');
  }

  /// Initialize the OidcUserManager. This service must be configured before calling this
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
        _currentUser!.authenticated(
          OAuthToken.fromTokenResponse(response.token),
        );
        _authEventController.add(AuthEvent.authenticated);
        return currentUser;
      }
    }

    // All other cases are treated as a failed attempt
    _authEventController.add(AuthEvent.failed);

    throw CarpUnauthorizedException('Authentication failed.');
  }

  /// Authenticate to this CARP service using an magic link URI generated by CAWS
  /// as part of an anonymous access flow.
  ///
  /// The magic link can be found inside the .csv file downloaded from the portal.
  Future<CarpUser> authenticateWithMagicLink(String uri) async {
    assert(_manager != null, 'Manager not configured. Call configure() first.');
    if (!_manager!.didInit) await initManager();

    String? code;
    String? clientId = _authProperties?.clientId;
    String? redirectUri = _authProperties?.anonymousRedirectURI?.toString();
    uri = _constructAuthUri(uri);

    TokenResponse tokenResponse =
        await FlutterWebAuth2.authenticate(
          url: uri,
          callbackUrlScheme: redirectUri!.split(':/').first,
          options: FlutterWebAuth2Options(
            intentFlags: ephemeralIntentFlags,
            preferEphemeral: true,
          ),
        ).then((result) async {
          code = Uri.parse(result).queryParameters['code'];
          if ((_currentUser == null || _currentUser!.isAuthenticated) &&
              code != null) {
            return await FlutterAppAuth().token(
              TokenRequest(
                clientId!,
                redirectUri,
                authorizationCode: code,
                discoveryUrl: _authProperties?.discoveryURL
                    .replace(
                      pathSegments: [
                        ...?_authProperties?.discoveryURL.pathSegments,
                        '.well-known',
                        'openid-configuration',
                      ],
                    )
                    .toString(),
                grantType: 'authorization_code',
              ),
            );
          }
          return Future.error("No code in redirect URI");
        });

    _currentUser = getCurrentUserProfileFromTokenResponse(tokenResponse);

    final accessToken = tokenResponse.accessToken;
    final refreshToken = tokenResponse.refreshToken;
    final idToken = tokenResponse.idToken;
    final scopeString =
        tokenResponse.tokenAdditionalParameters?['scope'] ??
        tokenResponse.tokenType;
    final scope = (scopeString is String) ? scopeString.split(' ') : <String>[];
    final expiresAt =
        tokenResponse.accessTokenExpirationDateTime ??
        DateTime.now().add(const Duration(hours: 1));

    if (_currentUser != null) {
      _currentUser!.authenticated(
        OAuthToken(
          accessToken ?? '',
          refreshToken ?? '',
          idToken ?? '',
          expiresAt,
          scope,
          idToken ?? '',
        ),
      );
      _authEventController.add(AuthEvent.authenticated);
      return currentUser;
    }

    // All other cases are treated as a failed attempt
    _authEventController.add(AuthEvent.failed);
    throw CarpUnauthorizedException('Authentication failed.');
  }

  String _constructAuthUri(String uri) {
    String secondPart = uri.split('action-token').last;
    return '${authProperties.discoveryURL}/login-actions/action-token$secondPart';
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

    OidcUser? response;

    try {
      response = await manager?.loginPassword(
        username: username,
        password: password,
      );
    } catch (error) {
      throw CarpUnauthorizedException(
        'Authentication failed.',
        exception: error.toString(),
        path: authEndpointUri.toString(),
      );
    }

    if (response != null) {
      _currentUser = getCurrentUserProfile(response);

      if (_currentUser != null) {
        _currentUser!.authenticated(
          OAuthToken.fromTokenResponse(response.token),
        );
        _authEventController.add(AuthEvent.authenticated);
        return currentUser;
      }
    }

    // All other cases are treated as a failed attempt
    _authEventController.add(AuthEvent.failed);
    throw CarpUnauthorizedException(
      'Authentication failed.',
      path: authEndpointUri.toString(),
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
        _currentUser!.authenticated(
          OAuthToken.fromTokenResponse(response.token),
        );
        _authEventController.add(AuthEvent.authenticated);
        return currentUser;
      }
    }

    // All other cases are treated as a failed attempt
    _authEventController.add(AuthEvent.failed);
    throw CarpUnauthorizedException(
      'Authentication failed.',
      path: authEndpointUri.toString(),
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

  /// Gets the CARP profile of the current user from a [TokenResponse].
  /// Using the parameters in the [TokenResponse] we create an [OAuthToken]
  /// to generate the CarpUser.
  CarpUser? getCurrentUserProfileFromTokenResponse(
    TokenResponse tokenResponse,
  ) {
    final accessToken = tokenResponse.accessToken;
    final refreshToken = tokenResponse.refreshToken;
    final idToken = tokenResponse.idToken;
    final tokenType = 'bearer';
    final scopeString =
        tokenResponse.tokenAdditionalParameters?['scope'] ??
        tokenResponse.tokenType;
    final scope = (scopeString is String) ? scopeString.split(' ') : <String>[];

    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    final jwt = JwtDecoder.decode(accessToken);
    final expiresAt =
        tokenResponse.accessTokenExpirationDateTime ??
        DateTime.now().add(const Duration(hours: 1));

    final oauthToken = OAuthToken(
      accessToken,
      refreshToken ?? '',
      tokenType,
      expiresAt,
      scope,
      idToken ?? '',
    );

    return CarpUser.fromJWTOAuth(jwt, oauthToken);
  }

  /// Makes sure that the [CarpApp] or [CarpUser] is configured, by throwing a
  /// [CarpServiceException] if they are null.
  /// Otherwise, returns the non-null value.
  T nonNullAble<T>(T? argument) {
    if (argument == null && argument is CarpApp) {
      throw CarpServiceException(
        "CARP Service not initialized. Call 'CarpAuthService().configure()' first.",
      );
    } else if (argument == null && argument is CarpUser) {
      throw CarpServiceException(
        "CARP User not authenticated. Call 'CarpAuthService().authenticate()' first.",
      );
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
