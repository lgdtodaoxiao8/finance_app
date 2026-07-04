import 'dart:convert';

import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/widget_bridge/widget_service.dart';
import 'package:home_widget/home_widget.dart';

/// Key of the JSON array of amounts queued by the widget's native quick-add
/// buttons (see FinanceWidget.swift `QuickAddIntent`).
const String _pendingKey = 'pending_quickadd';

/// Drains the quick-add queue written by the widget buttons: turns each queued
/// amount into an expense (first account, base currency, first category) and
/// refreshes the widget. Called at startup and whenever the app resumes, so a
/// tap on the widget persists without the user opening the app manually.
Future<void> drainPendingQuickAdds() async {
  final json = await HomeWidget.getWidgetData<String>(_pendingKey);
  if (json == null || json.isEmpty || json == '[]') return;

  List<dynamic> amounts;
  try {
    amounts = jsonDecode(json) as List<dynamic>;
  } catch (_) {
    await HomeWidget.saveWidgetData<String>(_pendingKey, '[]');
    return;
  }
  if (amounts.isEmpty) return;

  final accounts = await getIt<AccountRepository>().getAll();
  final base = await getIt<CurrencyRepository>().getBase();
  final categories = await getIt<CategoryRepository>().getAll();

  // Always clear the queue so it can't pile up; if setup is incomplete we just
  // drop the pending items.
  await HomeWidget.saveWidgetData<String>(_pendingKey, '[]');
  if (accounts.isEmpty || base == null || categories.isEmpty) return;

  final transactions = getIt<TransactionRepository>();
  for (final raw in amounts) {
    final amount = (raw as num?)?.toDouble() ?? 0;
    if (amount <= 0) continue;
    await transactions.add(
      accountId: accounts.first.id,
      categoryId: categories.first.id,
      currencyId: base.currencyId,
      amount: amount,
      date: DateTime.now(),
      note: 'Quick add',
      type: 'expense',
    );
  }

  await getIt<WidgetService>().publishOnce();
}
