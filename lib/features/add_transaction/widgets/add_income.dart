import 'package:finance_app/features/add_transaction/widgets/widgets.dart';
import 'package:flutter/material.dart';

class AddIncome extends StatelessWidget {
  const AddIncome({
    super.key,
    required this.addNewCategory,
    required this.addNewAccount,
    required this.initialCategoryId,
    required this.initialAccountId,
    required this.categoriesList,
    required this.accountsList,
    required this.onSelectCategory,
    required this.onSelectAccount,
  });

  final Future<int> Function() addNewCategory;
  final Future<int> Function() addNewAccount;

  final int? initialCategoryId;
  final int? initialAccountId;

  final List<Map<String, dynamic>>? categoriesList;
  final List<Map<String, dynamic>>? accountsList;

  final void Function(int) onSelectCategory;
  final void Function(int) onSelectAccount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        //from setter
        PopupDropdown(
          borderCircularRadius: 15,
          onAddNew: addNewCategory,
          tableType: Tables.category,
          currentValue: initialCategoryId,
          label: 'From category',
          values: categoriesList,
          onSelect: onSelectCategory,
        ),

        const SizedBox(
          width: 20,
        ),

        //to setter
        PopupDropdown(
          borderCircularRadius: 15,
          onAddNew: addNewAccount,
          tableType: Tables.account,
          currentValue: initialAccountId,
          values: accountsList,
          label: 'To account',
          onSelect: onSelectAccount,
        ),
      ],
    );
  }
}
