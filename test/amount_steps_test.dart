import 'package:finance_app/features/widget_config/data/amount_steps.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('autoAmountSteps', () {
    test('reproduces the dollar-friendly 100/500/1000 around ~100', () {
      expect(autoAmountSteps(100), [100, 500, 1000]);
      expect(autoAmountSteps(120), [100, 500, 1000]); // snaps down to 100
      expect(autoAmountSteps(87), [100, 500, 1000]); // snaps up to 100
    });

    test('scales up for high-denomination currencies (tenge)', () {
      // A ~50 000 typical bill → 50 000 / 250 000 / 500 000.
      expect(autoAmountSteps(50000), [50000, 250000, 500000]);
      // A ~500 coffee in tenge → 500 / 2500 / 5000.
      expect(autoAmountSteps(500), [500, 2500, 5000]);
    });

    test('scales down for small typical spends', () {
      expect(autoAmountSteps(5), [5, 25, 50]);
      expect(autoAmountSteps(45), [50, 250, 500]);
    });

    test('every step follows the u / 5u / 10u ratio', () {
      for (final m in [3.0, 12.0, 230.0, 7400.0, 999999.0]) {
        final s = autoAmountSteps(m);
        expect(s.length, 3);
        expect(s[1], s[0] * 5);
        expect(s[2], s[0] * 10);
      }
    });

    test('falls back to a sane default without a signal', () {
      expect(autoAmountSteps(0), [100, 500, 1000]);
      expect(autoAmountSteps(double.nan), [100, 500, 1000]);
      expect(autoAmountSteps(double.infinity), [100, 500, 1000]);
    });

    test('treats a negative magnitude as its absolute value', () {
      expect(autoAmountSteps(-50000), [50000, 250000, 500000]);
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
