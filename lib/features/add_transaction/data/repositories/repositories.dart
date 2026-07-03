import 'package:finance_app/features/add_transaction/data/data.dart';
import 'package:finance_app/models/main_model.dart';

Future<List<Currency>> fetchCurrenciesObjectsList() async {
  final futureList = await fetchCurrenciesFutureListFromBase();
  List<Currency> currenciesList = [];
  for (final map in futureList) {
    currenciesList.add(Currency.fromMap(map));
  }
  return currenciesList;
}

Future<List<Account>> fetchAccountsObjectsList() async {
  final futureList = await fetchAccountsFutureListFromBase();
  List<Account> accountsList = [];
  for (final map in futureList) {
    accountsList.add(Account.fromMap(map));
  }
  return accountsList;
}
