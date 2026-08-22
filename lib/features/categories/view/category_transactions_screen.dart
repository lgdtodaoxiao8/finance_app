import 'dart:async';

import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/widgets/amount_text.dart';
import 'package:finance_app/core/widgets/empty_state.dart';
import 'package:finance_app/core/widgets/item_avatar.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/add_transaction/view/add_transaction_screen.dart';
import 'package:finance_app/features/settings/widgets/manage_section.dart';
import 'package:finance_app/features/transactions_list/period_grouping.dart';
import 'package:finance_app/features/transactions_list/widgets/day_transactions_card.dart';
import 'package:finance_app/features/transactions_list/widgets/period_filter_chips.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Every transaction in one category: a period-aware total header + the history,
/// grouped by day. Add (pre-filled with this category), edit and delete live in
/// the app bar / FAB. Opened by tapping a category.
class CategoryTransactionsScreen extends StatefulWidget {
  const CategoryTransactionsScreen({super.key, required this.category});

  final Category category;

  @override
  State<CategoryTransactionsScreen> createState() =>
      _CategoryTransactionsScreenState();
}

class _CategoryTransactionsScreenState
    extends State<CategoryTransactionsScreen> {
  StreamSubscription<List<TransactionDetails>>? _txSub;
  StreamSubscription<List<Category>>? _catSub;
  StreamSubscription<List<dynamic>>? _currencySub;

  late Category _category = widget.category;
  List<TransactionDetails> _txns = const [];
  String? _symbol;

  PeriodPreset? _preset;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _txSub = getIt<TransactionRepository>().watchAllWithDetails().listen((all) {
      final id = _category.categoryId;
      final mine = all.where((t) => t.categoryId == id).toList();
      if (mounted) setState(() => _txns = mine);
    });
    _catSub = getIt<CategoryRepository>().watchAll().listen((cats) {
      final match = cats
          .where((c) => c.categoryId == _category.categoryId)
          .toList();
      if (match.isEmpty) {
        if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
        return;
      }
      if (mounted) setState(() => _category = match.first);
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

  List<MapEntry<DateTime, List<TransactionDetails>>> get _byDay =>
      groupByDay(_filtered);

  double get _total =>
      _filtered.fold(0, (s, t) => s + t.amountInBase);

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

  Future<void> _addTransaction() async {
    await Navigator.of(context).pushNamed(
      '/add-transaction',
      arguments: AddTxArgs(
        categoryId: _category.categoryId,
        type: _category.isIncome ? 'income' : 'expense',
      ),
    );
  }

  Future<void> _edit() async {
    await Navigator.of(
      context,
    ).pushNamed('/add-category', arguments: _category);
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final count = await getIt<CategoryRepository>().transactionCount(
      _category.categoryId,
    );
    if (!mounted) return;
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.cantDeleteCategoryInUse(count))),
      );
      return;
    }
    await confirmDelete(
      context,
      what: _category.categoryName,
      onConfirm: () =>
          getIt<CategoryRepository>().delete(_category.categoryId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_category.categoryName, style: kTextStyle.copyWith()),
        actions: [
          IconButton(
            tooltip: l.editCategoryTitle,
            onPressed: _edit,
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: l.delete,
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTransaction,
        icon: const Icon(Icons.add_rounded),
        label: Text(l.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          _header(l),
          const SizedBox(height: 16),
          PeriodFilterChips(
            selected: _preset,
            onSelect: (p) => setState(() => _preset = p),
            onPickCustom: _pickCustomRange,
          ),
          const SizedBox(height: 12),
          if (_filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: AppEmptyState(
                icon: Icons.receipt_long_rounded,
                title: l.noTransactions,
                subtitle: l.nothingInPeriod,
              ),
            )
          else
            for (final entry in _byDay)
              DayTransactionsCard(day: entry.key, items: entry.value),
        ],
      ),
    );
  }

  Widget _header(AppLocalizations l) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ItemAvatar(
                color: _category.categoryColor,
                icon: _category.categoryIcon,
                diameter: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _category.isIncome ? l.income : l.expense,
                  style: kTextStyle.copyWith(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AmountText(
            _total,
            symbol: _symbol,
            adaptive: true,
            style: kTextStyle.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: _category.isIncome ? AppColors.positive : cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.nOperations(_filtered.length),
            style: kTextStyle.copyWith(
              fontSize: 13,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
