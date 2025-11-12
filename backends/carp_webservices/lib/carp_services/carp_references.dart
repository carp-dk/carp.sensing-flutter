/*
 * Copyright 2018-2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_services.dart';

/// Abstract CARP web service references.
abstract class CarpReference {
  CarpBaseService service;

  CarpReference._(this.service);

  Map<String, String> get headers => service.headers;
}

abstract class RPCCarpReference extends CarpReference {
  RPCCarpReference._(CarpBaseService service) : super._(service);

  /// The URL for this reference's endpoint at CARP.
  ///
  /// Typically on the form:
  /// `{{PROTOCOL}}://{{SERVER_HOST}}:{{SERVER_PORT}}/api/...`
  String get rpcEndpointUri;

  /// A generic RPC request to the CARP service.
  Future<dynamic> _rpc(ServiceRequest request, [String? endpointName]) async =>
      await service._rpc(request, endpointName);
}
