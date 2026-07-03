import 'package:finance_app/database/database_helper.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

enum PeriodPreset { day, week, month, year, custom }

Map<PeriodPreset, List<String>> periodsNames = {
  PeriodPreset.day: ['Today', 'EEE, d MMM'],
  PeriodPreset.week: ['Week', 'd MMM'],
  PeriodPreset.month: ['Month', 'd MMM'],
  PeriodPreset.year: ['Year', 'd MMM, yyyy', 'yy'],
  PeriodPreset.custom: ['Custom', 'd.MM.yy'],
};

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  final db = DatabaseHelper.instance;
  List<Map<String, dynamic>> transactions = [];

  // фильтр / период
  PeriodPreset _preset = PeriodPreset.month;
  DateTimeRange? _customRange;

  late Future<void> fetchTransactions;

  int screenIndex = 0;

  @override
  void initState() {
    super.initState();
    // db.deleteTable('currencies');
    // db.deleteDatabaseFile();

    fetchTransactions = _fetchTransactionsFuture();
  }

  // Future<void> _seedData() async {
  //   final currencies = await db.getAll("currencies");
  //   if (currencies.isEmpty) {
  //     final firstCurrency = currenciesList.first;

  //     for (final currency in currenciesList) {
  //       if (firstCurrency == currency && false) {
  //         await db.insert("currencies", {
  //           ...currency,
  //           "rate_to_base": 1.0,
  //           "is_base": 1,
  //         });
  //       } else {
  //         await db.insert("currencies", {
  //           ...currency,
  //           "is_base": 0,
  //         });
  //       }
  //     }
  //   }
  //   final accounts = await db.getAll("accounts");
  //   if (accounts.isEmpty) {
  //     await db.insert("accounts", {
  //       "name": "Cash",
  //       "currency_id": 1,
  //       "icon_code_point": Icons.account_balance_wallet.codePoint,
  //     });
  //     await db.insert("accounts", {
  //       "name": "Bank",
  //       "currency_id": 1,
  //       "icon_code_point": Icons.account_balance_rounded.codePoint,
  //     });
  //   }
  //   final categories = await db.getAll("categories");
  //   if (categories.isEmpty) {
  //     await db.insert("categories", {
  //       "name": "Food",
  //       "color": 4282682111, // integer
  //       "icon_color": 4278190080,
  //       "icon_code_point": Icons.fastfood_rounded.codePoint,
  //     });
  //     await db.insert("categories", {
  //       "name": "Salary",
  //       "color": 4294953540,
  //       "icon_color": 4278190080,
  //       "icon_code_point": Icons.attach_money_rounded.codePoint,
  //     });
  //   }
  //   await _refreshTransactions();
  // }

  Future<void> _fetchTransactionsFuture() async {
    final data = await db.getTransactionsWithDetails();
    setState(() {
      transactions = data;
    });
  }

  // -------------------- date helpers --------------------
  DateTime parseDate(dynamic raw) {
    try {
      return DateTime.parse(raw).toLocal();
    } catch (e) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  DateTime startOfWeek(DateTime d) {
    return d.toLocal().subtract(const Duration(days: 6));
  }

  DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month - 1, d.day);

  //have to delete this
  DateTime startOfNextMonth(DateTime d) => (d.month == 12)
      ? DateTime(d.year + 1, 1, 1)
      : DateTime(d.year, d.month + 1, 1);

  String fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';

  String formatAuto(DateTimeRange range, PeriodPreset period) {
    final start = DateFormat(
      periodsNames[period]![1],
      'en_US',
    ).format(range.start);
    final end = DateFormat(
      periodsNames[period]!.last,
      'en_US',
    ).format(range.end);

    return '${periodsNames[_preset]![0]}: ${period != PeriodPreset.day ? '$start - ' : ''}$end';
  }

  DateTimeRange computeRange(PeriodPreset preset) {
    final now = DateTime.now();
    final todayStart = startOfDay(now);
    switch (preset) {
      case PeriodPreset.day:
        return DateTimeRange(start: todayStart, end: endOfDay(now));
      case PeriodPreset.week:
        final weekStart = startOfWeek(now);
        return DateTimeRange(
          start: weekStart,

          end: endOfDay(now),
        );
      case PeriodPreset.month:
        return DateTimeRange(
          start: startOfMonth(now),
          end: endOfDay(now),
        );
      case PeriodPreset.year:
        final yStart = startOfDay(now).copyWith(year: now.year - 1);
        final yEnd = endOfDay(now);
        return DateTimeRange(start: yStart, end: yEnd);
      case PeriodPreset.custom:
        if (_customRange != null) return _customRange!;
        return DateTimeRange(start: todayStart, end: endOfDay(todayStart));
    }
  }

  // фильтрация по диапазону (в локальном времени)
  List<Map<String, dynamic>> filterByRange(
    List<Map<String, dynamic>> all,
    DateTime start,
    DateTime end,
  ) {
    return all.where((t) {
      final dt = parseDate(t['date']);
      return !dt.isBefore(start) && !dt.isAfter(end);
    }).toList();
  }

  // группировка по правилам
  List<Map<String, dynamic>> groupTransactions(
    List<Map<String, dynamic>> filteredTransactions,
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
      } // group by day
      else if (totalDays <= 30) {
        strategy = PeriodPreset.month;
      } // group by week
      else if (totalDays <= 365) {
        strategy = PeriodPreset.year;
      } // group by month
      else {
        strategy = PeriodPreset.year;
      }
    }

    ///
    ///
    /// have to add a grouping multiple years (one year and one day begin) by each year
    ///
    ///

    ///
    /// have to edit 'title' property to set here individual date
    ///

    filteredTransactions.sort(
      (a, b) => parseDate(b['date']).compareTo(parseDate(a['date'])),
    );

    final List<Map<String, dynamic>> groups = [];

    if (strategy == PeriodPreset.day) {
      for (final t in filteredTransactions) {
        final dt = parseDate(t['date']);
        groups.add({
          'start': dt,
          'end': dt,
          'items': [t],
        });
      }
      return groups;
    }

    if (strategy == PeriodPreset.week) {
      final Map<DateTime, List<Map<String, dynamic>>> map = {};
      for (final t in filteredTransactions) {
        final dt = parseDate(t['date']);
        final key = startOfDay(dt);
        map.putIfAbsent(key, () => []).add(t);
      }
      final keys = map.keys.toList();
      for (final k in keys) {
        groups.add({
          'title': fmt(k),
          'start': k,
          'end': endOfDay(k),
          'items': map[k]!,
        });
      }
      return groups;
    }

    if (strategy == PeriodPreset.month) {
      DateTime cursor = start;
      while (!cursor.isAfter(end)) {
        final weekStart = cursor;
        final weekEnd = endOfDay(cursor.add(const Duration(days: 6)));
        final items = filteredTransactions.where((t) {
          final dt = parseDate(t['date']);
          return !dt.isBefore(weekStart) && !dt.isAfter(weekEnd);
        }).toList();
        if (items.isNotEmpty) {
          final displayEnd = weekEnd.isBefore(end) ? weekEnd : end;
          groups.add({
            'title': '${fmt(weekStart)} — ${fmt(displayEnd)}',
            'start': weekStart,
            'end': displayEnd,
            'items': items,
          });
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
        final items = filteredTransactions.where((t) {
          final dt = parseDate(t['date']);
          return !dt.isBefore(monthStart) && !dt.isAfter(monthEnd);
        }).toList();
        if (items.isNotEmpty) {
          groups.add({
            'title': '${monthStart.month}/${monthStart.year}',
            'start': monthStart,
            'end': monthEnd,
            'items': items,
          });
        }
        cursor = nextMonth;
      }
      return groups.reversed.toList();
    }

    return groups;
  }

  // chips UI
  Widget _buildPresetChips() {
    final labels = {
      PeriodPreset.day: 'Day',
      PeriodPreset.week: 'Week',
      PeriodPreset.month: 'Month',
      PeriodPreset.year: 'Year',
      PeriodPreset.custom: 'Other',
    };
    return Wrap(
      spacing: 8,
      children: PeriodPreset.values.map((p) {
        final selected = p == _preset;
        return ChoiceChip(
          label: Text(labels[p]!, style: kTextStyle.copyWith()),
          selected: selected,
          onSelected: (v) async {
            if (!v) return;
            if (p == PeriodPreset.custom) {
              final today = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(today.year - 5),
                lastDate: DateTime(today.year + 1),
                initialDateRange:
                    _customRange ??
                    DateTimeRange(
                      start: today.subtract(const Duration(days: 7)),
                      end: today,
                    ),
              );
              if (picked != null) {
                setState(() {
                  _customRange = DateTimeRange(
                    start: startOfDay(picked.start),
                    end: endOfDay(picked.end),
                  );
                  _preset = PeriodPreset.custom;
                });
              }
            } else {
              setState(() {
                _preset = p;
              });
            }
          },
        );
      }).toList(),
    );
  }

  // color/icon helpers (DB stores integers in categories.color and icon_code_point)
  Color _colorFromDb(dynamic raw) {
    if (raw == null) return Colors.grey;
    if (raw is int) return Color(raw);
    if (raw is String) {
      final v = int.tryParse(raw);
      if (v != null) return Color(v);
    }
    return Colors.grey;
  }

  Color _iconColorFromDb(dynamic raw) {
    if (raw == null) return Colors.white;
    if (raw is int) return Color(raw);
    if (raw is String) {
      final v = int.tryParse(raw);
      if (v != null) return Color(v);
    }
    return Colors.white;
  }

  IconData _iconDataFromDb(dynamic raw) {
    if (raw == null) return Icons.help_outline;
    if (raw is int) return IconData(raw, fontFamily: 'MaterialIcons');
    if (raw is String) {
      final v = int.tryParse(raw);
      if (v != null) return IconData(v, fontFamily: 'MaterialIcons');
    }
    return Icons.help_outline;
  }

  Future<void> openAddScreen() async {
    if (!mounted) return;

    await Navigator.of(context).pushNamed('/add-transaction');

    setState(() {
      fetchTransactions = _fetchTransactionsFuture();
    });
  }

  Map<String, double> getReport(
    List<Map<String, dynamic>> filteredTransactions,
  ) {
    Map<String, double> totalReport = {};

    for (final transaction in filteredTransactions) {
      if (transaction['type'] == 'expense') {
        totalReport.update(
          'expense',
          (existing) => existing + transaction['amount'],
          ifAbsent: () => transaction['amount'],
        );
      }
      if (transaction['type'] == 'income') {
        totalReport.update(
          'income',
          (existing) => existing + transaction['amount'],
          ifAbsent: () => transaction['amount'],
        );
      }
    }
    return totalReport;
  }

  void onScreenChange(int index) {
    setState(() {
      screenIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // db.deleteAll();

    final range = computeRange(_preset);
    final filtered = filterByRange(transactions, range.start, range.end);
    final groups = groupTransactions(filtered, range.start, range.end, _preset);
    final report = getReport(filtered);

    return FutureBuilder(
      future: fetchTransactions,
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (asyncSnapshot.hasError) {
          debugPrint(asyncSnapshot.error.toString());
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                'Something went wrong',
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('List', style: kTextStyle.copyWith()),
            backgroundColor: const Color(0xFFF7F7FA),
            centerTitle: true,
            scrolledUnderElevation: 0,
            actions: [
              IconButton(
                onPressed: openAddScreen,
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFF7F7FA),

          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPresetChips(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            formatAuto(range, _preset),
                            style: kTextStyle.copyWith(),
                          ),

                          const Spacer(),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '+${(report['income'] ?? 0).toStringAsFixed(2)}',
                                style: kTextStyle.copyWith(
                                  color: Colors.green[400],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '-${(report['expense'] ?? 0).toStringAsFixed(2)}',
                                style: kTextStyle.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (groups.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Нет транзакций в выбранном диапазоне',
                      style: kTextStyle.copyWith(),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, gi) {
                      final group = groups[gi];
                      final items =
                          group['items'] as List<Map<String, dynamic>>;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          color: Colors.white,
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (group['title'] != null) ...[
                                  Text(
                                    group['title'] as String,
                                    style: kTextStyle.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                ...items.map((t) {
                                  final dt = parseDate(t['date']);
                                  final color = _colorFromDb(
                                    t['category_color'],
                                  );
                                  final iconColor = _iconColorFromDb(
                                    t['category_icon_color'],
                                  );
                                  final iconData = _iconDataFromDb(
                                    t['category_icon_code'],
                                  );
                                  return ListTile(
                                    leading: Container(
                                      width: 45,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: color,
                                      ),
                                      child: Icon(
                                        iconData,
                                        // color: Colors.white,
                                        color: iconColor,
                                        size: 25,
                                      ),
                                    ),
                                    title: t['type'] == 'expense'
                                        ? Text(
                                            '- ${t['amount']} ${t['currency_code']}',
                                            style: kTextStyle.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.error,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          )
                                        : t['type'] == 'income'
                                        ? Text(
                                            '+ ${t['amount']} ${t['currency_code']}',
                                            style: kTextStyle.copyWith(
                                              color: Colors.green[500],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          )
                                        : Text(
                                            '${t['amount']} ${t['currency_code']}',
                                            style: kTextStyle.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),

                                    subtitle: RichText(
                                      text: TextSpan(
                                        style: DefaultTextStyle.of(
                                          context,
                                        ).style,
                                        children: [
                                          TextSpan(text: t['account_name']),
                                          WidgetSpan(
                                            child: Icon(
                                              t['type'] == 'income'
                                                  ? Icons.arrow_left_rounded
                                                  : Icons.arrow_right_rounded,
                                              size: 20,
                                              color: Colors.grey,
                                            ),
                                            alignment:
                                                PlaceholderAlignment.middle,
                                          ),
                                          TextSpan(
                                            text: t['type'] == 'transfer'
                                                ? t['account_destination_name']
                                                : t['category_name'],
                                          ),
                                        ],
                                      ),
                                    ),

                                    trailing: Text(
                                      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                                      style: kTextStyle.copyWith(),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: groups.length,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
