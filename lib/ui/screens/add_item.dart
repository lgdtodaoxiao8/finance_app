import 'package:finance_app/ui/widgets/icon_picker.dart';
import 'package:finance_app/ui/widgets/popup_dropdown_special.dart';
import 'package:finance_app/ui/widgets/color_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Color? _currentColor;
  bool isColorPicking = false;

  IconData? _selectedIcon;

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
      //save to bd
      //return the id back to add transaction screen
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (widget.tableType == Tables.category) {
      content = Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          children: [
            // const SizedBox(height: 30),
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
                Text(
                  _nameController.text,
                  style: GoogleFonts.lato(
                    fontSize: 26,
                    color: const Color(0xFF242528),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Form(
              key: _formKey,
              child: TextFormField(
                onChanged: (value) {
                  setState(() {});
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
                style: GoogleFonts.lato(
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  constraints: const BoxConstraints(maxHeight: 63),
                  labelText: 'Name',
                  labelStyle: GoogleFonts.lato(
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
              // color: Color(0xFFE2E2E9), // или Theme.of(context).dividerColor
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
        ),
      );
    } else {
      content = Text(widget.tableType.toString());
    }

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
            style: GoogleFonts.lato(
              fontSize: 22,
              color: const Color(0xFF242528),
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: saveNewItem,
              child: const Text('Add'),
            ),
          ],
        ),
        body: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height,
          ),
          child: content,
        ),
      ),
    );
  }
}
