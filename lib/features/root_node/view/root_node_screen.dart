import 'package:finance_app/features/home/home.dart';
import 'package:finance_app/features/root_node/widgets/widgets.dart';
import 'package:finance_app/features/settings/view/settings_screen.dart';
import 'package:finance_app/features/transactions_list/transactions_list.dart';
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
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        currentIndex: currentIndex,
        onChanged: (i) => setState(() => currentIndex = i),
      ),
    );
  }
}
