import 'dart:async';

import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/format.dart';
import 'package:finance_app/core/settings/settings_service.dart';
import 'package:finance_app/core/widgets/amount_text.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/transactions_list/period_grouping.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// A horizontally-scrollable strip of at-a-glance stat chips for the selected
/// period — kept in step with the summary tiles above it. Free, local.
class StatStrip extends StatefulWidget {
  const StatStrip({super.key, required this.range});

  /// The period window to summarise (same range the analytics tiles use), so
  /// the strip never disagrees with them.
  final DateTimeRange range;

  @override
  State<StatStrip> createState() => _StatStripState();
}

class _StatStripState extends State<StatStrip> {
  StreamSubscription<List<TransactionDetails>>? _sub;
  StreamSubscription<List<dynamic>>? _currencySub;
  String? _symbol;
  List<TransactionDetails> _txns = const [];
  List<_Stat> _stats = const [];

  final _settings = getIt<SettingsService>().settings;

  @override
  void initState() {
    super.initState();
    _watchBaseSymbol();
    _sub = getIt<TransactionRepository>().watchAllWithDetails().listen(
      _recompute,
    );
    // Recompute masked/unmasked labels when "hide amounts" flips.
    _settings.addListener(_onSettings);
  }

  void _onSettings() => _recompute(_txns);

  @override
  void didUpdateWidget(covariant StatStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The user switched period (Day/Week/Month/…) — resummarise the last
    // transactions over the new window.
    if (oldWidget.range != widget.range) _recompute(_txns);
  }

  // Reactive base-currency symbol. This strip bakes the symbol into its stat
  // labels, so a change must re-run _recompute over the last transactions
  // (Home stays alive in an IndexedStack — a one-shot read would go stale).
  void _watchBaseSymbol() {
    _currencySub = getIt<CurrencyRepository>().watchAll().listen((currencies) {
      for (final c in currencies) {
        if (c.isBaseCurrency) {
          if (mounted && c.currencySymbol != _symbol) {
            _symbol = c.currencySymbol;
            _recompute(_txns);
          }
          return;
        }
      }
    });
  }

  void _recompute(List<TransactionDetails> txns) {
    _txns = txns;
    final range = widget.range;
    final filtered = filterByRange(txns, range.start, range.end);

    double income = 0, expense = 0, biggest = 0;
    var count = 0;
    // Distinct calendar dates (year+month+day key, so days in different months
    // never collide the way a bare day-of-month would).
    final activeDays = <int>{};
    for (final t in filtered) {
      count++;
      activeDays.add(t.date.year * 10000 + t.date.month * 100 + t.date.day);
      if (t.isIncome) income += t.amountInBase;
      if (t.isExpense) {
        expense += t.amountInBase;
        if (t.amountInBase > biggest) biggest = t.amountInBase;
      }
    }
    final net = income - expense;
    final days = range.end.difference(range.start).inDays + 1;
    final avgPerDay = expense / (days < 1 ? 1 : days);

    // "Saved" only makes sense when the period is in the black. A net loss as a
    // percentage of a tiny income explodes into nonsense (e.g. -21028%), so when
    // net is negative we show the shortfall AS MONEY under an "in the red" label
    // instead; a non-negative net shows the savings rate (0% when no income).
    final _Stat savedOrRed;
    if (net < 0) {
      savedOrRed = _Stat(
        Icons.trending_down_rounded,
        AmountText.maskString(compactMoney(net.abs(), _symbol)),
        _StatKind.inRed,
        AppColors.negative,
      );
    } else {
      final savingsRate = income > 0 ? (net / income * 100).round() : 0;
      savedOrRed = _Stat(
        Icons.savings_rounded,
        '$savingsRate%',
        _StatKind.saved,
        AppColors.positive,
      );
    }

    if (!mounted) return;
    setState(() {
      _stats = [
        savedOrRed,
        _Stat(
          Icons.today_rounded,
          AmountText.maskString(compactMoney(avgPerDay, _symbol)),
          _StatKind.perDay,
          AppColors.primary,
        ),
        _Stat(
          Icons.local_fire_department_rounded,
          AmountText.maskString(compactMoney(biggest, _symbol)),
          _StatKind.biggest,
          const Color(0xFFF5A623),
        ),
        _Stat(
          Icons.receipt_long_rounded,
          '$count',
          _StatKind.thisMonth,
          const Color(0xFF7C3AED),
        ),
        _Stat(
          Icons.event_available_rounded,
          '${activeDays.length}',
          _StatKind.activeDays,
          AppColors.positive,
        ),
      ];
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _currencySub?.cancel();
    _settings.removeListener(_onSettings);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_stats.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: _stats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _Chip(stat: _stats[i]),
      ),
    );
  }
}

/// Which stat a chip shows — the label is resolved at build time so it follows
/// the app language (the values are computed off-context in the stream).
enum _StatKind { saved, inRed, perDay, biggest, thisMonth, activeDays }

class _Stat {
  const _Stat(this.icon, this.value, this.kind, this.color);
  final IconData icon;
  final String value;
  final _StatKind kind;
  final Color color;
}

class _Chip extends StatelessWidget {
  const _Chip({required this.stat});
  final _Stat stat;

  String _label(BuildContext context, _StatKind kind) {
    final l = AppLocalizations.of(context);
    return switch (kind) {
      _StatKind.saved => l.statSaved,
      _StatKind.inRed => l.statInRed,
      _StatKind.perDay => l.statPerDay,
      _StatKind.biggest => l.statBiggest,
      _StatKind.thisMonth => l.statThisMonth,
      _StatKind.activeDays => l.statActiveDays,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(kRadiusMd),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(stat.icon, size: 18, color: stat.color),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              stat.value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            _label(context, stat.kind),
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
