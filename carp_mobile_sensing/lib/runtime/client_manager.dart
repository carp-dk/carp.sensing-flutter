/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

part of '../runtime.dart';

/// The possible states of the [SmartPhoneClientManager].
enum ClientManagerState { created, configured, disposed }

class SmartPhoneClientManager extends SmartphoneClient {
  static final SmartPhoneClientManager _instance = SmartPhoneClientManager._();
  NotificationController? _notificationController;
  bool _heartbeat = true;
  bool _askForPermissions = true;
  final StreamGroup<Measurement> _group = StreamGroup.broadcast();
  ClientManagerState _state = ClientManagerState.created;
  final Map<Study, SmartphoneStudyController> _controllers = {};

  /// Will this client manager ask for permission when a new study is deployed?
  bool get askForPermissions => _askForPermissions;

  /// The runtime state of this client manager.
  ClientManagerState get state => _state;

  /// The stream of all [Measurement]s collected by this client manager.
  /// This is the aggregation of all measurements collected by the
  /// studies running on this client.
  Stream<Measurement> get measurements => _group.stream;

  SmartPhoneClientManager._()
    : super(repository: SmartphoneClientRepository()) {
    WidgetsFlutterBinding.ensureInitialized();
    // WidgetsBinding.instance.addObserver(this);
    CarpMobileSensing.ensureInitialized();

    // Make sure to create controllers for ally studies which may have been
    // loaded from the persistence repository.
    Persistence().getAllStudies().then((studies) {
      for (var study in studies) {
        final controller = SmartphoneStudyController(study);
        _controllers[study] = controller;
        _group.add(controller.measurements);
      }

      // Once all studies and their controllers are loaded, we can resume
      // the sampling
      resume();
    });
  }

  /// Get the singleton [SmartPhoneClientManager].
  ///
  /// In CARP Mobile Sensing the [SmartPhoneClientManager] is a singleton,
  /// which implies that only one client manager is used in an app.
  factory SmartPhoneClientManager() => _instance;

  /// Is this client sending [Heartbeat] measurements for its studies?
  bool get heartbeat => _heartbeat;

  @override
  List<SmartphoneStudy> get studies => repository
      .getStudyList()
      .map((study) => study as SmartphoneStudy)
      .toList();

  DeviceController get deviceController =>
      super.dataCollectorFactory as DeviceController;

  /// The [NotificationController] responsible for sending notification on [AppTask]s.
  NotificationController? get notificationController => _notificationController;

  /// The study controller for the study with [studyDeploymentId] and [deviceRoleName].
  SmartphoneStudyController? getController(
    String studyDeploymentId,
    String deviceRoleName,
  ) => _controllers[getStudy(studyDeploymentId, deviceRoleName)];

