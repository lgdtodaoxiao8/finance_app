// import 'package:currency_picker/currency_picker.dart';
import 'package:finance_app/database/database_helper.dart';
import 'package:finance_app/ui/widgets/icon_picker.dart';
import 'package:finance_app/ui/widgets/popup_dropdown_special.dart';
import 'package:finance_app/ui/widgets/color_picker.dart';
import 'package:flutter/material.dart';

import 'package:finance_app/main.dart';

class AddItem extends StatefulWidget {
  const AddItem({
    super.key,
    required this.tableType,
  });

  final Tables tableType;

  // final static allCurensiesList = ;

  @override
  State<AddItem> createState() => _AddItemState();
}

class _AddItemState extends State<AddItem> {
  final _nameController = TextEditingController();
  final _rate_to_base = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final db = DatabaseHelper.instance;

  String previewText = 'Name';

  Color? _currentColor;

  IconData? _selectedIcon;

  // Currency? _selectedCurrency;

  void updateColor(Color value) {
    setState(() {
      _currentColor = value;
    });
  }

  void updateIcon(IconData icon) {
    setState(() {
      _selectedIcon = icon;
    });
  }

  void saveNewItem() {
    if (_formKey.currentState!.validate() &&
        _currentColor != null &&
        _selectedIcon != null) {
      if (widget.tableType == Tables.account) {}

      //save to bd
      //return the id back to add transaction screen
    }
  }

  Widget _newCategoryItem() => Column(
    children: [
      Row(
        children: [
          Container(
            width: 53,
            height: 53,
            decoration: BoxDecoration(
              color: _currentColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedIcon,
              size: 31,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              previewText,
              maxLines: 1,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: kTextStyle.copyWith(
                fontSize: 25,
                color: const Color(0xFF242528),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 20),

      Form(
        key: _formKey,
        child: TextFormField(
          onChanged: (value) {
            setState(() {
              if (_nameController.text == '') {
                previewText = 'Name';
              } else {
                previewText = _nameController.text;
              }
            });
          },

          keyboardType: TextInputType.text,
          controller: _nameController,
          clipBehavior: Clip.hardEdge,
          validator: (value) {
            if (value == null || value.trim().length < 4) {
              return 'Must be at least 4 characters long.';
            }
            if (value.length > 30) {
              return 'Maximum 30 characters long.';
            }
            return null;
          },
          style: kTextStyle.copyWith(
            fontSize: 16,
            color: const Color(0xFF242528),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            constraints: const BoxConstraints(maxHeight: 63),
            labelText: 'Name',
            labelStyle: kTextStyle.copyWith(
              fontSize: 15,
              color: const Color.fromARGB(255, 77, 78, 81),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),

      Divider(
        // готово и просто
        height: 2, // пространство, которое занимает Divider (вертикально)
        thickness: 2, // фактическая толщина линии
        color: Theme.of(context).dividerColor,
        indent: 25, // отступ слева
        endIndent: 25, // отступ справа
      ),

      const SizedBox(height: 10),

      ColorPicker(
        onColorChanged: updateColor,
      ),

      const SizedBox(height: 10),

      IconPicker(onSelectIcon: updateIcon),
    ],
  );

  Widget _newAccountItem() => Column();

  Widget _newCurrencyItem() => Column(
    children: [
      Form(
        key: _formKey,

        child: Column(
          children: [
            // ElevatedButton(
            //   onPressed: () {
            //     showCurrencyPicker(
            //       context: context,
            //       theme: CurrencyPickerThemeData(
            //         backgroundColor: Colors.grey[50],
            //         inputDecoration: InputDecoration(
            //           prefixIcon: const Icon(Icons.search, color: Colors.blue),
            //           hintText: 'Currency searching',
            //           hintStyle: kTextStyle.copyWith(color: Colors.grey),
            //           filled: true,
            //           fillColor: Colors.white,
            //           border: OutlineInputBorder(
            //             borderRadius: BorderRadius.circular(12),
            //             borderSide: BorderSide.none,
            //           ),
            //           // contentPadding: EdgeInsets.symmetric(
            //           //   horizontal: 16,
            //           //   vertical: 14,
            //           // ),
            //           suffixIcon: IconButton(
            //             icon: const Icon(Icons.close),
            //             onPressed: () {
            //               Navigator.of(context).pop();
            //             },
            //           ),
            //         ),
            //       ),
            //       onSelect: (Currency currency) {
            //         _selectedCurrency = currency;
            //         print(
            //           'Выбрана валюта: ${currency.name} (${currency.code})',
            //         );
            //       },
            //     );
            //   },
            //   child: const Text('currency picker'),
            // ),
            TextFormField(
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              controller: _rate_to_base,
              clipBehavior: Clip.hardEdge,
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    double.tryParse(value) == null ||
                    double.tryParse(value)! <= 0) {
                  return 'Rate must be more than 0';
                }
                return null;
              },
              style: kTextStyle.copyWith(
                fontSize: 16,
                color: const Color(0xFF242528),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                counterText: 'Exchange rate to the base currency',

                hintText: 'e.g. 1.25 or 0.73',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                constraints: const BoxConstraints(maxHeight: 63),
                labelText: 'Rate to base',
                labelStyle: kTextStyle.copyWith(
                  fontSize: 15,
                  color: const Color.fromARGB(255, 77, 78, 81),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            TextFormField(
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              controller: _rate_to_base,
              clipBehavior: Clip.hardEdge,
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    double.tryParse(value) == null ||
                    double.tryParse(value)! <= 0) {
                  return 'Rate must be more than 0';
                }
                return null;
              },
              style: kTextStyle.copyWith(
                fontSize: 16,
                color: const Color(0xFF242528),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                counterText: 'Exchange rate to the base currency',

                hintText: 'e.g. 1.25 or 0.73',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                constraints: const BoxConstraints(maxHeight: 63),
                labelText: 'Rate to base',
                labelStyle: kTextStyle.copyWith(
                  fontSize: 15,
                  color: const Color.fromARGB(255, 77, 78, 81),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'New ${widget.tableType.name}',
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
        body: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: widget.tableType == Tables.category
                ? _newCategoryItem()
                : widget.tableType == Tables.currency
                ? _newCurrencyItem()
                : Text(widget.tableType.name),
          ),
        ),
      ),
    );
  }
}
