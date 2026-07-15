import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/widgets/amount_text.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/ai/view/insight_widgets.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Detail for the free "Top category" card: the full spending breakdown this
/// month, ranked. Local, no API.
class CategoryDetailScreen extends StatefulWidget {
  const CategoryDetailScreen({super.key});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  bool _loading = true;
  String? _symbol;
  double _total = 0;
  List<CategoryBar> _categories = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final txns = await getIt<TransactionRepository>().getAllWithDetails();
    final base = await getIt<CurrencyRepository>().getBase();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);

    double total = 0;
    final byCategory = <String, double>{};
    final colorOf = <String, Color>{};
    for (final t in txns) {
      if (t.date.isBefore(monthStart) || !t.isExpense) continue;
      total += t.amountInBase;
      final name = t.categoryName ?? 'Other';
      byCategory[name] = (byCategory[name] ?? 0) + t.amountInBase;
      colorOf[name] = t.categoryColor;
    }

    final cats =
        byCategory.entries
            .map(
              (e) => CategoryBar(
                name: e.key,
                amount: e.value,
                share: total == 0 ? 0 : e.value / total,
                color: colorOf[e.key] ?? AppColors.primary,
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    if (mounted) {
      setState(() {
        _loading = false;
        _symbol = base?.currencySymbol;
        _total = total;
        _categories = cats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).spendingBreakdown),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? Center(
              child: Text(
                AppLocalizations.of(context).noExpensesThisMonthYet,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 22,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(kRadiusLg),
                    boxShadow: kCardShadow,
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context).totalSpentThisMonth,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AmountText(
                        _total,
                        symbol: _symbol,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(
                          context,
                        ).acrossNCategories(_categories.length),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final c in _categories)
                  CategoryBarRow(bar: c, symbol: _symbol),
              ],
            ),
    );
  }
}
