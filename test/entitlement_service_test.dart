import 'package:finance_app/core/preferences/app_preferences.dart';
import 'package:finance_app/features/auth/auth_service.dart';
import 'package:finance_app/features/subscription/entitlement_service.dart';
import 'package:finance_app/features/subscription/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('EntitlementService (backend not bound)', () {
    late SubscriptionService sub;
    late AuthService auth;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = AppPreferences(await SharedPreferences.getInstance());
      sub = SubscriptionService(prefs);
      auth = AuthService(); // never bound → isAvailable == false
    });

    tearDown(() => auth.dispose());

    test('bind is inert when the backend is off', () {
      final ent = EntitlementService(auth, sub);
      ent.bind(); // must not throw or touch premium
      expect(sub.isPremium.value, isFalse);
      ent.dispose();
    });

    test('refresh is a no-op while signed out — a debug toggle survives', () async {
      await sub.setPremium(true); // e.g. a debug long-press on the upsell card
      final ent = EntitlementService(auth, sub);
      await ent.refresh(); // no account → can't verify → leave the value alone
      expect(sub.isPremium.value, isTrue);
      ent.dispose();
    });
  });
}
