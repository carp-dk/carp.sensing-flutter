# CARP Transportation Sampling Package

[![CARP](https://img.shields.io/badge/CARP-carp.dk-2E8B57)](https://carp.dk/)
[![pub package](https://img.shields.io/pub/v/carp_transportation_package.svg)](https://pub.dev/packages/carp_transportation_package)
[![GitHub](https://img.shields.io/badge/GitHub-carp.sensing--flutter-deeppink?logo=github&logoColor=white)](https://github.com/carp-dk/carp.sensing-flutter)
[![MIT License](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/Docs-docs.carp.dk-0A66C2?logo=readthedocs&logoColor=white)](https://docs.carp.dk/carp-mobile-sensing/)

This library contains a sampling package for the
[`carp_mobile_sensing`](https://pub.dartlang.org/packages/carp_mobile_sensing)
framework implementing the **Mobility Sampling Package Design Specification**:
it holds the data types of a mobility processing pipeline which turns raw
sensor observations into increasingly higher-level mobility information.

Unlike most sampling packages, this package does not sense from a phone sensor
itself. The raw sensor data (location, acceleration, rotation) is already
collected by the existing packages (e.g. `carp_context_package`'s location
probe); this package defines what the processing on top of it produces:

```
sensor samples --> TransportationSample --> MoveStage / StopStage --> MobilityActivity
                    (mode classification)      (segment decode)      (activity identification)
```

1. **Point-wise** - `TransportationSample`: a location observation enriched
   with its learned `embedding` and the predicted `TransportationMode`,
   together with the raw model output (`logits`, `probabilities`,
   `confidence`).
2. **Stage-wise** - `MoveStage` and `StopStage` (both subclasses of `Stage`):
   continuous segments obtained by grouping consecutive transportation
   samples. A `MoveStage` is a movement between locations (distance, speed
   statistics, public-transport information); a `StopStage` is a stay within
   a small area (centroid, max displacement, nearest POI).
3. **Semantic** - `MobilityActivity`: the interpretation of a meaningful
   stop, e.g. being at home, working, or shopping.
4. **User feedback** - `StageModeCorrection`: the user's correction of the
   mode predicted for a stage.

Two configuration types are collected once at initialization and hold what
does not change per sample: `TransportationModelConfiguration` (embedding
model, mode labels, classification and decoding method, device information)
and `StageConfiguration` (user id, segmentation method).

> **Naming**: `MoveStage`, `StopStage`, and `MobilityActivity` carry a suffix/
> prefix relative to the design specification (`Move`, `Stop`, `Activity`) to
> avoid clashing with `carp_core`'s `Stop` deployment request and
> `carp_context_package`'s `Activity` data type, which are typically imported
> alongside this package.

> **Not yet implemented** (reserved for future versions, per the design
> specification): `Trip`, stage boundary correction, and semantic correction
> of activities/trips.

This package defines its own namespace `dk.cachet.carp.transportation` and
supports the following [`Measure`](https://docs.carp.dk/carp-mobile-sensing/measure-types) types:

* `dk.cachet.carp.transportation.modelconfiguration` : the transportation
  model configuration (one-time).
* `dk.cachet.carp.transportation.stageconfiguration` : the stage segmentation
  configuration (one-time).
* `dk.cachet.carp.transportation.transportationsample` : a point-wise
  transportation sample.
* `dk.cachet.carp.transportation.move` : a stage-level moving segment.
* `dk.cachet.carp.transportation.stop` : a stage-level still segment.
* `dk.cachet.carp.transportation.activity` : the semantic interpretation of a
  stop.
* `dk.cachet.carp.transportation.stagemodecorrection` : a user correction of a
  stage's transportation mode.

Since none of the above are sensed automatically, all are collected via the
same no-op `TransportationProbe`. App code adds data to it once available:

```dart
// look up the running probe for this study deployment
final probe = Sensing().controller!.executor.lookupProbe(
  TransportationSamplingPackage.TRANSPORTATION_SAMPLE,
).first as TransportationProbe;

// after mode inference (in batches)
probe.addMeasurement(Measurement.fromData(transportationSample));

// when a stage is newly created or modified
probe.addMeasurement(Measurement.fromData(moveStage));

// when the user corrects a stage's mode
probe.addMeasurement(Measurement.fromData(correction));
```

## Derived attributes

Attributes marked *derived* in the design specification are computed, not
stored - they are serialized to JSON, but recomputed from their source on
deserialization:

* `TransportationModelConfiguration.numModes` - from `modeLabels`.
* `TransportationSample.embeddingDim` - from `embedding`.
* `TransportationSample.confidence` - from the entropy of `probabilities`
  when not given explicitly:
  `confidence = 1 - (-sum(p * log p)) / log K`.
* `Stage.numSamples`, `Stage.durationInMinutes` - from the sample id and time
  boundaries.
* `MobilityActivity.dwellTime` - from the activity's time boundaries.

The stage attributes derived from the samples a stage spans (traveled
distance, speed statistics, centroid, max displacement) are computed by the
`MoveStage.fromSamples` and `StopStage.fromSamples` factories:

```dart
var move = MoveStage.fromSamples(samples, stageId: 2, mode: TransportationMode.bus);
var stop = StopStage.fromSamples(samples, stageId: 3);
```

## Installation

To use this package, add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  carp_transportation_package: ^0.1.0
```

## Usage

To use this package, register it in the
[`carp_mobile_sensing`](https://pub.dev/packages/carp_mobile_sensing)
package using:

```dart
SamplingPackageRegistry().register(TransportationSamplingPackage());
```

An example of a study protocol configuration:

```dart
protocol.addTaskControl(
  ImmediateTrigger(),
  BackgroundTask()
    ..addMeasure(Measure(type: TransportationSamplingPackage.TRANSPORTATION_SAMPLE))
    ..addMeasure(Measure(type: TransportationSamplingPackage.MOVE))
    ..addMeasure(Measure(type: TransportationSamplingPackage.STOP))
    ..addMeasure(Measure(type: TransportationSamplingPackage.ACTIVITY)),
  phone,
);
```

See the [`example`](example/lib/example.dart) folder for a full example.
