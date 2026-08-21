import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/features/accounts/account_math.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Account _acc(
  int id, {
  String kind = 'general',
  double? currentValue,
  double? rate,
}) => Account(
  accountId: id,
  accountName: 'A$id',
  currencyId: 1,
  accountIcon: Icons.wallet,
  accountKind: kind,
  currentValue: currentValue,
  interestRate: rate,
);

TransactionDetails _tx({
  required double amount,
  required String type,
  int? src,
  int? dst,
}) => TransactionDetails(
  id: 0,
  amount: amount,
  date: DateTime(2026),
  type: type,
  isCanceled: false,
  accountId: src,
  accountDestinationId: dst,
);

void main() {
  test('perAccountBalance sums income − expense and moves transfers', () {
    final accounts = [_acc(1), _acc(2)];
    final txns = [
      _tx(amount: 100, type: 'income', src: 1),
      _tx(amount: 30, type: 'expense', src: 1),
      _tx(amount: 50, type: 'transfer', src: 1, dst: 2),
    ];
    final bal = perAccountBalance(accounts, txns);
    expect(bal[1], 20); // 100 − 30 − 50
    expect(bal[2], 50);
  });

  test('net worth counts an investment by its current value, adding the gain', () {
    final accounts = [
      _acc(1),
      _acc(2, kind: 'investment', currentValue: 1500),
    ];
    final txns = [
      _tx(amount: 1000, type: 'income', src: 1),
      _tx(amount: 1000, type: 'transfer', src: 1, dst: 2),
    ];
    // cash 0 + investment value 1500 → 1500 (a 500 gain over the 1000 put in).
    expect(netWorth(accounts, txns), 1500);
    final bal = perAccountBalance(accounts, txns);
    expect(investmentReturn(accounts[1], bal[2]!), 500);
  });

  test('an investment without a set value falls back to contributions', () {
    final accounts = [_acc(1, kind: 'investment')];
    final txns = [_tx(amount: 800, type: 'income', src: 1)];
    expect(netWorth(accounts, txns), 800);
    expect(investmentReturn(accounts[0], 800), isNull);
  });

  test('annualInterest projects only for savings with a rate', () {
    expect(annualInterest(_acc(1, kind: 'savings', rate: 4), 2000), 80);
    expect(annualInterest(_acc(2), 2000), isNull); // general
    expect(annualInterest(_acc(3, kind: 'savings'), 2000), isNull); // no rate
  });
}
