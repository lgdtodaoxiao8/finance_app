import 'package:finance_app/features/budget/view/budget_section.dart';
import 'package:finance_app/features/goals/view/goals_section.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// The planning hub: budgets today, with goals, planned payments and debts
/// added as further sections. One scrollable place for everything forward-
/// looking about the user's money.
class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.plansTitle, style: kTextStyle.copyWith())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: const [
          BudgetSection(),
          SizedBox(height: 24),
          GoalsSection(),
        ],
      ),
    );
  }
}
