/*
 * Copyright 2019 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../domain.dart';

/// Signature of a data transformer, which maps one [Data] object to another.
///
/// Used to convert data to another format (e.g. OMH or FHIR) or to protect
/// privacy (e.g. hash an identifier). Grouped in a [DataTransformerSchema].
typedef DataTransformer = Data Function(Data);

/// A no-operation transformer that returns [data] unchanged.
Data noop(Data data) => data;

/// A marker interface for [Data] classes that can be made by a
/// [DataTransformer], e.g. an OMH data point.
///
/// Static members are not inherited, so implementations declare their own
/// static `transformer` getter by convention. CAMS does not read it.
abstract class DataTransformerFactory {
  static DataTransformer? get transformer => null;
}

/// The registry of all [DataTransformerSchema]s, looked up by namespace.
///
/// A singleton. The CARP, OMH, FHIR, and default privacy schemas are
/// registered on creation. Sampling packages add their transformers to these
/// schemas, and the [SmartphoneStudyController] uses them to transform each
/// measurement before it reaches the [DataManager].
class DataTransformerSchemaRegistry {
  static final DataTransformerSchemaRegistry _instance = DataTransformerSchemaRegistry._();

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

  /// Registers [schema] under its namespace, replacing any existing one, and
  /// calls [DataTransformerSchema.onRegister].
  void register(DataTransformerSchema schema) {
    _schemas[schema.namespace] = schema;
    schema.onRegister();
  }

  /// The transformer schema for [namespace], or `null` if none is registered.
  DataTransformerSchema? lookup(String namespace) => _schemas[namespace];
}

/// A set of [DataTransformer]s that map data from the CARP namespace to
/// another [namespace], indexed by data type.
///
/// Implement one for each supported namespace and register it in the
/// [DataTransformerSchemaRegistry]. The schema used for a study is selected
/// by [DataEndPoint.dataFormat] or [SmartphoneStudyProtocol.privacySchemaName].
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

  /// Adds a [transformer] for data of type [format], replacing any existing one.
  void add(String format, DataTransformer transformer) => transformers[format] = transformer;

  /// Transforms [data] using the transformer for its data type.
  ///
  /// Returns [data] unchanged if no transformer is found.
  Data transform(Data data) {
    DataTransformer? transformer = transformers[data.dataType.toString()];
    return (transformer != null) ? transformer(data) : data;
  }
}

/// The default [DataTransformerSchema] for the CARP namespace, with no
/// transformers (data is kept as collected).
class CARPTransformerSchema extends DataTransformerSchema {
  @override
  String get namespace => NameSpace.CARP;
  @override
  void onRegister() {}
}

/// The default [DataTransformerSchema] for Open mHealth (OMH) transformers.
///
/// Empty by default; sampling packages add their OMH transformers to it.
class OMHTransformerSchema extends DataTransformerSchema {
  @override
  String get namespace => NameSpace.OMH;
  @override
  void onRegister() {}
}

/// The default [DataTransformerSchema] for HL7 FHIR transformers.
///
/// Empty by default; sampling packages add their FHIR transformers to it.
class FHIRTransformerSchema extends DataTransformerSchema {
  @override
  String get namespace => NameSpace.FHIR;
  @override
  void onRegister() {}
}

/// The default [DataTransformerSchema] for privacy transformers.
///
/// Selected with [SmartphoneStudyProtocol.privacySchemaName] set to [DEFAULT].
/// Sampling packages add transformers that hide or hash sensitive data.
class PrivacySchema extends DataTransformerSchema {
  /// The namespace of the default privacy schema.
  static const String DEFAULT = 'default-privacy-schema';

  @override
  String get namespace => DEFAULT;
  @override
  void onRegister() {}
}
