part of '../../main.dart';

/// The main view of the app, shown once loading is done.
class HomePage extends StatefulWidget {
  final AppViewModel appViewModel = AppViewModel();

  HomePage({super.key});
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [];

  AppViewModel get model => widget.appViewModel;

  HomePageState() : super();

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
