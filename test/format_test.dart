import 'package:finance_app/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('abbreviateAmount', () {
    setUp(() => setCompactSuffixes(thousands: 'K', millions: 'M'));

    test('keeps three informative decimals for millions', () {
      expect(abbreviateAmount(2291724.70), '2.292M');
      expect(abbreviateAmount(1863662.80), '1.864M');
    });

    test('keeps thousands short (one decimal), dropping trailing zeros', () {
      expect(abbreviateAmount(253701.30), '253.7K');
      expect(abbreviateAmount(869500), '869.5K');
      expect(abbreviateAmount(50000), '50K');
    });

    test('leaves sub-thousand values in full', () {
      expect(abbreviateAmount(999), '999.00');
      expect(abbreviateAmount(42.5), '42.50');
    });

    test('abbreviates from 1000 up', () {
      expect(abbreviateAmount(12345), '12.3K');
    });

    test('honours localized suffixes', () {
      setCompactSuffixes(thousands: 'К', millions: 'М');
      expect(abbreviateAmount(2291724.70), '2.292М');
      expect(abbreviateAmount(253701.30), '253.7К');
    });
  });
}
