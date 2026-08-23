import 'dart:async';

import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/format.dart';
import 'package:finance_app/core/widgets/amount_text.dart';
import 'package:finance_app/core/widgets/item_avatar.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/budget_repository.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/budget/budget_math.dart';
import 'package:finance_app/features/budget/data/budget.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// The Budget block of the Plans hub: an overall monthly cap plus per-category
/// limits, each with this month's spend, a progress bar and a status. Self-
/// contained (owns its own streams) so the hub just drops it in.
class BudgetSection extends StatefulWidget {
  const BudgetSection({super.key});

  @override
  State<BudgetSection> createState() => _BudgetSectionState();
}

class _BudgetSectionState extends State<BudgetSection> {
  StreamSubscription<List<Budget>>? _budgetSub;
  StreamSubscription<List<TransactionDetails>>? _txSub;
  StreamSubscription<List<Category>>? _catSub;
  StreamSubscription<List<dynamic>>? _currencySub;

  List<Budget> _budgets = const [];
  List<TransactionDetails> _txns = const [];
  List<Category> _categories = const [];
  String? _symbol;

  @override
  void initState() {
    super.initState();
    _budgetSub = getIt<BudgetRepository>().watchAll().listen(
      (b) => mounted ? setState(() => _budgets = b) : null,
    );
    _txSub = getIt<TransactionRepository>().watchAllWithDetails().listen(
      (t) => mounted ? setState(() => _txns = t) : null,
    );
    _catSub = getIt<CategoryRepository>().watchAll().listen(
      (c) => mounted ? setState(() => _categories = c) : null,
    );
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
    _budgetSub?.cancel();
    _txSub?.cancel();
    _catSub?.cancel();
    _currencySub?.cancel();
    super.dispose();
  }

  Category? _cat(int id) {
    for (final c in _categories) {
      if (c.categoryId == id) return c;
    }
    return null;
  }

  Future<void> _editOverall(double current) async {
    final l = AppLocalizations.of(context);
    final amount = await _amountDialog(l.overallBudget, current);
    if (amount == null) return;
    if (amount <= 0) {
      await getIt<BudgetRepository>().removeBudget();
    } else {
      await getIt<BudgetRepository>().setBudget(amount: amount);
    }
  }

  Future<void> _editCategory(int categoryId, double current) async {
    final cat = _cat(categoryId);
    final amount = await _amountDialog(cat?.categoryName ?? '', current);
    if (amount == null) return;
    if (amount <= 0) {
      await getIt<BudgetRepository>().removeBudget(categoryId: categoryId);
    } else {
      await getIt<BudgetRepository>().setBudget(
        categoryId: categoryId,
        amount: amount,
      );
    }
  }

