import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/format.dart';
import 'package:finance_app/core/widgets/premium_badge.dart';
import 'package:finance_app/features/ai/view/ai_insights_screen.dart';
import 'package:finance_app/features/ai/view/forecast_screen.dart';
import 'package:finance_app/features/subscription/subscription_service.dart';
import 'package:finance_app/features/subscription/view/paywall_sheet.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// A named spend slice used by the free cards' detail sheets.
typedef CategoryLine = ({String name, double amount, Color color});

/// Grid of AI/insight feature cards on Home. Two free cards show real data;
/// the premium cards show a teaser and open the paywall until subscribed, then
/// drill into their live detail screens.
class AiDashboard extends StatelessWidget {
  const AiDashboard({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
    required this.symbol,
    required this.categories,
  });

  final double income;
  final double expense;
  final double balance;
  final String? symbol;
  final List<CategoryLine> categories;

  @override
  Widget build(BuildContext context) {
    final sub = getIt<SubscriptionService>();
    final topCategory = categories.isNotEmpty ? categories.first : null;

    return ValueListenableBuilder<bool>(
      valueListenable: sub.isPremium,
      builder: (context, premium, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Insights',
                  style: kTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (!premium) const PremiumBadge(label: 'PREMIUM'),
              ],
            ),
            const SizedBox(height: 12),
            _Grid(
              children: [
                // --- Free (real, local) ---
                _AiCard(
                  title: 'This month',
                  icon: Icons.calendar_today_rounded,
                  accent: AppColors.primary,
                  value: formatMoney(balance, symbol),
                  valueColor: balance < 0
                      ? AppColors.negative
                      : AppColors.positive,
                  caption: 'net balance',
                  onTap: () => _showMonthSheet(context),
                ),
                _AiCard(
                  title: 'Top category',
                  icon: Icons.donut_large_rounded,
                  accent: const Color(0xFF7C3AED),
                  value: topCategory?.name ?? '—',
                  caption: topCategory != null
                      ? formatMoney(topCategory.amount, symbol)
                      : 'no spend yet',
                  onTap: () => _showCategorySheet(context),
                ),
                // --- Premium ---
                _AiCard(
                  title: 'AI Coach',
                  icon: Icons.psychology_rounded,
                  accent: AppColors.primary,
                  value: premium ? 'Analyze' : 'Score 78',
                  caption: premium ? 'tap to run' : 'health score + tips',
                  locked: !premium,
                  onTap: () => _openPremium(
                    context,
                    premium,
                    const AiInsightsScreen(),
                  ),
                ),
                _AiCard(
                  title: 'Forecast',
                  icon: Icons.trending_up_rounded,
                  accent: AppColors.positive,
                  value: premium ? 'Project' : '+340',
                  caption: premium ? 'month-end' : 'month-end balance',
                  locked: !premium,
                  onTap: () => _openPremium(
                    context,
                    premium,
                    const ForecastScreen(),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _openPremium(BuildContext context, bool premium, Widget screen) {
    if (!premium) {
      PaywallSheet.show(context);
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _showMonthSheet(BuildContext context) {
    _sheet(context, 'This month', [
      _SheetRow('Income', formatMoney(income, symbol), AppColors.positive),
      _SheetRow('Expense', formatMoney(expense, symbol), AppColors.negative),
      _SheetRow(
        'Balance',
        formatMoney(balance, symbol),
        balance < 0 ? AppColors.negative : AppColors.textPrimary,
      ),
    ]);
  }

  void _showCategorySheet(BuildContext context) {
    if (categories.isEmpty) {
      _sheet(context, 'Top categories', [
        const _SheetRow('No expenses yet', '', AppColors.textSecondary),
      ]);
      return;
    }
    _sheet(context, 'Top categories', [
      for (final c in categories.take(6))
        _SheetRow(c.name, formatMoney(c.amount, symbol), c.color),
    ]);
  }

  void _sheet(BuildContext context, String title, List<_SheetRow> rows) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Two columns; children come in pairs.
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
          child: Row(
            children: [
              Expanded(child: children[i]),
              const SizedBox(width: 12),
              if (i + 1 < children.length)
                Expanded(child: children[i + 1])
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _AiCard extends StatelessWidget {
  const _AiCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.value,
    required this.caption,
    required this.onTap,
    this.valueColor,
    this.locked = false,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final String value;
  final String caption;
  final VoidCallback onTap;
  final Color? valueColor;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 128,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(kRadiusLg),
          boxShadow: kCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 19, color: accent),
                ),
                const Spacer(),
                if (locked)
                  const Icon(
                    Icons.lock_rounded,
                    size: 15,
                    color: AppColors.textTertiary,
                  ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: locked
                    ? AppColors.textTertiary
                    : (valueColor ?? AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
