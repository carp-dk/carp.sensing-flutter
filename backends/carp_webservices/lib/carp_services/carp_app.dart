/*
 * Copyright 2018-2024 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_services.dart';

/// The CAWS server instance that the client services talk to.
///
/// Pass it to [CarpBaseService.configure] on [CarpService] and the other
/// CAWS services. Authentication is set up separately with
/// [CarpAuthProperties].
class CarpApp {
  /// The name of this app. The name has to be unique.
  final String name;

  /// The base URI of the CAWS server, like `https://dev.carp.dk`.
  final Uri uri;

  /// Creates a [CarpApp] pointing to the CAWS server at [uri].
  CarpApp({required this.name, required this.uri});

  @override
  int get hashCode => (name + uri.toString()).hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarpApp && runtimeType == other.runtimeType && name == other.name && uri == other.uri;

  @override
  String toString() => 'CarpApp - name: $name, uri: $uri';
}
