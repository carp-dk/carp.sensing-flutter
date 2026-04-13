part of '../../main.dart';

/// A view model for the [StudyPage] view.
class StudyViewModel with ChangeNotifier {
  SmartphoneStudy? _study;

  StudyViewModel(this._study) : super();

  set study(SmartphoneStudy study) {
    _study = study;
    study.addListener(() => notifyListeners()); // Notify when study changes
    notifyListeners();
  }

  SmartphoneDeployment? get deployment => _study?.deployment;
  Image get image => Image.asset('assets/study.png');
  String get title => _study == null
      ? 'No Study'
      : _study?.isDeployed == false
      ? 'No Deployment'
      : deployment?.studyDescription?.title ?? 'No Deployment';
  String get description => _study == null
      ? 'No study has yet been added. Press the "+" button to add a study.'
      : deployment?.studyDescription?.description ??
            'The study has not been deployed yet. Press the "Refresh" button to begin deployment. ';
  String get studyDeploymentId =>
      _study != null ? '...-${_study?.studyDeploymentId.split('-').last}' : '';
  String get deviceRoleName => _study?.deviceRoleName ?? '';
  String get participantRoleName => _study?.participantRoleName ?? '';
  String? get dataEndpointType => deployment?.dataEndPoint?.type;

  StudyDeploymentStatusTypes? get studyDeploymentStatus =>
      _study?.deploymentStatus?.status;

  StudyStatus? get studyStatus => bloc.sensing.controller?.study.status;

  /// Events on the study status of the client manager
  Stream<StudyStatus> get studyStatusEvents =>
      bloc.sensing.controller?.study.events.map(
        (event) => event.study.status,
      ) ??
      Stream.empty();

  /// Current state of the study executor (e.g., started, stopped, ...)
  ExecutorState get executorState =>
      bloc.sensing.controller?.executor.state ?? ExecutorState.Undefined;

  /// Events on the state of the study executor
  Stream<ExecutorState> get executorStateEvents =>
      bloc.sensing.controller?.executor.stateEvents ?? Stream.empty();

  /// Get all sensing events (i.e. all [Measurement] objects being collected).
  Stream<Measurement> get measurements =>
      bloc.sensing.controller?.measurements ?? Stream.empty();

  /// The total sampling size so far since this study was started.
  int get samplingSize => bloc.sensing.samplingSize;

  /// Get the latest status of the study deployment.
  Future<void> refreshStudyDeploymentStatus() async => (_study != null)
      ? await bloc.sensing.client.getStudyDeploymentStatus(_study!)
      : null;
}
