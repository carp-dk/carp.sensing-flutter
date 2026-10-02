/// A sampling package that collects network connectivity, wifi, Bluetooth and beacon data.
///
/// Register [ConnectivitySamplingPackage] in the `SamplingPackageRegistry` to
/// use these measure types in a protocol:
///  * `dk.cachet.carp.connectivity` - connectivity status changes ([Connectivity]).
///  * `dk.cachet.carp.wifi` - the connected wifi network ([Wifi]).
///  * `dk.cachet.carp.bluetooth` - nearby Bluetooth devices ([Bluetooth]).
///  * `dk.cachet.carp.beacon` - nearby iBeacons in given regions ([BeaconData]).
///
/// Works on Android and iOS, using the [Smartphone] primary device. Wifi and
/// Bluetooth names are hashed by the default `PrivacySchema`.
library;

import 'dart:async';
import 'dart:convert';

import 'package:dchs_flutter_beacon/dchs_flutter_beacon.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:connectivity_plus/connectivity_plus.dart' as connectivity;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

part 'connectivity_probes.dart';
part 'connectivity_data.dart';
part 'connectivity.g.dart';
part 'connectivity_package.dart';
part 'connectivity_privacy.dart';

// auto generate json code (.g files) with:
//   flutter pub run build_runner build --delete-conflicting-outputs
