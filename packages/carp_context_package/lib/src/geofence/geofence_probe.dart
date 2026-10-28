part of '../../carp_context_package.dart';

/// Listens to location changes and reports a [Geofence] on the [stream] when
/// the phone enters, exits or dwells in a geofence.
///
/// The probe for [ContextSamplingPackage.GEOFENCE]. It handles one geofence,
/// set by a [GeofenceSamplingConfiguration]. For multiple geofences, add one
/// measure per geofence to the protocol. Uses a [CircularGeofence] to detect
/// the events.
class GeofenceProbe extends StreamProbe {
  /// Controller for the [stream] of geofence measurements.
  StreamController<Measurement> geoFenceStreamController = StreamController.broadcast();

  /// Distance filter for geofence location tracking, in meters (always 10).
  ///
  /// Not used; the [LocationService] settings apply.
  double get distanceFilter => 10;

  @override
  LocationServiceManager get deviceManager => super.deviceManager as LocationServiceManager;

  @override
  Future<bool> onResume() async {
    CircularGeofence fence = CircularGeofence.fromGeofenceSamplingConfiguration(
      samplingConfiguration as GeofenceSamplingConfiguration,
    );

    // listen in on the location service
    deviceManager.manager.onLocationChanged.map((location) => GeoPosition.fromLocation(location)).listen((location) {
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

/// The position of the phone relative to a [CircularGeofence].
enum GeofenceState { inside, outside, unknown }

/// A circular geofence with a center, a radius (in meters) and a name.
///
/// Tracks whether the phone is inside and turns location updates into
/// [Geofence] events via [moved]. Used by [GeofenceProbe].
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
  /// geofence for more than [dwell], [moved] returns a [GeofenceType.DWELL]
  /// event.
  Duration dwell;

  /// The name of this geofence.
  String name;

  /// Specify a geofence.
  CircularGeofence({required this.center, required this.radius, required this.dwell, required this.name}) : super();

  /// Creates a [CircularGeofence] from a [GeofenceSamplingConfiguration].
  factory CircularGeofence.fromGeofenceSamplingConfiguration(GeofenceSamplingConfiguration configuration) =>
      CircularGeofence(
        center: configuration.center,
        radius: configuration.radius,
        dwell: configuration.dwell,
        name: configuration.name,
      );

  /// Updates the [state] with a new [location] and returns the resulting
  /// [Geofence] event, or null if nothing happened.
  ///
  /// Returns ENTER when coming from outside (or unknown), EXIT when leaving,
  /// and DWELL each time [dwell] has passed since the last event while inside.
  /// The first update outside the fence also gives an EXIT event.
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
  String toString() => 'Geofence - center: $center, radius: $radius, dwell: $dwell, name: $name, state: $state';
}
