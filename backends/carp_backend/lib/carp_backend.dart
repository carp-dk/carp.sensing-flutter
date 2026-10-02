/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

/// Connects CARP Mobile Sensing (CAMS) to the CARP Web Services (CAWS) backend.
///
/// Provides:
///  * [CarpDataEndPoint] and [CarpDataManager], which buffer measurements on the
///    phone and upload them to CAWS. Register [CarpDataManagerFactory] in the
///    [DataManagerRegistry] before deploying a study that uses this data endpoint.
///  * [CarpResourceManager], which downloads and caches study resources from CAWS:
///    the consent document, localizations and [Message]s.
///  * [CarpLocalizations], a Flutter localization delegate backed by CAWS.
///
/// Uses the `carp_webservices` package, so [CarpService] and [CarpAuthService]
/// must be configured and a user authenticated before use.
library;

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_webservices/carp_services/carp_services.dart';
import 'package:research_package/research_package.dart';

part 'carp_data_manager.dart';
part 'data_stream_buffer.dart';
part 'localization_manager.dart';
part 'informed_consent_manager.dart';
part 'carp_resource_manager.dart';
part 'message_manager.dart';
part 'carp_localization.dart';
part 'carp_backend.g.dart';

/// A data endpoint that uploads collected data to CARP Web Services (CAWS).
///
/// Set it as the [SmartphoneStudyProtocol.dataEndPoint] of a protocol to have
/// measurements uploaded to CAWS. At runtime it is handled by a
/// [CarpDataManager], created by the [CarpDataManagerFactory].
///
/// Key points:
///  * [uploadMethod] selects how data is sent; [CarpUploadMethod.stream] is the default.
///  * Data is buffered locally and uploaded every [uploadInterval] minutes.
///  * Serializes to JSON (type `CAWS`), so it can be part of a protocol stored on CAWS.
///
/// ```dart
/// protocol.dataEndPoint = CarpDataEndPoint(
///   uploadMethod: CarpUploadMethod.stream,
///   onlyUploadOnWiFi: true,
/// );
/// ```
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class CarpDataEndPoint extends DataEndPoint {
  /// The method used to upload to CARP. See [CarpUploadMethod] for options.
  CarpUploadMethod uploadMethod;

  /// A human-readable name of the CAWS endpoint.
  ///
  /// Can be anything, but it is recommended to use the name of the CAWS server.
  String name;

  /// Whether to upload only when the phone is on a WiFi network.
  bool onlyUploadOnWiFi = false;

  /// How often buffered data is uploaded, in minutes.
  ///
  /// Default is 10 minutes. If [Settings.debugLevel] is [DebugLevel.debug],
  /// data is uploaded every minute regardless of this setting.
  int uploadInterval = 10;

  /// Whether buffered data (and uploaded [FileData] files) on the phone are
  /// deleted once uploaded.
  ///
  /// If `false`, buffered measurements are kept but marked as uploaded.
  bool deleteWhenUploaded = true;

  /// Whether data is compressed before upload.
  ///
  /// Only used by [CarpUploadMethod.stream].
  bool compress = true;

  /// Creates a [CarpDataEndPoint].
  CarpDataEndPoint({
    super.dataFormat,
    this.name = 'CARP Web Services',
    this.uploadMethod = CarpUploadMethod.stream,
    this.onlyUploadOnWiFi = false,
    this.uploadInterval = 10,
    this.deleteWhenUploaded = true,
    this.compress = true,
  }) : super(type: DataEndPointTypes.CAWS);

  @override
  Function get fromJsonFunction => _$CarpDataEndPointFromJson;

  factory CarpDataEndPoint.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<CarpDataEndPoint>(json);
  @override
  Map<String, dynamic> toJson() => _$CarpDataEndPointToJson(this);

  @override
  String toString() =>
      '$runtimeType [$name] - method: ${uploadMethod.name}, interval: $uploadInterval';
}

/// The ways a [CarpDataManager] can upload data to CAWS.
enum CarpUploadMethod {
  /// Upload data as data streams (the default method).
  stream,

  /// Upload measurements as data points using the deprecated DataPoint endpoint.
  datapoint,

  /// Collect measurements in a SQLite DB file and upload as a `db` file.
  ///
  /// Not implemented yet. Selecting it uploads nothing.
  file,
}

/// Exception thrown on errors when communicating with CAWS.
class CarpBackendException implements Exception {
  /// A description of the error, if any.
  String? message;
  CarpBackendException([this.message]);
  @override
  String toString() => "$runtimeType - ${message ?? ""}";
}
