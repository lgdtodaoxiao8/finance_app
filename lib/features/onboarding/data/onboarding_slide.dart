import 'package:finance_app/l10n/app_localizations.dart';

/// One page of the first-run marketing carousel.
class OnboardingSlide {
  const OnboardingSlide({
    required this.asset,
    required this.title,
    required this.subtitle,
    this.isPremium = false,
  });

  /// Path to the SVG illustration under `assets/illustrations/`.
  final String asset;
  final String title;
  final String subtitle;

  /// Marks a premium-teaser slide (shows a PREMIUM badge).
  final bool isPremium;
}

/// The marketing slides shown before base-currency setup, in the user's
/// language. Order matters.
List<OnboardingSlide> onboardingSlides(AppLocalizations l) => [
  OnboardingSlide(
    asset: 'assets/illustrations/onboarding_track.svg',
    title: l.onboardTrackTitle,
    subtitle: l.onboardTrackBody,
  ),
  OnboardingSlide(
    asset: 'assets/illustrations/onboarding_insights.svg',
    title: l.onboardInsightsTitle,
    subtitle: l.onboardInsightsBody,
  ),
  OnboardingSlide(
    asset: 'assets/illustrations/onboarding_ai.svg',
    title: l.onboardAiTitle,
    subtitle: l.onboardAiBody,
    isPremium: true,
  ),
];
