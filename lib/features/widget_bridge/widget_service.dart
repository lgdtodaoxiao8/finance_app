import 'dart:async';
import 'dart:convert';

import 'package:finance_app/core/preferences/app_preferences.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/widget_bridge/widget_snapshot.dart';
import 'package:finance_app/features/widget_config/data/widget_shortcut.dart';
import 'package:finance_app/models/main_model.dart';
// foundation also exports a `Category` annotation; hide it so ours wins.
import 'package:flutter/foundation.dart' hide Category;
import 'package:home_widget/home_widget.dart';

/// Keeps the native home-screen widget in sync with the app's data.
///
/// Subscribes to the reactive transaction + currency streams, recomputes a
/// compact [WidgetSnapshot], writes it to the shared store and asks the OS to
/// redraw the widget — so the widget updates automatically whenever a
/// transaction is added/edited/deleted anywhere (incl. the quick-add flow).
class WidgetService {
  WidgetService(
    this._transactionRepository,
    this._currencyRepository,
    this._categoryRepository,
    this._preferences,
  );

  final TransactionRepository _transactionRepository;
  final CurrencyRepository _currencyRepository;
  final CategoryRepository _categoryRepository;
  final AppPreferences _preferences;

  /// Native widget identifiers (must match the iOS/Android widget names).
  static const String iosWidgetName = 'FinanceWidget';
  static const String androidWidgetName = 'FinanceWidgetProvider';

  /// The configurable quick-add widget (its own WidgetKit kind).
  static const String iosQuickAddWidgetName = 'QuickAddWidget';

  /// iOS App Group shared between the app and the widget extension.
  /// Must match the App Group capability added to both the Runner and the
  /// widget-extension targets in Xcode.
  static const String appGroupId = 'group.com.lgdtodaoxiao.financeApp';

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

  /// Fetches the current data once and publishes a fresh snapshot. Used by the
  /// background interactivity callback (a separate isolate with no live stream).
  Future<void> publishOnce() async {
    _transactions = await _transactionRepository.getAllWithDetails();
    final currencies = await _currencyRepository.getAll();
    for (final c in currencies) {
      if (c.isBaseCurrency) {
        _baseSymbol = c.currencySymbol;
        break;
      }
    }
    await _publish();
  }

  Future<void> _publish() async {
    final snapshot = buildWidgetSnapshot(
      _transactions,
      baseSymbol: _baseSymbol,
    );
    final groups = _preferences.getWidgetGroups();
    final categories = await _categoryRepository.getAll();
    final byId = {for (final c in categories) c.categoryId: c};
    try {
      final writes = <Future<void>>[
        HomeWidget.saveWidgetData<double>('income', snapshot.income),
        HomeWidget.saveWidgetData<double>('expense', snapshot.expense),
        HomeWidget.saveWidgetData<double>('today', snapshot.todayExpense),
        HomeWidget.saveWidgetData<double>('balance', snapshot.balance),
        HomeWidget.saveWidgetData<String>('symbol', snapshot.baseSymbol),
        HomeWidget.saveWidgetData<String>(
          'categories',
          jsonEncode([
            for (final c in snapshot.topCategories)
              {
                'name': c.name,
                'value': c.value,
                'color': c.colorValue,
                'iconCode': c.iconCode,
              },
          ]),
        ),
        HomeWidget.saveWidgetData<String>(
          'recent',
          jsonEncode([
            for (final t in snapshot.recent)
              {
                'name': t.name,
                'amount': t.amount,
                'isExpense': t.isExpense,
                'color': t.colorValue,
                'iconCode': t.iconCode,
                'date': t.dateMs,
              },
          ]),
        ),
        // The list of groups the widget's "Edit Widget" picker offers.
        HomeWidget.saveWidgetData<String>(
          'widget_groups',
          jsonEncode([
            for (final g in groups) {'id': g.id, 'name': g.name},
          ]),
        ),
      ];
      // Each group's resolved shortcuts under its own key; the default group
      // also under the legacy `shortcuts` key so an unconfigured instance
      // still shows something.
      for (final g in groups) {
        final json = _resolveShortcutsJson(g.shortcuts, byId);
        writes.add(
          HomeWidget.saveWidgetData<String>('shortcuts.${g.id}', json),
        );
        if (g.id == AppPreferences.defaultWidgetGroupId) {
          writes.add(HomeWidget.saveWidgetData<String>('shortcuts', json));
        }
      }
      await Future.wait(writes);
      await HomeWidget.updateWidget(
        iOSName: iosWidgetName,
        androidName: androidWidgetName,
      );
      await HomeWidget.updateWidget(iOSName: iosQuickAddWidgetName);
    } catch (e) {
      // Native side not configured yet (e.g. no widget extension) — safe no-op.
      debugPrint('WidgetService._publish skipped: $e');
    }
  }

  /// Resolves configured [WidgetShortcut]s against the current categories into
  /// the compact JSON the native widget renders (colour + icon come from the
  /// category, so they always reflect the latest edits).
  String _resolveShortcutsJson(
    List<WidgetShortcut> shortcuts,
    Map<int, Category> byId,
  ) {
    final out = <Map<String, dynamic>>[];
    for (final s in shortcuts) {
      final category = byId[s.categoryId];
      if (category == null) continue;
      out.add({
        'id': s.id,
        'categoryId': s.categoryId,
        'name': category.categoryName,
        'iconCode': category.categoryIcon.codePoint,
        'color': category.categoryColor.toARGB32(),
        'iconColor': category.categoryIconColor.toARGB32(),
        'mode': s.mode.name,
        'amount': s.amount,
        'presets': s.presets,
      });
    }
    return jsonEncode(out);
  }

  Future<void> dispose() async {
    await _txSubscription?.cancel();
    await _currencySubscription?.cancel();
  }
}
