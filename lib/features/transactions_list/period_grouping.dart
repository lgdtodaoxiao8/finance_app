import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Preset time windows for the list. Note these are rolling windows relative
/// to "now" (e.g. [week] = last 7 days), not calendar boundaries.
enum PeriodPreset { day, week, month, year, custom }

const Map<PeriodPreset, List<String>> periodsNames = {
  PeriodPreset.day: ['Today', 'EEE, d MMM'],
  PeriodPreset.week: ['Week', 'd MMM'],
  PeriodPreset.month: ['Month', 'd MMM'],
  PeriodPreset.year: ['Year', 'd MMM, yyyy', 'yy'],
  PeriodPreset.custom: ['Custom', 'd.MM.yy'],
};

/// Localised label for a period chip.
String periodChipLabel(AppLocalizations l, PeriodPreset p) => switch (p) {
  PeriodPreset.day => l.periodDay,
  PeriodPreset.week => l.periodWeek,
  PeriodPreset.month => l.periodMonth,
  PeriodPreset.year => l.periodYear,
  PeriodPreset.custom => l.periodOther,
};

/// Localised name of the period used when describing the active range.
String periodDisplayName(AppLocalizations l, PeriodPreset p) => switch (p) {
  PeriodPreset.day => l.periodToday,
  PeriodPreset.week => l.periodWeek,
  PeriodPreset.month => l.periodMonth,
  PeriodPreset.year => l.periodYear,
  PeriodPreset.custom => l.periodCustom,
};

/// A titled bucket of transactions produced by [groupTransactions].
class TransactionGroup {
  const TransactionGroup({
    required this.start,
    required this.end,
    required this.items,
    this.title,
  });

  final String? title;
  final DateTime start;
  final DateTime end;
  final List<TransactionDetails> items;
}

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime endOfDay(DateTime d) =>
    DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
DateTime startOfWeek(DateTime d) => d.subtract(const Duration(days: 6));
DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month - 1, d.day);
DateTime startOfNextMonth(DateTime d) => (d.month == 12)
    ? DateTime(d.year + 1, 1, 1)
    : DateTime(d.year, d.month + 1, 1);

String fmt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.'
    '${d.month.toString().padLeft(2, '0')}.${d.year}';

/// Describes the active range, e.g. "Month: 13 Jun - 13 Jul". [locale] drives
/// month/weekday names so dates read naturally in the user's language.
String formatAuto(
  DateTimeRange range,
  PeriodPreset preset,
  AppLocalizations l,
  String locale,
) {
  final start = DateFormat(
    periodsNames[preset]![1],
    locale,
  ).format(range.start);
  final end = DateFormat(periodsNames[preset]!.last, locale).format(range.end);

  return '${periodDisplayName(l, preset)}: '
      '${preset != PeriodPreset.day ? '$start - ' : ''}$end';
}

/// Groups [txns] by calendar day (newest day first, newest transaction first
/// within each day). Used by the per-account / per-category history screens.
List<MapEntry<DateTime, List<TransactionDetails>>> groupByDay(
  List<TransactionDetails> txns,
) {
  final map = <DateTime, List<TransactionDetails>>{};
  for (final t in txns) {
    final day = DateTime(t.date.year, t.date.month, t.date.day);
    (map[day] ??= <TransactionDetails>[]).add(t);
  }
  final entries = map.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
  for (final e in entries) {
    e.value.sort((a, b) => b.date.compareTo(a.date));
  }
  return entries;
}

DateTimeRange computeRange(PeriodPreset preset, {DateTimeRange? customRange}) {
  final now = DateTime.now();
  final todayStart = startOfDay(now);
  switch (preset) {
    case PeriodPreset.day:
      return DateTimeRange(start: todayStart, end: endOfDay(now));
    case PeriodPreset.week:
      return DateTimeRange(start: startOfWeek(now), end: endOfDay(now));
    case PeriodPreset.month:
      return DateTimeRange(start: startOfMonth(now), end: endOfDay(now));
    case PeriodPreset.year:
      return DateTimeRange(
        start: startOfDay(now).copyWith(year: now.year - 1),
        end: endOfDay(now),
      );
    case PeriodPreset.custom:
      return customRange ??
          DateTimeRange(start: todayStart, end: endOfDay(todayStart));
  }
}

