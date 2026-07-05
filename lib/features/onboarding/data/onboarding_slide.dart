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

/// The marketing slides shown before base-currency setup. Order matters.
const onboardingSlides = <OnboardingSlide>[
  OnboardingSlide(
    asset: 'assets/illustrations/onboarding_track.svg',
    title: 'Track every spend',
    subtitle:
        'Log an expense in a couple of taps — even straight from your '
        'home-screen widget. No spreadsheet, no friction.',
  ),
  OnboardingSlide(
    asset: 'assets/illustrations/onboarding_insights.svg',
    title: 'See where your money goes',
    subtitle:
        'Clean charts and monthly breakdowns turn your history into insights '
        'you can actually act on.',
  ),
  OnboardingSlide(
    asset: 'assets/illustrations/onboarding_ai.svg',
    title: 'AI that plans ahead',
    subtitle:
        'Personal budget coaching, spending forecasts and smart alerts — your '
        'money on autopilot, powered by AI.',
    isPremium: true,
  ),
];
