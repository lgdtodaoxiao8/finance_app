import 'package:finance_app/ui/widgets/popup_dropdown_custom.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/material.dart';

class AddItem extends StatefulWidget {
  const AddItem({
    super.key,
    required this.tableType,
  });

  final Tables tableType;

  @override
  State<AddItem> createState() => _AddItemState();
}

class _AddItemState extends State<AddItem> {
  Color _currentColor = Colors.blue;

  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Выберите цвет'),
          content: MaterialPicker(
            pickerColor: _currentColor,
            onColorChanged: (color) {
              setState(() => _currentColor = color);
            },
            // showLabel: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Готово'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              color: _currentColor,
              margin: const EdgeInsets.all(20),
            ),
            ElevatedButton(
              onPressed: _openColorPicker,
              child: const Text('Выбрать цвет'),
            ),
          ],
        ),
      ),
    );
  }
}
