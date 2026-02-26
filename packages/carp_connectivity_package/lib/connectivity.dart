/// A library for collecting connectivity data on:
/// * bluetooth info from nearby devices
/// * connectivity status
/// * wifi status
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
