import 'package:flutter/material.dart';
import 'package:finance_app/main.dart';

class BottomBarCustom extends StatefulWidget {
  const BottomBarCustom({super.key, required this.onChanged});

  final Function(int) onChanged;

  @override
  State<BottomBarCustom> createState() {
    return _BottomBarCustomState();
  }
}

class _BottomBarCustomState extends State<BottomBarCustom> {
  int _selectedIndex = 0;

  Widget _bottomButton(
    int index,
    String label,
    IconData icon,
  ) {
    final isActive = index == _selectedIndex;
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          widget.onChanged(index);
        },
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
        // height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _bottomButton(0, 'Home', Icons.home_rounded),
            _bottomButton(1, 'Transactions', Icons.swap_vert_rounded),
            _bottomButton(2, 'Settings', Icons.settings_rounded),
          ],
        ),
      ),
    );
  }
}
