import 'dart:async';

import 'package:finance_app/router/router.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

class FinanceApp extends StatefulWidget {
  const FinanceApp({super.key});

  @override
  State<FinanceApp> createState() => _FinanceAppState();
}

class _FinanceAppState extends State<FinanceApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri?>? _widgetClickSubscription;

  @override
  void initState() {
    super.initState();
    // App launched by tapping the home-screen widget.
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetLaunch);
    // App already running and the widget was tapped.
    _widgetClickSubscription = HomeWidget.widgetClicked.listen(
      _handleWidgetLaunch,
    );
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
