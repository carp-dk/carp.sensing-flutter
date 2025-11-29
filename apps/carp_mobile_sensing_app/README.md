# CARP Mobile Sensing App

The CARP Mobile Sensing App provides an example on how to use the [`carp_mobile_sensing`](https://pub.dartlang.org/packages/carp_mobile_sensing) package.
The app sets up a `SmartphoneStudyProtocol` (or just "Protocol") that uses a set of `Device`s and collects a set of `Measures`s.
Following the [CARP Mobile Sensing architecture](https://github.com/cph-cachet/carp.sensing-flutter/wiki/1.-Software-Architecture), the protocol is "Deployed" on the phone and data collection is done via a set of "Probes" which each use a "Device", including the phone itself.
The UI of the app is shown below, showing (from left to right) the Study Deployment page, the Probe List page, and the Device List page.

![Study Visualization page](documentation/study_viz_3.jpg) __
![Probe List page](documentation/probe_list_3.jpg)__
![Device List page](documentation/device_list_3.jpg)

The architecture of the app is illustrated below. It follows the [Model-ViewModel-View](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel),
which is the recommended [Flutter Architecture](https://docs.flutter.dev/app-architecture).

![Bloc Architecture](documentation/architecture_4.png)

All sensing logic is handled via the `Sensing` class responsible for handling sensing via the [`carp_mobile_sensing`](https://pub.dartlang.org/packages/carp_mobile_sensing) package.
All business logic is handled by the singleton `SensingBLoC` which is the only way the UI models can access and modify data or initiate life cycle events (like pausing and resuming sensing).
All data to be shown in the UI are handled by view models, and finally each page is implemented as a [`StatefulWidget`](https://docs.flutter.io/flutter/widgets/StatefulWidget-class.html) in Flutter.
Each view widget only knows its corresponding view model and the view model knows the BloC.
**NO** data or control flows between the UI and the Bloc or Sensing layer.

## Sensing BLoC

Since the [`SensingBLoC`](https://github.com/cph-cachet/carp.sensing-flutter/blob/main/apps/carp_mobile_sensing_app/lib/src/blocs/sensing_bloc.dart) is the controller of the entire app, let's look closer on this class. Below are essential parts shown (omitting some implementation details):

````dart
class SensingBLoC {
    /// The [Sensing] layer used in the app.
  Sensing get sensing => Sensing();

  /// What kind of deployment are we running? Default is local.
  DeploymentMode deploymentMode => ...

  /// The study for the currently running study deployment.
  /// The study is cached locally on the phone.
  /// Returns `null` if no study is deployed (yet).
  SmartphoneStudy? get study => ...
  
  /// Use the cached study deployment?
  bool get useCachedStudyDeployment => ...

  /// Should sensing be automatically resumed on app startup?
  bool get resumeSensingOnStartup => ...

  /// The [SmartphoneDeployment] deployed on this phone.
  SmartphoneDeployment? get deployment => sensing.controller?.deployment;

  /// What kind of deployment are we running. Default is local.
  DeploymentMode deploymentMode = DeploymentMode.local;

  StudyDeploymentModel? _model;

  /// Get the view model for this study [deployment].
  StudyDeploymentViewModel get studyDeploymentViewModel =>
      _model ??= StudyDeploymentViewModel(deployment!);

  /// Get a list of view models for the running probes.
  Iterable<ProbeViewModel> get runningProbes =>
      bloc.sensing.runningProbes.map((probe) => ProbeViewModel(probe));

  /// Get a list of view models for the available devices.
  Iterable<DeviceViewModel> get availableDevices =>
      bloc.sensing.availableDevices.map((device) => DeviceViewModel(device));

  /// Get a list of view models for connected devices.
  Iterable<DeviceViewModel> get connectedDevices =>
      bloc.sensing.connectedDevices.map((device) => DeviceViewModel(device));

  /// Initialize the BLoC.
  Future<void> initialize({
    DeploymentMode deploymentMode = DeploymentMode.local,
    String dataFormat = NameSpace.CARP,
    bool useCachedStudyDeployment = true,
    bool resumeSensingOnStartup = false,
  }) async {
    await Settings().init();
    Settings().debugLevel = DebugLevel.debug;
    this.deploymentMode = deploymentMode;
    this.dataFormat = dataFormat;
    _resumeSensingOnStartup = resumeSensingOnStartup;
    _useCached = useCachedStudyDeployment;

    info('$runtimeType initialized');
  }

  /// Connect to a [device] which is part of the [deployment].
  void connectToDevice(DeviceModel device) => SmartPhoneClientManager()
      .deviceController
      .devices[device.type!]!
      .connect();

  void start() async => SmartPhoneClientManager().start();
  void stop() async => SmartPhoneClientManager().stop();

  /// Is sensing running, i.e. has the study executor been started?
  bool get isRunning =>
      SmartPhoneClientManager().state == ClientManagerState.started;
}

final bloc = SensingBLoC();
````

The BLoC basically plays three roles:

* it holds core business data like the `study` and `deployment` configuration
* it can create view models such as the `StudyDeploymentViewModel` and the list of `ProbeViewModel`s and `DeviceViewModel`s
* it provide a set of life cycle methods for sensing like `initialize`, `connectToDevice` and `start`.

Finally, note that the singleton `bloc` variable is instantiated, which makes the BLoC accessible in the entire app.

## Sensing

Configuration of sensing is done in the [`Sensing`](https://github.com/cph-cachet/carp.sensing-flutter/blob/main/apps/carp_mobile_sensing_app/lib/src/sensing/sensing.dart) class.

This class also illustrates how the app can be run both in a "local" deployment mode and in different "CAWS" modes. Depending on the deployment mode (local or using CAWS), deployment is initialized using the [`SmartphoneDeploymentService`](https://pub.dev/documentation/carp_mobile_sensing/latest/runtime/SmartphoneDeploymentService-class.html) or the [`CarpDeploymentService`](https://pub.dev/documentation/carp_webservices/latest/carp_services/CarpDeploymentService-class.html), respectively.

In the case a local deployment is used, a protocol is fetched from the `LocalStudyProtocolManager`, which is then added to the local `SmartphoneDeploymentService`.
In the case a CAWS deployment is used, the study deployment configuration will be fetched from the `CarpDeploymentService` based on the `study`, which again is part of an `invitation` (this invitation is fetched as part of the `init` method of the main `App` class).

Once, the right deployment service is configured, the `SmartPhoneClientManager` singleton is configured and the study is added (based on the deployment id and the role name of the phone) and deployed.
When deployed, the runtime (`SmartphoneDeploymentController`) is configured and sampling can now be started or stopped. This part of `Sensing` is shown below:

```dart
    // Configure the client manager with the deployment service selected above
    // (local or CAWS), add the study, and deploy it.
    await SmartPhoneClientManager().configure(
      deploymentService: deploymentService,
      askForPermissions: true,
    );

    study = await SmartPhoneClientManager().addStudy(bloc.study!);
    await controller?.tryDeployment(useCached: bloc.useCachedStudyDeployment);
    await controller?.configure();
```

## User Interface View Models

The CARP Mobile Sensing App uses one view model for each UI page. For example, the view model `StudyDeploymentViewModel` serves the UI Widget `StudyDeploymentPage`. The main responsibility of the view model is to provide access to data (both getter and setters), which again is available via the BLoC.

The `StudyDeploymentViewModel` class looks like this:

`````dart
/// A view model for the [StudyDeploymentPage] view.
class StudyDeploymentViewModel {
  SmartphoneDeployment deployment;

  String get title => deployment.studyDescription?.title ?? '';
  String get description =>
      deployment.studyDescription?.description ?? 'No description available.';
  Image get image => Image.asset('assets/study.png');
  String get studyDeploymentId => deployment.studyDeploymentId;
  String get deviceRoleName => deployment.deviceConfiguration.roleName;
  String get userID => deployment.userId ?? '';
  String get dataEndpoint => deployment.dataEndPoint.toString();

  /// Events on the state of the study executor
  Stream<ExecutorState> get studyExecutorStateEvents =>
      bloc.sensing.controller!.executor.stateEvents;

  /// Current state of the study executor (e.g., started, stopped, ...)
  ExecutorState get studyState => bloc.sensing.controller!.executor.state;

  /// Get all sensing events (i.e. all [Measurement] objects being collected).
  Stream<Measurement> get measurements =>
      bloc.sensing.controller?.measurements ?? Stream.empty();

  /// The total sampling size so far since this study was started.
  int get samplingSize => bloc.sensing.controller?.samplingSize ?? 0;

  StudyDeploymentViewModel(this.deployment) : super();
}
`````

In this view model there are only data **getters**, since in the current version of the app, you cannot change a study once it is running. However, if modification of a study was to be supported, then **setter** methods would be implemented in the model as well.

## User Interface Views

The top layer contains the UI views. Each UI view takes in its constructor its corresponding view model. For example, the `StudyDeploymentPage` widget's `State` takes a `StudyDeploymentViewModel` in its constructor:

`````dart
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
  Widget build(BuildContext context) {
    ... 
  }
}
`````

In this way, the `viewModel` is available in the entire UI Widget. This allows us to access data and show it in the UI. For example, to show the study title and image this code is used:

````dart
 FlexibleSpaceBar(
    title: Text(viewModel.title),
    background: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        viewModel.image,
      ],
    ),
 ),

````

More sophisticated (reactive) UI implementation can also be done. For example, to show the counter showing sampling size the following `StreamBuilder` is used.

`````dart
StreamBuilder<Measurement>(
    stream: viewModel.measurements,
    builder: (context,
            AsyncSnapshot<Measurement> snapshot) =>
        _StudyControllerLine('${viewModel.samplingSize}',
            heading: 'Sample Size')),
`````

## Technical Notes

The CARP Mobile Sensing Demo app makes use of many of the CAMS Sampling Packages. Each of these have their own requirements to work, which entails modification on how to configure and build the app on iOS and Android. You should pay special attention to the requirements described in the README of each sampling package. This often entails editing and modifying:

* the `info.plist` on iOS
* the `AndroidManifest.xml` file on Android
* the `MainActivity.kt` or `MainActivity.java` on Android
* the different `build.gradle` and `settings.gradle` files on Android

This example app also illustrates how these files should be configured.
