import 'package:finance_app/features/widget_config/data/amount_steps.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('autoAmountSteps', () {
    // Element-wise closeTo comparison — niceRound returns doubles that can carry
    // tiny float error (e.g. 1.5000000000000002).
    void expectSteps(List<double> actual, List<double> expected) {
      expect(actual.length, expected.length);
      for (var i = 0; i < expected.length; i++) {
        expect(actual[i], closeTo(expected[i], 1e-6));
      }
    }

    test('is 10% / 30% / 50% of the median for dollar-scale spends', () {
      expectSteps(autoAmountSteps(100), [10, 30, 50]);
      expectSteps(autoAmountSteps(200), [20, 60, 100]);
      expectSteps(autoAmountSteps(1000), [100, 300, 500]);
    });

    test('scales up for high-denomination currencies (tenge)', () {
      // A ~50 000 typical bill → 5 000 / 15 000 / 25 000.
      expectSteps(autoAmountSteps(50000), [5000, 15000, 25000]);
      // A ~500 coffee in tenge → 50 / 150 / 250.
      expectSteps(autoAmountSteps(500), [50, 150, 250]);
    });

    test('scales down for small typical spends', () {
      expectSteps(autoAmountSteps(5), [0.5, 1.5, 2.5]);
    });

    test('snaps each step to the nearest nice round number', () {
      // 340 → 34 / 102 / 170; 102 tidies to a round 100 (2 significant figures).
      expectSteps(autoAmountSteps(340), [34, 100, 170]);
    });

    test('always returns three positive, strictly increasing steps', () {
      for (final m in [3.0, 12.0, 230.0, 7400.0, 999999.0]) {
        final s = autoAmountSteps(m);
        expect(s.length, 3);
        expect(s[0], greaterThan(0));
        expect(s[1], greaterThan(s[0]));
        expect(s[2], greaterThan(s[1]));
      }
    });

    test('falls back to a ~100 spend (10 / 30 / 50) without a signal', () {
      expectSteps(autoAmountSteps(0), [10, 30, 50]);
      expectSteps(autoAmountSteps(double.nan), [10, 30, 50]);
      expectSteps(autoAmountSteps(double.infinity), [10, 30, 50]);
    });

    test('treats a negative magnitude as its absolute value', () {
      expectSteps(autoAmountSteps(-50000), [5000, 15000, 25000]);
    });
  });

  group('median', () {
    test('null on empty', () => expect(median([]), isNull));
    test('odd length', () => expect(median([3, 1, 2]), 2));
    test('even length averages the middle pair', () {
      expect(median([1, 2, 3, 4]), 2.5);
    });
    test('robust to a single outlier', () {
      expect(median([10, 10, 12, 11, 5000]), 11);
    });
  });

  group('niceRound', () {
    test('rounds to 2 significant figures', () {
      expect(niceRound(51730), 52000);
      expect(niceRound(20690), 21000);
      expect(niceRound(258000), 260000);
      expect(niceRound(5.17), closeTo(5.2, 1e-9));
    });
    test('keeps already-clean values', () {
      expect(niceRound(50000), 50000);
      expect(niceRound(100), 100);
    });
    test('passes through 0 / non-finite', () {
      expect(niceRound(0), 0);
      expect(niceRound(double.nan).isNaN, true);
    });
  });

  group('rescaleAmounts', () {
    test('converts by rate then snaps to nice numbers', () {
      // 1 USD = 517.3 KZT → multiplier 517.3.
      expect(rescaleAmounts([40, 80], 517.3), [21000, 41000]);
      expect(rescaleAmounts([100, 500, 1000], 517.3), [52000, 260000, 520000]);
    });
    test('dedupes collisions and sorts', () {
      // 51.2 and 51.4 both round to 51 000 after ×1000 + 2-sig-fig rounding.
      expect(rescaleAmounts([51.4, 51.2], 1000), [51000]);
      // Distinct 2-sig-fig buckets stay separate, sorted ascending.
      expect(rescaleAmounts([52, 48], 1000), [48000, 52000]);
    });
    test('drops non-positive values', () {
      expect(rescaleAmounts([0, -5, 10], 100), [1000]);
    });
  });
}
