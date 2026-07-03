import 'package:finance_app/database/database_helper.dart';
import 'package:finance_app/features/add_item/widgets/widgets.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final db = DatabaseHelper.instance;

  Color? _currentColor;
  Color? _currentIconColor;

  IconData? _selectedIcon;

  bool isSending = false;

  void updateColor(Color value) {
    setState(() {
      _currentColor = value;
    });
  }

  void updateIconColor(Color value) {
    setState(() {
      _currentIconColor = value;
    });
  }

  void updateIcon(IconData icon) {
    setState(() {
      _selectedIcon = icon;
    });
  }

  void saveNewItem() async {
    final nameIsValid = _nameKey.currentState?.validate() ?? false;
    if (nameIsValid && _currentColor != null && _selectedIcon != null) {
      final nameText = _nameKey.currentState?.text;
      final colorValue = _currentColor!.toARGB32();
      final iconColorValue = _currentIconColor!.toARGB32();
      final iconCode = _selectedIcon!.codePoint;

      setState(() {
        isSending = true;
      });

      final response = await db.insert("categories", {
        "name": nameText,
        "color": colorValue,
        "icon_color": iconColorValue,
        "icon_code_point": iconCode,
      });

      setState(() {
        isSending = false;
      });

      if (mounted) {
        Navigator.of(context).pop(response);
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
          'New Category',
          style: kTextStyle.copyWith(
            fontSize: 22,
            color: const Color(0xFF242528),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ElevatedButton(
              onPressed: isSending ? null : saveNewItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: isSending
                  ? const CircularProgressIndicator()
                  : Text('Add', style: kTextStyle.copyWith()),
            ),
          ),
        ],
      ),
      body: ConstrainedBox(
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
                CustomTextField(
                  key: _nameKey,
                  errorTextPadding: const EdgeInsetsGeometry.only(
                    left: 20,
                    top: 3,
                  ),
                  prefixBackgroundColor: _currentColor,
                  prefixIcon: _selectedIcon,
                  // prefixIconColor: const Color(0xFF40434A),
                  prefixIconColor: _currentIconColor,
                  hint: 'Name',
                  validate: nameValidator,
                ),

                Divider(
                  height: 2,
                  thickness: 2,
                  color: Theme.of(context).dividerColor,
                  indent: 25,
                  endIndent: 25,
                ),

                const SizedBox(height: 10),
                BlackAndWhiteSlider(
                  onColorChanged: updateIconColor,
                ),
                const SizedBox(height: 10),

                ColorPickerr(onColorChanged: updateColor),
                const SizedBox(height: 10),

                IconPicker(
                  onSelectIcon: updateIcon,
                  backgroundColor: _currentColor,
                  iconColor: _currentIconColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
