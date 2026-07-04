import 'package:flutter/material.dart';
import 'package:finance_app/theme/theme.dart';

enum Tables {
  currency,
  account,
  category,
}

Map<Tables, List<String>> tablesValues = {
  Tables.currency: ['symbol', 'code'],
  Tables.account: ['icon_code_point', 'name'],
  Tables.category: ['icon_code_point', 'name'],
};

class PopupDropdown extends StatefulWidget {
  const PopupDropdown({
    super.key,
    required this.currentValue,
    required this.tableType,
    required this.onSelect,
    required this.onAddNew,
    required this.values,
    required this.label,
    this.expand = false,
    this.borderCircularRadius = 10,
    this.colorFilling = const Color(0xFFDBE2F9),
    // this.colorFilling = const Color(0xFFE2E2E9),
  });

  final Future<int> Function() onAddNew;
  final List<Map<String, dynamic>>? values;
  final void Function(int) onSelect;
  final int? currentValue;
  final Tables tableType;
  final String label;
  final bool expand;
  final double borderCircularRadius;
  final Color colorFilling;

  @override
  State<PopupDropdown> createState() => _PopupDropdownState();
}

class _PopupDropdownState extends State<PopupDropdown> {
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
          ...widget.values!.map(
            (value) {
              final isSelected = widget.currentValue == value['id'];
              return PopupMenuItem<String>(
                enabled: !isSelected,
                onTap: () => widget.onSelect(value['id']),
                child: Row(
                  children: [
                    if (widget.tableType == Tables.currency)
                      Text(
                        value['symbol'],
                        style: kTextStyle.copyWith(
                          fontSize: 16,
                          color: isSelected
                              ? const Color(0xFFB3B3B8)
                              : const Color(0xFF242528),
                        ),
                      )
                    else if (widget.tableType == Tables.account)
                      Icon(
                        IconData(
                          value['icon_code_point'],
                          fontFamily: 'MaterialIcons',
                          fontPackage: null,
                        ),
                        size: 25,
                        color: const Color(0xFF40434A),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Color(
                                  value['color'],
                                ).withValues(alpha: 0.5)
                              : Color(
                                  value['color'],
                                ),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          IconData(
                            value['icon_code_point'],
                            fontFamily: 'MaterialIcons',
                            fontPackage: null,
                          ),
                          size: 25,
                          // color: const Color(0xFF40434A),
                          color: Color(value['icon_color']),
                        ),
                      ),

                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        value[tablesValues[widget.tableType]![1]],
                        style: kTextStyle.copyWith(
                          fontSize: 16,
                          color: isSelected
                              ? const Color(0xFFB3B3B8)
                              : const Color(0xFF242528),
                        ),
                        maxLines: 1,
                        // overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

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
                'Add one',
                style: kTextStyle.copyWith(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                maxLines: 1,
                // overflow: TextOverflow.ellipsis,
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
    // Resolve the selected row once, safely (no `.firstWhere` that can throw
    // "No element" when the id isn't present / the list is empty).
    Map<String, dynamic>? selected;
    if (widget.values != null && widget.currentValue != null) {
      for (final value in widget.values!) {
        if (value['id'] == widget.currentValue) {
          selected = value;
          break;
        }
      }
    }
    final isNull = selected == null;

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
                    Padding(
                      padding: EdgeInsets.only(
                        left: widget.tableType == Tables.category ? 6 : 12,
                      ),
                      child: isNull
                          ? null
                          : widget.tableType == Tables.currency
                          ? Text(
                              selected['symbol'],
                              style: kTextStyle.copyWith(
                                fontSize: 20,
                                color: const Color(0xFF242528),
                              ),
                              overflow: TextOverflow.ellipsis,
                            )
                          : widget.tableType == Tables.account
                          ? Icon(
                              IconData(
                                selected['icon_code_point'],
                                fontFamily: 'MaterialIcons',
                                fontPackage: null,
                              ),
                              size: 25,
                              color: const Color(0xFF40434A),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(selected['color']),
                              ),
                              padding: const EdgeInsets.all(7),
                              margin: const EdgeInsets.only(top: 4),
                              child: Icon(
                                IconData(
                                  selected['icon_code_point'],
                                  fontFamily: 'MaterialIcons',
                                  fontPackage: null,
                                ),
                                size: 23,
                                color: Color(selected['icon_color']),
                              ),
                            ),
                    ),
                    if (!isNull) const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isNull
                            ? 'Have no items'
                            : selected[tablesValues[widget.tableType]![1]],
                        style: kTextStyle.copyWith(
                          fontSize: 16,
                          color: const Color(0xFF242528),
                        ),
                        maxLines: 1,
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
                //fontWeight: FontWeight.w600,
                color: const Color(0xFF242528),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
