/*
 * Copyright 2021 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../runtime.dart';

/// The possible states of the [SmartPhoneClientManager].
enum ClientManagerState { created, configured, started, stopped, disposed }

class SmartPhoneClientManager extends ClientManager
    with WidgetsBindingObserver {
  static final SmartPhoneClientManager _instance = SmartPhoneClientManager._();
  NotificationController? _notificationController;
  bool _heartbeat = true;
  bool _askForPermissions = true;
  final StreamGroup<Measurement> _group = StreamGroup.broadcast();
  ClientManagerState _state = ClientManagerState.created;

  /// Will this client manager ask for permission when a new study is deployed?
  bool get askForPermissions => _askForPermissions;

  /// The runtime state of this client manager.
  ClientManagerState get state => _state;

  /// The stream of all [Measurement]s collected by this client manager.
  /// This is the aggregation of all measurements collected by the
  /// [studies] running on this client.
  Stream<Measurement> get measurements => _group.stream;

  SmartPhoneClientManager._() {
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.addObserver(this);
    CarpMobileSensing.ensureInitialized();
  }

  /// Get the singleton [SmartPhoneClientManager].
  ///
  /// In CARP Mobile Sensing the [SmartPhoneClientManager] is a singleton,
  /// which implies that only one client manager is used in an app.
  factory SmartPhoneClientManager() => _instance;

  /// Is this client sending [Heartbeat] measurements for its studies?
  bool get heartbeat => _heartbeat;

  /// The number of studies running on this client.
  int get studyCount => studies.length;

  // /// The list of studies deployed on this client manager.
  // List<Study> get studies => repository.keys.toList();

  @override
  DeviceController get deviceController =>
      super.deviceController as DeviceController;

  /// The [NotificationController] responsible for sending notification on [AppTask]s.
  NotificationController? get notificationController => _notificationController;

  @override
  SmartphoneDeploymentController? getStudyRuntime(String studyDeploymentId) =>
      super.getStudyRuntime(studyDeploymentId)
          as SmartphoneDeploymentController;

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
    DeploymentService? deploymentService,
    DeviceDataCollectorFactory? deviceController,
    DeviceRegistration? registration,
    bool enableNotifications = true,
    NotificationController? notificationController,
    bool askForPermissions = true,
    bool heartbeat = true,
  }) async {
    // initialize misc device settings
    await DeviceInfo().init();
    await Settings().init();
    await Persistence().init();

    // create and register the built-in data managers
    DataManagerRegistry().register(ConsoleDataManagerFactory());
    DataManagerRegistry().register(FileDataManagerFactory());
    DataManagerRegistry().register(SQLiteDataManagerFactory());

    // create the device registration using the [DeviceInfo] singleton
    registration ??= DefaultDeviceRegistration(
      deviceId: DeviceInfo().deviceID,
      deviceDisplayName: DeviceInfo().toString(),
    );

    // initialize default services, if not specified
    deploymentService ??= SmartphoneDeploymentService();
    deviceController ??= DeviceController();
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

    super.configure(
      deploymentService: deploymentService,
      deviceController: deviceController,
      registration: registration,
    );

    // look up and register all connected devices and services on this client
    this.deviceController.registerAllAvailableDevices();

    var statusMsg =
        '===========================================================\n'
        '  CARP Mobile Sensing (CAMS) - $runtimeType\n'
        '===========================================================\n'
        '             device : ${registration.deviceDisplayName}\n'
        ' deployment service : ${this.deploymentService}\n'
        '  device controller : ${this.deviceController}\n'
        '  available devices : ${this.deviceController.devicesToString()}\n'
        '        persistence : ${Persistence().databaseName.split('/').last}\n'
        '===========================================================\n';
    debugPrint(statusMsg);

    _state = ClientManagerState.configured;
  }

  @override
  Future<SmartphoneStudy> addStudy(Study study) async {
    assert(
      study is SmartphoneStudy,
      'Trying to add a study which is not a SmartphoneStudy to a SmartphoneStudyClientManager.',
    );

    await super.addStudy(study);

    // Always create a new controller
    final controller = SmartphoneDeploymentController(
      deploymentService!,
      deviceController,
    );
    repository[study.studyDeploymentId] = controller;
    _group.add(controller.measurements);

    await controller.addStudy(study, registration!);
    info('$runtimeType - Added study: $study');

    return study as SmartphoneStudy;
  }

  /// Add a study based on an [invitation] which needs to be executed on
  /// this client.
  ///
  /// This is similar to the [addStudy] method, but the study is created from the
  /// [invitation].
  ///
  /// Returns the newly added study.
  Future<SmartphoneStudy> addStudyFromInvitation(
    ActiveParticipationInvitation invitation,
  ) async {
    assert(
      deploymentService != null,
      'Deployment Service has not been configured. Call configure() first.',
    );

    final study = SmartphoneStudy(
      studyId: invitation.studyId,
      studyDeploymentId: invitation.studyDeploymentId,
      deviceRoleName: invitation.deviceRoleName ?? Smartphone.DEFAULT_ROLE_NAME,
      participantId: invitation.participantId,
      participantRoleName: invitation.participantRoleName,
    );

    return await addStudy(study);
  }

  /// Create and add a study based on the [protocol] which needs to be executed on
  /// this client.
  ///
  /// This is similar to the [addStudy] method, but the study is created from the
  /// [protocol]. If [studyDeploymentId] is specifies this id is used as the study
  /// deployment id. If not specified, an UUID v1 id is generated.
  ///
  /// Returns the newly added study.
  Future<SmartphoneStudy> addStudyFromProtocol(
    StudyProtocol protocol, [
    String? studyDeploymentId,
  ]) async {
    assert(
      deploymentService != null,
      'Deployment Service has not been configured. Call configure() first.',
    );

    final status = await deploymentService!.createStudyDeployment(
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
    return await addStudy(study);
  }

  @override
  Future<void> removeStudy(String studyDeploymentId) async {
    // fast out if not a valid deployment id
    if (!studies.containsKey(studyDeploymentId)) return;

    info('Removing study from $runtimeType - $studyDeploymentId');

    // Disconnecting from all devices will stop sensing on each of them.
    await deviceController.disconnectAllConnectedDevices();

    AppTaskController().removeStudyDeployment(studyDeploymentId);

    var m = getStudyRuntime(studyDeploymentId)?.measurements;
    if (m != null) _group.remove(m);

    await super.removeStudy(studyDeploymentId);
  }

  /// Persistently save information related to this client manger.
  /// Typically used for later resuming when app is restarted. See [resume].
  Future<void> save() async {
    for (var studyDeploymentId in repository.keys) {
      await getStudyRuntime(studyDeploymentId)?.saveDeployment();
    }
  }

  /// Called when this client manager is being (re-)activated by the OS.
  ///
  /// Implementations of this method should start with a call to the inherited
  /// method, as in `super.activate()`.
  @protected
  @mustCallSuper
  void activate() {}

  /// Called when this client manager is being deactivated and potentially
  /// stopped by the OS.
  ///
  /// Implementations of this method should start with a call to the inherited
  /// method, as in `super.deactivate()`.
  @protected
  @mustCallSuper
  Future<void> deactivate() async => await save();

  /// Start all studies in this client manager.
  void start() {
    for (var studyDeploymentId in repository.keys) {
      getStudyRuntime(studyDeploymentId)?.start();
    }
    _state = ClientManagerState.started;
  }

  /// Stop all studies in this client manager.
  Future<void> stop() async {
    for (var studyDeploymentId in repository.keys) {
      await getStudyRuntime(studyDeploymentId)?.stop();
    }
    _state = ClientManagerState.stopped;
  }

  /// Restore and resume all study deployments which were running on this
  /// client manager when the app was killed / stopped (e.g., by the OS).
  ///
  /// This method is useful on app restart, since it will restore and
  /// resume all sampling on this client.
  /// Data sampling will be resumed for studies which were running
  /// (i.e., having [StudyStatus.Running]) when the app was closed.
  ///
  /// Returns the number of restored studies, if any (may be zero).
  /// To access a list of resumed studies, check the list of [studies]
  /// **after** this resume method has ended.
  Future<int> resume() async {
    info('$runtimeType - restoring all study deployments');
    var persistentStudies = await Persistence().getAllStudyDeployments();

    debug('$runtimeType - studies: $persistentStudies');

    for (var study in persistentStudies) {
      debug('$runtimeType - study status: ${study.status}');

      // only add deployed, running or stopped studies
      if (study.status == StudyStatus.Deployed ||
          study.status == StudyStatus.Running ||
          study.status == StudyStatus.Stopped) {
        // add the restored study
        await addStudy(study);

        // deploy the study using the cached deployment
        final controller = getStudyRuntime(study.studyDeploymentId);
        await controller?.tryDeployment();
        await controller?.configure();

        // if this study was running when the app was closed, restart sampling
        if (study.status == StudyStatus.Running) controller?.start();
      }
    }
    _state = ClientManagerState.started;
    return studyCount;
  }

  /// Called when this client is disposed permanently.
  ///
  /// When this method is called, the client is never used again. It is an error
  /// to call any of the [start] or [stop] methods at this point.
  ///
  /// Subclasses should override this method to release any resources retained
  /// by this client.
  /// Implementations of this method should end with a call to the inherited
  /// method, as in `super.dispose()`.
  ///
  /// See also:
  ///
  ///  * [deactivate], which is called prior to [dispose].
  @mustCallSuper
  void dispose() {
    deactivate();
    for (var studyDeploymentId in repository.keys) {
      getStudyRuntime(studyDeploymentId)?.dispose();
    }
    _group.close();
    Persistence().close();
    _state = ClientManagerState.disposed;
  }

  /// Called when the system puts the app in the background or returns
  /// the app to the foreground.
  ///
  /// Implements the [WidgetsBindingObserver].
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debug('$runtimeType - App lifecycle state changed: $state');
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        deactivate();
        break;
      case AppLifecycleState.resumed:
        activate();
        break;
    }
  }
}
