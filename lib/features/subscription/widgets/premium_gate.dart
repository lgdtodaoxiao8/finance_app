import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/widgets/premium_badge.dart';
import 'package:finance_app/features/subscription/subscription_service.dart';
import 'package:finance_app/features/subscription/view/paywall_sheet.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Gate an action behind premium. If the user is premium, returns true
/// immediately; otherwise it opens the paywall and returns whether they became
/// premium as a result.
///
/// Usage: `if (await ensurePremium(context)) { ...run the feature... }`.
Future<bool> ensurePremium(BuildContext context) async {
  final sub = getIt<SubscriptionService>();
  if (sub.isPremium.value) return true;
  await PaywallSheet.show(context);
  return sub.isPremium.value;
}

/// Wraps a premium-only surface. Shows [child] when premium; otherwise shows a
/// tappable, blurred-out teaser that opens the paywall.
class PremiumLock extends StatelessWidget {
  const PremiumLock({
    super.key,
    required this.child,
    required this.title,
    this.subtitle,
  });

  final Widget child;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final sub = getIt<SubscriptionService>();
    return ValueListenableBuilder<bool>(
      valueListenable: sub.isPremium,
      builder: (context, premium, _) {
        if (premium) return child;
        return _LockedTeaser(title: title, subtitle: subtitle);
      },
    );
  }
}

class _LockedTeaser extends StatelessWidget {
  const _LockedTeaser({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => PaywallSheet.show(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(kRadiusLg),
          border: Border.all(color: AppColors.divider),
          boxShadow: kCardShadow,
        ),
        child: Column(
          children: [
            const PremiumBadge(),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.tonal(
              onPressed: () => PaywallSheet.show(context),
              child: const Text('Unlock with Premium'),
            ),
          ],
        ),
      ),
    );
  }
}
