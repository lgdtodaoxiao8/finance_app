import 'package:finance_app/features/root_node/widgets/navigation_bar_button.dart';
import 'package:flutter/material.dart';

class NavigationBar extends StatelessWidget {
  const NavigationBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;

  final Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
        right: 15,
        left: 15,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.onSurface,
          borderRadius: BorderRadius.circular(30),
        ), //secondary
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            NavigationBarButton(
              isActive: currentIndex == 0,
              label: 'Home',
              icon: Icons.home_rounded,
              onTap: () {
                onChanged(0);
              },
            ),
            NavigationBarButton(
              isActive: currentIndex == 1,
              label: 'Transactions',
              icon: Icons.swap_vert_rounded,
              onTap: () {
                onChanged(1);
              },
            ),
            NavigationBarButton(
              isActive: currentIndex == 2,
              label: 'Settings',
              icon: Icons.settings_rounded,
              onTap: () {
                onChanged(2);
              },
            ),
          ],
        ),
      ),
    );
  }
}
