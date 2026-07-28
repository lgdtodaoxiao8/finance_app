import 'package:finance_app/features/root_node/widgets/navigation_bar_button.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/core/app_icons.dart';

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
    // The pill stays dark in both themes (its buttons use fixed light-on-dark
    // colours). In dark mode use an elevated dark so it lifts off the near-black
    // background.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillColor = isDark
        ? AppColorsDark.surfaceHigh
        : AppColors.textPrimary;
    final l = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
        right: 15,
        left: 15,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: pillColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            NavigationBarButton(
              isActive: currentIndex == 0,
              label: l.navHome,
              icon: AppIcons.home,
              onTap: () {
                onChanged(0);
              },
            ),
            NavigationBarButton(
              isActive: currentIndex == 1,
              label: l.navTransactions,
              icon: AppIcons.swap_vert,
              onTap: () {
                onChanged(1);
              },
            ),
            NavigationBarButton(
              isActive: currentIndex == 2,
              label: l.navSettings,
              icon: AppIcons.settings,
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
