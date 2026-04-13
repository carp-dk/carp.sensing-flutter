part of 'carp_auth.dart';

/// Holds information of a token issued by an OAuth authorization endpoint.
@JsonSerializable(
  fieldRename: FieldRename.snake,
  includeIfNull: false,
  explicitToJson: true,
)
class OAuthToken {
  /// The OAuth access token.
  final String accessToken;

  /// The OAuth refresh token.
  final String refreshToken;

  /// The type of token.
  final String tokenType;

  /// The ID token used to uniquely identify the user with KeyCloak.
  final String idToken;

  /// Scope of this token:
  final List<String> scope;

  /// Expires at [DateTime].
  DateTime expiresAt;

  /// The number of seconds until this token expires.
  int? expiresIn;

  /// The date the access token was issued.
  final DateTime issuedDate = DateTime.now();

  /// Constructor
  OAuthToken(
    this.accessToken,
    this.refreshToken,
    this.tokenType,
    this.expiresAt,
    this.scope,
    this.idToken,
  );

  factory OAuthToken.fromTokenResponse(OidcToken response) {
    return OAuthToken(
      response.accessToken.toString(),
      response.refreshToken.toString(),
      response.tokenType.toString(),
      response
          .calculateExpiresAt()!, // Throw an error if there is no access token expiration date
      response.scope ?? [],
      response.idToken.toString(),
    );
  }

  /// Clone this token.
  OAuthToken clone() => OAuthToken(
    accessToken,
    refreshToken,
    tokenType,
    expiresAt,
    scope,
    idToken,
  );

  /// Expire the authenticated OAuth token for this user.
  void expire() => expiresAt = DateTime.now();

  /// Has the access token expired?
  bool get hasExpired => DateTime.now().isAfter(expiresAt);

  String get tokenInfo =>
      "Access Token: $accessToken, "
      "Refresh Token: $refreshToken, "
      "Expiry date: $expiresAt";

  factory OAuthToken.fromJson(Map<String, dynamic> json) =>
      _$OAuthTokenFromJson(json);
  Map<String, dynamic> toJson() => _$OAuthTokenToJson(this);

  @override
  String toString() =>
      'OAuthToken - accessToken: $accessToken, refresh_token: $refreshToken, token_type: $tokenType, expires_in: $expiresAt, scope: $scope';
}

/// Specifies an OAuth 2.0 REST endpoint.
class OAuthEndPoint {
  /// The OAuth 2.0 client id.
  String clientID;

  /// Path of the authentication endpoint.
  /// Default is `/oauth/token`
  String path;

  OAuthEndPoint({required this.clientID, this.path = "/oauth/token"});
}
