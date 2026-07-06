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
      throw AiFailure('AI request failed (${e.status}).');
    }
  }
}
