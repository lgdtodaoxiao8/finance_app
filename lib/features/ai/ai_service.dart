import 'package:finance_app/core/config/app_config.dart';
import 'package:finance_app/features/ai/data/ai_insight.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// User-facing AI problem (backend off, network, model error).
class AiFailure implements Exception {
  AiFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Calls the `ai-insights` Supabase Edge Function, which holds the Anthropic
/// key server-side. The app only ever sends a spending summary and receives
/// structured insights — the model key is never shipped in the binary.
class AiService {
  bool get isAvailable => AppConfig.isBackendConfigured;

  Future<AiInsightsResult> insights(Map<String, dynamic> summary) async {
    if (!isAvailable) {
      throw AiFailure('AI needs the backend configured (Supabase + key).');
    }
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'ai-insights',
        body: summary,
      );
      final data = res.data;
      if (data is Map && data['error'] != null) {
        throw AiFailure(data['error'].toString());
      }
      if (data is! Map<String, dynamic>) {
        throw AiFailure('Unexpected AI response.');
      }
      return AiInsightsResult.fromJson(data);
    } on FunctionException catch (e) {
      // Surface the server's real error (the Edge Function returns
      // {error: ...}) instead of a bare status code.
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
