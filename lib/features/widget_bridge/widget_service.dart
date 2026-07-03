import 'dart:async';
import 'dart:convert';

import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/widget_bridge/widget_snapshot.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Keeps the native home-screen widget in sync with the app's data.
///
/// Subscribes to the reactive transaction + currency streams, recomputes a
/// compact [WidgetSnapshot], writes it to the shared store and asks the OS to
/// redraw the widget — so the widget updates automatically whenever a
/// transaction is added/edited/deleted anywhere (incl. the quick-add flow).
class WidgetService {
  WidgetService(this._transactionRepository, this._currencyRepository);

  final TransactionRepository _transactionRepository;
  final CurrencyRepository _currencyRepository;

  /// Native widget identifiers (must match the iOS/Android widget names).
  static const String iosWidgetName = 'FinanceWidget';
  static const String androidWidgetName = 'FinanceWidgetProvider';

  /// iOS App Group shared between the app and the widget extension.
  /// Set the real value once the widget extension is created in Xcode.
  static const String appGroupId = 'group.finance.app.widget';

  StreamSubscription<List<TransactionDetails>>? _txSubscription;
  StreamSubscription<List<dynamic>>? _currencySubscription;

  List<TransactionDetails> _transactions = const [];
  String _baseSymbol = '';

  Future<void> start() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('WidgetService.setAppGroupId failed (native not set up?): $e');
    }

    _txSubscription = _transactionRepository.watchAllWithDetails().listen((
      transactions,
    ) {
      _transactions = transactions;
      _publish();
    });

    _currencySubscription = _currencyRepository.watchAll().listen((currencies) {
      for (final c in currencies) {
        if (c.isBaseCurrency) {
          _baseSymbol = c.currencySymbol;
          break;
        }
      }
      _publish();
    });
  }

  Future<void> _publish() async {
    final snapshot = buildWidgetSnapshot(_transactions, baseSymbol: _baseSymbol);
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<double>('income', snapshot.income),
        HomeWidget.saveWidgetData<double>('expense', snapshot.expense),
        HomeWidget.saveWidgetData<double>('balance', snapshot.balance),
        HomeWidget.saveWidgetData<String>('symbol', snapshot.baseSymbol),
        HomeWidget.saveWidgetData<String>(
          'categories',
          jsonEncode([
            for (final c in snapshot.topCategories)
              {'name': c.name, 'value': c.value, 'color': c.colorValue},
          ]),
        ),
      ]);
      await HomeWidget.updateWidget(
        iOSName: iosWidgetName,
        androidName: androidWidgetName,
      );
    } catch (e) {
      // Native side not configured yet (e.g. no widget extension) — safe no-op.
      debugPrint('WidgetService._publish skipped: $e');
    }
  }

  Future<void> dispose() async {
    await _txSubscription?.cancel();
    await _currencySubscription?.cancel();
  }
}
