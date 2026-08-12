## 3.0.0

* **BREAKING** replaced the built-in `Uuid` class with the [uuid](https://pub.dev/packages/uuid) package, which is now re-exported
  * the old generator seeded a `Random` with `DateTime.now().microsecond` — the sub-millisecond component (0-999), not a point in time. Being deterministic, it could only ever emit 1000 distinct ids on any device in any run, so ids collided heavily once more than a handful were generated
  * ids are now generated with `v4()` (random) rather than `v1()` (time- and MAC-based), so they no longer embed device identity or creation time
  * migration: `Uuid().v1` (getter) becomes `const Uuid().v4()` (method)

## 2.0.1

* bumped Flutter version to 3

## 2.0.0

* type safe annotation in class factor method, like this; `FromJsonFactory().fromJson<A>(json)`
* graceful handling of errors when a non-known JSON type is encountered by allowing for a "notAvailable" parameter to the fromJson factory method, like this; `FromJsonFactory().fromJson<B>(json, notAvailable: B(-1))`
* refactor of universal unique IDs (UUIDs) to using the `Uuid().v1` construct
* extending unit test coverage (incl., e.g. exceptions)
* improvement to examples in the `example.dart` file and documentation in the API doc and README

## 1.2.0

* added support for generating universal unique IDs (UUIDs) via the `UUID.v1` construct

## 1.1.1

* Dart type annotation in json is changed from `$type` to `__type` since there were conflict in the Javascript world. This also follows the [CARP Core](https://github.com/cph-cachet/carp.core-kotlin) serialization approach.
* fix of linter errors

## 1.0.0

* Initial release extracted from [carp_core](https://pub.dev/packages/carp_core) version 0.40.0
