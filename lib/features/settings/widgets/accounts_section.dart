import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/features/settings/cubit/accounts_cubit.dart';
import 'package:finance_app/features/settings/cubit/manage_status.dart';
import 'package:finance_app/features/settings/widgets/manage_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountsSection extends StatelessWidget {
  const AccountsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AccountsCubit(getIt<AccountRepository>()),
      child: const _AccountsView(),
    );
  }
}

class _AccountsView extends StatelessWidget {
  const _AccountsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountsCubit, AccountsState>(
      listenWhen: (p, c) => c.message != null && p.message != c.message,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message!)),
        );
        context.read<AccountsCubit>().clearMessage();
      },
      builder: (context, state) {
        return ManageSection(
          title: 'Accounts',
          onAdd: () => Navigator.of(context).pushNamed('/add-account'),
          loading: state.status == ManageStatus.loading,
          emptyLabel: 'No accounts yet',
          isEmpty: state.accounts.isEmpty,
          children: [
            for (final account in state.accounts)
              ManageTile(
                leading: Icon(
                  account.accountIcon,
                  color: const Color(0xFF40434A),
                ),
                title: account.accountName,
                onDelete: () => confirmDelete(
                  context,
                  what: account.accountName,
                  onConfirm: () =>
                      context.read<AccountsCubit>().delete(account.accountId),
                ),
              ),
          ],
        );
      },
    );
  }
}