  /// Configure this [SmartPhoneClientManager].
  ///
  /// If the [deploymentService] is not specified, the local
  /// [SmartphoneDeploymentService] will be used.
  /// If the [deviceController] is not specified, the default [DeviceController]
  /// is used.
  /// The [registration] is a unique device registration for this client device.
  /// If not specified, a [SmartphoneDeviceRegistration] is created and used.
  ///
  /// If [enableNotifications] is true (default), notifications is created when
  /// an [AppTask] is triggered.
  /// The [notificationController] specifies what [NotificationController] to
  /// use for notifications. If not specified, the [FlutterLocalNotificationController]
  /// is used.
  ///
  /// If [askForPermissions] is true (default), this client manager will
  /// automatically ask for permissions for all sampling packages at once.
  /// If you want the app to handle permissions itself, set this to false.
  /// You can later use the [askForAllPermissions] to ask for all permissions.
  ///
  /// If [heartbeat] is true, a [Heartbeat] data point will be uploaded for all
  /// devices (including the phone) in all studies running on this client
  /// (every 5 minutes).
  @override
  Future<void> configure({
    DeviceRegistration? registration,
    DeploymentService? deploymentService,
    DeviceDataCollectorFactory? dataCollectorFactory,
    bool enableNotifications = true,
    NotificationController? notificationController,
    bool askForPermissions = true,
    bool heartbeat = true,
  }) async {
    // fast out if already configured
    if (state.index >= ClientManagerState.configured.index) return;

    // initialize misc device settings
    await DeviceInfo().init();
    await Settings().init();
    await Persistence().init();

    // create and register the built-in data managers
    DataManagerRegistry().register(ConsoleDataManagerFactory());
    DataManagerRegistry().register(FileDataManagerFactory());
    DataManagerRegistry().register(SQLiteDataManagerFactory());

    // initialize default services, if not specified
    deploymentService ??= SmartphoneDeploymentService();
    dataCollectorFactory ??= DeviceController();
    if (enableNotifications) {
      _notificationController =
          notificationController ?? FlutterLocalNotificationController();
    }

    _heartbeat = heartbeat;
    _askForPermissions = askForPermissions;

    // initialize the app task controller singleton
    await AppTaskController().initialize(
      enableNotifications: enableNotifications,
    );

    // Create the device registration using the [Smartphone] registration builder.
    registration ??= Smartphone().createRegistration(
      deviceId: DeviceInfo().deviceID,
      platform: DeviceInfo().platform,
      deviceManufacturer: DeviceInfo().deviceManufacturer,
      hardware: DeviceInfo().hardware,
      deviceModel: DeviceInfo().deviceModel,
      sdk: DeviceInfo().sdk,
    );

    super.configure(
      registration: registration,
      deploymentService: deploymentService,
      dataCollectorFactory: dataCollectorFactory,
    );

    // look up and register all connected devices and services on this client
    // TODO: I can't do this until I have a deployment protocol, which specified which devices to register?
    // deviceController.registerAllAvailableDevices();

    var statusMsg =
        '===========================================================\n'
        '  CARP Mobile Sensing (CAMS) - $runtimeType\n'
        '===========================================================\n'
        '             device : ${registration.deviceDisplayName}\n'
        ' deployment service : $deploymentService\n'
        '  device controller : $deviceController\n'
        '  available devices : ${deviceController.devicesToString()}\n'
        '        persistence : ${Persistence().databaseName.split('/').last}\n'
        '===========================================================\n';
    debugPrint(statusMsg);

    _state = ClientManagerState.configured;
  }

  @override
  Future<void> addStudy(Study study) async {
    assert(
      study is SmartphoneStudy,
      'Trying to add a study which is not a SmartphoneStudy to a SmartphoneStudyClientManager.',
    );

    await super.addStudy(study);

    // Always create a fresh controller
    final controller = SmartphoneStudyController(study as SmartphoneStudy);
    _controllers[study] = controller;
    _group.add(controller.measurements);

    info('$runtimeType - Added study: $study');
  }

  /// Add a study based on an [invitation] which needs to be executed on
  /// this client.
  ///
  /// This is similar to the [addStudy] method, but the study is created from the
  /// [invitation].
  Future<void> addStudyFromInvitation(
    ActiveParticipationInvitation invitation,
  ) async => await addStudy(
    SmartphoneStudy(
      studyId: invitation.studyId,
      studyDeploymentId: invitation.studyDeploymentId,
      deviceRoleName: invitation.deviceRoleName ?? Smartphone.DEFAULT_ROLE_NAME,
      participantId: invitation.participantId,
      participantRoleName: invitation.participantRoleName,
    ),
  );

  /// Create and add a study based on the [protocol] which needs to be executed on
  /// this client.
  ///
  /// This is similar to the [addStudy] method, but the study is created from the
  /// [protocol]. If [studyDeploymentId] is specifies this id is used as the study
  /// deployment id. If not specified, an UUID v1 id is generated.
  Future<void> addStudyFromProtocol(
    StudyProtocol protocol, [
    String? studyDeploymentId,
  ]) async {
    final status = await deploymentService.createStudyDeployment(
      protocol,
      [],
      studyDeploymentId,
    );

    // no participant is specified in a protocol so look up the local user id
    var userId = await Settings().userId;

    final study = SmartphoneStudy(
      studyDeploymentId: status.studyDeploymentId,
      deviceRoleName: protocol.primaryDevice.roleName,
      // we expect that this is a "local" protocol where we use the user id as
      // participant id and with just one participant
      participantId: userId,
      participantRoleName:
          protocol.participantRoles == null ||
              protocol.participantRoles!.isEmpty
          ? 'Participant'
          : protocol.participantRoles?.first.role,
    );
    await addStudy(study);
  }

