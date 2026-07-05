import 'package:finance_app/core/widgets/premium_badge.dart';
import 'package:finance_app/features/onboarding/data/onboarding_slide.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A single marketing slide: illustration on a soft backdrop, title, subtitle
/// and (optionally) a PREMIUM badge.
class OnboardingSlideView extends StatelessWidget {
  const OnboardingSlideView({super.key, required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration sits on a soft rounded backdrop for depth.
          AspectRatio(
            aspectRatio: 320 / 260,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(kRadiusLg),
                boxShadow: kCardShadow,
              ),
              padding: const EdgeInsets.all(20),
              child: SvgPicture.asset(slide.asset, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 36),
          if (slide.isPremium) ...[
            const PremiumBadge(),
            const SizedBox(height: 14),
          ],
          Text(
            slide.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.subtitle,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
