import 'package:flutter/material.dart';
import 'package:finance_app/main.dart';

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

class PopupDropdownSpecial extends StatelessWidget {
  const PopupDropdownSpecial({
    super.key,
    required this.currentValue,
    required this.tableType,
    required this.onSelect,
    required this.onAddNew,
    required this.values,
    required this.label,
  });

  final Future<int> Function(Tables) onAddNew;
  final List<Map<String, dynamic>> values;
  final void Function(int) onSelect;
  final int currentValue;
  final Tables tableType;
  final String label;

  void _openDropdownMenu(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final containerWidth = renderBox.size.width;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          offset.dx,
          offset.dy + renderBox.size.height + 7,
          containerWidth,
          0,
        ),
        Offset.zero & MediaQuery.of(context).size,
      ),
      constraints: BoxConstraints(
        minWidth: containerWidth,
        maxWidth: containerWidth,
      ),
      color: const Color(0xFFF8F8FB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(10),
      ),
      items: [
        ...values.map(
          (value) {
            final isSelected = currentValue == value['id'];
            return PopupMenuItem<String>(
              enabled: !isSelected,
              onTap: () => onSelect(value['id']),
              child: Row(
                children: [
                  if (tableType == Tables.currency)
                    Text(
                      value['symbol'],
                      style: kTextStyle.copyWith(
                        fontSize: 16,
                        color: isSelected
                            ? const Color(0xFFB3B3B8)
                            : const Color(0xFF242528),
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    Icon(
                      IconData(
                        value['icon_code_point'],
                        fontFamily: 'MaterialIcons',
                        fontPackage: null,
                      ),
                      size: 25,
                      color: const Color(0xFF40434A),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    value[tablesValues[tableType]![1]],
                    // value['name'],
                    style: kTextStyle.copyWith(
                      fontSize: 16,
                      color: isSelected
                          ? const Color(0xFFB3B3B8)
                          : const Color(0xFF242528),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),

        PopupMenuItem(
          onTap: () async {
            print('new item ');
            final result = await onAddNew(tableType);
            if (result == -1) return;

            onSelect(result);
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
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Expanded(
      child: SizedBox(
        height: 55,
        width: (screenWidth - 50) / 2,
        child: Stack(
          children: [
            Positioned.fill(
              top: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E2E9),
                  borderRadius: BorderRadius.circular(10),
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
                        padding: const EdgeInsets.only(left: 12),
                        child: tableType == Tables.currency
                            ? Text(
                                values.firstWhere(
                                  (value) => value['id'] == currentValue,
                                )['symbol'],
                                style: kTextStyle.copyWith(
                                  fontSize: 20,
                                  color: const Color(0xFF242528),
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : Icon(
                                IconData(
                                  values.firstWhere(
                                    (value) => value['id'] == currentValue,
                                  )['icon_code_point'],
                                  fontFamily: 'MaterialIcons',
                                  fontPackage: null,
                                ),
                                size: 25,
                                color: const Color(0xFF40434A),
                              ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        //padding top 5
                        child: Text(
                          values.firstWhere(
                            (value) => value['id'] == currentValue,
                          )[tablesValues[tableType]![1]], //was 'name' inside
                          style: kTextStyle.copyWith(
                            fontSize: 16,
                            color: const Color(0xFF242528),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 25),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -4,
              left: 5,
              child: Text(
                label,
                style: kTextStyle.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF242528),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
