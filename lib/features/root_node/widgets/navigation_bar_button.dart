import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

class NavigationBarButton extends StatelessWidget {
  const NavigationBarButton({
    super.key,
    required this.isActive,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool isActive;
  final IconData icon;
  final String label;

  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = themeFromSeed.colorScheme;

    return Expanded(
      flex: 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isActive ? null : onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? colorScheme.surface : colorScheme.secondary,
              size: isActive ? 30 : 24,
            ),
            Text(
              label,
              style: kTextStyle.copyWith(
                color: isActive ? colorScheme.surface : colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
