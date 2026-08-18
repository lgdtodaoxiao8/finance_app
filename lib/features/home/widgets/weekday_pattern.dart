import 'dart:async';

import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/settings/settings_service.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Full-width infographic: which weekday you spend most on (this month).
/// Seven simple bars with the peak day highlighted. Free, local.
class WeekdayPattern extends StatefulWidget {
  const WeekdayPattern({super.key});

  @override
  State<WeekdayPattern> createState() => _WeekdayPatternState();
}

class _WeekdayPatternState extends State<WeekdayPattern> {
  StreamSubscription<List<TransactionDetails>>? _sub;
  // Index 0 = Monday .. 6 = Sunday.
  List<double> _byDay = List.filled(7, 0);

  /// Short weekday initials, index 0 = Monday.
  List<String> _labels(AppLocalizations l) => [
    l.weekdayShortMon,
    l.weekdayShortTue,
    l.weekdayShortWed,
    l.weekdayShortThu,
    l.weekdayShortFri,
    l.weekdayShortSat,
    l.weekdayShortSun,
  ];

  /// Plural weekday phrases for the summary line ("on Mondays"), index 0 = Mon.
  List<String> _names(AppLocalizations l) => [
    l.weekdayMondays,
    l.weekdayTuesdays,
    l.weekdayWednesdays,
    l.weekdayThursdays,
    l.weekdayFridays,
    l.weekdaySaturdays,
    l.weekdaySundays,
  ];

  final _settings = getIt<SettingsService>().settings;

  @override
  void initState() {
    super.initState();
    _sub = getIt<TransactionRepository>().watchAllWithDetails().listen(
      _recompute,
    );
    // Reorder live when the "start of week" preference changes.
    _settings.addListener(_onSettings);
  }

  void _onSettings() {
    if (mounted) setState(() {});
  }

  /// Display order of day indices (0=Mon..6=Sun) honouring the week-start pref.
  List<int> get _order => _settings.value.weekStartsMonday
      ? const [0, 1, 2, 3, 4, 5, 6]
      : const [6, 0, 1, 2, 3, 4, 5];

  void _recompute(List<TransactionDetails> txns) {
    final now = DateTime.now();
    // Rolling month, matching the Home tiles (not a calendar month).
    final monthStart = DateTime(now.year, now.month - 1, now.day);
    final byDay = List.filled(7, 0.0);
    for (final t in txns) {
      if (!t.isExpense || t.date.isBefore(monthStart)) continue;
      byDay[t.date.weekday - 1] += t.amountInBase;
    }
    if (mounted) setState(() => _byDay = byDay);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _settings.removeListener(_onSettings);
    super.dispose();
  }

  int get _peak {
    var idx = 0;
    for (var i = 1; i < 7; i++) {
      if (_byDay[i] > _byDay[idx]) idx = i;
    }
    return idx;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labels = _labels(l);
    final max = _byDay.reduce((a, b) => a > b ? a : b);
    final total = _byDay.fold<double>(0, (a, b) => a + b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.whenYouSpend,
            style: kTextStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            total == 0
                ? l.noSpendingThisMonth
                : l.youSpendMostOn(_names(l)[_peak]),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 104,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final i in _order)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: max == 0 ? 4 : (8 + (_byDay[i] / max) * 66),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: i == _peak && total > 0
                                ? AppColors.primaryDark
                                : AppColors.primary.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: i == _peak
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: i == _peak
                                ? AppColors.primaryDark
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
