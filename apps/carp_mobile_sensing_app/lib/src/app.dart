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
          : CarpMobileSensingApp(),
    );
  }
}

/// The main view of the app, shown once loading is done.
class CarpMobileSensingApp extends StatefulWidget {
  final AppViewModel appViewModel = AppViewModel();

  CarpMobileSensingApp({super.key});
  @override
  CarpMobileSensingAppState createState() => CarpMobileSensingAppState();
}

class CarpMobileSensingAppState extends State<CarpMobileSensingApp> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [];

  AppViewModel get model => widget.appViewModel;

  CarpMobileSensingAppState() : super();

  @override
  void initState() {
    _pages.addAll([
      StudyPage(model.studyViewModel),
      ProbesListPage(ProbeListViewModel()),
      DevicesListPage(DeviceListViewModel()),
    ]);
    super.initState();
  }

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
      onPressed: _onButtonPressed,
      child: ListenableBuilder(
        listenable: bloc.sensing.client,
        builder: (_, _) => !model.hasStudy
            ? Icon(Icons.add)
            : !model.isDeployed
            ? Icon(Icons.refresh)
            : model.isRunning
            ? Icon(Icons.pause)
            : Icon(Icons.play_arrow),
      ),
    ),
  );

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  /// Handle press on the floating action button.
  /// If there is no study, add a study first.
  /// If the study is not yet deployed, deploy it.
  /// Once deployed, resume/pause sensing.
  void _onButtonPressed() => bloc.sensing.client.studies.isEmpty
      ? bloc.addStudy(context)
      : bloc.runStudy();
}
