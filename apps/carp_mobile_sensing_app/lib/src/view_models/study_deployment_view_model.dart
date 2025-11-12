part of '../../main.dart';

/// A view model for the [StudyDeploymentPage] view.
class StudyDeploymentViewModel {
  SmartphoneDeployment deployment;

  String get title => deployment.studyDescription?.title ?? '';
  String get description =>
      deployment.studyDescription?.description ?? 'No description available.';
  Image get image => Image.asset('assets/study.png');
  String get studyDeploymentId => deployment.studyDeploymentId;
  StudyDeploymentStatusTypes get studyDeploymentStatus => deployment.status;
  String get deviceRoleName => deployment.deviceConfiguration.roleName;
  String get participant => deployment.participantId ?? '';
  String get participantRoleName => deployment.participantRoleName ?? '';
  String get dataEndpointType =>
      deployment.dataEndPoint?.type ?? DataEndPointTypes.UNKNOWN;

  /// Current status of the study.
  StudyStatus get studyStatus =>
      bloc.sensing.controller?.status ?? StudyStatus.DeploymentNotStarted;

  /// Events on the study status of the client manager
  Stream<StudyStatus> get studyStatusEvents =>
      bloc.sensing.controller?.statusEvents ?? Stream.empty();

  /// Current state of the study executor (e.g., started, stopped, ...)
  ExecutorState get executorState =>
      bloc.sensing.controller?.executor.state ?? ExecutorState.created;

  /// Events on the state of the study executor
  Stream<ExecutorState> get executorStateEvents =>
      bloc.sensing.controller?.executor.stateEvents ?? Stream.empty();

  /// Get all sensing events (i.e. all [Measurement] objects being collected).
  Stream<Measurement> get measurements =>
      bloc.sensing.controller?.measurements ?? Stream.empty();

  /// The total sampling size so far since this study was started.
  int get samplingSize => bloc.sensing.controller?.samplingSize ?? 0;

  StudyDeploymentViewModel(this.deployment) : super();
}
