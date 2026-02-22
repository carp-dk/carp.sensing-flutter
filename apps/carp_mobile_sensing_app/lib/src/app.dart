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
    // Request all necessary permissions upfront
    await Permission.locationWhenInUse.request();
    await Permission.locationAlways.request();
    await Permission.activityRecognition.request();
    await Permission.sensors.request();

    // For Android 14+, also request notification permission for foreground services
    if (Theme.of(context).platform == TargetPlatform.android) {
      await Permission.notification.request();
    }

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
