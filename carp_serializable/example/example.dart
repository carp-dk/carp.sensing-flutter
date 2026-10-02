import 'package:carp_serializable/carp_serializable.dart';
import 'package:json_annotation/json_annotation.dart';

// Auto generate json code (.g files) with:
//   dart run build_runner build --delete-conflicting-outputs
part 'example.g.dart';

/// A base class with default behavior.
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

/// A class extending [A].
///
/// This class highlight three non-default behaviors:
///  * it holds a nullable string [str] which is not included in the JSON since the
///    [includeIfNull] is set to false
///  * has its own non-default [jsonType] type name
///  * provides a [notAvailable] parameter to the [fromJson] factory method which
///    specifies a default value for the class, if a fromJson method is not registered
///    in the [FromJsonFactory].
@JsonSerializable(includeIfNull: false)
class B extends A {
  String? str;

  B([super.index, this.str]) : super();

  @override
  String get jsonType => 'dk.carp.$runtimeType';

  @override
  Function get fromJsonFunction => _$BFromJson;
  factory B.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<B>(json, notAvailable: B(-1));
  @override
  Map<String, dynamic> toJson() => _$BToJson(this);
}

/// A class nesting another serializable class ([B]).
///
/// Note that [explicitToJson] must be set to true in order to make a 'deep'
/// serialization to JSON via the [toJson] method.
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

void main() {
  // remember to register the de-serialization functions in the JSON Factory
  FromJsonFactory().register(A());
  FromJsonFactory().register(B());
  FromJsonFactory().register(C(0, B()));

  // can also register B using another jsonType
  FromJsonFactory().register(B(1), type: 'B');

  A a = A(1);
  B b = B(2, 'abc');
  C c = C(3, b);

  print(toJsonString(a));
  print(toJsonString(b));
  print(toJsonString(c));

  A newA = A.fromJson(a.toJson());
  B newB = B.fromJson(b.toJson());

  // Note that the following ONLY works if the C class is annotated with
  // "explicitToJson" set to true. This ensures "deep" conversion to JSON.
  C newC = C.fromJson(c.toJson());

  print(toJsonString(newA.toJson()));
  print(toJsonString(newB.toJson()));
  print(toJsonString(newC.toJson()));
}
