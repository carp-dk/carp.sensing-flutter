part of '../main.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
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
      await CarpBackend().authenticate();

      // Check if there is a local study.
      // If not, get a study deployment based on an invitation.
      if (bloc.study == null) {
        await CarpBackend().getStudyInvitation(context);
      }

      // Make sure that CarpService knows the study deployment.
      // This is useful when an app (like this one only handles one study at a time
      CarpService().study = bloc.study;
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
              )))
          : CarpMobileSensingApp(),
    );
  }
}

/// The main view of the app, shown once loading is done.
class CarpMobileSensingApp extends StatefulWidget {
  CarpMobileSensingApp({super.key});
  @override
  CarpMobileSensingAppState createState() => CarpMobileSensingAppState();
}

class CarpMobileSensingAppState extends State<CarpMobileSensingApp> {
  int _selectedIndex = 0;

  final _pages = [
    StudyDeploymentPage(),
    ProbesListPage(),
    DevicesListPage(),
  ];

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Study'),
          BottomNavigationBarItem(icon: Icon(Icons.adb), label: 'Probes'),
          BottomNavigationBarItem(icon: Icon(Icons.watch), label: 'Devices'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _restart,
        child: bloc.isRunning ? Icon(Icons.stop) : Icon(Icons.play_arrow),
      ),
    );
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  void _restart() =>
      setState(() => (bloc.isRunning) ? bloc.stop() : bloc.start());
}
