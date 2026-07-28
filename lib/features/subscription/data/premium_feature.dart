import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
    PhosphorIconsFill.brain,
    l.featureAiCoachTitle,
    l.featureAiCoachBody,
  ),
  PremiumFeature(
    PhosphorIconsFill.trendUp,
    l.featureForecastTitle,
    l.featureForecastBody,
  ),
  PremiumFeature(
    PhosphorIconsFill.gauge,
    l.featureHealthTitle,
    l.featureHealthBody,
  ),
  PremiumFeature(
    PhosphorIconsFill.cloudArrowUp,
    l.featureSyncTitle,
    l.featureSyncBody,
  ),
  PremiumFeature(
    PhosphorIconsFill.chatCircle,
    l.featureAskTitle,
    l.featureAskBody,
  ),
  PremiumFeature(
    PhosphorIconsFill.bellRinging,
    l.featureAlertsTitle,
    l.featureAlertsBody,
  ),
];
