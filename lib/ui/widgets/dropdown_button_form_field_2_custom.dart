import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SecondaryIdentificator {
  accounts,
  currencies,
  categories,
}

Map<SecondaryIdentificator, String> secondaryIdentificatorDictionary = {
  SecondaryIdentificator.accounts: 'icon_code_point',
  SecondaryIdentificator.currencies: 'symbol',
  SecondaryIdentificator.categories: 'icon_code_point',
};

class DropdownButtonFormField2Custom extends StatelessWidget {
  const DropdownButtonFormField2Custom({
    super.key,
    required this.value,
    required this.values,
    required this.onSelected,
    required this.widthRate,
    required this.label,
    required this.secondaryId,
    required this.onAddNewItem,
  });

  final int value;
  final List<Map<String, dynamic>> values;
  final void Function(int) onSelected;
  final double widthRate;
  final String label;
  final SecondaryIdentificator secondaryId;
  final Future<dynamic> Function() onAddNewItem;

  @override
  Widget build(BuildContext context) {
    final widthRateClamped = widthRate.clamp(6, 30) as double;
    //22 and 8 for half screen
    //30 and 12 for full screen
    return Expanded(
      child: DropdownButtonFormField2(
        selectedItemBuilder: (context) {
          if (values.isEmpty) {
            return [const DropdownMenuItem(child: Text('No items'))];
          }
          return values.map((account) {
            return DropdownMenuItem<int>(
              alignment: AlignmentGeometry.centerLeft,
              value: int.parse(account['id'].toString()),
              child: secondaryId == SecondaryIdentificator.currencies
                  ? Text(account['symbol'])
                  : Text(account['name']),
            );
          }).toList();
        },
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.lato(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: secondaryId == SecondaryIdentificator.currencies
              ? null
              : Padding(
                  padding: EdgeInsets.only(left: widthRateClamped * 0.5 - 3),
                  child: //
                  Icon(
                    IconData(
                      values.firstWhere(
                        (val) => val['id'] == value,
                      )['icon_code_point'],
                      fontFamily: 'MaterialIcons',
                      fontPackage: null,
                    ),
                  ),
                ),
          prefixIconConstraints: BoxConstraints(
            maxWidth: widthRateClamped,
          ),
          // suffixIcon: null,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            // horizontal: 30,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color.fromARGB(255, 241, 241, 244),
          ),
          isOverButton: false,
          offset: const Offset(0, -7),
        ),
        items: [
          ...values.map((val) {
            final isSelected = val['id'] == value;

            return DropdownMenuItem<int>(
              alignment: AlignmentGeometry.centerLeft,
              value: int.parse(val['id'].toString()),
              enabled: !isSelected,
              child: Row(
                children: [
                  if (secondaryId == SecondaryIdentificator.currencies)
                    Text(
                      val[secondaryIdentificatorDictionary[secondaryId]],
                      style: GoogleFonts.lato(
                        color: isSelected ? const Color(0xFFB3B3B8) : null,
                      ),
                    )
                  else ...[
                    Icon(
                      IconData(
                        val[secondaryIdentificatorDictionary[secondaryId]],
                        fontFamily: 'MaterialIcons',
                        fontPackage: null,
                      ),
                      color: isSelected ? const Color(0xFFB3B3B8) : null,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      val['name'],
                      style: GoogleFonts.lato(
                        color: isSelected ? const Color(0xFFB3B3B8) : null,
                      ),
                    ),
                  ],

                  // if (values.last == val)
                ],
              ),
            );
          }),
          // DropdownMenuItem<int>(
          //   alignment: AlignmentGeometry.centerLeft,
          //   enabled: true,

          //   child: Row(
          //     children: [
          //       Icon(
          //         Icons.add_circle_outline_rounded,
          //         color: Theme.of(context).colorScheme.primary,
          //       ),
          //       const SizedBox(width: 7),
          //       Text(
          //         'Add one',
          //         style: GoogleFonts.lato(
          //           color: Theme.of(context).colorScheme.primary,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
        onChanged: (value) {
          if (value != null) onSelected(value);
        },
      ),
    );
  }
}
