/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

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

/// Specify a CARP Web Service (CAWS) endpoint for uploading data.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class CarpDataEndPoint extends DataEndPoint {
  /// The method used to upload to CARP. See [CarpUploadMethod] for options.
  CarpUploadMethod uploadMethod;

  /// A printer-friendly name of the CAWS endpoint. Can be anything, but its
  /// recommended to name it according to the CAWS service name.
  String name;

  /// Only upload when connected via WiFi network?
  bool onlyUploadOnWiFi = false;

  /// How often should data be uploaded. In minutes.
  ///
  /// Default is every 10 minutes. If running in debug mode, the interval is set to
  /// 1 minute regardless of this setting.
  int uploadInterval = 10;

  /// Should the local buffered data on the phone be deleted once uploaded?
  bool deleteWhenUploaded = true;

  /// Should data be compressed / zipped before upload?
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

/// A enumeration of upload methods to CAWS
enum CarpUploadMethod {
  /// Upload data as data streams (the default method).
  stream,

  /// Upload measurements as data points using the non-core DataPoint endpoint.
  datapoint,

  /// Collect measurements in a SQLite DB file and upload as a `db` file.
  file,
}

/// Exception for CAWS communication.
class CarpBackendException implements Exception {
  String? message;
  CarpBackendException([this.message]);
  @override
  String toString() => "$runtimeType - ${message ?? ""}";
}
