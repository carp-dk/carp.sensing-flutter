import 'package:carp_core/carp_core.dart';
import 'package:test/test.dart';

void main() {
  test('a failing or removed listener does not break the others', () {
    final study = Study('1234', 'phone');
    final called = <String>[];
    void removed() => called.add('removed');

    study.addListener(() => throw StateError('boom'));
    study.addListener(() => study.removeListener(removed));
    study.addListener(removed);
    study.addListener(() => called.add('last'));

    study.notifyListeners();

    expect(called, ['last']);
  });
}
