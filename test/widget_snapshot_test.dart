import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/features/widget_bridge/widget_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionDetails _tx({
  required int id,
  required double amount,
  required String type,
  String? category,
  int? color,
  double rate = 1,
}) {
  return TransactionDetails(
    id: id,
    amount: amount,
    date: DateTime.now(),
    type: type,
    isCanceled: false,
    categoryName: category,
    categoryColorValue: color,
    currencyRateToBase: rate,
  );
}

void main() {
  test('buildWidgetSnapshot aggregates totals and top categories in base', () {
    final txs = [
      _tx(id: 1, amount: 10, type: 'income'),
      _tx(id: 2, amount: 42, type: 'expense', category: 'Food', color: 1),
      _tx(
        id: 3,
        amount: 3,
        type: 'expense',
        category: 'Food',
        color: 1,
        rate: 2,
      ),
      _tx(id: 4, amount: 4, type: 'expense', category: 'Transport', color: 2),
    ];

    final snapshot = buildWidgetSnapshot(txs, baseSymbol: r'$');

    expect(snapshot.income, 10);
    expect(snapshot.expense, 52); // 42 + 6 + 4
    expect(snapshot.balance, -42);
    expect(snapshot.baseSymbol, r'$');

    expect(snapshot.topCategories.length, 2);
    expect(snapshot.topCategories.first.name, 'Food');
    expect(snapshot.topCategories.first.value, 48); // 42 + (3 * 2)
    expect(snapshot.topCategories[1].name, 'Transport');
    expect(snapshot.topCategories[1].value, 4);
  });
}
