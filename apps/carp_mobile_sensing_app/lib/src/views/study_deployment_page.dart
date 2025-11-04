part of '../../main.dart';

class StudyDeploymentPage extends StatefulWidget {
  @override
  StudyDeploymentPageState createState() =>
      StudyDeploymentPageState(bloc.studyDeploymentViewModel);
}

class StudyDeploymentPageState extends State<StudyDeploymentPage> {
  static final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();
  final double _appBarHeight = 256.0;

  final StudyDeploymentViewModel viewModel;

  StudyDeploymentPageState(this.viewModel) : super();

  @override
  Widget build(BuildContext context) =>
      _buildStudyVisualization(context, bloc.studyDeploymentViewModel);

  Widget _buildStudyVisualization(
    BuildContext context,
    StudyDeploymentViewModel viewModel,
  ) {
    return Scaffold(
      key: _scaffoldKey,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: _appBarHeight,
            pinned: true,
            floating: false,
            snap: false,
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
            flexibleSpace: FlexibleSpaceBar(
              title: Text(viewModel.title),
              background: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  viewModel.image,
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(_studyPanel(context, viewModel)),
          ),
        ],
      ),
    );
  }

  List<Widget> _studyPanel(
      BuildContext context, StudyDeploymentViewModel viewModel) {
    List<Widget> children = [];

    children.add(AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: _studyControllerPanel(context, viewModel),
    ));

    for (var task in viewModel.deployment.tasks) {
      children.add(_TaskPanel(task: task));
    }

    return children;
  }

  Widget _studyControllerPanel(
      BuildContext context, StudyDeploymentViewModel viewModel) {
    final ThemeData themeData = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: themeData.dividerColor))),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.titleMedium!,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  width: 72.0,
                  child:
                      Icon(Icons.settings, size: 50, color: CachetColors.BLUE)),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _StudyControllerLine(viewModel.title, heading: 'Title'),
                    _StudyControllerLine(viewModel.description),
                    _StudyControllerLine(viewModel.studyDeploymentId,
                        heading: 'Deployment ID'),
                    _StudyControllerLine(viewModel.deviceRoleName,
                        heading: 'Device Role Name'),
                    _StudyControllerLine(viewModel.userID, heading: 'User'),
                    _StudyControllerLine(viewModel.dataEndpoint,
                        heading: 'Data Endpoint'),
                    StreamBuilder<ExecutorState>(
                        stream: viewModel.studyExecutorStateEvents,
                        initialData: ExecutorState.created,
                        builder:
                            (context, AsyncSnapshot<ExecutorState> snapshot) {
                          if (snapshot.hasData) {
                            return _StudyControllerLine(
                                ProbeDescription
                                    .probeStateLabel[snapshot.data!],
                                heading: 'State');
                          } else {
                            return _StudyControllerLine(
                                ProbeDescription
                                    .probeStateLabel[ExecutorState.initialized],
                                heading: 'State');
                          }
                        }),
                    StreamBuilder<Measurement>(
                        stream: viewModel.measurements,
                        builder: (context,
                                AsyncSnapshot<Measurement> snapshot) =>
                            _StudyControllerLine('${viewModel.samplingSize}',
                                heading: 'Sample Size')),
                  ]))
            ],
          ),
        ),
      ),
    );
  }

  void _showSettings() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Settings not implemented yet...', softWrap: true)));
  }
}

class _StudyControllerLine extends StatelessWidget {
  final String? line, heading;

  _StudyControllerLine(this.line, {this.heading}) : super();

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: (heading == null)
                ? Text(line!, textAlign: TextAlign.left, softWrap: true)
                : Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                            text: '$heading: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: line),
                      ],
                    ),
                  )));
  }
}

class _TaskPanel extends StatelessWidget {
  _TaskPanel({this.task});

  final TaskConfiguration? task;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final List<Widget> children =
        task!.measures?.map((measure) => _MeasureLine(measure)).toList() ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: themeData.dividerColor))),
      child: DefaultTextStyle(
          style: Theme.of(context).textTheme.titleMedium!,
          child: SafeArea(
              top: false,
              bottom: false,
              child: Column(children: <Widget>[
                Row(children: <Widget>[
                  Icon(Icons.description, size: 40, color: CachetColors.ORANGE),
                  Text('  ${task!.name}',
                      style: themeData.textTheme.titleLarge),
                ]),
                Column(children: children)
                //Expanded(child: Column(children: children))
              ]))),
    );
  }
}

class _MeasureLine extends StatelessWidget {
  _MeasureLine(this.measure);

  final Measure measure;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final Icon icon = (ProbeDescription.descriptors[measure.type]?.icon != null)
        ? Icon(ProbeDescription.descriptors[measure.type]!.icon?.icon, size: 25)
        : Icon(Icons.error, size: 25);

    final String name = SamplingPackageRegistry()
            .samplingSchemes[measure.type]
            ?.dataType
            .displayName ??
        measure.type.split('.').last.toUpperCase();

    final List<Widget> columnChildren = [];
    columnChildren.add(Text(name));
    columnChildren
        .add(Text(measure.toString(), style: themeData.textTheme.bodySmall));

    final List<Widget> rowChildren = [];
    rowChildren.add(SizedBox(
        width: 72.0,
        child: IconButton(
          icon: icon,
          onPressed: null,
        )));

    rowChildren.addAll([
      Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: columnChildren))
    ]);
    return MergeSemantics(
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: rowChildren)),
    );
  }
}
