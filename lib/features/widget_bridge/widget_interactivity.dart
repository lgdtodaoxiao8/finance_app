import 'dart:convert';

import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/widget_bridge/widget_service.dart';
import 'package:home_widget/home_widget.dart';

/// Key of the JSON array of `{categoryId, amount}` queued by the widget's
/// native quick-add buttons (see FinanceWidget.swift `QuickAddIntent`).
/// "Ask each time" shortcuts don't queue anything — they arrive as
/// `financeapp://quickadd?category=` deep links (widget Buttons can't open
/// the app on iOS 17, so the widget uses Link/widgetURL for those).
const String _pendingKey = 'pending_quickadd';

/// One entry queued by a widget button: which category to log into and how
/// much. Older builds queued bare numbers (`[5, 10]`); those are still parsed
/// and fall back to the first category.
class _PendingQuickAdd {
  const _PendingQuickAdd(this.categoryId, this.amount);

  final int? categoryId;
  final double amount;

  static _PendingQuickAdd? parse(dynamic raw) {
    if (raw is num) return _PendingQuickAdd(null, raw.toDouble());
    if (raw is Map) {
      final amount = (raw['amount'] as num?)?.toDouble() ?? 0;
      if (amount <= 0) return null;
      return _PendingQuickAdd((raw['categoryId'] as num?)?.toInt(), amount);
    }
    return null;
  }
}

/// Drains the quick-add queue written by the widget buttons: turns each queued
/// `{categoryId, amount}` into an expense (its category, or the first category
/// as a fallback; first account; base currency) and refreshes the widget.
/// Called at startup and whenever the app resumes, so a tap on the widget
/// persists without the user opening the app manually.
Future<void> drainPendingQuickAdds() async {
  final json = await HomeWidget.getWidgetData<String>(_pendingKey);
  if (json == null || json.isEmpty || json == '[]') return;

  List<dynamic> queued;
  try {
    queued = jsonDecode(json) as List<dynamic>;
  } catch (_) {
    await HomeWidget.saveWidgetData<String>(_pendingKey, '[]');
    return;
  }
  if (queued.isEmpty) return;

  final accounts = await getIt<AccountRepository>().getAll();
  final base = await getIt<CurrencyRepository>().getBase();
  final categories = await getIt<CategoryRepository>().getAll();

  // Always clear the queue so it can't pile up; if setup is incomplete we just
  // drop the pending items.
  await HomeWidget.saveWidgetData<String>(_pendingKey, '[]');
  if (accounts.isEmpty || base == null || categories.isEmpty) return;

  final byId = {for (final c in categories) c.id: c};
  final transactions = getIt<TransactionRepository>();
  for (final raw in queued) {
    final entry = _PendingQuickAdd.parse(raw);
    if (entry == null) continue;
    final category = byId[entry.categoryId] ?? categories.first;
    await transactions.add(
      accountId: accounts.first.id,
      categoryId: category.id,
      currencyId: base.currencyId,
      amount: entry.amount,
      date: DateTime.now(),
      note: 'Quick add',
      type: 'expense',
    );
  }

  await getIt<WidgetService>().publishOnce();
}
