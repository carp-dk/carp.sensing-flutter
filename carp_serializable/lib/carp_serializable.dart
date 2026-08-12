library carp_serializable;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

export 'package:uuid/uuid.dart' show Uuid;

/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

/// This is the base class for all JSON serializable objects.
///
/// Using this class allow for implementing both serialization and
/// deserialization to/from JSON.
/// This is done using the [json_serializable](https://pub.dev/packages/json_serializable)
/// package.
///
/// It also allows for serialization of polymorphic classes.
///
/// To support polymorphic serialization, each subclass should:
///
///  * annotate the class with `@JsonSerializable`
///  * add the three json methods
///      * `Function get fromJsonFunction => ...`
///      * `factory ...fromJson(...)`
///      * `Map<String, dynamic> toJson() => ...`
///  * register the classes in the `FromJsonFactory()` registry.
///  * build json function using the `flutter pub run build_runner build --delete-conflicting-outputs` command
///
/// Below is a simple example of two classes `A` and `B` where B extends A.
///
/// ```dart
/// @JsonSerializable()
/// class A extends Serializable {
///   int? index;
///
///   A() : super();
///
///   Function get fromJsonFunction => _$AFromJson;
///   factory A.fromJson(Map<String, dynamic> json) =>
///       FromJsonFactory().fromJson(json) as A;
///   Map<String, dynamic> toJson() => _$AToJson(this);
/// }
///
/// @JsonSerializable()
/// class B extends A {
///   String? str;
///
///   B() : super();
///
///   Function get fromJsonFunction => _$BFromJson;
///   factory B.fromJson(Map<String, dynamic> json) =>
///       FromJsonFactory().fromJson(json) as B;
///   Map<String, dynamic> toJson() => _$BToJson(this);
/// }
/// ````
///
/// Note that the naming of the `fromJson()` and `toJson()` functions follows
/// [json_serializable](https://pub.dev/packages/json_serializable)
/// package. For example the `fromJson` function for class `A` is called `_$AFromJson`.
///
/// The [fromJsonFunction] must be registered on app startup (before
/// use of de-serialization) in the [FromJsonFactory] singleton, like this:
///
/// ```dart
///  FromJsonFactory().register(A());
/// ````
///
/// For this purpose it is helpful to have an empty constructor, but any constructor
/// will work, since only the `fromJsonFunction` function is used.
///
/// Polymorphic serialization is handled by setting the `__type` property in the
/// [Serializable] class. Per default, an object's `runtimeType` is used as the
/// `__type` for an object. Hence, the json of object of type `A` and `B` would
/// look like this:
///
/// ```json
///  {
///   "__type": "A",
///   "index": 1
///  }
///  {
///   "__type": "B",
///   "index": 2
///   "str": "abc"
///  }
/// ```
///
/// However, if you want to specify your own class type (e.g., if you get
/// json serialized from another language which uses a package structure like
/// Java, C# or Kotlin), you can specify the json type in the [jsonType] property
/// of the class.
///
/// For example, if the class `B` above should use a different `__type` annotation,
/// using the following:
///
/// ```dart
/// @JsonSerializable()
/// class B extends A {
///
///   <<as above>>
///
///   String get jsonType => 'dk.cachet.$runtimeType';
/// }
/// ````
///
/// In which case the json would look like:
///
/// ```json
///  {
///   "__type": "dk.cachet.B",
///   "index": 2
///   "str": "abc"
///  }
/// ```
///
abstract class Serializable {
  /// The identifier of the class type in JSON serialization.
  static const String CLASS_IDENTIFIER = '__type';

  /// The runtime class name (type) of this object.
  /// Used for deserialization from JSON objects.
  @JsonKey(name: CLASS_IDENTIFIER)
  String? $type;

  /// Create an object that can be serialized to JSON.
  Serializable() {
    $type = jsonType;
  }

  /// The function which can convert a JSON string to an object of this type.
  Function get fromJsonFunction;

  /// Return a JSON encoding of this object.
  Map<String, dynamic> toJson();

  /// Return the `__type` to be used for JSON serialization of this class.
  /// Default is [runtimeType]. Only specify this if you need another type.
  String get jsonType => runtimeType.toString();
}

/// A factory that holds [fromJson] functions to be used in JSON
/// deserialization.
class FromJsonFactory {
  static final FromJsonFactory _instance = FromJsonFactory._();
  factory FromJsonFactory() => _instance;

  final Map<String, Function> _registry = {};

  FromJsonFactory._();

  /// Register [serializable] as a class which can be deserialized from JSON.
  ///
  /// If [type] is specified, then this is used as the type identifier as
  /// specified in [CLASS_IDENTIFIER].
  /// Otherwise the [Serializable] class [jsonType] is used.
  ///
  /// A type needs to be registered **before** a class can be deserialized from
  /// JSON to a Dart class.
  void register(Serializable serializable, {String? type}) =>
      _registry[type ?? serializable.jsonType] = serializable.fromJsonFunction;

  /// Register all [serializables].
  ///
  /// A connivent way to call [register] for multiple types.
  void registerAll(List<Serializable> serializables) {
    for (var serializable in serializables) {
      register(serializable);
    }
  }

  /// Deserialize [json] based on its type [T].
  ///
  /// Returns the deserialized object if the type [T] has been registered in
  /// this factory.
  /// If the type is not available (registered), [notAvailable] is returned if specified.
  /// Otherwise, a [SerializationException] is thrown.
  T fromJson<T extends Serializable>(
    Map<String, dynamic> json, {
    T? notAvailable,
  }) {
    var message = '';
    final type = json[Serializable.CLASS_IDENTIFIER];
    if (!_registry.containsKey(type)) {
      message =
          "A 'fromJson' function was not found in the FromJsonFactory for the type '$type'. "
          "Register a Serializable class using the 'FromJsonFactory().register()' method."
          "\nIf you are using CARP Mobile Sensing, you can ensure json initialization by calling"
          "'CarpMobileSensing.ensureInitialized()' as part of your main method.";

      if (notAvailable != null) {
        debugPrint('$runtimeType - $message');
        return notAvailable;
      } else {
        throw SerializationException(message);
      }
    }

    var fromJson = Function.apply(_registry[type!]!, [json]);
    if (fromJson is T) return fromJson;

    message =
        "The 'fromJson' function registered for the type '$type' does not return an object of the correct type ('$T'). "
        "Make sure that the fromJson function returns a class of type '$T'.";

    if (notAvailable != null) {
      debugPrint('$runtimeType - $message');
      return notAvailable;
    } else {
      throw SerializationException(message);
    }
  }
}

/// Throws when serialization to/from json fails.
class SerializationException implements Exception {
  final String _message;
  String get message => _message;
  SerializationException([this._message = '']);
  @override
  String toString() => '$runtimeType - $message';
}

/// Converts [object] to a formatted JSON [String].
String toJsonString(Object? object) =>
    const JsonEncoder.withIndent(' ').convert(object);


