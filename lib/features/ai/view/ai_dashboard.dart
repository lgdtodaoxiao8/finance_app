import 'dart:async';

import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/format.dart';
import 'package:finance_app/core/widgets/premium_badge.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/ai/ai_service.dart';
import 'package:finance_app/features/ai/view/ai_insights_screen.dart';
import 'package:finance_app/features/ai/view/category_detail_screen.dart';
import 'package:finance_app/features/ai/view/forecast_screen.dart';
import 'package:finance_app/features/ai/view/month_detail_screen.dart';
import 'package:finance_app/features/subscription/subscription_service.dart';
import 'package:finance_app/features/subscription/view/paywall_sheet.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Home "Insights" section: a grid of at-a-glance cards. Everything numeric is
/// computed locally for this month (free, instant); the AI Coach card shows a
/// cached score without any network call. Premium cards drill into their live
/// detail screens; locked ones show a teaser preview + the paywall.
class AiDashboard extends StatefulWidget {
  const AiDashboard({super.key});

  @override
  State<AiDashboard> createState() => _AiDashboardState();
}

class _AiDashboardState extends State<AiDashboard> {
  StreamSubscription<List<TransactionDetails>>? _sub;

  String? _symbol;
  double _income = 0, _expense = 0;
  String? _topName;
  double _topAmount = 0, _topShare = 0;
  Color _topColor = AppColors.primary;
  double _forecast = 0;

  double get _net => _income - _expense;

  @override
  void initState() {
    super.initState();
    _loadSymbol();
    _sub = getIt<TransactionRepository>().watchAllWithDetails().listen(
      _recompute,
    );
  }

  Future<void> _loadSymbol() async {
    final base = await getIt<CurrencyRepository>().getBase();
    if (mounted) setState(() => _symbol = base?.currencySymbol);
  }

  void _recompute(List<TransactionDetails> txns) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    double income = 0, expense = 0;
    final byCategory = <String, double>{};
    final colorOf = <String, Color>{};
    for (final t in txns) {
      if (t.date.isBefore(monthStart)) continue;
      if (t.isIncome) income += t.amountInBase;
      if (t.isExpense) {
        expense += t.amountInBase;
        final name = t.categoryName ?? 'Other';
        byCategory[name] = (byCategory[name] ?? 0) + t.amountInBase;
        colorOf[name] = t.categoryColor;
      }
    }

    String? topName;
    double topAmount = 0;
    byCategory.forEach((name, amount) {
      if (amount > topAmount) {
        topAmount = amount;
        topName = name;
      }
    });

    final dailyRate = now.day == 0 ? 0.0 : expense / now.day;

    if (!mounted) return;
    setState(() {
      _income = income;
      _expense = expense;
      _topName = topName;
      _topAmount = topAmount;
      _topShare = expense == 0 ? 0 : topAmount / expense;
      _topColor = topName != null
          ? (colorOf[topName] ?? AppColors.primary)
          : AppColors.primary;
      _forecast = income - dailyRate * daysInMonth;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sub = getIt<SubscriptionService>();
    return ValueListenableBuilder<bool>(
      valueListenable: sub.isPremium,
      builder: (context, premium, _) {
        final cached = getIt<AiService>().cached;
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
                if (!premium) const PremiumBadge(),
              ],
            ),
            const SizedBox(height: 12),
            _Grid(
              children: [
                _ThisMonthCard(
                  income: _income,
                  expense: _expense,
                  net: _net,
                  symbol: _symbol,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MonthDetailScreen(),
                    ),
                  ),
                ),
                _TopCategoryCard(
                  name: _topName,
                  amount: _topAmount,
                  share: _topShare,
                  color: _topColor,
                  symbol: _symbol,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CategoryDetailScreen(),
                    ),
                  ),
                ),
                _AiCoachCard(
                  premium: premium,
                  score: cached?.score,
                  label: cached?.scoreLabel,
                  onOpen: () =>
                      _open(context, premium, const AiInsightsScreen()),
                ),
                _ForecastCard(
                  premium: premium,
                  projected: _forecast,
                  symbol: _symbol,
                  onOpen: () => _open(context, premium, const ForecastScreen()),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _open(BuildContext context, bool premium, Widget screen) {
    if (!premium) {
      PaywallSheet.show(context);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

// ------------------------------------------------------------------ cards ---

class _CardShell extends StatelessWidget {
  const _CardShell({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 152,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(kRadiusLg),
          boxShadow: kCardShadow,
        ),
        child: child,
      ),
    );
  }
}

class _CardHead extends StatelessWidget {
  const _CardHead({
    required this.icon,
    required this.accent,
    required this.title,
    this.locked = false,
  });
  final IconData icon;
  final Color accent;
  final String title;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: accent),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (locked)
          const Icon(
            Icons.lock_rounded,
            size: 14,
            color: AppColors.textTertiary,
          ),
      ],
    );
  }
}

