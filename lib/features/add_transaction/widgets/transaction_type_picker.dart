import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

class TransactionTypePicker extends StatelessWidget {
  const TransactionTypePicker({
    super.key,
    required this.initialValue,
    required this.onSave,
  });

  final String initialValue;
  final void Function(String, int) onSave;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tabs = <Map<String, dynamic>>[
      {
        'value': ['expense', 0],
        'label': l.expense,
        'icon': Icons.arrow_upward_rounded,
      },
      {
        'value': ['income', 1],
        'label': l.income,
        'icon': Icons.arrow_downward_rounded,
      },
      {
        'value': ['transfer', 2],
        'label': l.transfer,
        'icon': Icons.swap_vert_rounded,
      },
    ];

    final colorTheme = Theme.of(context).colorScheme;

    return Row(
      children: tabs.map((tab) {
        final isSelected = tab['value'][0] == initialValue;
        return Expanded(
          child: InkWell(
            onTap: () => onSave(tab['value'][0], tab['value'][1]),
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(15),
                color: isSelected ? colorTheme.primary : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    tab['icon'],
                    color: isSelected
                        ? colorTheme.onPrimary
                        : colorTheme.onSurface,
                  ),
                  Text(
                    tab['label'],
                    style: kTextStyle.copyWith(
                      color: isSelected
                          ? colorTheme.onPrimary
                          : colorTheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
