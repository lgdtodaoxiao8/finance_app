import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PopupDropdownSimple extends StatelessWidget {
  const PopupDropdownSimple({
    super.key,
    required this.currentValue,
    required this.onSelect,
    required this.width,
    required this.height,
    required this.values,
    required this.label,
  });

  final List<dynamic> values;
  final void Function(dynamic) onSelect;
  final dynamic currentValue;
  final String label;
  final double width;
  final double height;

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
            final isSelected = currentValue == value;
            return PopupMenuItem(
              enabled: !isSelected,
              onTap: () => onSelect(value),
              child: Text(
                value,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: isSelected
                      ? const Color(0xFFB3B3B8)
                      : const Color(0xFF242528),
                  fontWeight: FontWeight.w500,
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
                color: const Color(0xFFF8F8FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  _openDropdownMenu(context);
                },
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, top: 5, bottom: 5),
                  child: Row(
                    children: [
                      Text(
                        currentValue,
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          color: const Color(0xFF242528),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -4,
            left: 5,
            child: Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF242528),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
