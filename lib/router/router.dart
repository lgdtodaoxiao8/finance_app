import 'package:finance_app/features/add_item/add_item.dart';
import 'package:finance_app/features/add_transaction/add_transaction.dart';
import 'package:finance_app/features/root_node/root_node.dart';

final routes = {
  '/': (ctx) => const RootNodeScreen(),
  '/add-transaction': (ctx) => const AddTransaction(),
  '/add-category': (ctx) => const AddCategoryScreen(),
  '/add-currency': (ctx) => const AddCurrencyScreen(),
  '/add-account': (ctx) => const AddAccountScreen(),
};
