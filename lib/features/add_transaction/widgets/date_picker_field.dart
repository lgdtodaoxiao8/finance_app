import 'dart:io';

import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:intl/intl.dart';

class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.onChanged,
    required this.context,
    required this.value,
  });

  final Function(DateTime) onChanged;
  final BuildContext context;

  final DateTime value;

  String _formatDate(DateTime date) {
    return DateFormat(
      'd MMM HH:mm',
      Localizations.localeOf(context).toString(),
    ).format(date);
  }

  Future<void> _pickDate() async {
    final DateTime dateNow = DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: dateNow.copyWith(year: dateNow.year - 20),
      lastDate: dateNow,
    );

    if (newDate != null) {
      // Сохраняем время из исходного value при выборе новой даты
      final newDateTime = DateTime(
        newDate.year,
        newDate.month,
        newDate.day,
        value.hour,
        value.minute,
        value.second,
      );
      onChanged(newDateTime);
    }
  }

  void _cupertinoPickDateTime() {
    final dateNow = DateTime.now();
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    AppLocalizations.of(context).done,
                    style: kTextStyle.copyWith(),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: value,
                  minimumDate: dateNow.copyWith(year: dateNow.year - 20),
                  maximumDate: dateNow,
                  onDateTimeChanged: (DateTime newDateTime) {
                    onChanged(newDateTime);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          const BoxShadow(
            blurRadius: 3,
            color: Colors.black12,
          ),
        ],
        color: themeFromSeed.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextButton.icon(
        onPressed: Platform.isIOS ? _cupertinoPickDateTime : _pickDate,
        icon: const Icon(Icons.calendar_today, size: 18),
        label: Text(
          _formatDate(value),
          style: kTextStyle.copyWith(overflow: TextOverflow.visible),
        ),

        style: TextButton.styleFrom(
          shadowColor: Colors.black26,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: themeFromSeed.scaffoldBackgroundColor,
          // backgroundColor: const Color(0XFFDBE2F9),
          // backgroundColor: const Color(0XFFE2E2E9),
          foregroundColor: const Color.fromARGB(255, 64, 65, 69),
        ),
      ),
    );
  }
}
