part of '../main.dart';

class MobileSensingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      darkTheme: ThemeData.dark(),
      theme: ThemeData(),
      home: LoadingPage(),
    );
  }
}

/// A loading page shown while the app is loading and setting up the sensing layer.
class LoadingPage extends StatelessWidget {
  /// Initialize the app and the sensing.
  ///
  /// If using CAWS, this method also initialize the CAWS backend,
  /// authenticate the user, and gets the study invitation from CAWS.
  ///
  /// Returns true when successfully done.
  Future<bool> init(BuildContext context) async {
    // Request location "always" permissions upfront.
    // Note that this is a two-step process on Android, where the user first has
    // to grant "when in use" permissions, and then "always" permissions.
    await Permission.locationWhenInUse.request();
    await Permission.locationAlways.request();

    // Initialize and use the CAWS backend if not in local deployment mode
    if (bloc.deploymentMode != DeploymentMode.local) {
      await CarpBackend().initialize();
      // await CarpBackend().authenticate();
      await CarpBackend().authenticateWithUsernamePassword(username, password);
    }

    await bloc.sensing.initialize();

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: init(context),
      builder: (context, snapshot) => (!snapshot.hasData)
          ? Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [CircularProgressIndicator()],
                ),
              ),
            )
          : HomePage(),
    );
  }
}
