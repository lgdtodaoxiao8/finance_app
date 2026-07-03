import 'package:finance_app/database/database_helper.dart';
import 'package:finance_app/features/add_item/widgets/widgets.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

class SetBaseCurrency extends StatefulWidget {
  const SetBaseCurrency({super.key});

  @override
  State<SetBaseCurrency> createState() => _SetBaseCurrencyState();
}

class _SetBaseCurrencyState extends State<SetBaseCurrency> {
  final db = DatabaseHelper.instance;

  final _rateKey = GlobalKey<CustomTextFieldState>();
  double? _rateToBase;

  String? defaultCurrencySymbol;

  int? _currencyId;
  late Future<List<Map<String, dynamic>>> _currencyListFuture;

  bool isSending = false;
  bool isSuccess = false;

  bool isFirstSetup = false;
  bool needToEnterRate =
      false; //if it's new currency and we already have old base currency

  @override
  void initState() {
    super.initState();
    _currencyListFuture = fetchFromDataBase();
  }

  Future<List<Map<String, dynamic>>> fetchFromDataBase() async {
    try {
      await db.database;

      final currencyList = await db.getAllCurrencies();
      final baseCurrency = await db.getDefaultCurrency();

      if (baseCurrency.isEmpty) {
        //maybe isEmpty is not correct way to check for absence

        //after some test no error has identified
        isFirstSetup = true;
        initializeCurrency(currencyList);
      } else {
        updateBaseCurrencySymbol(baseCurrency.first['symbol']);
        initializeCurrency(
          currencyList,
          baseCurrency: baseCurrency.first,
        );
      }
      return currencyList;
    } catch (e, st) {
      debugPrint('Faild to fetch currencies with null rate: $e\n$st');
      return [];
    }
  }

  void initializeCurrency(
    List<Map<String, dynamic>> currencyList, {
    Map<String, dynamic>? baseCurrency,
  }) {
    if (currencyList.isNotEmpty) {
      if (baseCurrency case final base?) {
        _currencyId = base['id'];
      } else {
        // _currencyId = currenyList.first['id']; // delete with else
      }
    }
  }

  void updateBaseCurrencySymbol(String? symbol) async {
    if (symbol case final symbol?) {
      defaultCurrencySymbol = symbol;
    }
  }

  void updateCurrencyId(int value) async {
    //if it's new cur so enter the exchange rate to old base

    //add the text information about it
    setState(() {
      _currencyId = value;
    });

    final rateRow = await db.getCurrencyRate(value);

    if (!isFirstSetup && rateRow.first['rate_to_base'] == null) {
      //show rate setter
      setState(() => needToEnterRate = true);
    } else {
      setState(() => needToEnterRate = false);
    }
  }

  void setDefault() async {
    //add checking for the rate validation and whether it is needed before saving
    //and if it needed so save it first

    final rateIsValid =
        _rateKey.currentState?.validate() ?? (needToEnterRate ? false : true);

    if (!rateIsValid) return;

    if (_currencyId case final id?) {
      try {
        setState(() {
          isSending = true;
          isSuccess = false;
        });

        final minimumWait = Future.delayed(const Duration(milliseconds: 500));

        final saveBaseCurrency = () async {
          final double? rate = _rateToBase;

          if (needToEnterRate) {
            if (rate != null) {
              await db.setNewRate(rate, _currencyId!);
            } else {
              throw Exception('Rate is null');
            }
          }

          await db.makeCurrencyBase(
            id,
          );

          final newSymbol = await db.getCurrencySymbol(id);
          updateBaseCurrencySymbol(newSymbol);
        }();

        await Future.wait([minimumWait, saveBaseCurrency]);

        setState(() {
          isSending = false;
          isSuccess = true;
          _currencyListFuture = fetchFromDataBase();
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              isSuccess = false;
            });
          }
        });
      } catch (e) {
        setState(() {
          isSending = false;
        });

        debugPrint("Error in setDefault: $e");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Somethig went wrong while setting default currency: $e",
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
    if (value == 0) return 'Can not be null';
    if (value < 0) return 'Can not be negative';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
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
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut, // Мягкое начало и конец
              child: ClipRect(
                // Обрезает содержимое, которое не влезает
                child: needToEnterRate
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: CustomTextField(
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
                          counterTextPadding:
                              const EdgeInsetsGeometry.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                          counter: (_rateToBase != null && _rateToBase! > 0)
                              ? '1 $defaultCurrencySymbol  is equal  ${_rateToBase! % 1 == 0 ? _rateToBase!.toInt() : _rateToBase!.toDouble()} ${asyncSnapshot.data?.firstWhere((raw) => raw['id'] == _currencyId)['symbol']}'
                              : 'Exchange rate to base cur.',
                        ),
                      )
                    : const SizedBox(width: double.infinity, height: 0),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isSending || isSuccess
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
                  onPressed: isSending || isSuccess ? () {} : setDefault,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isSending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : isSuccess
                        ? const Icon(
                            Icons.check_rounded,
                            key: ValueKey('success'),
                            color: Colors.white,
                          )
                        : Text(
                            "Add",
                            style: kTextStyle.copyWith(),
                            key: const ValueKey('default'),
                          ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
