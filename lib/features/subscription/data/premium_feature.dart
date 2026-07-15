import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// A selling point shown on the paywall.
class PremiumFeature {
  const PremiumFeature(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}

/// The premium value proposition, in the user's language. Kept in one place so
/// the paywall, the settings upgrade card and any teasers stay in sync.
List<PremiumFeature> premiumFeatures(AppLocalizations l) => [
  PremiumFeature(
    Icons.psychology_rounded,
    l.featureAiCoachTitle,
    l.featureAiCoachBody,
  ),
  PremiumFeature(
    Icons.trending_up_rounded,
    l.featureForecastTitle,
    l.featureForecastBody,
  ),
  PremiumFeature(
    Icons.speed_rounded,
    l.featureHealthTitle,
    l.featureHealthBody,
  ),
  PremiumFeature(
    Icons.cloud_sync_rounded,
    l.featureSyncTitle,
    l.featureSyncBody,
  ),
  PremiumFeature(
    Icons.chat_bubble_outline_rounded,
    l.featureAskTitle,
    l.featureAskBody,
  ),
  PremiumFeature(
    Icons.notifications_active_rounded,
    l.featureAlertsTitle,
    l.featureAlertsBody,
  ),
];
