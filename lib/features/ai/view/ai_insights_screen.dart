import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/widgets/premium_badge.dart';
import 'package:finance_app/features/ai/ai_service.dart';
import 'package:finance_app/features/ai/data/ai_insight.dart';
import 'package:finance_app/features/ai/data/spending_summary.dart';
import 'package:finance_app/features/widget_bridge/widget_service.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:finance_app/l10n/app_localizations.dart';
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

  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The summary needs the locale (the coach answers in the user's language),
    // and Localizations is only reachable once dependencies are ready — so the
    // first load happens here rather than in initState.
    if (!_didLoad) {
      _didLoad = true;
      _load();
    }
  }

  /// Builds a compact base-currency spending summary for the model. Read the
  /// locale before the await — the coach answers in the user's language, and
  /// touching context after an async gap is unsafe.
  Future<Map<String, dynamic>> _buildSummary() =>
      buildSpendingSummary(language: Localizations.localeOf(context).languageCode);

  /// AiService has no BuildContext, so it reports a [AiFailureKind] and we turn
  /// it into a message in the user's language here.
  String _localizedFailure(AiFailure e) {
    final l = AppLocalizations.of(context);
    return switch (e.kind) {
      AiFailureKind.backendOff => l.aiErrorBackendOff,
      AiFailureKind.noCredit => l.aiErrorNoCredit,
      AiFailureKind.invalidKey => l.aiErrorInvalidKey,
      AiFailureKind.keyNotSet => l.aiErrorKeyNotSet,
      AiFailureKind.dailyLimit => l.aiErrorDailyLimit,
      AiFailureKind.badResponse => l.aiErrorBadResponse,
      AiFailureKind.unknown => l.somethingWentWrongDetail(e.detail ?? ''),
    };
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await _buildSummary();
      // Cache-aware: no network call unless the data changed or the user
      // forced a refresh.
      final result = await _ai.insights(summary, force: force);
      if (mounted) setState(() => _result = result);
      // The cache just updated — refresh the home-screen AI widget so its score
      // matches without waiting for the next transaction change.
      getIt<WidgetService>().refreshAiWidget();
    } on AiFailure catch (e) {
      if (mounted) setState(() => _error = _localizedFailure(e));
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(
            context,
          ).somethingWentWrongDetail('$e'),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).aiInsightsTitle),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context).reAnalyze,
            onPressed: _loading ? null : () => _load(force: true),
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
        Center(
          child: PremiumBadge(label: AppLocalizations.of(context).aiCoachBadge),
        ),
        const SizedBox(height: 20),
        _ScoreHero(score: result.score, label: result.scoreLabel),
        const SizedBox(height: 20),
        Text(
          result.summary,
          style: TextStyle(
            fontSize: 18,
            height: 1.4,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
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

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.score, required this.label});

  final int score;
  final String label;

  Color get _color => switch (score) {
    >= 70 => AppColors.positive,
    >= 40 => const Color(0xFFF5A623),
    _ => AppColors.negative,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: kCardShadow,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 130,
            width: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 130,
                  width: 130,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(_color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: _color,
                        height: 1,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context).outOf100,
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppLocalizations.of(context).financialHealth,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
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
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.detail,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: cs.onSurfaceVariant,
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
                Text(
                  AppLocalizations.of(context).coachTip,
                  style: const TextStyle(
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).readingYourSpending,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
            Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}
