## 3.0.0

* require `carp_mobile_sensing` ^3.0.0

## 2.1.0

* require `carp_serializable` ^3.0.0, which replaces the built-in `Uuid` with the [uuid](https://pub.dev/packages/uuid) package

## 2.0.2

* discover data types from both the online streaming (PMD) and the HR service SDK features, so devices that only deliver HR via the standard BLE HR service (e.g. Verity Sense) report their supported types
* clear the discovered data types on disconnect
* clean up the event listeners when a connection attempt fails, so a later attempt does not stack subscriptions on a half-connected device
* await the cancellation of the event listeners when disconnecting, so the disconnect emitted by the SDK is not handled by the listeners being torn down

## 2.0.1

* register the 1.x `PolarDevice` device type as a `fromJson` alias, for backwards compatibility with studies created on CAMS 1.x (protocol API level < 2.0)

## 2.0.0

* upgrade to CARP Core and CAMS API level 2.0.0

## 1.6.2

* upgrade to carp_serialization v. 2.0 & carp_mobile_sensing: 1.10.0
* fix of error on reconnect
* upgrade to latest Flutter version
* update of README

## 1.5.0

* upgrading to carp_mobile_sensing v. 1.9.0 (better permission handling)

## 1.4.2

* small update to disconnection handling.
* samples uses Dart DateTime timestamps instead of int (milliseconds)

## 1.4.0

* upgrade to Dart 3.2
* update to `carp_mobile_sensing` v. 1.4.0

## 1.3.1

* upgrade of permission_handler plugins
* update to `carp_mobile_sensing` v. 1.3.0

## 1.2.0

* update to `carp_mobile_sensing` v. 1.2.0 using the new device permissions model

## 1.1.1

* update to `polar` v. 6.0 (Polar API level 5.2)

## 1.1.0

* update to `carp_mobile_sensing` v. 1.1.0
* update to `polar` v. 5.2.0 (Polar API level 5)

## 0.40.1

* upgrade to`polar` 3.4.0

## 0.40.0

* initial release based on `carp_mobile_sensing` v. 0.40.0
