/*
 * Copyright 2018 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

/// Client services for the CARP Web Services (CAWS) backend.
///
/// The CARP Core services are implemented as CAWS clients:
///
///  * [CarpProtocolService] - manages protocols (researchers only).
///  * [CarpParticipationService] - invitations and participant data.
///  * [CarpDeploymentService] - device registration and deployments.
///  * [CarpDataStreamService] - uploads and reads measurements in data streams.
///
/// [CarpService] gives access to the CAWS-only ("non-core") endpoints: files,
/// documents and collections, plus the legacy consent and data point endpoints.
/// Authentication is handled by [CarpAuthService] in the `carp_auth` library.
/// References such as [DeploymentReference] and [ParticipationReference] bind
/// these calls to one study deployment. The `carp_backend` package builds on
/// this library to upload data from a running study.
///
/// Each app is assumed to connect to one CAWS backend only, so the default
/// constructors return shared instances. Configure them before use, like:
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
/// where `authProperties`, `username`, and `password` set up authentication,
/// and `app` is the [CarpApp] that points the participation service to the
/// right CAWS instance.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_webservices/carp_auth/carp_auth.dart';
import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:carp_core/carp_core.dart' hide Smartphone;
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

/// Base exception thrown by the CAWS client services.
///
/// Thrown directly for client-side errors, like using a service before it is
/// configured. Errors returned by the server are thrown as the
/// [CarpServiceRequestException] subclass.
class CarpServiceException implements Exception {
  final String message;
  CarpServiceException([this.message = 'CARP Service Exception']);
}

/// Exception for CAWS REST/HTTP service communication.
///
/// Thrown for non-success HTTP responses with a decodable JSON body, including
/// CAWS application exceptions. The latter typically arise from CARP Core
/// exceptions on the server side, which are mapped to HTTP status codes and
/// messages sent back to the client. Transport failures and undecodable
/// response bodies can propagate as other exceptions.
class CarpServiceRequestException extends CarpServiceException {
  /// The HTTP status from CAWS associated with this exception.
  HTTPStatus httpStatus;

  /// The Java exception from CARP Core.
  String? exception;

  /// The URL path that caused the exception.
  String? path;

  CarpServiceRequestException(super.message, {required this.httpStatus, this.exception, this.path});

  /// Creates the matching exception from an HTTP [httpStatusCode] and the
  /// decoded JSON [response] body.
  ///
  /// Returns a [CarpBadRequestException], [CarpUnauthorizedException],
  /// [CarpNotFoundException] or [CarpInternalServerException] for the
  /// matching status codes, and a plain [CarpServiceRequestException] otherwise.
  ///
  /// There are two types of error messages - from CAWS and from NGINX.
  /// CAWS errors contain 'path' and 'exception' fields,
  /// whereas NGINX errors contain an 'instance' field.
  factory CarpServiceRequestException.fromHttpStatus(int httpStatusCode, dynamic response) {
    String? message = 'Unknown error', exception, path;

    if (response is Map<String, dynamic>) {
      if (response.containsKey('path')) {
        // CAWS error message
        message = response["message"].toString();
        exception = response["exception"].toString();
        path = response["path"].toString();
      } else if (response.containsKey('instance')) {
        // NGINX error message
        message = response["detail"].toString();
        exception = '';
        path = response["instance"].toString();
      } else {
        exception = response["exception"].toString();
        path = response["path"].toString();
      }
    }

    return switch (httpStatusCode) {
      HttpStatus.badRequest => CarpBadRequestException(message, exception: exception, path: path),
      HttpStatus.unauthorized ||
      HttpStatus.forbidden => CarpUnauthorizedException(message, exception: exception, path: path),
      HttpStatus.notFound => CarpNotFoundException(message, exception: exception, path: path),
      HttpStatus.internalServerError => CarpInternalServerException(message, exception: exception, path: path),
      _ => CarpServiceRequestException(
        message,
        httpStatus: HTTPStatus(httpStatusCode),
        exception: exception,
        path: path,
      ),
    };
  }

  @override
  String toString() =>
      "$runtimeType: $httpStatus - $message"
      " - ${exception ?? "exception"} - ${path ?? "path"}";
}

/// A [CarpServiceRequestException] for HTTP 400 Bad Request.
class CarpBadRequestException extends CarpServiceRequestException {
  CarpBadRequestException(super.message, {super.exception, super.path})
    : super(httpStatus: const HTTPStatus(HttpStatus.badRequest));
}

/// A [CarpServiceRequestException] for HTTP 401 Unauthorized or 403 Forbidden.
///
/// Also thrown by [CarpAuthService] when authentication or token refresh fails.
class CarpUnauthorizedException extends CarpServiceRequestException {
  CarpUnauthorizedException(super.message, {super.exception, super.path})
    : super(httpStatus: const HTTPStatus(HttpStatus.unauthorized));
}

/// A [CarpServiceRequestException] for HTTP 404 Not Found.
class CarpNotFoundException extends CarpServiceRequestException {
  CarpNotFoundException(super.message, {super.exception, super.path})
    : super(httpStatus: const HTTPStatus(HttpStatus.notFound));
}

/// A [CarpServiceRequestException] for HTTP 500 Internal Server Error.
class CarpInternalServerException extends CarpServiceRequestException {
  CarpInternalServerException(super.message, {super.exception, super.path})
    : super(httpStatus: const HTTPStatus(HttpStatus.internalServerError));
}

/// An HTTP status code and its reason phrase, as held by a
/// [CarpServiceRequestException].
///
/// See https://en.wikipedia.org/wiki/List_of_HTTP_status_codes
class HTTPStatus {
  /// Reason phrases for the most common HTTP status codes.
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

  final int httpResponseCode;

  /// The reason phrase for [httpResponseCode], or "Unknown Status Code" if
  /// it is not in [httpStatusPhrases].
  String get httpReasonPhrase => httpStatusPhrases[httpResponseCode] ?? "Unknown Status Code";

  const HTTPStatus(this.httpResponseCode);

  @override
  String toString() => "$httpReasonPhrase ($httpResponseCode)";
}
