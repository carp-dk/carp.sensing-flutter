/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

part of '../runtime.dart';

/// The possible states of the [SmartPhoneClientManager].
enum ClientManagerState { created, configured, disposed }

/// The singleton `SmartPhoneClientManager()` is the main entry point for CARP
/// Mobile Sensing.
///
/// Call [configure] before using this client.
///
/// It holds a set of [SmartphoneStudy] [studies], which can been added,
/// deployed, stopped, and removed via the [addStudy], [tryDeployment],
/// [stopStudy], and [removeStudy] methods.
///
/// A client manager is also a [ChangeNotifier] which notifies its
/// listeners on any changes to its list of [studies]. The [events] stream emits
/// and event when the state of the client changes.
///
/// Assuming a `protocol` as a [StudyProtocol], this will configure and run a study
/// in a client manager:
///
/// ```dart
/// // Create and configure a client manager for this phone.
/// await SmartPhoneClientManager().configure();
///
/// // Create a study based on a protocol.
/// var study = await SmartPhoneClientManager().addStudyFromProtocol(protocol);
///
/// // Deploy the study.
///   await SmartPhoneClientManager().tryDeployment(
///     study.studyDeploymentId,
///     study.deviceRoleName,
///   );
/// ```
///
/// Note that 'deploying' a study does not start data collection. Use the methods
/// [resume] and [pause] to resume and pause data collection.
class SmartPhoneClientManager
    extends ClientManager<Smartphone, SmartphoneRegistration, SmartphoneStudy>
    with ChangeNotifier {
  static final SmartPhoneClientManager _instance = SmartPhoneClientManager._();

  final NotificationManager _notificationManager =
      FlutterLocalNotificationManager();
  bool _askForPermissions = true;
  final StreamGroup<Measurement> _group = StreamGroup.broadcast();
  ClientManagerState _state = ClientManagerState.created;
  final StreamController<ClientManagerState> _controller =
      StreamController.broadcast();
  final Map<Study, SmartphoneStudyController> _controllers = {};

  /// Will this client manager ask for permission when a new study is deployed?
  bool get askForPermissions => _askForPermissions;

  /// The runtime state of this client manager.
  ClientManagerState get state => _state;
  set state(ClientManagerState state) {
    _state = state;
    _controller.add(state);
    notifyListeners();
  }

  /// A stream of [ClientManagerState] events.
  Stream<ClientManagerState> get events => _controller.stream;

  /// The stream of all [Measurement]s collected by this client manager.
  /// This is the aggregation of all measurements collected by the
  /// studies running on this client.
  Stream<Measurement> get measurements => _group.stream;

  SmartPhoneClientManager._()
    : super(repository: SmartphoneClientRepository()) {
    WidgetsFlutterBinding.ensureInitialized();
    CarpMobileSensing.ensureInitialized();
  }

  /// Get the singleton [SmartPhoneClientManager].
  ///
  /// In CARP Mobile Sensing the [SmartPhoneClientManager] is a singleton,
  /// which implies that only one client manager is used in an app.
  factory SmartPhoneClientManager() => _instance;

  DeviceController get deviceController =>
      super.dataCollectorFactory as DeviceController;

  /// The [NotificationManager] responsible for sending notification on [AppTask]s.
  NotificationManager get notificationManager => _notificationManager;

  /// Get the study controller for a [study].
  /// If a study controller is not available, a fresh controller will be created.
  SmartphoneStudyController? getStudyController(SmartphoneStudy study) {
    if (_controllers.containsKey(study)) return _controllers[study];

    // Create a fresh controller and start listening to it.
    final controller = SmartphoneStudyController(study);
    _controllers[study] = controller;
    _group.add(controller.measurements);
    return controller;
  }

  /// Configure this [SmartPhoneClientManager].
  ///
  /// If the [deploymentService] is not specified, the local
  /// [SmartphoneDeploymentService] will be used.
  /// If the [dataCollectorFactory] is not specified, the default [DeviceController]
  /// is used.
  /// The [registration] is a unique device registration for this client device.
  /// If not specified, a registration is created from the [Smartphone.createRegistration]
  /// factory method.
  ///
  /// If [enableNotifications] is true (default), notifications is created when
  /// an [AppTask] is triggered.
  ///
  /// If [enableBackgroundMode] is true (default), data sampling will be enabled
  /// to run in the background. This means that data sampling will continue
  /// even when the app is not in the foreground, as long as the phone is not
  /// restarted. If background mode is enabled, the [backgroundNotificationTitle]
  /// and [backgroundNotificationText] can be specified to customize the notification
  /// shown when data sampling is running in the background. If not specified,
  /// default English titles and text will be used. If you want to use localized
  /// titles and text, you can provide them here.
  /// Note that background mode is only supported on Android, and will be ignored on iOS.
  ///
  /// If [askForPermissions] is true (default), this client manager will
  /// automatically ask for permissions for all sampling packages at once.
  /// If you want the app to handle permissions itself, set this to false.
  ///
  /// When this method is called, the client manager will restore the state of
  /// all previously added studies and resume data sampling in those studies if
  /// they were previously resumed.
  ///
  /// Note that the client manager needs to be configured before adding any studies.
  ///
  /// If the client manager is already configured, this method will do nothing.
  @override
  Future<void> configure({
    SmartphoneRegistration? registration,
    DeploymentService? deploymentService,
    DeviceDataCollectorFactory? dataCollectorFactory,
    bool enableNotifications = true,
    bool enableBackgroundMode = true,
    String? backgroundNotificationTitle,
    String? backgroundNotificationText,
    bool askForPermissions = true,
  }) async {
    // Fast out if already configured
    if (state.index >= ClientManagerState.configured.index) return;

    _askForPermissions = askForPermissions;

    // Initialize infrastructure services and the repository.
    await DeviceInfoService().init();
    await Settings().init();
    await PersistenceService().init();
    await SmartphoneClientRepository().init();

    // Create and register the built-in data managers.
    DataManagerRegistry().register(ConsoleDataManagerFactory());
    DataManagerRegistry().register(FileDataManagerFactory());
    DataManagerRegistry().register(SQLiteDataManagerFactory());

    // Initialize default registration and services and configure this client manager.
    registration ??= Smartphone().createRegistration();
    deploymentService ??= SmartphoneDeploymentService();
    dataCollectorFactory ??= DeviceController();
    super.configure(
      registration: registration,
      deploymentService: deploymentService,
      dataCollectorFactory: dataCollectorFactory,
    );

    // Register all primary and connected device and service managers available.
    deviceController.registerAllAvailableDevices();

    // Enable background mode if specified. This will make sure that data sampling
    // will continue even when the app is not in the foreground, as long as the
    // phone is not restarted.
    if (enableBackgroundMode) {
      await BackgroundService().initialize(
        notificationTitle: backgroundNotificationTitle,
        notificationText: backgroundNotificationText,
      );
      await BackgroundService().enable();
    }

    // Configure the notification manager.
    // This will ask for permissions if needed.
    await notificationManager.configure();

    // Initialize the app task controller.
    // This will restore previous queue from persistent storage.
    await AppTaskController().initialize(
      enableNotifications: enableNotifications,
    );

    var statusMsg =
        '===========================================================\n'
        '  CARP Mobile Sensing (CAMS) - $runtimeType\n'
        '===========================================================\n'
        '             Device : ${registration.deviceDisplayName}\n'
        '         Repository : $repository\n'
        ' Deployment Service : $deploymentService\n'
        '  Device Controller : $deviceController\n'
        '  Available Devices : ${deviceController.devicesToString()}\n'
        '        Persistence : ${PersistenceService().databaseName.split('/').last}\n'
        '    Background Mode : ${BackgroundService().isEnabled ? "enabled" : "disabled"}\n'
        '===========================================================\n';
    debugPrint(statusMsg);

    // Now add previously stored studies to this client.
    debug(
      '$runtimeType - Loaded ${studies.length} studies. Now starting them...',
    );
    for (var study in studies) {
      await addStudy(study);

      // Mark that an updated deployment status has been received for this study,
      // and if a deployment is available, mark that as well.
      // This will trigger the study controller to update the deployment and start
      // sampling if the deployment is valid.
      study.deploymentStatusReceived();
      if (study.deployment != null) {
        study.deviceDeploymentReceived();
      }
    }

    state = ClientManagerState.configured;
    notifyListeners();
  }

  @override
  Future<SmartphoneStudy> addStudy(SmartphoneStudy study) async {
    await super.addStudy(study);

    // Will create a fresh controller, if this is a new study.
    getStudyController(study);

    info(
      '$runtimeType - Adding study, deployment: ${study.deployment?.studyDeploymentId}',
    );
    notifyListeners();
    return study;
  }

  /// Add a study based on an [invitation] which needs to be executed on
  /// this client.
  ///
  /// This is similar to the [addStudy] method, but the study is created from the
  /// [invitation].
  Future<SmartphoneStudy> addStudyFromInvitation(
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
  Future<SmartphoneStudy> addStudyFromProtocol(
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
    return await addStudy(study);
  }

  @override
  @mustCallSuper
  Future<void> removeStudy(
    String studyDeploymentId,
    String deviceRoleName,
  ) async {
    var study = getStudy(studyDeploymentId, deviceRoleName);
    // fast out if not a valid study
    if (study == null) return;

    info('$runtimeType - Removing study: $study');

    AppTaskController().removeStudy(study);
    var controller = _controllers[study];
    if (controller != null) _group.remove(controller.measurements);
    controller?.dispose();
    _controllers.remove(study);
    await super.removeStudy(studyDeploymentId, deviceRoleName);
    notifyListeners();
  }

  @override
  @mustCallSuper
  Future<StudyStatus> stopStudy(
    String studyDeploymentId,
    String deviceRoleName,
  ) async {
    var study = getStudy(studyDeploymentId, deviceRoleName);
    // fast out if not a valid study
    if (study == null) {
      throw Exception(
        '$runtimeType - Cannot stop study - no study with deployment id '
        '$studyDeploymentId and device role name $deviceRoleName found.',
      );
    }

    info('$runtimeType - Stopping study: $study');

    AppTaskController().removeStudy(study);

    var controller = _controllers[study];
    if (controller != null) _group.remove(controller.measurements);
    controller?.dispose();
    _controllers.remove(study);
    var status = await super.stopStudy(studyDeploymentId, deviceRoleName);
    notifyListeners();
    return status;
  }

  /// Resume data sampling for all studies in this client manager.
  void resume() {
    for (var controller in _controllers.values) {
      // controller.resume();
      // Using restart instead of resume to make sure that sampling is restarted
      // and not merely resumed based on the previous state.
      // This is to make sure that sampling is restarted even if the study was paused or stopped before.
      controller.restart();
    }
    notifyListeners();
  }

  /// Pause data sampling for all studies in this client manager.
  void pause() {
    for (var controller in _controllers.values) {
      controller.pause();
    }
    notifyListeners();
  }

  /// Called when this client is disposed. Will dispose all studies running
  /// in this client.
  @override
  @mustCallSuper
  void dispose() {
    debug('$runtimeType - Disposing client manager...');

    // First pause all data sampling
    pause();

    // Then dispose all study controllers.
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();

    // Finally dispose the client manager itself.
    ExecutorFactory().dispose();
    _group.close();
    PersistenceService().close();
    _state = ClientManagerState.disposed;
    super.dispose();
  }
}
