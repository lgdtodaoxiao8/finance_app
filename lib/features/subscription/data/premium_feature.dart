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
    Icons.psychology_rounded,
    'AI money coach',
    'A personal read on where your money leaks — and the one move to fix it.',
  ),
  PremiumFeature(
    Icons.trending_up_rounded,
    'Month-end forecast',
    'See how the month will end while you can still change it, not after.',
  ),
  PremiumFeature(
    Icons.speed_rounded,
    'Financial health score',
    'One number that tells you if you\'re winning with money — and how to raise it.',
  ),
  PremiumFeature(
    Icons.cloud_sync_rounded,
    'Sync everywhere',
    'Your money on phone and web, always backed up. Never lose a record.',
  ),
  PremiumFeature(
    Icons.chat_bubble_outline_rounded,
    'Ask your money anything',
    '“How much on coffee last month?” — answered in plain language, instantly.',
  ),
  PremiumFeature(
    Icons.notifications_active_rounded,
    'Smart alerts',
    'A nudge before a category blows its budget — catch overspend early.',
  ),
];
