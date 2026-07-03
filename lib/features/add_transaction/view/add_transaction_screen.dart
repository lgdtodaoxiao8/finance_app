import 'package:finance_app/database/database_helper.dart';
import 'package:finance_app/features/add_item/widgets/custom_text_field.dart';
import 'package:finance_app/features/add_transaction/widgets/widgets.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/features/add_transaction/data/data.dart';

import 'package:finance_app/theme/theme.dart';

class AddTransaction extends StatefulWidget {
  const AddTransaction({super.key});

  @override
  State<AddTransaction> createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> {
  bool isSending = false;

  final db = DatabaseHelper.instance;
  List<Map<String, dynamic>> accounts = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> currencies = [];
  List<Currency> currenciesObjetsList = [];
  List<Account> accountsObjectsList = [];

  late Future isLoadingDone;

  String transactionType = 'expense';
  int transactionTypeIndex = 0;

  int? accountId;
  int? accountDestinationId;

  int? categoryId;

  int? currencyId;

  DateTime transactionDate = DateTime.now();

  String? _error;

  @override
  void initState() {
    super.initState();
    isLoadingDone = fetchDataFromBase();
  }

  Future fetchDataFromBase() async {
    try {
      await db.database;

      final fetchedCurrencies = await db.getCurrenciesWithRate();
      final fetchedAccounts = await db.getAll("accounts");
      final fetchedCategories = await db.getAll("categories");
      final fetchedCurrenciesObjectList = await fetchCurrenciesObjectsList();
      final fetchedAccountsObjectList = await fetchAccountsObjectsList();

      setState(() {
        currencies = fetchedCurrencies;
        currenciesObjetsList = fetchedCurrenciesObjectList;
        accounts = fetchedAccounts;
        accountsObjectsList = fetchedAccountsObjectList;
        categories = fetchedCategories;
      });

      initialiseFields();
    } catch (e, st) {
      debugPrint('fetchDataFromBase error: $e\n$st');
      _error = 'Failed to load data';
    }
  }

  Future fetchCategoriesFromBase() async {
    try {
      await db.database;

      final fetchedCategories = await db.getAll("categories");

      setState(() {
        categories = fetchedCategories;
      });
    } catch (e, st) {
      debugPrint('fetchDataFromBase error: $e\n$st');
      _error = 'Failed to load categories data';
    }
  }

  // Future fetchAccountsFromBase() async {
  //   try {
  //     await db.database;

  //     final fetchedAccounts = await db.getAll("accounts");

  //     setState(() {
  //       accounts = fetchedAccounts;
  //     });
  //   } catch (e, st) {
  //     debugPrint('fetchDataFromBase error: $e\n$st');
  //     _error = 'Failed to load accounts data';
  //   }
  // }

  // Future fetchCurrenciesFromBase() async {
  //   try {
  //     await db.database;

  //     final fetchedCurrencies = await db.getCurrenciesWithRate();

  //     setState(() {
  //       currencies = fetchedCurrencies;
  //     });
  //   } catch (e, st) {
  //     debugPrint('fetchDataFromBase error: $e\n$st');
  //     _error = 'Failed to load currencies data';
  //   }
  // }

  Future<void> fetchCurrenciesFromBase() async {
    try {
      final fetchedCurrencies = await fetchCurrenciesObjectsList();
      setState(() {
        currenciesObjetsList = fetchedCurrencies;
      });
    } catch (e, st) {
      debugPrint('faild reason: $e : $st');
    }
  }

  Future<void> fetchAccountsFromBase() async {
    final fetchedAccounts = await fetchAccountsObjectsList();
    setState(() {
      accountsObjectsList = fetchedAccounts;
    });
  }

  void initialiseFields() {
    if (accountsObjectsList.isNotEmpty) {
      accountId = accountsObjectsList.first.id;
    } else {
      _error = 'You had no added any account';
    }

    if (accountsObjectsList.length > 1) {
      accountDestinationId = accountsObjectsList
          .second
          ?.id; // add try-catch here and in similar cases
    } else if (transactionType == 'transfer') {
      _error = 'You had no second account to transfer';
    }

    if (categories.isNotEmpty) {
      categoryId = categories.first['id'];
    } else {
      _error = 'You had no added any category';
    }

    if (currenciesObjetsList.isNotEmpty) {
      currencyId = currenciesObjetsList.first.id;
    } else {
      _error = 'You have no added any currency';
    }
  }

  Future<int> addNewCategory() async {
    if (!mounted) return -1;

    final id = await Navigator.of(context).pushNamed('/add-category');

    if (id != null && id is int && id > 0) {
      await fetchCategoriesFromBase();
      return id;
    }
    return -1;
  }

  Future<int> addNewCurrency() async {
    if (!mounted) return -1;

    final id = await Navigator.of(context).pushNamed('/add-currency');
    if (id != null && id is int && id > 0) {
      await fetchCurrenciesFromBase();

      return id;
    }

    return -1;
  }

  Future<int> addNewAccount() async {
    if (!mounted) return -1;

    final id = await Navigator.of(context).pushNamed('/add-account');

    if (id != null && id is int && id > 0) {
      await fetchAccountsFromBase();
      return id;
    }

    return -1;
  }

  Future<void> addTransaction() async {
    final amountIsValid = _amountKey.currentState?.validate() ?? false;
    final transferValid =
        transactionType != 'transfer' || accountDestinationId != null;

    if (amountIsValid &&
        transferValid &&
        _error == null &&
        currencyId != null &&
        accountId != null &&
        categoryId != null) {
      setState(() {
        isSending = true;
      });

      try {
        await db.database;

        await db.insert("transactions", {
          "account_id": accountId,
          if (transactionType == 'transfer')
            "account_destination_id": accountDestinationId,
          "category_id": categoryId,
          "currency_id": currencyId,
          "amount": double.parse(_amountKey.currentState!.text),
          "date": transactionDate.toUtc().toIso8601String(),
          "note": _noteKey.currentState!.text,
          "type": transactionType,
          "is_canceled": 0,
        });

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e, st) {
        debugPrint('Error to push new transaction to DB: $e\n$st');
        return;
      }
    }
  }

  void onTypePicked(String type, int index) {
    setState(() {
      transactionType = type;
      transactionTypeIndex = index;
      // Only ensure a destination account exists for transfers — do not
      // clobber the user's already-chosen account/category/currency.
      if (type == 'transfer' &&
          accountDestinationId == null &&
          accountsObjectsList.length > 1) {
        accountDestinationId = accountsObjectsList.second?.id;
      }
    });
  }

  void onSelectCategory(int value) => setState(() {
    categoryId = value;
    //make validate field
  });

  void onSelectCurrency(int value) => setState(() {
    currencyId = value;
  });

  void onSelectAccount(int value) => setState(() {
    accountId = value;
  });

  void onSelectAccountDestination(int value) => setState(() {
    accountDestinationId = value;
  });

  final _amountKey = GlobalKey<CustomTextFieldState>();

  String? amountValidate(String value) {
    if (double.tryParse(value) == null) {
      return 'Must be a number';
    } else if (value.isEmpty || double.tryParse(value)! <= 0) {
      return 'Must be more than 0';
    }
    return null;
  }

  final _noteKey = GlobalKey<CustomTextFieldState>();

  bool isActive = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Transaction', style: kTextStyle.copyWith()),
      ),
      body: FutureBuilder(
        future: isLoadingDone,
        builder: (context, asyncSnapshot) {
          if (asyncSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (asyncSnapshot.hasError) {
            debugPrint('${asyncSnapshot.error}');
            return Center(
              child: Text(
                'Something went wrong',
                style: kTextStyle.copyWith(),
                softWrap: true,
              ),
            );
          }

          final keyboardSpace = MediaQuery.viewInsetsOf(context).bottom;

          if (accountId == accountDestinationId &&
              transactionType == 'transfer') {
            _error = 'Account departure and destination must be different';
          } else if (_error ==
              'Account departure and destination must be different') {
            // Clear the transfer-specific error once the accounts differ,
            // otherwise it stays sticky and blocks saving.
            _error = null;
          }
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + keyboardSpace),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  //transaction type setter
                  TransactionTypePicker(
                    initialValue: transactionType,
                    onSave: onTypePicked,
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  // const SizedBox(height: 10),
                  IndexedStack(
                    index: transactionTypeIndex,
                    children: [
                      AddExpense(
                        addNewAccount: addNewAccount,
                        addNewCategory: addNewCategory,
                        initialAccountId: accountId,
                        initialCategoryId: categoryId,
                        accountsList: accounts,
                        categoriesList: categories,
                        onSelectAccount: onSelectAccount,
                        onSelectCategory: onSelectCategory,
                      ),
                      AddIncome(
                        addNewCategory: addNewCategory,
                        addNewAccount: addNewAccount,
                        initialCategoryId: categoryId,
                        initialAccountId: accountId,
                        categoriesList: categories,
                        accountsList: accounts,
                        onSelectCategory: onSelectCategory,
                        onSelectAccount: onSelectAccount,
                      ),
                      AddTransfer(
                        addNewAccount: addNewAccount,
                        initialAccountId: accountId,
                        initialAccountDestinationId: accountDestinationId,
                        accountsList: accounts,
                        onSelectAccount: onSelectAccount,
                        onSelectAccountDestination: onSelectAccountDestination,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  //amount and currency setter
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //amount setter
                      Expanded(
                        child: CustomTextField(
                          key: _amountKey,
                          shadowRadis: 3,
                          errorTextPadding: const EdgeInsetsGeometry.symmetric(
                            horizontal: 10,
                          ),
                          fieldBorderRadius: 15,
                          fieldFontSize: 15,
                          textPadding: const EdgeInsetsGeometry.symmetric(
                            horizontal: 12,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          hint: 'Amount',
                          validate: amountValidate,
                        ),
                      ),

                      const SizedBox(width: 20),

                      //currency setter
                      PopupDropdownObject(
                        currentValue: currencyId,
                        onSelect: onSelectCurrency,
                        onAddNew: addNewCurrency,
                        values: currenciesObjetsList,
                        label: 'Currency',
                      ),
                      // PopupDropdown(
                      //   borderCircularRadius: 15,
                      //   onAddNew: addNewCurrency,
                      //   tableType: Tables.currency,
                      //   currentValue: currencyId,
                      //   values: currencies,
                      //   label: 'Currency',
                      //   onSelect: onSelectCurrency,
                      // ),
                    ],
                  ),

                  const SizedBox(height: 5),
                  Row(
                    children: [
                      //note setter
                      Expanded(
                        flex: 3,
                        child: CustomTextField(
                          key: _noteKey,
                          hint: 'Note',
                          prefixIcon: Icons.note,
                          prefixIconColor: const Color(0xFF40434A),
                          prefixIconSize: 23,
                          shadowRadis: 3,
                          errorTextPadding: const EdgeInsetsGeometry.symmetric(
                            horizontal: 10,
                          ),
                          fieldBorderRadius: 15,
                          fieldFontSize: 15,
                          textPadding: EdgeInsetsGeometry.zero,
                          prefixPadding: EdgeInsetsGeometry.zero,
                        ),
                      ),

                      const SizedBox(width: 20),

                      //date picker
                      Expanded(
                        flex: 2,
                        child: DatePickerField(
                          context: context,
                          value: transactionDate,
                          onChanged: (value) =>
                              setState(() => transactionDate = value),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSending
                            ? null
                            : () {
                                Navigator.of(context).pop();
                              },
                        child: Text(
                          'Cancel',
                          style: kTextStyle.copyWith(),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                        ),
                        onPressed: isSending ? null : addTransaction,
                        child: isSending
                            ? const CircularProgressIndicator()
                            : Text(
                                'Add',
                                style: kTextStyle.copyWith(),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
