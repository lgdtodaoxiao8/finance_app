import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/main.dart';
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
    return DateFormat('d MMM HH:mm', 'en_US').format(date).toString();
  }

  Future<void> _pickDate() async {
    final DateTime dateNow = DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: dateNow.copyWith(year: dateNow.year - 20),
      lastDate: dateNow,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
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
                  child: Text('Done', style: kTextStyle.copyWith()),
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
    return TextButton.icon(
      onPressed: Platform.isIOS ? _cupertinoPickDateTime : _pickDate,
      icon: const Icon(Icons.calendar_today, size: 18),
      label: Text(_formatDate(value), style: kTextStyle.copyWith()),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: const Color(0XFFE2E2E9),
        foregroundColor: const Color.fromARGB(255, 64, 65, 69),
      ),
    );
  }
}
