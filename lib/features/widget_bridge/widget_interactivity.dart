import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/widget_bridge/widget_service.dart';
import 'package:flutter/widgets.dart';

/// Runs in a background isolate (no UI) when a home-screen widget button is
/// tapped via the native App Intent. Adds a quick expense using sensible
/// defaults — first account, base currency, first category — WITHOUT opening
/// the app, then refreshes the widget.
///
/// URI shape: `financeapp://quickadd?amount=5`
@pragma('vm:entry-point')
Future<void> widgetInteractiveCallback(Uri? uri) async {
  if (uri == null || uri.host != 'quickadd') return;

  final amount = double.tryParse(uri.queryParameters['amount'] ?? '');
  if (amount == null || amount <= 0) return;

  // The callback runs in a fresh isolate: bootstrap the binding + DI here.
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  try {
    final accounts = await getIt<AccountRepository>().getAll();
    final base = await getIt<CurrencyRepository>().getBase();
    final categories = await getIt<CategoryRepository>().getAll();
    if (accounts.isEmpty || base == null || categories.isEmpty) return;

    await getIt<TransactionRepository>().add(
      accountId: accounts.first.id,
      categoryId: categories.first.id,
      currencyId: base.currencyId,
      amount: amount,
      date: DateTime.now(),
      note: 'Quick add',
      type: 'expense',
    );

    await getIt<WidgetService>().publishOnce();
  } catch (e, st) {
    debugPrint('widgetInteractiveCallback error: $e\n$st');
  }
}
