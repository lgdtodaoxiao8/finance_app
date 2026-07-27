import 'package:finance_app/models/main_model.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/theme/theme.dart';

class PopupDropdownObject extends StatefulWidget {
  const PopupDropdownObject({
    super.key,
    required this.currentValue,
    required this.onSelect,
    required this.onAddNew,
    required this.values,
    required this.label,
    this.expand = false,
    this.borderCircularRadius = 10,
    this.colorFilling = const Color(0xFFDBE2F9),
  });

  final Future<int> Function() onAddNew;
  final List<dynamic>? values;
  final void Function(int) onSelect;
  final int? currentValue;

  final String label;
  final bool expand;
  final double borderCircularRadius;
  final Color colorFilling;

  @override
  State<PopupDropdownObject> createState() => _PopupDropdownState();
}

class _PopupDropdownState extends State<PopupDropdownObject> {
  bool isActive = false;

  void _openDropdownMenu(BuildContext context) async {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final containerWidth = renderBox.size.width;
    final widgetHeight = renderBox.size.height;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    double spaceBelow =
        screenHeight - offset.dy - widgetHeight - 7 - keyboardHeight;
    if (spaceBelow < 100) spaceBelow = 200;

    setState(() {
      isActive = true;
    });

    await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          offset.dx,
          offset.dy + widgetHeight + 7,
          containerWidth,
          0,
        ),
        Offset.zero & MediaQuery.of(context).size,
      ),
      constraints: BoxConstraints(
        minWidth: containerWidth,
        maxWidth: containerWidth,
        maxHeight: spaceBelow,
      ),
      color: const Color(0xFFF8F8FB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(
          widget.borderCircularRadius,
        ),
      ),
      items: [
        if (widget.values != null)
          ...widget.values!.map((item) {
            final data = item as RootData;
            final isSelect = data.id == widget.currentValue;
            return PopupMenuItem(
              enabled: !isSelect,
              onTap: () => widget.onSelect(data.id),
              child: data.buildDropdownRow(context, isSelect),
            );
          }),

        PopupMenuItem(
          onTap: () async {
            debugPrint('new item ');
            final result = await widget.onAddNew();
            if (result == -1) return;
            setState(() {
              widget.onSelect(result);
            });
          },
          child: Row(
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                size: 25,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).addOne,
                style: kTextStyle.copyWith(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    setState(() {
      isActive = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Find the selected item without ever calling `.first` on a possibly-empty
    // list — an empty list (e.g. no currencies with a rate yet) must simply
    // render the "Have no items" state instead of crashing with "No element".
    final values = widget.values?.cast<RootData>();
    RootData? currentValue;
    if (values != null && widget.currentValue != null) {
      for (final value in values) {
        if (value.id == widget.currentValue) {
          currentValue = value;
          break;
        }
      }
    }
    final isNull = values == null || currentValue == null;

    final String? label = currentValue?.displayName;

    return Container(
      height: 55,
      width: widget.expand ? null : (screenWidth - 52) / 2,
      decoration: BoxDecoration(
        boxShadow: [
          const BoxShadow(
            blurRadius: 3,
            color: Colors.black12,
          ),
        ],
        color: themeFromSeed.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          width: 2,
          color: isActive
              ? themeFromSeed.colorScheme.primaryFixedDim
              : Colors.transparent,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            top: 6,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  widget.borderCircularRadius,
                ),
              ),
              child: InkWell(
                onTap: () {
                  _openDropdownMenu(context);
                },
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!isNull) ...[
                      currentValue.buildIcon(context),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        label ?? AppLocalizations.of(context).haveNoItems,
                        style: kTextStyle.copyWith(
                          fontSize: 16,
                          color: const Color(0xFF242528),
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded, size: 25),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -3,
            left: 12,
            child: Text(
              widget.label,
              style: kTextStyle.copyWith(
                fontSize: 10,
                color: const Color(0xFF242528),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
