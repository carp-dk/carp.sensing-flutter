/// A library for collecting communication data, from
///  * text messages (sms)
///  * phone calls
///  * calendar entries
library;

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:another_telephony/telephony.dart';
import 'package:call_e_log/call_log.dart';
import 'package:device_calendar_plus/device_calendar_plus.dart' as cal;
import 'package:crypto/crypto.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

part 'communication_data.dart';
part 'communication_probes.dart';
part 'communication_package.dart';
part 'communication_privacy.dart';
part 'communication.g.dart';
