part of '../../main.dart';

/// A view model for [ProbesListPage]
class ProbeListViewModel with ChangeNotifier {
  /// Get a list of view models for the running probes.
  Iterable<ProbeViewModel> get runningProbes => bloc.sensing.runningProbes
      .toSet() // only unique probes
      .where((probe) => probe is! StubProbe) // remove stub probes
      .map((probe) => ProbeViewModel(probe));
}

/// A view model for a [Probe].
class ProbeViewModel {
  Probe probe;
  String? get type => probe.type;
  Measure? get measure => probe.measure;
  ExecutorState get state => probe.state;
  Stream<ExecutorState> get stateEvents => probe.stateEvents;

  /// A printer-friendly name for this probe.
  String? get name =>
      SamplingPackageRegistry()
          .samplingSchemes[measure?.type]
          ?.dataType
          .displayName ??
      measure.runtimeType.toString();

  /// A printer-friendly description of this probe.
  String? get description => ProbeDescription.descriptors[type]?.description;

  /// The icon for this type of probe.
  Icon? get icon => ProbeDescription.descriptors[type]?.icon;

  /// The icon for the runtime state of this probe.
  Icon? get stateIcon => ProbeDescription.probeStateIcon[state];

  ProbeViewModel(this.probe) : super();
}
