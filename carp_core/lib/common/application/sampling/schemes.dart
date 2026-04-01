/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of '../../../common.dart';

/// Specifies the sampling scheme for a data type ([dataType]), including possible
/// options, defaults, and constraints.
///
/// From sampling schemes, matching sampling configurations can be created.
/// Per data type, only one [SamplingConfiguration] is ever active on a device.
/// The sampling configuration to be used is determined on clients in the following
/// order of priority:
///
///  * The sampling configuration, if specified in the study protocol, as part
///    of the [Measure] as part of the [Measure.overrideSamplingConfiguration].
///
///  * The default sampling configuration, if specified in the study protocol, as
///    part of the [DeviceConfiguration.defaultSamplingConfiguration]. This can
///    be retrieved through the [PrimaryDeviceDeployment] on the client.
///
///  * The default sampling configuration hardcoded in the
///    [DeviceConfiguration.dataTypeSamplingSchemes] sampling schemes of the
///    concrete [DeviceConfiguration], if none of the previous configurations
///    are present.
///
/// See also the section on[Sampling schemes and configurations](https://github.com/carp-dk/carp.core-kotlin/blob/develop/docs/carp-common.md#sampling-schemes-and-configurations)
/// in the CARP Core Framework.
class DataTypeSamplingScheme {
  /// The data type this sampling scheme relates to.
  DataTypeMetaData dataType;

  // TODO - note that this is called "default" in carp-core-kotlin.
  // But "default" is a reserved word in Dart. May cause serialization problems in the future?
  /// The default configuration to use when no other configuration is specified.
  late SamplingConfiguration defaultSamplingConfiguration;

  /// The data type as String.
  String get type => dataType.type;

  /// Create a [Measure] for the [dataType] defined by this sampling scheme,
  /// and override the measure's default [SamplingConfiguration] with
  /// this scheme's [defaultSamplingConfiguration].
  Measure get measure =>
      Measure(type: type)
        ..overrideSamplingConfiguration = defaultSamplingConfiguration;

  DataTypeSamplingScheme(
    this.dataType, [
    SamplingConfiguration? defaultSamplingConfiguration,
  ]) : super() {
    this.defaultSamplingConfiguration =
        defaultSamplingConfiguration ?? NoOptionsSamplingConfiguration();
  }
}

/// A set of [DataTypeSamplingScheme] mapped to their data type as `String`.
class DataTypeSamplingSchemeMap {
  final Map<String, DataTypeSamplingScheme> _map = {};

  /// Creates an empty [DataTypeSamplingSchemeMap].
  DataTypeSamplingSchemeMap();

  /// Creates a [DataTypeSamplingSchemeMap] from the list of [schemes].
  DataTypeSamplingSchemeMap.from(List<DataTypeSamplingScheme> schemes) {
    _map.addAll(
      Map.fromEntries(schemes.map((scheme) => MapEntry(scheme.type, scheme))),
    );
  }

  /// This sampling schema as a native [Map].
  Map<String, DataTypeSamplingScheme> toMap() => _map;

  /// The set of data types as `String` supported by this sampling schema.
  Set<String> get types => _map.keys.toSet();

  /// The list of data types as [DataTypeMetaData] supported by this sampling schema.
  List<DataTypeMetaData> get dataTypes =>
      _map.values.map((schema) => schema.dataType).toList();

  /// The map of all [SamplingConfiguration] entries in this scheme.
  Map<String, SamplingConfiguration> get configurations => _map.map(
    (key, value) => MapEntry(key, value.defaultSamplingConfiguration),
  );

  /// The configuration for the data type [type], or `null` if [type] is not in the map.
  DataTypeSamplingScheme? operator [](String? type) => _map[type];

  /// Associates the [type] with the given [schema].
  void operator []=(String type, DataTypeSamplingScheme schema) =>
      _map[type] = schema;

  /// Add [scheme] to this map of schemes.
  void add(DataTypeSamplingScheme scheme) => _map[scheme.type] = scheme;

  /// Adds all sampling configurations from another [schema] to this schema.
  /// If a configuration in [schema] is already in this schema, its value is overwritten.
  void addSamplingSchema(DataTypeSamplingSchemeMap schema) =>
      _map.addAll(schema._map);

  /// Removes [type] and its associated value, if present, from the map.
  ///
  /// Returns the configuration associated with `type` before it was removed.
  /// Returns `null` if `type` was not in the map.
  DataTypeSamplingScheme? remove(String type) => _map.remove(type);

  /// Removes all data schemes from this map.
  void clear() => _map.clear();

  /// Whether the schema contains the data type [type].
  bool contains(String type) => _map.keys.contains(type);

  @override
  String toString() => _map.toString();
}
