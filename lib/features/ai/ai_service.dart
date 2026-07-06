import 'dart:convert';

import 'package:finance_app/core/config/app_config.dart';
import 'package:finance_app/core/preferences/app_preferences.dart';
import 'package:finance_app/features/ai/data/ai_insight.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// User-facing AI problem (backend off, network, model error).
class AiFailure implements Exception {
  AiFailure(this.message);
  final String message;
  @override
  String toString() => message;
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
  String _signature(Map<String, dynamic> s) {
    final cats = (s['byCategory'] as List?) ?? const [];
    final catSig =
        cats
            .map((c) => '${c['name']}:${(c['amount'] as num?)?.round()}')
            .toList()
          ..sort();
    return '${(s['income'] as num?)?.round()}|'
        '${(s['expense'] as num?)?.round()}|${catSig.join(',')}';
  }

  Future<AiInsightsResult> insights(
    Map<String, dynamic> summary, {
    bool force = false,
  }) async {
    if (!isAvailable) {
      throw AiFailure('AI needs the backend configured (Supabase + key).');
    }

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
        throw AiFailure(_friendly(data['error'].toString()));
      }
      if (data is! Map<String, dynamic>) {
        throw AiFailure('Unexpected AI response.');
      }
      await _prefs.setAiInsightsCache(signature, jsonEncode(data));
      return AiInsightsResult.fromJson(data);
    } on FunctionException catch (e) {
      final details = e.details;
      final raw = (details is Map && details['error'] != null)
          ? details['error'].toString()
          : 'AI request failed (${e.status}).';
      throw AiFailure(_friendly(raw));
    }
  }

  /// Maps common backend errors to plain, actionable messages.
  String _friendly(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('insufficient_quota') || lower.contains('429')) {
      return 'The AI provider is out of credit. Add billing at '
          'platform.openai.com → Billing, then try again.';
    }
    if (lower.contains('401') || lower.contains('invalid api key')) {
      return 'The AI key on the server is invalid. Re-set it with '
          '`supabase secrets set OPENAI_API_KEY=...`.';
    }
    if (lower.contains('not set on the server')) {
      return 'AI isn\'t set up yet: set OPENAI_API_KEY in Supabase secrets.';
    }
    return raw;
  }
}
