import 'dart:convert';
import 'package:carp_serializable/carp_serializable.dart';
import 'package:test/test.dart';

// Using the examples for this test
import '../example/example.dart';

void main() {
  setUp(() {
    // register the de-serialization functions in the JSON Factory
    FromJsonFactory().register(A(0));
    FromJsonFactory().register(B(0));
    FromJsonFactory().register(C(0, B(0)));
  });

  test('A & B & C -> JSON', () async {
    A a = A(1);
    B b = B(2, 'abc');
    C c = C(3, b);

    print(toJsonString(a));
    print(toJsonString(b));
    print(toJsonString(c));
  });

  test('B -> JSON w. null value', () async {
    B b = B(2);
    print(toJsonString(b));
  });

  test('JSON -> A & B', () async {
    A a = A(1);
    B b = B(2, 'abc');

    A newA = A.fromJson(a.toJson());
    B newB = B.fromJson(b.toJson());

    expect(newA, isNot(a));
    expect(newB, isNot(b));
    expect(newA.index, a.index);
    expect(newB.str, b.str);

    print(toJsonString(newA.toJson()));
    print(toJsonString(newB.toJson()));
  });

  test('JSON -> A & B & C', () async {
    A a = A(1);
    B b = B(2, 'abc');
    C c = C(2, b);

    A newA = A.fromJson(a.toJson());
    B newB = B.fromJson(b.toJson());

    // Note that the following ONLY works if the C class is annotated with
    // "explicitToJson" set to true. This ensures "deep" conversion to JSON.
    C newC = C.fromJson(c.toJson());

    expect(newA, isNot(a));
    expect(newB, isNot(b));
    expect(newC, isNot(c));
    expect(newA.index, a.index);
    expect(newB.str, b.str);
    expect(newC.b, isNot(b));
    expect(newC.b.index, b.index);

    print(toJsonString(newA.toJson()));
    print(toJsonString(newB.toJson()));
    print(toJsonString(newC.toJson()));
  });

  test('JSON string -> A & B & C', () async {
    const a = '{"__type": "A", "index": 1 }';
    const b = '{"__type": "dk.carp.B", "index": 2, "str": "abc" }';
    const c =
        '{"__type": "C", "index": 3, "b": {"__type": "dk.carp.B", "index": 2, "str": "abc"} }';

    var newA = A.fromJson(json.decode(a) as Map<String, dynamic>);
    var newB = B.fromJson(json.decode(b) as Map<String, dynamic>);
    var newC = C.fromJson(json.decode(c) as Map<String, dynamic>);

    expect(newA.index, 1);
    expect(newB.str, 'abc');
    expect(newC.b.index, 2);

    print(toJsonString(newA.toJson()));
    print(toJsonString(newB.toJson()));
    print(toJsonString(newC.toJson()));
  });

  test('JSON string -> missing type', () async {
    // in this case the B __type is wrong (should be "dk.carp.B" and not just "B")
    const c =
        '{"__type": "C", "index": 3, "b": {"__type": "B", "index": 2, "str": "abc"} }';

    var newC = C.fromJson(json.decode(c) as Map<String, dynamic>);

    // expect -1 since this is the "notAvailable" value (see below)
    expect(newC.b.index, -1);
    print(toJsonString(newC.toJson()));
  });

  test('JSON string -> missing type throws exception', () async {
    // in this case the A __type is wrong (should be "A" and not "AB")
    const a = '{"__type": "AB", "index": 1 }';

    // the fromJson method should throw an exception since A does not define a "notAvailable" value
    expect(() => A.fromJson(json.decode(a) as Map<String, dynamic>),
        throwsA(const TypeMatcher<SerializationException>()));
  });

  test('UUID - version 1.0', () async {
    List<String> list = [];
    for (var i = 0; i < 5; i++) {
      list.add((const Uuid().v1()));
      list.add((const Uuid().v1()));
    }
    list.forEach(print);

    // check that all UUIDs are unique
    var unique = list.toSet().toList();
    expect(unique.length, list.length);
  });

  // A generator seeded from a small value range silently repeats itself once
  // more ids are drawn than the range holds. Small batches look unique, so the
  // number generated here needs to stay well above any such range.
  test('UUID - a large batch of ids is unique', () async {
    final ids = List.generate(100000, (_) => const Uuid().v1());
    expect(ids.toSet(), hasLength(ids.length));
  });
}
