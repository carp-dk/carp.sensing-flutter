part of '../../main.dart';

class ProbesListPage extends StatefulWidget {
  final ProbeListViewModel _probeListViewModel;
  ProbesListPage(this._probeListViewModel);

  @override
  ProbeListState createState() => ProbeListState();
}

class ProbeListState extends State<ProbesListPage> {
  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  ProbeListViewModel get model => widget._probeListViewModel;

  ProbeListState();

  @override
  Widget build(BuildContext context) {
    Iterable<Widget> probes = ListTile.divideTiles(
      context: context,
      tiles: model.runningProbes.map<Widget>(
        (probe) => _probeListTile(context, probe),
      ),
    );

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text('Probes'),
        //TODO - move actions/settings icon to the app level.
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Theme.of(context).platform == TargetPlatform.iOS
                  ? Icons.more_horiz
                  : Icons.more_vert,
            ),
            tooltip: 'Settings',
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Scrollbar(
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          children: probes.toList(),
        ),
      ),
    );
  }

  Widget _probeListTile(BuildContext context, ProbeViewModel probe) {
    return StreamBuilder<ExecutorState>(
      stream: probe.stateEvents,
      initialData: ExecutorState.Created,
      builder: (context, AsyncSnapshot<ExecutorState> snapshot) =>
          (snapshot.hasData)
          ? ListTile(
              isThreeLine: true,
              leading: probe.icon,
              title: Text(probe.name ?? 'Unknown'),
              subtitle: Text(probe.description ?? '...'),
              trailing: probe.stateIcon,
            )
          : (snapshot.hasError)
          ? Text('Error in probe state - ${snapshot.error}')
          : Text('Unknown'),
    );
  }

  void _showSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings not implemented yet...')),
    );
  }
}
