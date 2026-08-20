## 0.1.0

* Initial release of the transportation sampling package.
* Defines the `dk.cachet.carp.transportation` namespace with three data types:
  * `Route` (`.route`) - a GPS route trace sent from the phone to a
    classification server.
  * `Mode` (`.mode`) - the route split into `RouteSegment`s, each labelled
    with a detected `TransportationModeType`, as returned by the server.
  * `UserFeedback` (`.userfeedback`) - the user's approval, rejection, or
    correction of a segment's mode, or labeling of a location cluster (e.g.
    home, work, restaurant).
* Uses a no-op `TransportationProbe` - all three data types are added by app
  code via `probe.addMeasurement(...)`, since none are collected from a
  continuous phone sensor.
