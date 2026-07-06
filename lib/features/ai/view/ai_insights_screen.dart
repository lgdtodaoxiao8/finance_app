import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/widgets/premium_badge.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/ai/ai_service.dart';
import 'package:finance_app/features/ai/data/ai_insight.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Premium AI screen: sends a spending summary to the ai-insights Edge Function
/// and renders the coach's analysis.
class AiInsightsScreen extends StatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen> {
  final _ai = getIt<AiService>();
  bool _loading = true;
  String? _error;
  AiInsightsResult? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Builds a compact base-currency spending summary for the model.
  Future<Map<String, dynamic>> _buildSummary() async {
    final txns = await getIt<TransactionRepository>().getAllWithDetails();
    final base = await getIt<CurrencyRepository>().getBase();

    double income = 0, expense = 0;
    final byCategory = <String, double>{};
    for (final t in txns) {
      if (t.isIncome) income += t.amountInBase;
      if (t.isExpense) {
        expense += t.amountInBase;
        final name = t.categoryName ?? 'Uncategorized';
        byCategory[name] = (byCategory[name] ?? 0) + t.amountInBase;
      }
    }

    final categories =
        byCategory.entries
            .map((e) => {'name': e.key, 'amount': _round(e.value)})
            .toList()
          ..sort(
            (a, b) => (b['amount'] as num).compareTo(a['amount'] as num),
          );

    final recent = txns.reversed
        .take(15)
        .map(
          (t) => {
            'category': t.categoryName,
            'amount': _round(t.amountInBase),
            'type': t.type,
            'date': t.date.toIso8601String().split('T').first,
          },
        )
        .toList();

    return {
      'baseCurrency': base?.currencyCode ?? '',
      'income': _round(income),
      'expense': _round(expense),
      'balance': _round(income - expense),
      'byCategory': categories,
      'recent': recent,
    };
  }

  double _round(double v) => (v * 100).roundToDouble() / 100;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await _buildSummary();
      final result = await _ai.insights(summary);
      if (mounted) setState(() => _result = result);
    } on AiFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Something went wrong. $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const _Loading();
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    final result = _result;
    if (result == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const Center(child: PremiumBadge(label: 'AI COACH')),
        const SizedBox(height: 16),
        Text(
          result.summary,
          style: const TextStyle(
            fontSize: 18,
            height: 1.4,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        for (final insight in result.insights) _InsightCard(insight: insight),
        if (result.tip.isNotEmpty) ...[
          const SizedBox(height: 8),
          _TipCard(tip: result.tip),
        ],
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final AiInsight insight;

  Color get _accent => switch (insight.tone) {
    'positive' => AppColors.positive,
    'warning' => AppColors.negative,
    _ => AppColors.primary,
  };

  IconData get _icon => switch (insight.tone) {
    'positive' => Icons.trending_up_rounded,
    'warning' => Icons.warning_amber_rounded,
    _ => Icons.lightbulb_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: kCardShadow,
        border: Border(left: BorderSide(color: _accent, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: _accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.detail,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: PremiumBadge.gradient,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: kCardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Coach tip',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Reading your spending…',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
