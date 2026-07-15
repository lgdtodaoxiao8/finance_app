import 'dart:async';

import 'package:finance_app/core/config/app_config.dart';
import 'package:finance_app/core/database/app_database.dart';
import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/settings/app_settings.dart';
import 'package:finance_app/core/settings/settings_service.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/features/auth/auth_service.dart';
import 'package:finance_app/features/subscription/subscription_service.dart';
import 'package:finance_app/features/sync/sync_service.dart';
import 'package:finance_app/features/widget_bridge/widget_interactivity.dart';
import 'package:finance_app/features/widget_bridge/widget_service.dart';
import 'package:finance_app/router/router.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceApp extends StatefulWidget {
  const FinanceApp({super.key});

  @override
  State<FinanceApp> createState() => _FinanceAppState();
}

class _FinanceAppState extends State<FinanceApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri?>? _widgetClickSubscription;
  StreamSubscription<dynamic>? _dbSubscription;
  Timer? _syncDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Everything network/IO-heavy runs after the first frame so opening the
    // app is instant.
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  /// Brings up the backend and background services off the launch critical
  /// path: Supabase (session refresh is a network call), home-widget
  /// publishing, queued quick-adds, live-change sync, and the first sync.
  Future<void> _bootstrap() async {
    if (AppConfig.isBackendConfigured) {
      try {
        await Supabase.initialize(
          url: AppConfig.supabaseUrl,
          publishableKey: AppConfig.supabasePublishableKey,
        );
        getIt<AuthService>().bind();
        // Re-sync whenever the signed-in account changes.
        getIt<AuthService>().currentUser.addListener(_autoSync);
      } catch (e) {
        debugPrint('Supabase init failed: $e');
      }
    }

    // start() sets the iOS App Group id; the widget-launch handlers below need
    // it, so they must run after this.
    await getIt<WidgetService>().start();
    await drainPendingQuickAdds();

    // App launched by tapping the home-screen widget (one-shot check).
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetLaunch);
    // App already running and the widget was tapped.
    _widgetClickSubscription = HomeWidget.widgetClicked.listen(
      _handleWidgetLaunch,
    );

    // Invisible auto-sync: push local edits shortly after they happen.
    _dbSubscription = getIt<AppDatabase>().tableUpdates().listen((_) {
      if (getIt<SyncService>().isSyncing.value) return;
      _syncDebounce?.cancel();
      _syncDebounce = Timer(const Duration(seconds: 2), _autoSync);
    });

    _autoSync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Persist any quick-adds the user queued from the widget while away,
      // then pull down anything that changed on other devices.
      drainPendingQuickAdds();
      _autoSync();
    }
  }

  /// Opportunistic cloud sync — only for signed-in premium users. Failures are
  /// swallowed: sync is best-effort and never blocks the UI.
  void _autoSync() {
    if (!getIt<SubscriptionService>().isPremium.value) return;
    getIt<SyncService>().sync().catchError((_) {});
  }

  /// Routes a home-widget deep link. `*://add` opens the quick add-transaction
  /// screen so a spend can be logged in a couple of taps.
  void _handleWidgetLaunch(Uri? uri) {
    if (uri == null) return;
    final wantsAdd = uri.host == 'add' || uri.path.contains('add');
    if (!wantsAdd) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.pushNamed('/add-transaction');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _widgetClickSubscription?.cancel();
    _dbSubscription?.cancel();
    _syncDebounce?.cancel();
    getIt<AuthService>().currentUser.removeListener(_autoSync);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild the whole app when preferences change (theme, language) — the
    // values come from SettingsService, which is fed by local edits and cloud
    // sync alike.
    return ValueListenableBuilder<AppSettings>(
      valueListenable: getIt<SettingsService>().settings,
      builder: (context, settings, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          theme: themeFromSeed,
          darkTheme: darkThemeFromSeed,
          themeMode: settings.themeMode.material,
          locale: settings.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: routes,
        );
      },
    );
  }
}