  @override
  Future<void> removeStudy(
    String studyDeploymentId,
    String deviceRoleName,
  ) async {
    var study = getStudy(studyDeploymentId, deviceRoleName);
    // fast out if not a valid study
    if (study == null) return;

    info('Removing study from $runtimeType - $studyDeploymentId');

    // Disconnecting from all devices will stop sensing on each of them.
    await deviceController.disconnectAllConnectedDevices();

    AppTaskController().removeStudyDeployment(studyDeploymentId);

    var controller = _controllers[study];
    if (controller != null) _group.remove(controller.measurements);
    _controllers.remove(study);
    await super.removeStudy(studyDeploymentId, deviceRoleName);
  }

  // /// Persistently save information related to this client manger.
  // /// Typically used for later resuming when app is restarted. See [resume].
  // Future<void> save() async {
  //   for (var studyDeploymentId in repository.keys) {
  //     await getStudyRuntime(studyDeploymentId)?.saveDeployment();
  //   }
  // }

  // /// Called when this client manager is being (re-)activated by the OS.
  // ///
  // /// Implementations of this method should start with a call to the inherited
  // /// method, as in `super.activate()`.
  // @protected
  // @mustCallSuper
  // void activate() {}

  // /// Called when this client manager is being deactivated and potentially
  // /// stopped by the OS.
  // ///
  // /// Implementations of this method should start with a call to the inherited
  // /// method, as in `super.deactivate()`.
  // @protected
  // @mustCallSuper
  // Future<void> deactivate() async => await save();

  /// Start data sampling in all studies in this client manager.
  void start() {
    for (var controller in _controllers.values) {
      controller.start();
    }
  }

  // /// Stop all studies in this client manager.
  // Future<void> stop() async {
  //   for (var studyDeploymentId in repository.keys) {
  //     await getStudyRuntime(studyDeploymentId)?.stop();
  //   }
  // }

  /// Resume all studies deployed on this client manager.
  ///
  /// This method is useful on app restart, since it will resume all sampling
  /// on this client. Data sampling will be resumed for studies which were
  /// running (i.e., having [ExecutorState.resumed]) when the app was closed.
  ///
  /// To see the status of resumed studies, use the [getStudyStatusList]
  /// methods **after** this resume method has ended.
  Future<void> resume() async {
    info('$runtimeType - Resuming all studies...');

    for (var study in studies) {
      debug('$runtimeType - Resuming study: $study');
      final controller = _controllers[study];

      // If this study was running when the app was closed, restart sampling.
      // TODO: We actually do not know the status of the sampling, i.e., the executor....
      if (study.status == StudyStatus.Running) controller?.start();
    }
  }

  /// Called when this client is disposed. Will dispose all studies running
  /// in this client.
  @mustCallSuper
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }

    _group.close();
    Persistence().close();
    _state = ClientManagerState.disposed;
  }

  // // TODO - we don't need this anymore - studies are automatically saved when updated.

  // /// Called when the system puts the app in the background or returns
  // /// the app to the foreground.
  // ///
  // /// Implements the [WidgetsBindingObserver].
  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   debug('$runtimeType - App lifecycle state changed: $state');
  //   switch (state) {
  //     case AppLifecycleState.inactive:
  //     case AppLifecycleState.hidden:
  //       break;
  //     case AppLifecycleState.paused:
  //     case AppLifecycleState.detached:
  //       deactivate();
  //       break;
  //     case AppLifecycleState.resumed:
  //       activate();
  //       break;
  //   }
  // }
}
