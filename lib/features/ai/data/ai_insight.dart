/// One answer from the "Ask your money" chat, plus how many questions remain in
/// the user's daily quota ([remaining] is null when the server didn't report it).
class AiAnswer {
  const AiAnswer({required this.answer, this.remaining});

  final String answer;
  final int? remaining;
}

/// A single AI-generated insight card.
class AiInsight {
  const AiInsight({
    required this.title,
    required this.detail,
    required this.tone,
  });

  final String title;
  final String detail;

  /// One of: positive | warning | neutral. Drives the accent colour.
  final String tone;

  factory AiInsight.fromJson(Map<String, dynamic> json) => AiInsight(
    title: json['title'] as String? ?? '',
    detail: json['detail'] as String? ?? '',
    tone: json['tone'] as String? ?? 'neutral',
  );
}

/// Full AI insights payload returned by the ai-insights Edge Function.
class AiInsightsResult {
  const AiInsightsResult({
    required this.summary,
    required this.score,
    required this.scoreLabel,
    required this.insights,
    required this.tip,
  });

  final String summary;

  /// Overall financial-health score, 0-100.
  final int score;
  final String scoreLabel;
  final List<AiInsight> insights;
  final String tip;

  factory AiInsightsResult.fromJson(Map<String, dynamic> json) {
    final raw = (json['insights'] as List?) ?? const [];
    return AiInsightsResult(
      summary: json['summary'] as String? ?? '',
      score: (json['score'] as num?)?.round().clamp(0, 100) ?? 0,
      scoreLabel: json['scoreLabel'] as String? ?? '',
      insights: raw
          .whereType<Map<String, dynamic>>()
          .map(AiInsight.fromJson)
          .toList(),
      tip: json['tip'] as String? ?? '',
    );
  }
}
