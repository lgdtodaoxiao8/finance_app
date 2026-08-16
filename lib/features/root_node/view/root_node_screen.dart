import 'package:finance_app/features/home/home.dart';
import 'package:finance_app/features/root_node/widgets/widgets.dart';
import 'package:finance_app/features/settings/view/settings_screen.dart';
import 'package:finance_app/features/transactions_list/transactions_list.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart' hide NavigationBar;

class RootNodeScreen extends StatefulWidget {
  const RootNodeScreen({super.key});

  @override
  State<RootNodeScreen> createState() => _RootNodeScreenState();
}

class _RootNodeScreenState extends State<RootNodeScreen> {
  int currentIndex = 0;

  final screens = const [
    HomeScreen(),
    TransactionsListScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      // Logging a transaction is the app's primary action, so it gets a
      // prominent always-visible button floating above the nav — not the small
      // "+" buried in the Transactions header.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        height: 62,
        width: 62,
        child: FloatingActionButton(
          onPressed: () =>
              Navigator.of(context).pushNamed('/add-transaction'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 3,
          highlightElevation: 2,
          shape: const CircleBorder(),
          tooltip: l.add,
          child: const Icon(Icons.add_rounded, size: 32),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        currentIndex: currentIndex,
        onChanged: (i) => setState(() => currentIndex = i),
      ),
    );
  }
}
