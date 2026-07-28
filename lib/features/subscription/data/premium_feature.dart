import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/core/app_icons.dart';

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
    AppIcons.psychology,
    l.featureAiCoachTitle,
    l.featureAiCoachBody,
  ),
  PremiumFeature(
    AppIcons.trending_up,
    l.featureForecastTitle,
    l.featureForecastBody,
  ),
  PremiumFeature(
    AppIcons.speed,
    l.featureHealthTitle,
    l.featureHealthBody,
  ),
  PremiumFeature(
    AppIcons.cloud_sync,
    l.featureSyncTitle,
    l.featureSyncBody,
  ),
  PremiumFeature(
    AppIcons.chat_bubble,
    l.featureAskTitle,
    l.featureAskBody,
  ),
  PremiumFeature(
    AppIcons.notifications_active,
    l.featureAlertsTitle,
    l.featureAlertsBody,
  ),
];
