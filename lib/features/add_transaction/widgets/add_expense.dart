import 'package:finance_app/features/add_transaction/widgets/widgets.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AddExpense extends StatelessWidget {
  const AddExpense({
    super.key,
    required this.addNewAccount,
    required this.addNewCategory,
    required this.initialAccountId,
    required this.initialCategoryId,
    required this.accountsList,
    required this.categoriesList,
    required this.onSelectAccount,
    required this.onSelectCategory,
  });

  final Future<int> Function() addNewAccount;
  final Future<int> Function() addNewCategory;

  final int? initialAccountId;
  final int? initialCategoryId;

  final List<Map<String, dynamic>>? accountsList;
  final List<Map<String, dynamic>>? categoriesList;

  final void Function(int) onSelectAccount;
  final void Function(int) onSelectCategory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        //from setter
        PopupDropdown(
          borderCircularRadius: 15,
          onAddNew: addNewAccount,
          tableType: Tables.account,
          currentValue: initialAccountId,
          values: accountsList,
          label: AppLocalizations.of(context).fromAccount,
          onSelect: onSelectAccount,
        ),

        const SizedBox(
          width: 20,
        ),

        //to setter
        PopupDropdown(
          borderCircularRadius: 15,
          onAddNew: addNewCategory,
          tableType: Tables.category,
          currentValue: initialCategoryId,
          label: AppLocalizations.of(context).toCategory,
          values: categoriesList,
          onSelect: onSelectCategory,
        ),
      ],
    );
  }
}
