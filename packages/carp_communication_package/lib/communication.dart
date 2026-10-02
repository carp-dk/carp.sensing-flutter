/// A sampling package that collects phone calls, text messages and calendar entries.
///
/// Register [CommunicationSamplingPackage] in the `SamplingPackageRegistry` to
/// use these measure types in a protocol:
///  * `dk.cachet.carp.phonelog` - the phone call log ([PhoneLog]). Android only.
///  * `dk.cachet.carp.textmessagelog` - the text message (SMS) log ([TextMessageLog]). Android only.
///  * `dk.cachet.carp.textmessage` - incoming text messages ([TextMessage]). Android only.
///  * `dk.cachet.carp.calendar` - calendar entries ([Calendar]). Android and iOS.
///
/// All measures use the [Smartphone] primary device. Phone numbers, message
/// content and calendar titles are hashed by the default `PrivacySchema`
/// (see [textMessageAnonymizer] and related functions).
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
