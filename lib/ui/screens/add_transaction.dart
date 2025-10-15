import 'package:finance_app/database/database_helper.dart';
import 'package:finance_app/ui/screens/add_item.dart';
// import 'package:finance_app/models/main_model.dart';
import 'package:finance_app/ui/widgets/compact_calendar.dart';
// import 'package:finance_app/ui/widgets/dropdown_button_form_field_2_custom.dart';
import 'package:finance_app/ui/widgets/popup_dropdown_special.dart';
import 'package:finance_app/ui/widgets/transaction_type_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddTransaction extends StatefulWidget {
  const AddTransaction({
    super.key,
    required this.accounts,
    required this.categories,
    required this.currencies,
    required this.pushToBase,
  });
  final Future<void> Function(Map<String, dynamic>) pushToBase;
  final List<Map<String, dynamic>> accounts;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> currencies;

  @override
  State<AddTransaction> createState() {
    return _AddTransactionState();
  }
}

class _AddTransactionState extends State<AddTransaction>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool isSending = false;

  final db = DatabaseHelper.instance;
  late final List<Map<String, dynamic>> accounts;
  late final List<Map<String, dynamic>> categories;
  late final List<Map<String, dynamic>> currencies;

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String transactionType = 'expense';

  int? accountId;
  int? accountDestinationId;

  int? categoryId;

  int? currencyId;

  DateTime transactionDate = DateTime.now();

  String? _error;

  @override
  void initState() {
    super.initState();
    accounts = widget.accounts;
    categories = widget.categories;
    currencies = widget.currencies;
    initialiseFields();
  }

  void initialiseFields() {
    if (accounts.isNotEmpty) {
      accountId = accounts.first['id'];
    } else {
      _error = 'You had no added any account';
    }

    if (accounts.length > 1) {
      accountDestinationId = accounts[1]['id'];
    } else {
      _error = 'You had no second account to transfer';
    }

    if (categories.isNotEmpty) {
      categoryId = categories.first['id'];
    } else {
      _error = 'You had no added any category';
    }

    if (currencies.isNotEmpty) {
      currencyId = currencies.first['id'];
    } else {
      _error = 'You have no added any currency';
    }
  }

  // Future<void> addNewItem() async {
  //   if (!mounted) return;
  //   final result = await showModalBottomSheet(
  //     useRootNavigator: true,
  //     context: context,
  //     builder: (context) {
  //       print('aaaa');
  //       return Center(
  //         child: Text('hello!'),
  //       );
  //     },
  //   );

  //   if (result == 200) {
  //     setState(() {});
  //   }
  // }

  Future<int> addNewItem(Tables tableType) async {
    if (!mounted) return -1;
    // await Future.microtask(() {});

    final result = await showModalBottomSheet(
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return AddItem(tableType: tableType);
      },
    );
    setState(() {
      //currencyId = result;
    });
    return result ?? -1;
  }

  Future<void> addTransaction() async {
    if (_formKey.currentState!.validate() && _error != null) {
      isSending = true;
      //if not transfer - not to put destination

      //convert amount in selected currency in account currency
      await widget.pushToBase({
        "account_id": accountId,
        if (transactionType == 'transfer')
          "account_destination_id": accountDestinationId,
        "category_id": categoryId,
        "currency_id": currencyId,
        "amount": double.parse(_amountController.text),
        "date": transactionDate.toUtc().toIso8601String(),
        "note": _noteController.text.trim(),
        "type": transactionType,
        "is_canceled": 0,
      });
      _amountController.clear();
      _noteController.clear();

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void onTypePicked(String type) {
    setState(() {
      transactionType = type;
    });
    initialiseFields();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.viewInsetsOf(context).bottom;

    if (accountId == accountDestinationId) {
      _error = 'Account departure and destination must be different';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + keyboardSpace),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      //transaction type setter
                      TransactionTypePicker(
                        initialValue: transactionType,
                        onSave: onTypePicked,
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      //departure account setter

                      // if (accounts.isEmpty || accountId == null)
                      //   const Center(
                      //     child: Text('You had no added any account'),
                      //   )
                      // else ...[

                      //dropdown button form field 2
                      //from-to fields

                      // Row(
                      //   children: [
                      //     //from
                      //     DropdownButtonFormField2Custom(
                      //       onAddNewItem: addNewItem,
                      //       value: transactionType == 'income'
                      //           ? categoryId!
                      //           : accountId!,
                      //       values: transactionType == 'income'
                      //           ? categories
                      //           : accounts,
                      //       widthRate: 22,
                      //       label: transactionType == 'income'
                      //           ? 'From category'
                      //           : 'From account',
                      //       onSelected: (int value) => setState(() {
                      //         if (transactionType == 'expense') {
                      //           accountId = value;
                      //         } else if (transactionType == 'income') {
                      //           categoryId = value;
                      //         } else if (transactionType == 'transfer') {
                      //           accountId = value;
                      //         }
                      //       }),
                      //       secondaryId: SecondaryIdentificator.accounts,
                      //     ),
                      //     const SizedBox(
                      //       width: 20,
                      //     ),
                      //     //to
                      //     DropdownButtonFormField2Custom(
                      //       onAddNewItem: addNewItem,
                      //       value: transactionType == 'expense'
                      //           ? categoryId!
                      //           : transactionType == 'transfer'
                      //           ? accountDestinationId!
                      //           : accountId!,
                      //       values: transactionType == 'expense'
                      //           ? categories
                      //           : accounts,
                      //       widthRate: 22,
                      //       label: transactionType == 'expense'
                      //           ? 'To category'
                      //           : 'To account',
                      //       onSelected: (int value) => setState(() {
                      //         if (transactionType == 'expense') {
                      //           categoryId = value;
                      //         } else if (transactionType == 'income') {
                      //           accountId = value;
                      //         } else if (transactionType == 'transfer') {
                      //           accountDestinationId = value;
                      //         }
                      //       }),
                      //       secondaryId: SecondaryIdentificator.accounts,
                      //     ),
                      //   ],
                      // ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          //from
                          PopupDropdownSpecial(
                            onAddNew: addNewItem,
                            tableType: transactionType == 'income'
                                ? Tables.category
                                : Tables.account,
                            currentValue: transactionType == 'income'
                                ? categoryId!
                                : accountId!,
                            label: transactionType == 'income'
                                ? 'From category'
                                : 'From account',
                            values: transactionType == 'income'
                                ? categories
                                : accounts,
                            onSelect: (int value) => setState(() {
                              if (transactionType == 'income') {
                                categoryId = value;
                              } else {
                                accountId = value;
                              }
                            }),
                          ),

                          const SizedBox(
                            width: 20,
                          ),

                          //to
                          PopupDropdownSpecial(
                            onAddNew: addNewItem,
                            tableType: transactionType == 'expense'
                                ? Tables.category
                                : Tables.account,
                            currentValue: transactionType == 'transfer'
                                ? accountDestinationId!
                                : transactionType == 'expense'
                                ? categoryId!
                                : accountId!,
                            values: transactionType == 'expense'
                                ? categories
                                : accounts,
                            label: transactionType == 'expense'
                                ? 'To category'
                                : 'To account',
                            onSelect: (int value) => setState(() {
                              if (transactionType == 'income') {
                                accountId = value;
                              } else if (transactionType == 'expense') {
                                categoryId = value;
                              } else {
                                accountDestinationId = value;
                              }
                            }),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      //amount and currency setter
                      Row(
                        children: [
                          //amount setter
                          Expanded(
                            child: TextFormField(
                              autocorrect: false,
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                labelStyle: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              controller: _amountController,
                              // autofocus: true,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.lato(
                                // fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    double.tryParse(value) == null ||
                                    double.tryParse(value)! <= 0) {
                                  return 'amount must be more than 0';
                                }
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(width: 20),

                          //currency setter
                          PopupDropdownSpecial(
                            onAddNew: addNewItem,
                            tableType: Tables.currency,
                            currentValue: currencyId!,
                            //predict the case where currencyId and other must be null(noone in database)
                            onSelect: (int value) => setState(() {}),
                            values: currencies,
                            label: 'Currency',
                          ),

                          // if (currencies.isNotEmpty)

                          // DropdownButtonFormField2Custom(
                          //   onAddNewItem: addNewItem,
                          //   value: currencyId!,
                          //   values: [
                          //     ...currencies,
                          //     Currency(
                          //       currencyId: 2,
                          //       currencyCode: 'code',
                          //       currencySymbol: '\$',
                          //       currencyRateToBase: 0.00181818,
                          //     ).toMap(),
                          //     Currency(
                          //       currencyId: 3,
                          //       currencyCode: 'code',
                          //       currencySymbol: '€',
                          //       currencyRateToBase: 0.00147058,
                          //     ).toMap(),
                          //   ],
                          //   onSelected: (value) =>
                          //       setState(() => currencyId = value),
                          //   widthRate: 22,
                          //   label: 'Currency',
                          //   secondaryId: SecondaryIdentificator.currencies,
                          // ),

                          // else
                          //   const Center(
                          //     child: Text('You have no added any currency'),
                          //   ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //note setter
                          Expanded(
                            flex: 5,
                            child: TextFormField(
                              maxLength: 50,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.note),
                                labelText: 'Note',
                                labelStyle: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              controller: _noteController,
                              keyboardType: TextInputType.text,
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

                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isSending
                                ? null
                                : () {
                                    Navigator.of(context).pop();
                                  },
                            child: const Text('Cancel'),
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
                                : const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
