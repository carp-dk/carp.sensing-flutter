import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';

/// Resolving a self-signup code needs no credentials, so this test runs
/// against test.carp.dk without `_credentials.dart`.
void main() {
  SharedPreferences.setMockInitialValues({});
  final uri = Uri(scheme: 'https', host: 'test.carp.dk');

  setUpAll(
    () => CarpAuthService().configure(
      CarpAuthProperties(
        authURL: uri,
        clientId: 'studies-app',
        redirectURI: Uri.parse('carp-studies-auth://auth'),
        discoveryURL: uri.replace(pathSegments: ['auth', 'realms', 'Carp']),
      ),
    ),
  );

  test('known code resolves to a magic link', () async {
    final link = await CarpAuthService().magicLinkForCode('XXGHW');
    expect(link, startsWith('https://'));
    expect(link, contains('action-token'));
  });

  test('unknown code throws CarpNotFoundException', () {
    expect(
      CarpAuthService().magicLinkForCode('ZZZZZ'),
      throwsA(isA<CarpNotFoundException>()),
    );
  });
}
