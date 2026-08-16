import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/theme/theme.dart';

class PopupDropdownConstant extends StatefulWidget {
  const PopupDropdownConstant({
    super.key,
    required this.currentId,
    required this.onSelect,
    required this.values,
    required this.label,
  });

  final List<Map<String, dynamic>>? values;
  final void Function(int) onSelect;
  final int? currentId;
  final String label;

  @override
  State<PopupDropdownConstant> createState() => _PopupDropdownConstantState();
}

class _PopupDropdownConstantState extends State<PopupDropdownConstant> {
  bool isActive = false;

  void _openDropdownMenu(
    BuildContext context,
  ) async {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final containerWidth = renderBox.size.width;

    setState(() {
      isActive = true;
    });

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
        maxHeight: 320,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),

      items: [
        if (widget.values != null)
          ...widget.values!.map(
            (value) {
              final isSelected = widget.currentId == value['id'];
              return PopupMenuItem<String>(
                enabled: !isSelected,
                onTap: () => widget.onSelect(value['id']),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 100,
                            child: Row(
                              children: [
                                Text(
                                  value['symbol'],
                                  style: kTextStyle.copyWith(
                                    fontSize: 16,
                                    color: isSelected
                                        ? const Color(0xFFB3B3B8)
                                        : const Color(0xFF242528),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  value['code'],
                                  style: kTextStyle.copyWith(
                                    fontSize: 16,
                                    color: isSelected
                                        ? const Color(0xFFB3B3B8)
                                        : const Color(0xFF242528),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              value['name'],
                              softWrap: true,
                              style: kTextStyle.copyWith(
                                fontSize: 16,
                                color: isSelected
                                    ? const Color(0xFFB3B3B8)
                                    : const Color(0xFF242528),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );

    setState(() {
      isActive = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isNullCurrentValue = widget.currentId == null;
    final isNullValues = widget.values == null;
    Map<String, dynamic>? currentValue;
    if (!isNullCurrentValue && !isNullValues) {
      for (final value in widget.values!) {
        if (value['id'] == widget.currentId) {
          currentValue = value;
          break;
        }
      }
    }

    return Container(
      height: 55,
      decoration: BoxDecoration(
        boxShadow: [
          const BoxShadow(
            blurRadius: 3,
            color: Colors.black12,
          ),
        ],
        color: themeFromSeed.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 2,
          color: isActive
              ? themeFromSeed.colorScheme.primaryFixedDim
              : Colors.transparent,
        ),
      ),
      // width: (screenWidth - 30) / 2,
      child: Stack(
        children: [
          Positioned.fill(
            top: 3,
            child: Container(
              decoration: BoxDecoration(
                color: themeFromSeed.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: InkWell(
                onTap: () {
                  if (!isNullValues) {
                    _openDropdownMenu(context);
                  }
                },
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!isNullValues && !isNullCurrentValue) ...[
                      const SizedBox(width: 12),

                      Text(
                        currentValue?['symbol'],
                        style: kTextStyle.copyWith(
                          fontSize: 20,
                          color: const Color(0xFF242528),
                          //fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currentValue?['code'],
                              style: kTextStyle.copyWith(
                                fontSize: 16,
                                color: const Color(0xFF242528),
                                //fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                currentValue?['name'],
                                style: kTextStyle.copyWith(
                                  fontSize: 16,
                                  color: const Color(0xFF242528),
                                  //fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Spacer(), //make centering by stack (ask how do it)
                      if (isNullValues)
                        Text(
                          AppLocalizations.of(context).haveNoItems,
                          style: kTextStyle.copyWith(
                            fontSize: 16,
                            color: const Color(0xFF242528),
                            //fontWeight: FontWeight.w500,
                          ),
                        )
                      else if (isNullCurrentValue)
                        Text(
                          AppLocalizations.of(context).chooseBaseCurrency,
                          style: kTextStyle.copyWith(
                            fontSize: 16,
                            color: const Color(0xFF242528),
                            //fontWeight: FontWeight.w500,
                          ),
                        ),
                      const Spacer(),
                    ],

                    const Icon(Icons.arrow_drop_down_rounded, size: 25),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -1,
            left: 11,
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
