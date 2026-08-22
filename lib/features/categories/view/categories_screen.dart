import 'dart:async';

import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/widgets/amount_text.dart';
import 'package:finance_app/core/widgets/empty_state.dart';
import 'package:finance_app/core/widgets/item_avatar.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/categories/view/category_transactions_screen.dart';
import 'package:finance_app/features/transactions_list/period_grouping.dart';
import 'package:finance_app/features/transactions_list/widgets/period_filter_chips.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// The categories hub: a period-aware breakdown of spending and income by
/// category, plus the categories themselves. Add via the app bar; tap a
/// category to see all its transactions.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  StreamSubscription<List<TransactionDetails>>? _txSub;
  StreamSubscription<List<Category>>? _catSub;
  StreamSubscription<List<dynamic>>? _currencySub;

  List<TransactionDetails> _txns = const [];
  List<Category> _categories = const [];
  String? _symbol;

  PeriodPreset? _preset;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _txSub = getIt<TransactionRepository>().watchAllWithDetails().listen((all) {
      if (mounted) setState(() => _txns = all);
    });
    _catSub = getIt<CategoryRepository>().watchAll().listen((cats) {
      if (mounted) setState(() => _categories = cats);
    });
    _currencySub = getIt<CurrencyRepository>().watchAll().listen((currencies) {
      for (final c in currencies) {
        if (c.isBaseCurrency && mounted) {
          setState(() => _symbol = c.currencySymbol);
          return;
        }
      }
    });
  }

  @override
  void dispose() {
    _txSub?.cancel();
    _catSub?.cancel();
    _currencySub?.cancel();
    super.dispose();
  }

  List<TransactionDetails> get _filtered {
    if (_preset == null) return _txns;
    final range = computeRange(_preset!, customRange: _customRange);
    return filterByRange(_txns, range.start, range.end);
  }

  /// Per-category totals over the selected period, one list per kind, each
  /// ranked by amount (most first).
  ({List<_CatStat> expense, List<_CatStat> income}) get _stats {
    final totals = <int, double>{};
    final counts = <int, int>{};
    for (final t in _filtered) {
      final id = t.categoryId;
      if (id == null) continue;
      totals[id] = (totals[id] ?? 0) + t.amountInBase;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    final expense = <_CatStat>[];
    final income = <_CatStat>[];
    for (final c in _categories) {
      final stat = _CatStat(c, totals[c.categoryId] ?? 0, counts[c.categoryId] ?? 0);
      (c.isIncome ? income : expense).add(stat);
    }
    int byTotal(_CatStat a, _CatStat b) => b.total.compareTo(a.total);
    expense.sort(byTotal);
    income.sort(byTotal);
    return (expense: expense, income: income);
  }

  Future<void> _pickCustomRange() async {
    final today = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year + 1),
      initialDateRange:
          _customRange ??
          DateTimeRange(
            start: today.subtract(const Duration(days: 30)),
            end: today,
          ),
    );
    if (picked != null && mounted) {
      setState(() {
        _preset = PeriodPreset.custom;
        _customRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final stats = _stats;
    final totalExpense = stats.expense.fold<double>(0, (s, e) => s + e.total);
    final totalIncome = stats.income.fold<double>(0, (s, e) => s + e.total);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.categories),
        actions: [
          IconButton(
            tooltip: l.add,
            onPressed: () => Navigator.of(context).pushNamed('/add-category'),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: _categories.isEmpty
          ? Center(
              child: AppEmptyState(
                icon: Icons.category_outlined,
                title: l.noCategoriesYet,
                subtitle: l.addOne,
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                PeriodFilterChips(
                  selected: _preset,
                  onSelect: (p) => setState(() => _preset = p),
                  onPickCustom: _pickCustomRange,
                ),
                const SizedBox(height: 12),
                _summary(l, totalIncome, totalExpense),
                const SizedBox(height: 18),
                if (stats.expense.isNotEmpty)
                  _section(l.expenses, stats.expense, totalExpense),
                if (stats.income.isNotEmpty)
                  _section(l.income, stats.income, totalIncome),
              ],
            ),
    );
  }

  Widget _summary(AppLocalizations l, double income, double expense) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: kCardShadow,
      ),
      child: Row(
        children: [
          Expanded(child: _summaryCell(l.income, income, AppColors.positive)),
          Container(
            width: 1,
            height: 34,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
          ),
          Expanded(child: _summaryCell(l.expense, expense, AppColors.negative)),
        ],
      ),
    );
  }

  Widget _summaryCell(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: kTextStyle.copyWith(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        AmountText(
          value,
          symbol: _symbol,
          adaptive: true,
          style: kTextStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _section(String title, List<_CatStat> stats, double total) {
    final max = stats.fold<double>(1, (m, s) => s.total > m ? s.total : m);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8, left: 2),
          child: Text(
            title,
            style: kTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        for (final s in stats) _catTile(s, max, total),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _catTile(_CatStat s, double sectionMax, double total) {
    final cs = Theme.of(context).colorScheme;
    final pct = total > 0 ? (s.total / total * 100) : 0;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: kCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  CategoryTransactionsScreen(category: s.category),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    ItemAvatar(
                      color: s.category.categoryColor,
                      icon: s.category.categoryIcon,
                      diameter: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.category.categoryName,
                            style: kTextStyle.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (s.count > 0)
                            Text(
                              '${s.count} · ${pct.round()}%',
                              style: kTextStyle.copyWith(
                                fontSize: 12.5,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    AmountText(
                      s.total,
                      symbol: _symbol,
                      style: kTextStyle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (s.total > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        Container(
                          height: 5,
                          color: cs.onSurface.withValues(alpha: 0.08),
                        ),
                        FractionallySizedBox(
                          widthFactor: (s.total / sectionMax).clamp(0.03, 1.0),
                          child: Container(
                            height: 5,
                            color: s.category.categoryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatStat {
  const _CatStat(this.category, this.total, this.count);
  final Category category;
  final double total;
  final int count;
}
