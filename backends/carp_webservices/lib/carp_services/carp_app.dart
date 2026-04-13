/*
 * Copyright 2018-2024 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_services.dart';

/// Represents a CARP web service app endpoint.
class CarpApp {
  /// The name of this app. The name has to be unique.
  final String name;

  /// URI of the CARP web service
  final Uri uri;

  /// Create a [CarpApp] which know how to access a CARP backend.
  ///
  /// [name] and [uri] are required parameters in order to identify and
  /// know the CAWS endpoint URI.
  CarpApp({required this.name, required this.uri});

  @override
  int get hashCode => (name + uri.toString()).hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarpApp &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          uri == other.uri;

  @override
  String toString() => 'CarpApp - name: $name, uri: $uri';
}
