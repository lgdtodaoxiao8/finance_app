import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/widget_bridge/widget_service.dart';
import 'package:finance_app/features/widget_config/data/widget_flow.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Fast, low-friction transaction entry surfaced from the home-screen widget
/// (the "custom amount" / "ask each time" / "+" paths) and reusable anywhere a
/// one-tap log is wanted. Logs to the first account in the base currency; the
/// [flow] decides whether it's an expense or an income.
class QuickAddSheet extends StatefulWidget {
  const QuickAddSheet({
    super.key,
    this.categoryId,
    this.amount,
    this.flow = WidgetFlow.expense,
  });

  /// Pre-selected category (e.g. from a widget deep link). Null → user picks.
  final int? categoryId;

  /// Pre-filled amount (e.g. carried from the small widget's amount builder
  /// when the user taps "exact"). Null/≤0 → the field starts empty.
  final double? amount;

  /// Whether this logs an expense (default) or an income — the income widget
  /// opens the sheet in income mode (green accent, `type: 'income'`).
  final WidgetFlow flow;

  /// Opens the sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    int? categoryId,
    double? amount,
    WidgetFlow flow = WidgetFlow.expense,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          QuickAddSheet(categoryId: categoryId, amount: amount, flow: flow),
    );
  }

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final _amountController = TextEditingController();
  List<Category> _categories = const [];
  int? _selectedCategoryId;
  Currency? _base;
  Account? _account;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    // Carry over an amount already assembled on the widget, so "exact" continues
    // where the builder left off instead of starting from zero.
    if (widget.amount != null && widget.amount! > 0) {
      _amountController.text = _fmtAmount(widget.amount!);
    }
    _load();
  }

  /// Formats a prefilled amount without a trailing ".0" (e.g. "300", "12.5").
  static String _fmtAmount(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  Future<void> _load() async {
    final all = await getIt<CategoryRepository>().getAll();
    final accounts = await getIt<AccountRepository>().getAll();
    final base = await getIt<CurrencyRepository>().getBase();
    if (!mounted) return;
    // Only categories matching this sheet's flow (income sheet → income cats).
    final categories = all
        .where((c) => c.isIncome == widget.flow.isIncome)
        .toList();
    setState(() {
      _categories = categories;
      _base = base;
      _account = accounts.isEmpty ? null : accounts.first;
      _selectedCategoryId ??= categories.isEmpty
          ? null
          : categories.first.categoryId;
      // A pre-selected category that no longer exists falls back to the first.
      if (!categories.any((c) => c.categoryId == _selectedCategoryId)) {
        _selectedCategoryId = categories.isEmpty
            ? null
            : categories.first.categoryId;
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool get _ready =>
      _base != null && _account != null && _categories.isNotEmpty;

  bool get _isIncome => widget.flow.isIncome;

  double? get _amount {
    final raw = _amountController.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value <= 0) return null;
    return value;
  }

  Future<void> _save() async {
    final amount = _amount;
    if (amount == null || _selectedCategoryId == null || !_ready) return;
    setState(() => _saving = true);
    await getIt<TransactionRepository>().add(
      accountId: _account!.accountId,
      categoryId: _selectedCategoryId!,
      currencyId: _base!.currencyId,
      amount: amount,
      date: DateTime.now(),
      note: 'Quick add',
      type: widget.flow.transactionType,
    );
    await getIt<WidgetService>().publishOnce();
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.quickAddSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          top: false,
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _ready
              ? _buildForm(context, l)
              : _buildIncomplete(context, l),
        ),
      ),
    );
  }

  Widget _buildIncomplete(BuildContext context, AppLocalizations l) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _grabber(),
        const SizedBox(height: 20),
        Text(
          l.quickAddIncompleteSetup,
          textAlign: TextAlign.center,
          style: kTextStyle.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, AppLocalizations l) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _grabber(),
        const SizedBox(height: 16),
        Row(
          children: [
            if (_isIncome) ...[
              // Income = a down arrow (money coming in), matching the app's
              // stat cards / type picker convention.
              const Icon(
                Icons.arrow_downward_rounded,
                size: 20,
                color: AppColors.positive,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              _isIncome ? l.quickIncomeTitle : l.quickAddTitle,
              style: kTextStyle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _isIncome ? AppColors.positive : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l.selectCategory,
          style: kTextStyle.copyWith(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in _categories) _categoryChip(c),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _amountController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: kTextStyle.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '0',
            prefixText: '${_base!.currencySymbol} ',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: _isIncome
                ? FilledButton.styleFrom(backgroundColor: AppColors.positive)
                : null,
            onPressed: (_amount != null && !_saving) ? _save : null,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.save),
          ),
        ),
      ],
    );
  }

  Widget _categoryChip(Category c) {
    final selected = c.categoryId == _selectedCategoryId;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = c.categoryId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.categoryColor.withValues(alpha: selected ? 0.18 : 0.10),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? c.categoryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(c.categoryIcon, size: 16, color: c.categoryColor),
            const SizedBox(width: 6),
            Text(
              c.categoryName,
              style: kTextStyle.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? c.categoryColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grabber() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
