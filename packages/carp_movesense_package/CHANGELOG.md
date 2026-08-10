## 3.0.1

* default `namePrefix` to `'Movesense'` (mirroring `PolarDevice`), so BLE scan filtering works for Movesense devices deployed from CAWS without an explicit prefix

## 3.0.0

* **BREAKING (dependency only)**: migrated from the [`mdsflutter`](https://pub.dev/packages/mdsflutter) plugin to the [`carp_movesense_flutter`](https://pub.dev/packages/carp_movesense_flutter) plugin.
* The **public Dart API of this sampling package is unchanged**
* `carp_movesense_flutter` **bundles the native Movesense MDS libraries** (the Android `mdslib` `.aar` and the iOS `MovesenseMDS.xcframework`). Apps that upgrade should **remove the now-obsolete manual Movesense SDK setup**: the manually vendored `android/libs/mdslib-*.aar` + `flatDir` repository, and the `pod 'Movesense', :git => ...` line in the iOS `Podfile`. See the README for details.
* Raised the minimum Dart SDK to `3.12.2` (required by `carp_movesense_flutter`).

## 2.0.2

* disconnect from MDS when a connection attempt fails, so the native SDK stops auto-retrying in the background and the device settles as disconnected

## 2.0.1

* register the 1.x `MovesenseDevice` device type as a `fromJson` alias, for backwards compatibility with studies created on CAMS 1.x (protocol API level < 2.0)

## 2.0.0

* upgrade to CARP Core and CAMS API level 2.0.0

## 1.7.6

* fix of [#451](https://github.com/cph-cachet/carp.sensing-flutter/issues/451)

## 1.7.5

* fix of [#378](https://github.com/cph-cachet/carp_studies_app/issues/378)
* upgrade to latest Flutter plugins

## 1.7.3

* fix of [#455](https://github.com/cph-cachet/carp.sensing-flutter/issues/455)

## 1.7.2

* added device information measure and probe to get the device information from connected Movesense devices
* better error handling and messages
* fix of [#448](https://github.com/cph-cachet/carp.sensing-flutter/issues/448)
* fix of error on reconnect

## 1.6.0

* upgrade to carp_serialization v. 2.0 & carp_mobile_sensing: 1.10.0

## 1.5.1

* fix compatibility with Flutter 3.24

## 1.5.0

* upgrading to carp_mobile_sensing v. 1.9.0 (better permission handling)

## 1.4.5

* upgrade of plugin versions
* cleanup in pubspec

## 1.4.2

* added unit tests
* improved documentation

## 1.4.1

* initial release supporting Movesense device management and sampling of tap events, HR, ECG, temperature, and IMU measures.
* updated docs
