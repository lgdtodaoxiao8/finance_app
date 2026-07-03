import 'package:finance_app/database/database_helper.dart';
import 'package:finance_app/features/add_item/widgets/widgets.dart';
import 'package:finance_app/features/add_transaction/widgets/widgets.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final db = DatabaseHelper.instance;

  int? _currencyId;
  late Future<List<Map<String, dynamic>>> _currenciesList;

  IconData? _selectedIcon;

  bool isSending = false;

  @override
  void initState() {
    super.initState();
    _currenciesList = fetchCurrenciesWithRate();
  }

  Future<List<Map<String, dynamic>>> fetchCurrenciesWithRate() async {
    try {
      await db.database;

      final currencyList = await db.getCurrenciesWithRate();

      if (currencyList.isNotEmpty) {
        _currencyId = currencyList.first['id'];
      }

      return currencyList;
    } catch (e, st) {
      debugPrint('Faild to fetch currencies with rate: $e\n$st');
      return [];
    }
  }

  void updateIcon(IconData icon) {
    setState(() {
      _selectedIcon = icon;
    });
  }

  void updateCurrency(int id) {
    setState(() {
      _currencyId = id;
    });
  }

  void saveNewItem() async {
    final nameIsValid = _nameKey.currentState?.validate() ?? false;
    if (nameIsValid && _currencyId != null && _selectedIcon != null) {
      final nameText = _nameKey.currentState?.text;
      final iconCode = _selectedIcon!.codePoint;

      setState(() {
        isSending = true;
      });

      final response = await db.insert("accounts", {
        "name": nameText,
        "currency_id": _currencyId,
        "icon_code_point": iconCode,
      });

      setState(() {
        isSending = false;
      });

      if (mounted) {
        Navigator.of(context).pop<int>(response);
      }
    }
  }

  String? nameValidator(String value) {
    if (value.length < 4) {
      return 'Must be at least 4 characters long.';
    }
    if (value.length > 30) {
      return 'Maximum 30 characters long.';
    }
    return null;
  }

  Future<int> addNewCurrency() async {
    if (!mounted) return -1;

    await Navigator.of(context).pushNamed('/add-currency');

    return -1;
  }

  final _nameKey = GlobalKey<CustomTextFieldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'New Account',
          style: kTextStyle.copyWith(
            fontSize: 22,
            color: const Color(0xFF242528),
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ElevatedButton(
              onPressed: saveNewItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: Text('Add', style: kTextStyle.copyWith()),
            ),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _currenciesList,
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
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 13, 20, 20),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //replace with selfmade textField
                    // Container(
                    //   decoration: BoxDecoration(
                    //     color: const Color.fromARGB(255, 231, 231, 236),
                    //     borderRadius: BorderRadius.circular(20),
                    //   ),
                    //   padding: const EdgeInsets.symmetric(
                    //     vertical: 0,
                    //     horizontal: 8,
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       const SizedBox(width: 5),
                    //       Icon(
                    //         _selectedIcon,
                    //         size: 31,
                    //         color: Colors.black,
                    //       ),
                    //       Expanded(
                    //         child: TextField(
                    //           onTapOutside: (event) {
                    //             FocusScope.of(context).unfocus();
                    //           },
                    //           keyboardType: TextInputType.text,
                    //           controller: _nameController,
                    //           clipBehavior: Clip.hardEdge,
                    //           style: kTextStyle.copyWith(
                    //             fontSize: 19,
                    //             color: const Color(0xFF242528),
                    //             fontWeight: FontWeight.w500,
                    //           ),
                    //           onChanged: (event) {
                    //             if (_errorText == '') {
                    //               return;
                    //             }
                    //             _validate;
                    //           },
                    //           decoration: InputDecoration(
                    //             border: const OutlineInputBorder(
                    //               borderSide: BorderSide.none,
                    //             ),
                    //             hintText: 'Name',
                    //             labelStyle: kTextStyle.copyWith(
                    //               fontSize: 15,
                    //               color: const Color.fromARGB(
                    //                 255,
                    //                 77,
                    //                 78,
                    //                 81,
                    //               ),
                    //               fontWeight: FontWeight.w400,
                    //             ),
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(
                    //     horizontal: 20,
                    //     vertical: 0,
                    //   ),
                    //   child: Text(
                    //     _errorText ?? '',
                    //     style: kTextStyle.copyWith(
                    //       color: Colors.red[900],
                    //       fontSize: 13,
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.all(2),
                      child: CustomTextField(
                        key: _nameKey,
                        errorTextPadding: const EdgeInsetsGeometry.only(
                          left: 20,
                          top: 3,
                        ),
                        prefixIcon: _selectedIcon,
                        prefixPadding: EdgeInsetsGeometry.zero,
                        prefixIconColor: const Color(0xFF202020),
                        validate: nameValidator,
                        hint: 'Name',
                      ),
                    ),

                    Divider(
                      height: 2,
                      thickness: 2,
                      color: Theme.of(context).dividerColor,
                      indent: 25,
                      endIndent: 25,
                    ),

                    const SizedBox(height: 12),

                    PopupDropdown(
                      expand: true,
                      borderCircularRadius: 20,
                      colorFilling: const Color(0xFFEDEDF2),
                      currentValue: _currencyId,
                      tableType: Tables.currency,
                      onSelect: updateCurrency,
                      onAddNew: addNewCurrency,
                      values: asyncSnapshot.data,
                      label: 'Account currency',
                    ),
                    const SizedBox(height: 15),

                    IconPicker(onSelectIcon: updateIcon),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
