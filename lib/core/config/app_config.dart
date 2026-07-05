/// Deployment-specific endpoints the app owner must set before shipping.
///
/// Everything the app talks to on the network lives here so there's a single
/// place to point at your real infrastructure. Replace the placeholder domain
/// below with yours.
class AppConfig {
  AppConfig._();

  /// Your marketing + billing website.
  ///
  /// Subscriptions are sold here (on the web) rather than through in-app
  /// purchase, so Apple's 30% cut doesn't apply. The in-app "Upgrade" button
  /// just opens the pricing page in the browser.
  static const String webBaseUrl = 'https://your-domain.example';

  /// Pricing / checkout page opened by the in-app Upgrade button.
  static String get pricingUrl => '$webBaseUrl/pricing';

  /// Backend API root used for account auth and sync (Phase 4 steps 3–4).
  static const String apiBaseUrl = 'https://your-domain.example/api';
}
