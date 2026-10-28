/*
 * Copyright (c) 2025, the Technical University of Denmark (DTU).
 * All rights reserved. Please see the AUTHORS file for details. 
 * Use of this source code is governed by a MIT-style license that 
 * can be found in the LICENSE file.
 */

part of '../runtime.dart';

/// The lifecycle states of the [SmartPhoneClientManager], in order.
///
/// Emitted on [SmartPhoneClientManager.events].
enum ClientManagerState { created, configured, disposed }

/// The main entry point of CARP Mobile Sensing (CAMS) on the phone.
///
/// A singleton that holds all studies running on this phone, deploys them via a
/// [DeploymentService], and gives one [SmartphoneStudyController] per study.
/// An app calls [configure] once at startup, then adds studies with
/// [addStudyFromProtocol], [addStudyFromInvitation] or [addStudy].
///
/// Key points:
///  * [configure] must be called before adding studies. It initializes the
///    infrastructure services, registers the built-in data managers, restores
///    studies saved in earlier app runs and resumes their sampling.
///  * Deploying a study ([tryDeployment]) does not resume its task controls.
///    Use [resume] and [pause] to control sampling in all studies. (A
///    connected device that connects does resume its own task controls.)
///  * Permission requests go through [requestPermissions], one at a time.
///  * [measurements] merges the measurements of all studies on this phone.
///  * Is a [ChangeNotifier]: listeners are notified when the list of [studies]
///    or the sampling state changes. [events] emits [ClientManagerState] changes.
///
/// See also [SmartphoneStudyController], which runs a single study, and
/// [DeviceController], which manages the devices on this phone.
///
/// ```dart
/// await SmartPhoneClientManager().configure();
/// var study = await SmartPhoneClientManager().addStudyFromProtocol(protocol);
/// await SmartPhoneClientManager().tryDeployment(
///   study.studyDeploymentId,
///   study.deviceRoleName,
/// );
/// SmartPhoneClientManager().resume();
/// ```
class SmartPhoneClientManager extends ClientManager<Smartphone, SmartphoneRegistration, SmartphoneStudy>
    with ChangeNotifier {
  static final SmartPhoneClientManager _instance = SmartPhoneClientManager._();

  final NotificationManager _notificationManager = FlutterLocalNotificationManager();
  bool _askForPermissions = true;
  PermissionRequester _permissionRequester = requestPermissionsInOrder;
  Future<void> _asking = Future.value();
  final StreamGroup<Measurement> _group = StreamGroup.broadcast();
  ClientManagerState _state = ClientManagerState.created;
  final StreamController<ClientManagerState> _controller = StreamController.broadcast();
  final Map<Study, SmartphoneStudyController> _controllers = {};

  /// Whether permissions are asked for automatically when a study is deployed.
  ///
  /// Set in [configure].
  bool get askForPermissions => _askForPermissions;

  /// Asks the user for [permissions] with the configured [PermissionRequester].
  ///
  /// CAMS sends its permission requests through here (the notification
  /// permission is asked by the [NotificationManager] itself). Requests are queued and run one at a time: Android denies, without showing
  /// anything, any request made while another dialog is up.
  ///
  /// A failing requester is logged, not rethrown. Callers re-check the actual
  /// permission status afterwards, and an error must not block the requests
  /// queued behind it.
  Future<void> requestPermissions(List<Permission> permissions) => _asking = _asking.then((_) async {
    try {
      await _permissionRequester(permissions);
    } catch (error) {
      warning('$runtimeType - Permission requester failed - $error');
    }
  });

  /// The runtime state of this client manager.
  ///
  /// Setting it emits the new state on [events] and notifies listeners.
  ClientManagerState get state => _state;
  set state(ClientManagerState state) {
    _state = state;
    _controller.add(state);
    notifyListeners();
  }

  /// A stream of [ClientManagerState] events.
  Stream<ClientManagerState> get events => _controller.stream;

  /// All [Measurement]s collected by all studies on this client.
  ///
  /// Merges [SmartphoneStudyController.measurements] of each study, so
  /// measurements are already transformed by the study's privacy schema and
  /// data format. A broadcast stream.
  Stream<Measurement> get measurements => _group.stream;

  SmartPhoneClientManager._() : super(repository: SmartphoneClientRepository()) {
    WidgetsFlutterBinding.ensureInitialized();
    CarpMobileSensing.ensureInitialized();
  }

  /// Returns the singleton [SmartPhoneClientManager].
  ///
  /// An app has only one client manager.
  factory SmartPhoneClientManager() => _instance;

  /// The [DeviceController] that manages all devices on this phone.
  ///
  /// Only available after [configure] has been called.
  DeviceController get deviceController => super.dataCollectorFactory as DeviceController;

  /// The [NotificationManager] that shows notifications for [AppTask]s.
  NotificationManager get notificationManager => _notificationManager;

  /// Returns the [SmartphoneStudyController] for [study].
  ///
  /// Creates a new controller the first time a study is looked up, and adds
  /// its measurements to [measurements].
  SmartphoneStudyController? getStudyController(SmartphoneStudy study) {
    if (_controllers.containsKey(study)) return _controllers[study];

    // Create a fresh controller and start listening to it.
    final controller = SmartphoneStudyController(study);
    _controllers[study] = controller;
    _group.add(controller.measurements);
    return controller;
  }

  /// Configures this [SmartPhoneClientManager]. Call once, before adding studies.
  ///
  /// If [deploymentService] is not specified, the local
  /// [SmartphoneDeploymentService] is used.
  /// If [dataCollectorFactory] is not specified, the [DeviceController]
  /// singleton is used.
  /// The [registration] is a unique device registration for this phone.
  /// If not specified, it is created with [Smartphone.createRegistration].
  ///
  /// If [enableNotifications] is true (default), a notification is shown when
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
  /// If [askForPermissions] is true (default), this client manager
  /// asks for the permissions of all measures in a study when it is deployed.
  /// Set it to false if the app handles permissions itself.
  ///
  /// The [permissionRequester] decides how the user is asked whenever CAMS
  /// needs a permission. Defaults to [requestPermissionsInOrder], which shows
  /// the system dialogs one at a time. Pass your own to, e.g., show a rationale
  /// before each dialog.
  ///
  /// This method also restores all studies saved in earlier app runs and
  /// resumes sampling in the ones that were resumed.
  ///
  /// Does nothing if the client manager is already configured.
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
    PermissionRequester permissionRequester = requestPermissionsInOrder,
  }) async {
    // Fast out if already configured
    if (state.index >= ClientManagerState.configured.index) return;

    _askForPermissions = askForPermissions;
    _permissionRequester = permissionRequester;

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
    await AppTaskController().initialize(enableNotifications: enableNotifications);

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
    debug('$runtimeType - Loaded ${studies.length} studies. Now starting them...');
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

    info('$runtimeType - Adding study, deployment: ${study.deployment?.studyDeploymentId}');
    notifyListeners();
    return study;
  }

  /// Adds a study based on an [invitation], e.g. from a CARP server.
  ///
  /// Same as [addStudy], but the study is created from the [invitation].
  /// If the invitation has no device role name,
  /// [Smartphone.DEFAULT_ROLE_NAME] is used.
  Future<SmartphoneStudy> addStudyFromInvitation(ActiveParticipationInvitation invitation) async => await addStudy(
    SmartphoneStudy(
      studyId: invitation.studyId,
      studyDeploymentId: invitation.studyDeploymentId,
      deviceRoleName: invitation.deviceRoleName ?? Smartphone.DEFAULT_ROLE_NAME,
      participantId: invitation.participantId,
      participantRoleName: invitation.participantRoleName,
    ),
  );

  /// Creates a study deployment from [protocol] and adds it as a study.
  ///
  /// Same as [addStudy], but first creates the deployment in the
  /// [deploymentService]. If [studyDeploymentId] is specified, it is used as
  /// the study deployment id. Otherwise the deployment service generates one.
  ///
  /// Meant for local protocols with one participant: the local user id from
  /// [Settings.userId] is used as participant id, and the first participant
  /// role in the protocol (or 'Participant') as participant role name.
  Future<SmartphoneStudy> addStudyFromProtocol(StudyProtocol protocol, [String? studyDeploymentId]) async {
    final status = await deploymentService.createStudyDeployment(protocol, [], studyDeploymentId);

    // no participant is specified in a protocol so look up the local user id
    var userId = await Settings().userId;

    final study = SmartphoneStudy(
      studyDeploymentId: status.studyDeploymentId,
      deviceRoleName: protocol.primaryDevice.roleName,
      // we expect that this is a "local" protocol where we use the user id as
      // participant id and with just one participant
      participantId: userId,
      participantRoleName: protocol.participantRoles == null || protocol.participantRoles!.isEmpty
          ? 'Participant'
          : protocol.participantRoles?.first.role,
    );
    return await addStudy(study);
  }

  @override
  @mustCallSuper
  Future<void> removeStudy(String studyDeploymentId, String deviceRoleName) async {
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
  Future<StudyStatus> stopStudy(String studyDeploymentId, String deviceRoleName) async {
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

  /// Restarts data sampling in all studies on this client.
  ///
  /// Calls [SmartphoneStudyController.restart], so any stored sampling state
  /// is ignored and all task controls are resumed.
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

  /// Pauses data sampling in all studies on this client.
  void pause() {
    for (var controller in _controllers.values) {
      controller.pause();
    }
    notifyListeners();
  }

  /// Pauses and disposes all studies on this client.
  ///
  /// Then closes the [ExecutorFactory] and [PersistenceService].
  ///
  /// The client manager cannot be used afterwards.
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
