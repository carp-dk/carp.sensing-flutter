import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:test/test.dart';

void main() {
  // Same values as sample_statistics' `quartile3 - quartile1`, which this replaced.
  test('inter-quartile range', () {
    expect(interQuartileRange([5]), 0);
    expect(interQuartileRange([1, 2]), 1);
    expect(interQuartileRange([3, 1, 2]), 1); // q1 1.5, q3 2.5
    expect(interQuartileRange([4, 1, 3, 2]), 2); // q1 1.5, q3 3.5
    expect(interQuartileRange([1, 2, 3, 4, 5]), 2); // q1 2, q3 4
    expect(interQuartileRange([7, 1, 3, 9, 5, 11]), 6); // q1 3, q3 9
  });
}