  Future<void> _addCategoryBudget() async {
    final budgeted = _budgets.map((b) => b.categoryId).toSet();
    final options = _categories
        .where((c) => !c.isIncome && !budgeted.contains(c.categoryId))
        .toList();
    final picked = await showModalBottomSheet<Category>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _CategoryPickerSheet(categories: options),
    );
    if (picked == null || !mounted) return;
    await _editCategory(picked.categoryId, 0);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final spend = monthlySpend(_txns);
    Budget? overall;
    final catBudgets = <Budget>[];
    for (final b in _budgets) {
      if (b.isOverall) {
        overall = b;
      } else {
        catBudgets.add(b);
      }
    }
    catBudgets.sort((a, b) {
      final sa = spend.byCategory[a.categoryId] ?? 0;
      final sb = spend.byCategory[b.categoryId] ?? 0;
      return (sb / (b.amount <= 0 ? 1 : b.amount))
          .compareTo(sa / (a.amount <= 0 ? 1 : a.amount));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            l.budgetTitle,
            style: kTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        if (overall != null)
          _overallCard(l, overall.amount, spend.total)
        else
          _setOverallCard(l, spend.total),
        const SizedBox(height: 8),
        for (final b in catBudgets)
          _categoryRow(l, b, spend.byCategory[b.categoryId] ?? 0),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addCategoryBudget,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l.addCategoryLimit),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child, VoidCallback? onTap}) => Container(
    margin: const EdgeInsets.symmetric(vertical: 5),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(kRadiusLg),
      boxShadow: kCardShadow,
    ),
    clipBehavior: Clip.antiAlias,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );

  Widget _setOverallCard(AppLocalizations l, double spent) {
    final cs = Theme.of(context).colorScheme;
    return _card(
      onTap: () => _editOverall(0),
      child: Row(
        children: [
          Icon(Icons.flag_rounded, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l.setOverallBudget,
              style: kTextStyle.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _overallCard(AppLocalizations l, double limit, double spent) {
    return _card(
      onTap: () => _editOverall(limit),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.overallBudget,
                  style: kTextStyle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _status(l, spent, limit),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AmountText(
                spent,
                symbol: _symbol,
                style: kTextStyle.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: spent > limit ? AppColors.negative : null,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ ${formatMoney(limit, _symbol)}',
                style: kTextStyle.copyWith(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _bar(spent, limit, AppColors.primary),
        ],
      ),
    );
  }

  Widget _categoryRow(AppLocalizations l, Budget b, double spent) {
    final cat = _cat(b.categoryId!);
    final color = cat?.categoryColor ?? AppColors.primary;
    return _card(
      onTap: () => _editCategory(b.categoryId!, b.amount),
      child: Column(
        children: [
          Row(
            children: [
              ItemAvatar(
                color: color,
                icon: cat?.categoryIcon ?? Icons.category_rounded,
                diameter: 38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cat?.categoryName ?? '',
                  style: kTextStyle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${formatMoney(spent, _symbol)} / ${formatMoney(b.amount, _symbol)}',
                style: kTextStyle.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: spent > b.amount ? AppColors.negative : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _bar(spent, b.amount, color),
          const SizedBox(height: 6),
          Align(alignment: Alignment.centerRight, child: _status(l, spent, b.amount)),
        ],
      ),
    );
  }

  Widget _status(AppLocalizations l, double spent, double limit) {
    final over = spent > limit;
    final text = over
        ? l.overBy(formatMoney(spent - limit, _symbol))
        : l.leftAmount(formatMoney(limit - spent, _symbol));
    final color = over ? AppColors.negative : AppColors.positive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(kRadiusSm),
      ),
      child: Text(
        text,
        style: kTextStyle.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _bar(double spent, double limit, Color color) {
    final ratio = limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);
    final over = spent > limit;
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Stack(
        children: [
          Container(
            height: 8,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
          ),
          FractionallySizedBox(
            widthFactor: over ? 1.0 : ratio,
            child: Container(height: 8, color: over ? AppColors.negative : color),
          ),
        ],
      ),
    );
  }

  Future<double?> _amountDialog(String title, double current) {
    return showDialog<double>(
      context: context,
      builder: (_) => _AmountDialog(title: title, current: current, symbol: _symbol),
    );
  }
}

/// Amount entry that owns its controller (disposed after the close animation).
class _AmountDialog extends StatefulWidget {
  const _AmountDialog({
    required this.title,
    required this.current,
    this.symbol,
  });

  final String title;
  final double current;
  final String? symbol;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.current <= 0
        ? ''
        : (widget.current % 1 == 0
              ? widget.current.toInt().toString()
              : widget.current.toString()),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: l.monthlyLimit,
          suffixText: widget.symbol,
        ),
      ),
      actions: [
        if (widget.current > 0)
          TextButton(
            onPressed: () => Navigator.pop(context, 0.0),
            child: Text(l.delete, style: const TextStyle(color: AppColors.negative)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () {
            final v = double.tryParse(_controller.text.replaceAll(',', '.'));
            Navigator.pop(context, v);
          },
          child: Text(l.save),
        ),
      ],
    );
  }
}

/// Bottom sheet to pick an (expense) category to add a limit for.
class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l.addCategoryLimit,
                style: kTextStyle.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            child: categories.isEmpty
                ? Center(child: Text(l.noCategoriesYet))
                : ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, i) {
                      final c = categories[i];
                      return ListTile(
                        leading: ItemAvatar(
                          color: c.categoryColor,
                          icon: c.categoryIcon,
                          diameter: 38,
                        ),
                        title: Text(
                          c.categoryName,
                          style: kTextStyle.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onTap: () => Navigator.pop(context, c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
