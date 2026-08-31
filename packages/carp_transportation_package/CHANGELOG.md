## 0.1.0

* Initial release of the transportation (mobility) sampling package,
  implementing v0.1 of the Mobility Sampling Package Design Specification.
* Defines the `dk.cachet.carp.transportation` namespace with the data types of
  the mobility processing pipeline:
  * `TransportationModelConfiguration` (`.modelconfiguration`) and
    `StageConfiguration` (`.stageconfiguration`) - one-time configuration of
    the recognition and segmentation components.
  * `TransportationSample` (`.transportationsample`) - a point-wise sample
    with its embedding, predicted `TransportationMode`, and raw model output.
  * `MoveStage` (`.move`) and `StopStage` (`.stop`) - stage-level segments
    derived from consecutive transportation samples.
  * `MobilityActivity` (`.activity`) - the semantic interpretation of a stop.
  * `StageModeCorrection` (`.stagemodecorrection`) - a user correction of a
    stage's predicted mode.
* `Trip`, stage boundary correction, and semantic correction are not part of
  this version and are reserved for future development.
* Uses a no-op `TransportationProbe` - all data types are added by app code
  via `probe.addMeasurement(...)`, since none are collected from a continuous
  phone sensor.
