part of 'carp_auth.dart';

/// Represents a CARP web service app endpoint.
class CarpAuthProperties {
  /// The OAuth endpoint for this app.
  final Uri authURL;

  /// OAuth client id
  final String clientId;

  /// OAuth client secret
  String? clientSecret;

  /// Redirect URI for OAuth
  final Uri redirectURI;

  /// Same as [redirectURI] but for anonymous authentication using qr code.
  Uri? anonymousRedirectURI;

  /// Redirect uri for OAuth after logout
  /// If not specified, the [redirectURI] is used.
  Uri? logoutRedirectURI;

  /// Discovery URI for OAuth
  final Uri discoveryURL;

  /// The CARP study id for this app.
  String? studyId;

  /// The CARP study deployment id of this app.
  String? studyDeploymentId;

  /// Create a [CarpAuthProperties] which know how to access a CARP backend.
  ///
  /// [authURL], [clientId], [redirectURI] and [discoveryURL] are required to
  /// identify, address and authenticate this client.
  ///
  /// A [studyId] and a [studyDeploymentId] may be specified, if known at
  /// creation time.
  CarpAuthProperties({
    required this.authURL,
    required this.clientId,
    this.clientSecret,
    required this.redirectURI,
    this.anonymousRedirectURI,
    required this.discoveryURL,
    this.studyDeploymentId,
    this.studyId,
    this.logoutRedirectURI,
  });

  @override
  int get hashCode => authURL.hashCode;

  @override
  bool operator ==(other) => authURL == other;

  @override
  String toString() => 'CarpApp - auth URL: $authURL, studyDeploymentId: $studyDeploymentId, studyId: $studyId';
}
