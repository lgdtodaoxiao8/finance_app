import 'package:finance_app/core/config/app_config.dart';
import 'package:finance_app/core/widgets/premium_badge.dart';
import 'package:finance_app/features/subscription/data/premium_feature.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Bottom sheet that pitches premium and sends the user to the web to buy.
///
/// Deliberately has no in-app purchase button: checkout lives on the website
/// so there's no App Store commission. The CTA opens the pricing page in the
/// browser.
class PaywallSheet extends StatelessWidget {
  const PaywallSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaywallSheet(),
    );
  }

  Future<void> _openPricing(BuildContext context) async {
    final uri = Uri.parse(AppConfig.pricingUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).couldNotOpenBrowser),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  children: [
                    const Center(child: PremiumBadge()),
                    const SizedBox(height: 18),
                    Text(
                      AppLocalizations.of(context).turnTrackingIntoPlan,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).paywallBody,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    for (final f in premiumFeatures(
                      AppLocalizations.of(context),
                    ))
                      _FeatureRow(feature: f),
                  ],
                ),
              ),
              _Footer(onUpgrade: () => _openPricing(context)),
            ],
          ),
        );
      },
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});

  final PremiumFeature feature;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: PremiumBadge.gradient,
              borderRadius: BorderRadius.circular(kRadiusSm),
            ),
            child: Icon(feature.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.subtitle,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: kCardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: onUpgrade,
              icon: const Icon(PhosphorIconsFill.arrowSquareOut, size: 20),
              label: Text(
                AppLocalizations.of(context).continueOnWeb,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).secureCheckout,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
