import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/widget_bridge/widget_service.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Fast, low-friction expense entry surfaced from the home-screen widget (the
/// "custom amount" / "ask each time" paths) and reusable anywhere a one-tap log
/// is wanted. Logs an expense to the first account in the base currency.
class QuickAddSheet extends StatefulWidget {
  const QuickAddSheet({super.key, this.categoryId});

  /// Pre-selected category (e.g. from a widget deep link). Null → user picks.
  final int? categoryId;

  /// Opens the sheet as a modal bottom sheet.
  static Future<void> show(BuildContext context, {int? categoryId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickAddSheet(categoryId: categoryId),
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
    _load();
  }

  Future<void> _load() async {
    final categories = await getIt<CategoryRepository>().getAll();
    final accounts = await getIt<AccountRepository>().getAll();
    final base = await getIt<CurrencyRepository>().getBase();
    if (!mounted) return;
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
      type: 'expense',
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
        Text(
          l.quickAddTitle,
          style: kTextStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
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