class _ThisMonthCard extends StatelessWidget {
  const _ThisMonthCard({
    required this.income,
    required this.expense,
    required this.net,
    required this.symbol,
    required this.onTap,
  });
  final double income;
  final double expense;
  final double net;
  final String? symbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = income + expense;
    final inFlex = total == 0
        ? 1
        : (income / total * 100).round().clamp(1, 100);
    final outFlex = total == 0
        ? 1
        : (expense / total * 100).round().clamp(1, 100);
    return _CardShell(
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHead(
            icon: Icons.calendar_today_rounded,
            accent: AppColors.primary,
            title: 'This month',
          ),
          const Spacer(),
          Text(
            formatMoney(net, symbol),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: net < 0 ? AppColors.negative : AppColors.positive,
            ),
          ),
          const Text(
            'net this month',
            style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(
                  flex: inFlex,
                  child: Container(height: 6, color: AppColors.positive),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: outFlex,
                  child: Container(height: 6, color: AppColors.negative),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'in ${formatMoney(income, symbol)} · out ${formatMoney(expense, symbol)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCategoryCard extends StatelessWidget {
  const _TopCategoryCard({
    required this.name,
    required this.amount,
    required this.share,
    required this.color,
    required this.symbol,
    required this.onTap,
  });
  final String? name;
  final double amount;
  final double share;
  final Color color;
  final String? symbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHead(
            icon: Icons.donut_large_rounded,
            accent: color,
            title: 'Top category',
          ),
          const Spacer(),
          Text(
            name ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            name != null ? formatMoney(amount, symbol) : 'no spend yet',
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 10),
          _ProgressBar(value: share, color: color),
          const SizedBox(height: 6),
          Text(
            '${(share * 100).round()}% of spending',
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiCoachCard extends StatelessWidget {
  const _AiCoachCard({
    required this.premium,
    required this.score,
    required this.label,
    required this.onOpen,
  });
  final bool premium;
  final int? score; // cached AI score, if any
  final String? label;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    // Locked → enticing mock; premium+cached → real score; premium+no cache →
    // prompt to run.
    final showScore = premium ? score : 78;
    final showLabel = premium ? (label ?? 'Tap to analyze') : 'Overspending';
    return _CardShell(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHead(
            icon: Icons.psychology_rounded,
            accent: AppColors.primary,
            title: 'AI Coach',
            locked: !premium,
          ),
          const Spacer(),
          Row(
            children: [
              _ScoreRing(
                score: showScore ?? -1,
                dim: !premium,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      premium && score == null ? 'Run' : (showLabel),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: premium
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      premium ? 'health score' : 'Preview · unlock',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          const Text(
            'AI read on your spending + a tip',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({
    required this.premium,
    required this.projected,
    required this.symbol,
    required this.onOpen,
  });
  final bool premium;
  final double projected;
  final String? symbol;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final value = premium ? projected : 340.0; // mock when locked
    final positive = value >= 0;
    final color = premium
        ? (positive ? AppColors.positive : AppColors.negative)
        : AppColors.textTertiary;
    return _CardShell(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHead(
            icon: Icons.trending_up_rounded,
            accent: AppColors.positive,
            title: 'Forecast',
            locked: !premium,
          ),
          const Spacer(),
          Row(
            children: [
              Icon(
                positive ? Icons.north_east_rounded : Icons.south_east_rounded,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  formatMoney(value, symbol),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const Text(
            'projected month-end',
            style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
          ),
          const Spacer(),
          Text(
            premium
                ? (positive ? 'On pace to stay positive' : 'Heading negative')
                : 'Preview · unlock',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- primitives ---

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, this.dim = false});
  final int score; // -1 = unknown
  final bool dim;

  Color get _color {
    if (dim || score < 0) return AppColors.textTertiary;
    return switch (score) {
      >= 70 => AppColors.positive,
      >= 40 => const Color(0xFFF5A623),
      _ => AppColors.negative,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      width: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 46,
            width: 46,
            child: CircularProgressIndicator(
              value: score < 0 ? 0.75 : score / 100,
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.field,
              valueColor: AlwaysStoppedAnimation(_color),
            ),
          ),
          Text(
            score < 0 ? '?' : '$score',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.color});
  final double value; // 0..1
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        children: [
          Container(height: 7, color: AppColors.field),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(height: 7, color: color),
          ),
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