List<TransactionDetails> filterByRange(
  List<TransactionDetails> all,
  DateTime start,
  DateTime end,
) {
  return all
      .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
      .toList();
}

/// Sum of income/expense within [filtered], converted to the base currency
/// so amounts in different currencies are comparable.
Map<String, double> report(List<TransactionDetails> filtered) {
  final result = <String, double>{};
  for (final t in filtered) {
    if (t.isExpense) {
      result.update(
        'expense',
        (v) => v + t.amountInBase,
        ifAbsent: () => t.amountInBase,
      );
    } else if (t.isIncome) {
      result.update(
        'income',
        (v) => v + t.amountInBase,
        ifAbsent: () => t.amountInBase,
      );
    }
  }
  return result;
}

/// Groups [filtered] into buckets according to [preset] (or an adaptive
/// strategy for custom ranges based on the total number of days).
List<TransactionGroup> groupTransactions(
  List<TransactionDetails> filtered,
  DateTime start,
  DateTime end,
  PeriodPreset preset,
) {
  final totalDays = end.difference(start).inDays + 1;
  PeriodPreset strategy = preset;
  if (preset == PeriodPreset.custom) {
    if (totalDays <= 1) {
      strategy = PeriodPreset.day;
    } else if (totalDays <= 7) {
      strategy = PeriodPreset.week;
    } else if (totalDays <= 30) {
      strategy = PeriodPreset.month;
    } else {
      strategy = PeriodPreset.year;
    }
  }

  final items = [...filtered]..sort((a, b) => b.date.compareTo(a.date));
  final groups = <TransactionGroup>[];

  if (strategy == PeriodPreset.day) {
    for (final t in items) {
      groups.add(TransactionGroup(start: t.date, end: t.date, items: [t]));
    }
    return groups;
  }

  if (strategy == PeriodPreset.week) {
    final map = <DateTime, List<TransactionDetails>>{};
    for (final t in items) {
      map.putIfAbsent(startOfDay(t.date), () => []).add(t);
    }
    for (final key in map.keys) {
      groups.add(
        TransactionGroup(
          title: fmt(key),
          start: key,
          end: endOfDay(key),
          items: map[key]!,
        ),
      );
    }
    return groups;
  }

  if (strategy == PeriodPreset.month) {
    DateTime cursor = start;
    while (!cursor.isAfter(end)) {
      final weekStart = cursor;
      final weekEnd = endOfDay(cursor.add(const Duration(days: 6)));
      final weekItems = items
          .where((t) => !t.date.isBefore(weekStart) && !t.date.isAfter(weekEnd))
          .toList();
      if (weekItems.isNotEmpty) {
        final displayEnd = weekEnd.isBefore(end) ? weekEnd : end;
        groups.add(
          TransactionGroup(
            title: '${fmt(weekStart)} — ${fmt(displayEnd)}',
            start: weekStart,
            end: displayEnd,
            items: weekItems,
          ),
        );
      }
      cursor = cursor.add(const Duration(days: 7));
    }
    return groups.reversed.toList();
  }

  if (strategy == PeriodPreset.year) {
    DateTime cursor = DateTime(start.year, start.month, 1);
    while (!cursor.isAfter(end)) {
      final monthStart = DateTime(cursor.year, cursor.month, 1);
      final nextMonth = startOfNextMonth(monthStart);
      final monthEnd = endOfDay(nextMonth.subtract(const Duration(days: 1)));
      final monthItems = items
          .where(
            (t) => !t.date.isBefore(monthStart) && !t.date.isAfter(monthEnd),
          )
          .toList();
      if (monthItems.isNotEmpty) {
        groups.add(
          TransactionGroup(
            title: '${monthStart.month}/${monthStart.year}',
            start: monthStart,
            end: monthEnd,
            items: monthItems,
          ),
        );
      }
      cursor = nextMonth;
    }
    return groups.reversed.toList();
  }

  return groups;
}
