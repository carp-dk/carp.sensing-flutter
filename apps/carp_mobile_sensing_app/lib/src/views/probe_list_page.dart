part of '../../main.dart';

class ProbesListPage extends StatefulWidget {
  final ProbeListViewModel _probeListViewModel;
  ProbesListPage(this._probeListViewModel);

  @override
  ProbeListState createState() => ProbeListState();
}

class ProbeListState extends State<ProbesListPage> {
  ProbeListViewModel get model => widget._probeListViewModel;

  ProbeListState();

  @override
  Widget build(BuildContext context) {
    Iterable<Widget> probes = ListTile.divideTiles(
      context: context,
      tiles: model.runningProbes.map<Widget>((probe) => _probeListTile(probe)),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Probes')),
      body: Scrollbar(
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          children: probes.toList(),
        ),
      ),
    );
  }

  Widget _probeListTile(ProbeViewModel probe) {
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
}
