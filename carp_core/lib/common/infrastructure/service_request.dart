/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../common.dart';

/// Base class for all RPC requests to the CARP services.
///
/// Each service has its own request family, e.g., `DeploymentServiceRequest`.
/// A request serializes to the JSON that the CARP web services expect.
abstract class ServiceRequest extends Serializable {
  /// The API version of this request as defined by CARP Core Kotlin.
  String apiVersion = "1.0";
}
