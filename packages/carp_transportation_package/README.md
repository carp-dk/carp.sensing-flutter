# CARP Transportation Sampling Package

[![CARP](https://img.shields.io/badge/CARP-carp.dk-2E8B57)](https://carp.dk/)
[![pub package](https://img.shields.io/pub/v/carp_transportation_package.svg)](https://pub.dev/packages/carp_transportation_package)
[![GitHub](https://img.shields.io/badge/GitHub-carp.sensing--flutter-deeppink?logo=github&logoColor=white)](https://github.com/carp-dk/carp.sensing-flutter)
[![MIT License](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/Docs-docs.carp.dk-0A66C2?logo=readthedocs&logoColor=white)](https://docs.carp.dk/carp-mobile-sensing/)

This library contains a sampling package for the
[`carp_mobile_sensing`](https://pub.dartlang.org/packages/carp_mobile_sensing)
framework for **classifying transportation modes on routes** and collecting
**user feedback** on that classification.

Unlike most sampling packages, this package does not sense continuously from
a phone sensor. Instead it moves data between the phone and a route
classification server (note: this package does *not* implement the client
for talking to that server nor the location collection itself - both are
app/deployment specific, e.g. use `carp_context_package`'s location probe to
collect [`RoutePoint`]s):

1. The app builds up a [`Route`] (a GPS trace) from location data and sends
   it to a classification server (`dk.cachet.carp.transportation.route`).
2. The server classifies the route into segments and returns a [`Mode`]:
   the route split into [`RouteSegment`]s, each labelled with a detected
   [`TransportationModeType`] (`dk.cachet.carp.transportation.mode`).
3. The user reviews the classification in the app UI and can approve,
   reject, or correct a segment's mode, or label a cluster of locations
   (e.g. home, work, restaurant). This is captured as [`UserFeedback`]
   (`dk.cachet.carp.transportation.userfeedback`) and sent back to the
   server.

This package defines its own namespace `dk.cachet.carp.transportation` and
supports the following [`Measure`](https://docs.carp.dk/carp-mobile-sensing/measure-types) types:

* `dk.cachet.carp.transportation.route` : a GPS route trace sent to the
  classification server.
* `dk.cachet.carp.transportation.mode` : the transportation mode
  classification of a route, received from the server.
* `dk.cachet.carp.transportation.userfeedback` : user feedback on a route's
  mode classification, or a location cluster labeled as a place.

Since none of the above are sensed automatically, all three are collected
via the same no-op [`TransportationProbe`]. App code adds data to it once
available:

```dart
// look up the running probe(s) for this study deployment
final probe = Sensing().controller!.executor.lookupProbe(
  TransportationSamplingPackage.ROUTE,
).first as TransportationProbe;

// once the route is complete, add it
probe.addMeasurement(Measurement.fromData(route));

// once the server responds with a classification
probe.addMeasurement(Measurement.fromData(mode));

// once the user approves/rejects/corrects/labels
probe.addMeasurement(Measurement.fromData(userFeedback));
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
    ..addMeasure(Measure(type: TransportationSamplingPackage.ROUTE))
    ..addMeasure(Measure(type: TransportationSamplingPackage.MODE))
    ..addMeasure(Measure(type: TransportationSamplingPackage.USER_FEEDBACK)),
  phone,
);
```

See the [`example`](example/lib/example.dart) folder for a full example.
