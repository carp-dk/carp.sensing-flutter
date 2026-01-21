/*
 * Copyright 2019 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// Signature of a data transformer.
typedef DataTransformer = Data Function(Data);

/// A no-operation transformer.
Data noop(Data data) => data;

/// A factory which can create a [DataTransformer].
abstract class DataTransformerFactory {
  static DataTransformer? get transformer => null;
}

/// A registry of [DataTransformerSchema]s which hold a set of
/// [DataTransformer]s.
class DataTransformerSchemaRegistry {
  static final DataTransformerSchemaRegistry _instance =
      DataTransformerSchemaRegistry._();

  /// The map between the namespace of a transformer schema and the schema.
  Map<String, DataTransformerSchema> get schemas => _schemas;
  final Map<String, DataTransformerSchema> _schemas = {};

  /// Get the singleton instance of the [DataTransformerSchemaRegistry].
  factory DataTransformerSchemaRegistry() => _instance;

  DataTransformerSchemaRegistry._() {
    // register 3 default transformer schemas:
    // 1. a no-operation CARP schema
    // 2. a default OMH schema
    // 3. a default FHIR schema
    // 4. a default privacy transformation schemas
    register(CARPTransformerSchema());
    register(OMHTransformerSchema());
    register(FHIRTransformerSchema());
    register(PrivacySchema());
  }

  /// Register a transformer schema.
  void register(DataTransformerSchema schema) {
    _schemas[schema.namespace] = schema;
    schema.onRegister();
  }

  /// Lookup a transformer schema based on its namespace.
  DataTransformerSchema? lookup(String namespace) => _schemas[namespace];
}

/// An abstract class defining a transformer schema, which hold a set of
/// [DataTransformer]s that can map from the native CARP namespace
/// to another namespace.
/// A [DataTransformerSchema] must be implemented for each supported namespace.
abstract class DataTransformerSchema {
  /// The type of namespace that this package can transform to (see e.g.
  /// [NameSpace] for pre-defined namespaces).
  String get namespace;

  final Map<String, DataTransformer> _transformers = {};

  /// A map of transformers in this schema, indexed by the data type they
  /// can transform.
  Map<String, DataTransformer> get transformers => _transformers;

  /// Callback method when this schema is being registered.
  void onRegister();

  /// Add a transformer to this schema that can map data of a specific [format].
  void add(String format, DataTransformer transformer) =>
      transformers[format] = transformer;

  /// Transform the [data] using a transformer for its data format.
  /// If no transformer is found, returns [data] unchanged.
  Data transform(Data data) {
    DataTransformer? transformer = transformers[data.dataType.toString()];
    return (transformer != null) ? transformer(data) : data;
  }
}

/// A default [DataTransformerSchema] for CARP no-operation transformers
class CARPTransformerSchema extends DataTransformerSchema {
  @override
  String get namespace => NameSpace.CARP;
  @override
  void onRegister() {}
}

/// A default [DataTransformerSchema] for Open mHealth (OMH) transformers
class OMHTransformerSchema extends DataTransformerSchema {
  @override
  String get namespace => NameSpace.OMH;
  @override
  void onRegister() {}
}

/// A default [DataTransformerSchema] for HL7 FHIR transformers
class FHIRTransformerSchema extends DataTransformerSchema {
  @override
  String get namespace => NameSpace.FHIR;
  @override
  void onRegister() {}
}

/// A default [DataTransformerSchema] for privacy transformers
class PrivacySchema extends DataTransformerSchema {
  static const String DEFAULT = 'default-privacy-schema';

  @override
  String get namespace => DEFAULT;
  @override
  void onRegister() {}
}
