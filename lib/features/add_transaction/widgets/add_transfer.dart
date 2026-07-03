import 'package:finance_app/features/add_transaction/widgets/widgets.dart';
import 'package:flutter/material.dart';

class AddTransfer extends StatelessWidget {
  const AddTransfer({
    super.key,
    required this.addNewAccount,
    required this.initialAccountId,
    required this.initialAccountDestinationId,
    required this.accountsList,
    required this.onSelectAccount,
    required this.onSelectAccountDestination,
  });

  final Future<int> Function() addNewAccount;

  final int? initialAccountId;
  final int? initialAccountDestinationId;

  final List<Map<String, dynamic>>? accountsList;

  final void Function(int) onSelectAccount;
  final void Function(int) onSelectAccountDestination;

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
          label: 'From account',
          onSelect: onSelectAccount,
        ),

        const SizedBox(
          width: 20,
        ),

        //to setter
        PopupDropdown(
          borderCircularRadius: 15,
          onAddNew: addNewAccount,
          tableType: Tables.account,
          currentValue: initialAccountDestinationId,
          label: 'To account',
          values: accountsList,
          onSelect: onSelectAccountDestination,
        ),
      ],
    );
  }
}
