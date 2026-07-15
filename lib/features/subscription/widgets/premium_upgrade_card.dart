import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/widgets/premium_badge.dart';
import 'package:finance_app/features/subscription/subscription_service.dart';
import 'package:finance_app/features/subscription/view/paywall_sheet.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Settings entry point to premium: a gradient upsell when free, a calm
/// "active" state when subscribed.
class PremiumUpgradeCard extends StatelessWidget {
  const PremiumUpgradeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final sub = getIt<SubscriptionService>();
    return ValueListenableBuilder<bool>(
      valueListenable: sub.isPremium,
      builder: (context, premium, _) {
        return premium ? const _ActiveCard() : const _UpsellCard();
      },
    );
  }
}

class _UpsellCard extends StatelessWidget {
  const _UpsellCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => PaywallSheet.show(context),
      // Dev affordance until billing sync lands: long-press flips premium on
      // so gated features can be exercised without a live purchase.
      onLongPress: () => getIt<SubscriptionService>().setPremium(true),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: PremiumBadge.gradient,
          borderRadius: BorderRadius.circular(kRadiusLg),
          boxShadow: kCardShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).goPremium,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).goPremiumSubtitle,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                AppLocalizations.of(context).upgrade,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Dev affordance: long-press flips premium back off.
      onLongPress: () => getIt<SubscriptionService>().setPremium(false),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(kRadiusLg),
          boxShadow: kCardShadow,
        ),
        child: Row(
          children: [
            const PremiumBadge(),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context).premiumActive,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.verified_rounded, color: AppColors.positive),
          ],
        ),
      ),
    );
  }
}
