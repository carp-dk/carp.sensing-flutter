# CARP Serialization

A package for polymorphic serialization to/from JSON build on top of [json_serializable](https://pub.dev/packages/json_serializable).

This package allows for implementing serialization and deserialization to/from JSON.
This is done using the [json_serializable](https://pub.dev/packages/json_serializable) package, so please study how the json_serializable package works, before using this package.

The key feature of this package is that it extends json_serializable with support for serialization of **polymorphic** classes, i.e. classes that inherits from each other. This is done by adding type information to the json.

## Getting started

To use this package, add [`carp_serializable`](https://pub.dev/packages/carp_serializable) and [`json_annotation`](https://pub.dev/packages/json_annotation) as [dependencies in your `pubspec.yaml` file](https://flutter.io/platform-plugins/). Also add [`build_runner`](https://pub.dev/packages/build_runner) and [`json_serializable`](https://pub.dev/packages/json_serializable) to the `dev_dependencies`:

```yaml
dependencies:
  json_annotation: ^latest
  carp_serializable: ^latest

dev_dependencies:
  build_runner: any   # For building json serialization
  json_serializable: any
```

## Usage

To support polymorphic serialization, each class should:

* extend from `Serializable`
* annotate the class with `@JsonSerializable`
* add the three json methods
  * `Function get fromJsonFunction => ...`
  * `factory ...fromJson(...)`
  * `Map<String, dynamic> toJson() => ...`
* register the classes in the `FromJsonFactory()` registry.
* build json function using the `flutter pub run build_runner build --delete-conflicting-outputs` command

Below is a simple example of two classes `A` and `B` where B extends A.

```dart
@JsonSerializable()
class A extends Serializable {
  int index;

  A([this.index = 0]) : super();

  @override
  Function get fromJsonFunction => _$AFromJson;

  factory A.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<A>(json);

  @override
  Map<String, dynamic> toJson() => _$AToJson(this);
}

@JsonSerializable(includeIfNull: false)
class B extends A {
  String? str;

  B([super.index, this.str]) : super();

  @override
  Function get fromJsonFunction => _$BFromJson;

  factory B.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<B>(json);
  
  @override
  Map<String, dynamic> toJson() => _$BToJson(this);
}
```

Note that the naming of the `fromJson()` and `toJson()` functions follows the [json_serializable](https://pub.dev/packages/json_serializable) package. For example the `fromJson` function for class `A` is called `_$AFromJson`.

The `fromJsonFunction` must be registered on app startup (before use of de-serialization) in the `FromJsonFactory` singleton, like this:

```dart
FromJsonFactory().register(A());
```

For this purpose it is helpful to have an empty constructor, but any constructor will work, since only getting the `fromJsonFunction` function is used during registration.

Polymorphic serialization is handled by setting the `__type` property in the `Serializable` class. Per default, an object's `runtimeType` is used as the `__type` for an object. Hence, the JSON of objects of type `A` and `B` would look like this:

 ```json
  {
   "__type": "A",
   "index": 1
  }
  {
   "__type": "B",
   "index": 2
   "str": "abc"
  }
 ```

However, if you want to specify your own class type (e.g., if you get json serialized from another language which uses a package structure like Java, C# or Kotlin), you can specify the json type in the `jsonType` property of the class.

For example, if the class `B` above should use a different `__type` annotation, using the following:

```dart
 @JsonSerializable()
 class B extends A {

   <<as above>>

   String get jsonType => 'dk.carp.$runtimeType';
 }
 ````

 In which case the JSON would look like:

 ```json
  {
   "__type": "dk.carp.B",
   "index": 2
   "str": "abc"
  }
```

You can also create nested classes, like this class `C`:

```dart
@JsonSerializable(explicitToJson: true)
class C extends A {
  B b;

  C(super.index, this.b) : super();

  @override
  Function get fromJsonFunction => _$CFromJson;
  factory C.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<C>(json);
  @override
  Map<String, dynamic> toJson() => _$CToJson(this);
}
````

The following statement;

```dart
B b = B(2, 'abc');
C c = C(3, b);
```

will generate json like this:

```json
{
 "__type": "C",
 "index": 3,
 "b": {
  "__type": "dk.carp.B",
  "index": 2,
  "str": "abc"
 }
}
```

> Note that in order to support "deep" or nested toJson serialization, you need to annotate the class with `@JsonSerializable(explicitToJson: true)`.

Once the serialization code is written as above, run the

```shell
flutter pub run build_runner build --delete-conflicting-outputs
```

command as usual to generate the `toJson()` and `fromJson()` methods.

## Exception Handling

When trying to deserialize an object from JSON, this package looks up the `fromJson` function in the `FromJsonFactory`. In case the type is not found - either because it is unknown or has not been registered - an `SerializationException` will be thrown.

In order to avoid an exception, you can specify a default object to use in this exception case by specifying a `notAvailable` parameter to the `fromJson` method, like this:

```dart
class B extends A {

   <<as above>>

  factory B.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<B>(json, notAvailable: B(-1));
}
```

In case a deserialization method for B is not found, then the object `B(-1)` is returned. This will not be the "correct" object, but at least the serialization is not stopped. This is useful in deserialization of large, nested JSON.

## Universal Unique IDs

Often in serialization, there is a need to generate or use unique IDs. Hence, the package re-exports the [uuid](https://pub.dev/packages/uuid) package, so a Universal Unique ID (UUID) can be generated:

```dart
// Generate a v1 (time-based) id
var uuid = Uuid().v1();
```

## Features and bugs

Please read about existing issues and file new feature requests and bug reports at the [issue tracker][tracker].

[tracker]: https://github.com/cph-cachet/carp.sensing-flutter/issues

## License

This software is copyright (c) the [Technical University of Denmark (DTU)](https://www.dtu.dk) and is part of the [Copenhagen Research Platform](https://carp.cachet.dk/).
This software is available 'as-is' under a [MIT license](LICENSE).
