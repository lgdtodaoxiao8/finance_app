import 'dart:async';

import 'package:finance_app/features/widget_bridge/widget_interactivity.dart';
import 'package:finance_app/router/router.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

class FinanceApp extends StatefulWidget {
  const FinanceApp({super.key});

  @override
  State<FinanceApp> createState() => _FinanceAppState();
}

class _FinanceAppState extends State<FinanceApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri?>? _widgetClickSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // App launched by tapping the home-screen widget.
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetLaunch);
    // App already running and the widget was tapped.
    _widgetClickSubscription = HomeWidget.widgetClicked.listen(
      _handleWidgetLaunch,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Persist any quick-adds the user queued from the widget while away.
    if (state == AppLifecycleState.resumed) {
      drainPendingQuickAdds();
    }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      theme: themeFromSeed,
      routes: routes,
    );
  }
}
