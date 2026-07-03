import 'package:finance_app/database/database_helper.dart';
import 'package:finance_app/features/add_item/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/theme/theme.dart';

class AddCurrencyScreen extends StatefulWidget {
  const AddCurrencyScreen({
    super.key,
  });
  @override
  State<AddCurrencyScreen> createState() => _AddCurrencyScreenState();
}

class _AddCurrencyScreenState extends State<AddCurrencyScreen> {
  double _rateToBase = 0;

  final _rateKey = GlobalKey<CustomTextFieldState>();

  final db = DatabaseHelper.instance;

  int? _currencyId;
  String? defaultCurrencySymbol;

  late Future<List<Map<String, dynamic>>> _currencyListFuture;

  bool isSending = false;
  bool baseIsNotSet = false;

  @override
  void initState() {
    super.initState();
    _currencyListFuture = fetchRateWithNull();
    // fetchDefaultCurrency();
  }

  Future<List<Map<String, dynamic>>> fetchRateWithNull() async {
    try {
      await db.database;

      final currencyList = await db.getCurrenciesWithNullRate();
      initializeCurrency(currencyList);

      await fetchDefaultCurrency();

      return currencyList;
    } catch (e, st) {
      debugPrint('Faild to fetch currencies with null rate: $e\n$st');
      return [];
    }
  }

  // Future<List<Map<String, dynamic>>> fetchDefaultCurrency() async {
  Future fetchDefaultCurrency() async {
    try {
      await db.database;

      final baseCurrency = await db.getDefaultCurrency();
      if (baseCurrency.isEmpty) {
        setState(() {
          baseIsNotSet = true;
        });
      } else {
        defaultCurrencySymbol = baseCurrency.first['symbol'];
      }
      //else ... work out the case when default currensy wasn't set

      // return baseCurrency;
    } catch (e, st) {
      debugPrint('Faild to fetch base currency: $e\n$st');
    }
  }

  void initializeCurrency(List<Map<String, dynamic>> currenyList) {
    if (currenyList.isNotEmpty) {
      _currencyId = currenyList.first['id'];
    } //re-write all currency list in db
  }

  void updateCurrencyId(int value) {
    setState(() {
      _currencyId = value;
    });
  }

  void saveNewItem() async {
    final rateIsValid = _rateKey.currentState?.validate() ?? false;

    if (!rateIsValid && !baseIsNotSet) return;

    if (_currencyId case final id?) {
      try {
        setState(() {
          isSending = true;
        });

        if (baseIsNotSet) {
          await db.makeCurrencyBase(
            id,
          );
        } else {
          await db.setNewRate(_rateToBase, _currencyId!);
        }

        setState(() {
          isSending = false;
        });

        if (mounted) {
          Navigator.of(context).pop(_currencyId!);
          //return currency object instead id
        }
      } catch (e) {
        setState(() {
          isSending = false;
        });

        debugPrint("Error in add_currency_screen: $e");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Somethig went wrong with the adding new currency: $e",
                style: kTextStyle.copyWith(overflow: TextOverflow.visible),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  double? parseRateText(String text) {
    final normalized = text.replaceAll(',', '.');
    final value = double.tryParse(normalized);
    return value;
  }

  String? rateValidate(String text) {
    final value = parseRateText(text);
    if (value == null) return 'Must be a number';
    if (value <= 0) return 'Must be more than 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(
          baseIsNotSet ? 'Set Base Currency' : 'New Currency',
          style: kTextStyle.copyWith(
            fontSize: 22,
            color: const Color(0xFF242528),
          ),
        ),
      ),
      body: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: FutureBuilder(
            future: _currencyListFuture,
            builder: (context, asyncSnapshot) {
              if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (asyncSnapshot.hasError) {
                debugPrint(asyncSnapshot.error.toString());
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      'Something went wrong',
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PopupDropdownConstant(
                    currentId: _currencyId,
                    onSelect: updateCurrencyId,
                    values: asyncSnapshot.data,
                    label: 'All currencies',
                  ),

                  const SizedBox(height: 15),

                  if (!baseIsNotSet) ...[
                    CustomTextField(
                      key: _rateKey,
                      hint: 'e.g. 1.25 or 0.73',
                      label: 'Rate to base',
                      textPadding: const EdgeInsetsGeometry.symmetric(
                        horizontal: 10,
                      ),
                      fieldFontSize: 15,
                      errorTextPadding: const EdgeInsetsGeometry.symmetric(
                        horizontal: 15,
                        vertical: 4,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validate: rateValidate,
                      onChanged: () {
                        final text = _rateKey.currentState?.text ?? '';
                        final rate = parseRateText(text);
                        setState(() {
                          _rateToBase = rate ?? 0;
                        });
                      },
                      counterTextPadding: const EdgeInsetsGeometry.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      counter: _rateToBase > 0
                          ? '1 $defaultCurrencySymbol  is equal  ${_rateToBase % 1 == 0 ? _rateToBase.toInt() : _rateToBase.toDouble()} ${asyncSnapshot.data?.firstWhere((raw) => raw['id'] == _currencyId)['symbol']}'
                          : 'Exchange rate to base cur.',
                    ),

                    const SizedBox(height: 20),
                  ],
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
                        onPressed: isSending ? null : saveNewItem,
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
              );
            },
          ),
        ),
      ),
    );
  }
}
