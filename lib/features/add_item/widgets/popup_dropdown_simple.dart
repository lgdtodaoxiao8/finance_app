import 'package:flutter/material.dart';
import 'package:finance_app/theme/theme.dart';

class PopupDropdownSimple extends StatelessWidget {
  const PopupDropdownSimple({
    super.key,
    required this.onSelect,
    required this.values,
    required this.label,
    required this.currentValue,
    required this.height,
    required this.width,
  });

  final List<String> values;
  final void Function(String) onSelect;
  final String label;

  final double height;
  final double width;
  final String currentValue;

  void _openDropdownMenu(
    BuildContext context,
  ) async {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final containerWidth = renderBox.size.width;

    await showMenu(
      context: context,
      color: const Color(0xFFF8F8FB),
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
        maxHeight: 300,
      ),
      // color: const Color(0xFFF8F8FB),
      // color: const Color.fromARGB(255, 241, 241, 244),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(20),
      ),

      items: [
        ...values.map(
          (value) {
            final isSelected = currentValue == value;
            return PopupMenuItem<String>(
              enabled: !isSelected,
              onTap: () => onSelect(value),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  value,
                  softWrap: true,
                  // overflow: TextOverflow.ellipsis,
                  style: kTextStyle.copyWith(
                    fontSize: 16,
                    color: isSelected
                        ? const Color(0xFFB3B3B8)
                        : const Color(0xFF242528),
                    //fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: Stack(
        children: [
          Positioned.fill(
            top: 3,
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(225, 255, 255, 255),
                // color: const Color(0xFFDBE2F9),
                // color: const Color(0xFFE2E2E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: InkWell(
                onTap: () {
                  _openDropdownMenu(context);
                },
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        currentValue,
                        style: kTextStyle.copyWith(
                          fontSize: 16,
                          color: const Color(0xFF242528),
                          //fontWeight: FontWeight.w500,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
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
            top: -4,
            left: 5,
            child: Text(
              label,
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
