part of '../../carp_context_package.dart';

/// Listen on location movements and reports a [Geofence] to the [stream]
/// when a geofence event happens. This probe can handle only one measure.
/// If you need multiple geofences, add a [GeofenceMeasure] for each to your [Study]
/// for example using the [Trigger] model.
class GeofenceProbe extends StreamProbe {
  StreamController<Measurement> geoFenceStreamController =
      StreamController.broadcast();

  /// Set up option for geofence location tracking - accuracy
  /// is set to `low` and distance filter is 10 meters.
  double get distanceFilter => 10;

  @override
  LocationServiceManager get deviceManager =>
      super.deviceManager as LocationServiceManager;

  @override
  Future<bool> onResume() async {
    CircularGeofence fence = CircularGeofence.fromGeofenceSamplingConfiguration(
      samplingConfiguration as GeofenceSamplingConfiguration,
    );

    // listen in on the location service
    deviceManager.manager.onLocationChanged
        .map((location) => GeoPosition.fromLocation(location))
        .listen((location) {
          // when a location event is fired, check if the new location creates a new [GeofenceData] event.
          // if so -- add it to the main stream.
          Geofence? data = fence.moved(location);
          if (data != null) {
            geoFenceStreamController.add(Measurement.fromData(data));
          }
        });

    return await super.onResume();
  }

  @override
  Stream<Measurement> get stream => geoFenceStreamController.stream;
}

/// The possible states of a geofence.
enum GeofenceState { inside, outside, unknown }

/// A class representing a circular geofence with a center,
/// a radius (in meters) and a name.
class CircularGeofence {
  /// The last known state of this geofence.
  GeofenceState state = GeofenceState.unknown;

  /// The last time an event was detected in this geofence.
  DateTime lastEvent = DateTime.now();

  /// The center of the geofence as a GPS location.
  GeoPosition center;

  /// The radius of the geofence in meters.
  double radius;

  /// The dwell time of this geofence. If an object is located inside this
  /// geofence for more that [dwell], the [moved] function will return this.
  Duration dwell;

  /// The name of this geofence.
  String name;

  /// Specify a geofence.
  CircularGeofence({
    required this.center,
    required this.radius,
    required this.dwell,
    required this.name,
  }) : super();

  factory CircularGeofence.fromGeofenceSamplingConfiguration(
    GeofenceSamplingConfiguration configuration,
  ) => CircularGeofence(
    center: configuration.center,
    radius: configuration.radius,
    dwell: configuration.dwell,
    name: configuration.name,
  );

  Geofence? moved(GeoPosition location) {
    Geofence? data;
    if (center.distanceTo(location) < radius) {
      // we're inside the geofence
      switch (state) {
        case GeofenceState.unknown:
        case GeofenceState.outside:
          // if we came from outside the fence, we have now entered
          state = GeofenceState.inside;
          lastEvent = DateTime.now();
          data = Geofence(type: GeofenceType.ENTER, name: name);
          break;
        case GeofenceState.inside:
          // if we were already inside, check if dwelling takes place
          if (lastEvent.add(dwell).isBefore(DateTime.now())) {
            // we have been dwelling in this geofence
            state = GeofenceState.inside;
            lastEvent = DateTime.now();
            data = Geofence(type: GeofenceType.DWELL, name: name);
          }
          break;
      }
    } else {
      // we're outside the geofence - check if we have left
      if (state != GeofenceState.outside) {
        // we have just left the geofence
        state = GeofenceState.outside;
        lastEvent = DateTime.now();
        data = Geofence(type: GeofenceType.EXIT, name: name);
      }
    }

    return data;
  }

  @override
  String toString() =>
      'Geofence - center: $center, radius: $radius, dwell: $dwell, name: $name, state: $state';
}
