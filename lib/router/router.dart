import 'package:finance_app/features/add_item/add_item.dart';
import 'package:finance_app/features/add_transaction/add_transaction.dart';
import 'package:finance_app/features/finance_app/view/launch_gate.dart';
import 'package:finance_app/features/widget_config/view/widget_config_screen.dart';

final routes = {
  '/': (ctx) => const LaunchGate(),
  '/add-transaction': (ctx) => const AddTransaction(),
  '/add-category': (ctx) => const AddCategoryScreen(),
  '/add-currency': (ctx) => const AddCurrencyScreen(),
  '/add-account': (ctx) => const AddAccountScreen(),
  '/widget-config': (ctx) => const WidgetConfigScreen(),
};
