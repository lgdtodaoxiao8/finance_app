import 'dart:math' as math;

/// Currency-adaptive increment steps for the small widget's amount builder.
///
/// The builder's "+" buttons must make sense at any currency scale: `100/500/
/// 1000` reads well for dollars but is useless for tenge (where the same real
/// value is ~`50 000/250 000/500 000`). Rather than hard-code amounts, we
/// derive them from the user's own spending magnitude — so the ladder scales
/// automatically, and the widget just renders whatever numbers it's handed.

/// The three "+" steps for a representative spend [magnitude] (base currency).
///
/// Follows the `u / 5u / 10u` pattern (e.g. `100 / 500 / 1000`) — the same shape
/// the user already liked for dollars — where `u` is [magnitude] snapped to a
/// round `1/2/5 × 10^k`. So a typical single tap logs roughly one usual spend,
/// and off-grid amounts fall back to the exact-amount escape.
///
/// Falls back to `[100, 500, 1000]` when there's no magnitude signal yet.
List<double> autoAmountSteps(double magnitude) {
  final m = magnitude.abs();
  if (m <= 0 || m.isNaN || m.isInfinite) return const [100, 500, 1000];
  final unit = _niceUnit(m);
  return [unit, unit * 5, unit * 10];
}

/// Snaps [m] to the nearest human-round `1/2/5 × 10^k`.
double _niceUnit(double m) {
  final k = (math.log(m) / math.ln10).floor();
  final pow10 = math.pow(10, k).toDouble();
  final f = m / pow10; // normalised into [1, 10)
  final double nice;
  if (f < 1.5) {
    nice = 1;
  } else if (f < 3.5) {
    nice = 2;
  } else if (f < 7.5) {
    nice = 5;
  } else {
    nice = 10;
  }
  return nice * pow10;
}

/// Median of [values], or null when empty. Robust to outliers, so a single
/// large purchase doesn't skew a category's typical spend.
double? median(List<double> values) {
  if (values.isEmpty) return null;
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return (sorted[mid - 1] + sorted[mid]) / 2;
}

/// Rounds [value] to 2 significant figures — a clean "nice" number close to the
/// original (51 730 → 52 000, 5.17 → 5.2). Used to re-price configured widget
/// amounts after a base-currency change: convert by rate, then tidy up.
double niceRound(double value) {
  if (value == 0 || value.isNaN || value.isInfinite) return value;
  final a = value.abs();
  final k = (math.log(a) / math.ln10).floor();
  // Keep 2 significant digits: scale = 10^(k-1).
  final scale = math.pow(10, k - 1).toDouble();
  return (value / scale).round() * scale;
}

/// Re-prices a list of configured amounts after a base-currency change:
/// multiplies each by [multiplier] (old-base → new-base), snaps to a nice
/// number, drops non-positive/duplicate values and sorts ascending.
List<double> rescaleAmounts(List<double> amounts, double multiplier) {
  final out = <double>{};
  for (final a in amounts) {
    final v = niceRound(a * multiplier);
    if (v > 0) out.add(v);
  }
  return out.toList()..sort();
}
