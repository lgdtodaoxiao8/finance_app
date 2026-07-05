import 'package:flutter/material.dart';

/// A selling point shown on the paywall.
class PremiumFeature {
  const PremiumFeature(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;
}

/// The premium value proposition. Kept in one place so the paywall, the
/// settings upgrade card and any teasers stay in sync.
const premiumFeatures = <PremiumFeature>[
  PremiumFeature(
    Icons.auto_awesome_rounded,
    'AI money insights',
    'Weekly, human-readable breakdowns of where your money went and why.',
  ),
  PremiumFeature(
    Icons.trending_up_rounded,
    'Spending forecasts',
    'See your projected month-end balance before you overspend.',
  ),
  PremiumFeature(
    Icons.savings_rounded,
    'AI budget coach',
    'Personal budgets that adapt to your habits, with nudges that keep you on track.',
  ),
  PremiumFeature(
    Icons.cloud_sync_rounded,
    'Sync everywhere',
    'Your data on phone and web, always backed up and up to date.',
  ),
  PremiumFeature(
    Icons.widgets_rounded,
    'AI home-screen widget',
    'A smart widget that surfaces the number that matters right now.',
  ),
  PremiumFeature(
    Icons.chat_bubble_outline_rounded,
    'Ask your money anything',
    '“How much did I spend on coffee last month?” — answered instantly.',
  ),
];
