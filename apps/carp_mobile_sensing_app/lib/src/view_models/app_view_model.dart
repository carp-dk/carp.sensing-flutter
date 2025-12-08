part of '../../main.dart';

class AppViewModel with ChangeNotifier {
  StudyViewModel? _studyViewModel;

  AppViewModel() : super() {
    // Listen to changes in the client and notify listeners
    // bloc.sensing.client.addListener(() => notifyListeners());
    bloc.sensing.client.addListener(
      () => bloc.study != null ? studyViewModel.study = bloc.study! : null,
    );
  }

  /// Get the view model for the [study].
  StudyViewModel get studyViewModel =>
      _studyViewModel ??= StudyViewModel(bloc.study);

  /// Is sensing running, i.e. has the study executor been started?
  bool get isRunning =>
      bloc.sensing.controller?.executor.state == ExecutorState.Resumed;

  @override
  void dispose() {
    super.dispose();
    bloc.sensing.client.dispose();
  }
}
