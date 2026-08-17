import 'dart:convert';

import 'package:finance_app/core/config/app_config.dart';
import 'package:finance_app/core/preferences/app_preferences.dart';
import 'package:finance_app/features/ai/data/ai_insight.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// What went wrong, so the UI can show a localised message. [AiFailure.detail]
/// carries the raw provider text for [AiFailureKind.unknown].
enum AiFailureKind {
  /// Supabase/AI isn't configured in [AppConfig] yet.
  backendOff,

  /// The OpenAI account has no credit (429 / insufficient_quota).
  noCredit,

  /// The user hit their daily "Ask your money" question quota.
  dailyLimit,

  /// The server's OpenAI key is rejected (401).
  invalidKey,

  /// OPENAI_API_KEY isn't set in Supabase secrets.
  keyNotSet,

  /// The function returned something we couldn't parse.
  badResponse,

  /// Anything else — show [AiFailure.detail].
  unknown,
}

/// User-facing AI problem (backend off, network, model error). Localised at the
/// display site: the service has no BuildContext.
class AiFailure implements Exception {
  AiFailure(this.kind, [this.detail]);

  final AiFailureKind kind;
  final String? detail;

  @override
  String toString() => detail ?? kind.name;
}

/// Calls the `ai-insights` Supabase Edge Function (which holds the OpenAI key
/// server-side) — but only when it needs to.
///
/// Cost discipline: the heavy maths (totals, forecasts, rates) is done locally
/// for free; this paid call is just the narrative/coaching layer. The result
/// is cached against a fingerprint of the spending, so re-opening the AI Coach
/// with unchanged data returns instantly and spends nothing. A real request
/// only fires when the data actually changed (or the user forces a refresh).
class AiService {
  AiService(this._prefs);

  final AppPreferences _prefs;

  bool get isAvailable => AppConfig.isBackendConfigured;

  /// The last cached insights, if any (used by cards to show a score without a
  /// network call).
  AiInsightsResult? get cached {
    final json = _prefs.aiInsightsJson;
    if (json == null) return null;
    try {
      return AiInsightsResult.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  /// A stable fingerprint of the spending that matters for insights — income,
  /// expense and per-category totals (rounded). Recent-list order/dates are
  /// deliberately excluded so trivial changes don't invalidate the cache.
  ///
  /// The language is part of it: the coach answers in the user's language, so
  /// switching language must fetch fresh text rather than reuse the cached one.
  String _signature(Map<String, dynamic> s) {
    final cats = (s['byCategory'] as List?) ?? const [];
    final catSig =
        cats
            .map((c) => '${c['name']}:${(c['amount'] as num?)?.round()}')
            .toList()
          ..sort();
    return '${s['language']}|${(s['income'] as num?)?.round()}|'
        '${(s['expense'] as num?)?.round()}|${catSig.join(',')}';
  }

  Future<AiInsightsResult> insights(
    Map<String, dynamic> summary, {
    bool force = false,
  }) async {
    if (!isAvailable) throw AiFailure(AiFailureKind.backendOff);

    final signature = _signature(summary);
    if (!force && signature == _prefs.aiInsightsSignature) {
      final hit = cached;
      if (hit != null) return hit; // Free, instant — data hasn't changed.
    }

    try {
      final res = await Supabase.instance.client.functions.invoke(
        'ai-insights',
        body: summary,
      );
      final data = res.data;
      if (data is Map && data['error'] != null) {
        throw AiFailure(
          _classify(data['error'].toString()),
          '${data['error']}',
        );
      }
      if (data is! Map<String, dynamic>) {
        throw AiFailure(AiFailureKind.badResponse);
      }
      await _prefs.setAiInsightsCache(signature, jsonEncode(data));
      return AiInsightsResult.fromJson(data);
    } on FunctionException catch (e) {
      final details = e.details;
      final raw = (details is Map && details['error'] != null)
          ? details['error'].toString()
          : 'status ${e.status}';
      throw AiFailure(_classify(raw), raw);
    }
  }

  /// Answers a free-text money question over the user's own data (the "Ask your
  /// money" chat). Unlike [insights] this is never cached — every question is
  /// new — so it always hits the backend and therefore needs a signed-in user.
  /// [prior] carries the single previous turn so a follow-up stays in context.
  Future<AiAnswer> ask({
    required String question,
    required Map<String, dynamic> summary,
    ({String question, String answer})? prior,
  }) async {
    if (!isAvailable) throw AiFailure(AiFailureKind.backendOff);

    try {
      final res = await Supabase.instance.client.functions.invoke(
        'ask-money',
        body: {
          'question': question,
          'summary': summary,
          'language': summary['language'],
          if (prior != null)
            'prior': {'question': prior.question, 'answer': prior.answer},
        },
      );
      final data = res.data;
      if (data is Map && data['error'] != null) {
        throw AiFailure(_classify('${data['error']}'), '${data['error']}');
      }
      if (data is! Map || data['answer'] is! String) {
        throw AiFailure(AiFailureKind.badResponse);
      }
      return AiAnswer(
        answer: data['answer'] as String,
        remaining: (data['remaining'] as num?)?.toInt(),
      );
    } on FunctionException catch (e) {
      final details = e.details;
      final raw = (details is Map && details['error'] != null)
          ? details['error'].toString()
          : 'status ${e.status}';
      throw AiFailure(_classify(raw), raw);
    }
  }

  /// Test seams for the two pure helpers (spending fingerprint + error
  /// classification) so their behaviour can be checked without a live backend.
  @visibleForTesting
  String signatureFor(Map<String, dynamic> summary) => _signature(summary);

  @visibleForTesting
  AiFailureKind classifyError(String raw) => _classify(raw);

  /// Maps common provider errors onto a [AiFailureKind] the UI can localise.
  AiFailureKind _classify(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('daily_limit')) return AiFailureKind.dailyLimit;
    if (lower.contains('insufficient_quota') || lower.contains('429')) {
      return AiFailureKind.noCredit;
    }
    if (lower.contains('401') || lower.contains('invalid api key')) {
      return AiFailureKind.invalidKey;
    }
    if (lower.contains('not set on the server')) return AiFailureKind.keyNotSet;
    return AiFailureKind.unknown;
  }
}
