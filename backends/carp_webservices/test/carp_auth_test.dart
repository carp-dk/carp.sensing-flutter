import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:flutter/foundation.dart';
import 'package:test/test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_carp_properties.dart';
import '_credentials.dart';

void main() {
  SharedPreferences.setMockInitialValues({});

  /// Setup CAWS and authenticate.
  /// Runs once before all tests.
  setUpAll(() async {
    Settings().debugLevel = DebugLevel.debug;

    await CarpAuthService().configure(CarpProperties().authProperties);

    // configure the service with both an app and a study, using the same
    // test study for all tests
    CarpService().configure(CarpProperties().app, CarpProperties().study);
    CarpParticipationService().configureFrom(CarpService());
  });

  /// Close connection to CARP.
  /// Runs once after all tests.
  tearDownAll(() {
    CarpAuthService().logoutNoContext();
  });

  group('authentication', () {
    test('- authentication w. username and password', () async {
      CarpUser user = await CarpAuthService().authenticateWithUsernamePassword(
        username: username,
        password: password,
      );

      expect(user.token, isNotNull);
      expect(user.isAuthenticated, true);

      debugPrint("signed in : $user");
      debugPrint("token  : ${user.token}");
    });

    test('- failed authentication w. username and password', () async {
      expect(
        () async => await CarpAuthService().authenticateWithUsernamePassword(
          username: username,
          password: 'wrong_password',
        ),
        throwsA(isA<CarpUnauthorizedException>()),
      );
    });

    test('- get user profile', () async {
      await CarpAuthService().authenticateWithUsernamePassword(
        username: username,
        password: password,
      );
      expect(CarpAuthService().authenticated, true);

      CarpUser user = CarpAuthService().currentUser;

      debugPrint("signed in : $user");
      debugPrint("   name   : ${user.firstName} ${user.lastName}");

      expect(user.firstName, isNotEmpty);
      expect(user.lastName, isNotEmpty);
      expect(user.isAuthenticated, true);
    });

    test('- oauth token refreshes', () async {
      await CarpAuthService().authenticateWithUsernamePassword(
        username: username,
        password: password,
      );
      expect(CarpAuthService().authenticated, true);

      debugPrint('expiring token...');
      CarpAuthService().currentUser.token!.expire();

      CarpAuthService().currentUser;
    });

    test('- refreshing token', () async {
      CarpUser user = await CarpAuthService().authenticateWithUsernamePassword(
        username: username,
        password: password,
      );
      expect(CarpAuthService().authenticated, true);

      CarpUser newUser = await CarpAuthService().refresh();

      assert(newUser.isAuthenticated);
      assert(newUser.username == user.username);

      debugPrint("signed in : $newUser");
      debugPrint("   token  : ${newUser.token}");
    });
  });
}
