/*
 * Copyright 2018 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

/// A library for all CARP Web Services (CAWS):
///
///  * [CarpAuthService]
///  * [CarpService]
///  * [CarpProtocolService]
///  * [CarpParticipationService]
///  * [CarpDeploymentService]
///  * [CarpDataStreamService]
///
/// The (current) assumption is that each Flutter app (using this library) will
/// only connect to one CAWS backend.
/// All CAWS services are therefore singletons and can be used like:
///
/// ```dart
/// await CarpAuthService().configure(authProperties);
///
/// user = await CarpAuthService().authenticateWithUsernamePassword(
///   username: username,
///   password: password,
/// );
///
/// CarpParticipationService().configure(app);
/// ```
///
/// where `authProperties`, `username`, and `password` are parameters for setting up
/// authentication, and `app` is configuring the participation service to use the
/// right CAWS instance.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart';
import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';

part 'carp_base_service.dart';
part 'carp_service.dart';
part 'deployment_service.dart';
part 'participation_service.dart';
part 'protocol_service.dart';
part 'data_stream_service.dart';
part 'data_stream_reference.dart';
part 'carp_app.dart';
part 'carp_tasks.dart';
part 'consent_document.dart';
part 'carp_references.dart';
part 'data_point_reference.dart';
part 'data_point.dart';
part 'deployment_reference.dart';
part 'participation_reference.dart';
part 'collection_reference.dart';
part 'document_reference.dart';
part 'file_reference.dart';
part '../util/http_retry.dart';
part '../util/push_id_generator.dart';
part '../ui/invitations_dialog.dart';
part '../util/utils.dart';

part 'carp_services.g.dart';

/// Exception for CAWS REST/HTTP service communication.
class CarpServiceException implements Exception {
  HTTPStatus? httpStatus;
  String? message;
  String? path;

  /// Create new [CarpServiceException].
  CarpServiceException({this.httpStatus, this.message, this.path});

  /// Create new [CarpServiceException] from a HTTP response [httpStatusCode] and [map].
  factory CarpServiceException.fromMap(
      int httpStatusCode, Map<String, dynamic> map) {
    // we have two types of error messages - from CAWS and from NGINX
    if (map.containsKey('path')) {
      return CarpServiceException(
        httpStatus: HTTPStatus(httpStatusCode),
        message: map["message"].toString(),
        path: map["path"].toString(),
      );
    } else if (map.containsKey('instance')) {
      return CarpServiceException(
        httpStatus: HTTPStatus(httpStatusCode),
        message: map["detail"].toString(),
        path: map["instance"].toString(),
      );
    } else {
      return CarpServiceException(
        httpStatus: HTTPStatus(httpStatusCode),
        message: 'Unknown error',
      );
    }
  }

  @override
  String toString() =>
      "CarpServiceException: ${(httpStatus != null) ? "$httpStatus - " : ""} ${message ?? ""} - ${path ?? ""}";
}

/// Implements HTTP Response Code and associated Reason Phrase.
/// See https://en.wikipedia.org/wiki/List_of_HTTP_status_codes
class HTTPStatus {
  /// Mapping of the most common HTTP status code to text.
  /// See https://en.wikipedia.org/wiki/List_of_HTTP_status_codes
  static const Map<int, String> httpStatusPhrases = {
    100: "Continue",
    200: "OK",
    201: "Created",
    202: "Accepted",
    300: "Multiple Choices",
    301: "Moved Permanently",
    400: "Bad Request",
    401: "Unauthorized",
    402: "Payment Required",
    403: "Forbidden",
    404: "Not Found",
    405: "Method Not Allowed",
    408: "Request Timeout",
    409: "Conflict",
    410: "Gone",
    413: "Payload Too Large",
    500: "Internal Server Error",
    501: "Not Implemented",
    502: "Bad Gateway",
    503: "Service Unavailable",
    504: "Gateway Timeout",
    505: "HTTP Version Not Supported",
  };

  int httpResponseCode;
  String? httpReasonPhrase;

  HTTPStatus(this.httpResponseCode, [String? httpPhrase]) {
    httpReasonPhrase = ((httpPhrase == null) || (httpPhrase.isEmpty))
        ? httpStatusPhrases[httpResponseCode]
        : httpPhrase;
  }

  @override
  String toString() => "$httpResponseCode $httpReasonPhrase";
}
