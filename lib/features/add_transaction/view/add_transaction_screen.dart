import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/add_item/widgets/custom_text_field.dart';
import 'package:finance_app/features/add_transaction/cubit/add_transaction_cubit.dart';
import 'package:finance_app/features/add_transaction/widgets/widgets.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddTransaction extends StatelessWidget {
  const AddTransaction({super.key});

  @override
  Widget build(BuildContext context) {
    // Passed via Navigator.pushNamed('/add-transaction', arguments: details)
    // to edit an existing transaction; null when creating a new one.
    final existing =
        ModalRoute.of(context)?.settings.arguments as TransactionDetails?;

    return BlocProvider(
      create: (_) => AddTransactionCubit(
        getIt<AccountRepository>(),
        getIt<CategoryRepository>(),
        getIt<CurrencyRepository>(),
        getIt<TransactionRepository>(),
        existing: existing,
      ),
      child: _AddTransactionView(isEditing: existing != null),
    );
  }
}

class _AddTransactionView extends StatefulWidget {
  const _AddTransactionView({required this.isEditing});

  final bool isEditing;

  @override
  State<_AddTransactionView> createState() => _AddTransactionViewState();
}

class _AddTransactionViewState extends State<_AddTransactionView> {
  final _amountKey = GlobalKey<CustomTextFieldState>();
  final _noteKey = GlobalKey<CustomTextFieldState>();

  String? _amountValidate(String value) {
    final v = double.tryParse(value);
    if (v == null) return 'Must be a number';
    if (v <= 0) return 'Must be more than 0';
    return null;
  }

  Future<int> _addNew(String route, Future<void> Function(int) reload) async {
    final result = await Navigator.of(context).pushNamed(route);
    if (result is int && result > 0) {
      await reload(result);
      return result;
    }
    return -1;
  }

  void _submit() {
    final cubit = context.read<AddTransactionCubit>();
    final error = cubit.state.validationError;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    final amountValid = _amountKey.currentState?.validate() ?? false;
    if (!amountValid) return;
    final amount = double.tryParse(_amountKey.currentState!.text);
    if (amount == null) return;
    cubit.add(amount: amount, note: _noteKey.currentState?.text ?? '');
  }

  Future<void> _confirmDelete() async {
    final cubit = context.read<AddTransactionCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete transaction?', style: kTextStyle.copyWith()),
        content: Text(
          'This action cannot be undone.',
          style: kTextStyle.copyWith(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: kTextStyle.copyWith()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: kTextStyle.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) cubit.deleteTransaction();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Transaction' : 'Add Transaction',
          style: kTextStyle.copyWith(),
        ),
        actions: [
          if (widget.isEditing)
            IconButton(
              tooltip: 'Delete',
              onPressed: _confirmDelete,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ),
      body: BlocConsumer<AddTransactionCubit, AddTransactionState>(
        listenWhen: (p, c) => !p.saved && c.saved,
        listener: (context, state) => Navigator.of(context).pop(),
        builder: (context, state) {
          if (state.status == AddTransactionStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == AddTransactionStatus.error) {
            return Center(
              child: Text(
                'Something went wrong',
                style: kTextStyle.copyWith(),
                softWrap: true,
              ),
            );
          }

          // Onboarding gate: guide the user to set up prerequisites instead of
          // showing a half-empty form that can't be saved.
          if (!state.isReady) {
            return _OnboardingGate(state: state);
          }

          final cubit = context.read<AddTransactionCubit>();
          final keyboardSpace = MediaQuery.viewInsetsOf(context).bottom;
          final accountMaps = [for (final a in state.accounts) a.toMap()];
          final categoryMaps = [for (final c in state.categories) c.toMap()];

          Future<int> addNewAccount() =>
              _addNew('/add-account', cubit.reloadAccounts);
          Future<int> addNewCategory() =>
              _addNew('/add-category', cubit.reloadCategories);
          Future<int> addNewCurrency() =>
              _addNew('/add-currency', cubit.reloadCurrencies);

          return Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + keyboardSpace),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TransactionTypePicker(
                    initialValue: state.type,
                    onSave: cubit.setType,
                  ),
                  const SizedBox(height: 25),
                  IndexedStack(
                    index: state.typeIndex,
                    children: [
                      AddExpense(
                        addNewAccount: addNewAccount,
                        addNewCategory: addNewCategory,
                        initialAccountId: state.accountId,
                        initialCategoryId: state.categoryId,
                        accountsList: accountMaps,
                        categoriesList: categoryMaps,
                        onSelectAccount: cubit.setAccount,
                        onSelectCategory: cubit.setCategory,
                      ),
                      AddIncome(
                        addNewCategory: addNewCategory,
                        addNewAccount: addNewAccount,
                        initialCategoryId: state.categoryId,
                        initialAccountId: state.accountId,
                        categoriesList: categoryMaps,
                        accountsList: accountMaps,
                        onSelectCategory: cubit.setCategory,
                        onSelectAccount: cubit.setAccount,
                      ),
                      AddTransfer(
                        addNewAccount: addNewAccount,
                        initialAccountId: state.accountId,
                        initialAccountDestinationId: state.accountDestinationId,
                        accountsList: accountMaps,
                        onSelectAccount: cubit.setAccount,
                        onSelectAccountDestination: cubit.setAccountDestination,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomTextField(
                          key: _amountKey,
                          shadowRadis: 3,
                          errorTextPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          fieldBorderRadius: 15,
                          fieldFontSize: 15,
                          textPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          hint: 'Amount',
                          initialText: state.initialAmount,
                          validate: _amountValidate,
                        ),
                      ),
                      const SizedBox(width: 20),
                      PopupDropdownObject(
                        currentValue: state.currencyId,
                        onSelect: cubit.setCurrency,
                        onAddNew: addNewCurrency,
                        values: state.currencies,
                        label: 'Currency',
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: CustomTextField(
                          key: _noteKey,
                          hint: 'Note',
                          initialText: state.initialNote,
                          prefixIcon: Icons.note,
                          prefixIconColor: const Color(0xFF40434A),
                          prefixIconSize: 23,
                          shadowRadis: 3,
                          errorTextPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          fieldBorderRadius: 15,
                          fieldFontSize: 15,
                          textPadding: EdgeInsets.zero,
                          prefixPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: DatePickerField(
                          context: context,
                          value: state.date ?? DateTime.now(),
                          onChanged: cubit.setDate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: state.sending
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text('Cancel', style: kTextStyle.copyWith()),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                        ),
                        onPressed: state.sending ? null : _submit,
                        child: state.sending
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                widget.isEditing ? 'Save' : 'Add',
                                style: kTextStyle.copyWith(),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Shown instead of the form when prerequisites are missing, guiding the user
/// through the first-time setup (base currency -> account) with a clear CTA.
class _OnboardingGate extends StatelessWidget {
  const _OnboardingGate({required this.state});

  final AddTransactionState state;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final String title;
    final String subtitle;
    final String cta;
    final String route;

    if (state.needsBaseCurrency) {
      icon = Icons.currency_exchange_rounded;
      title = 'Set your base currency';
      subtitle = 'Choose the currency you track everything in. '
          'You can add more currencies later.';
      cta = 'Set base currency';
      route = '/add-currency';
    } else if (state.needsAccount) {
      icon = Icons.account_balance_wallet_rounded;
      title = 'Add an account';
      subtitle = 'Create an account (Cash, Card, Bank…) to log '
          'your transactions into.';
      cta = 'Add account';
      route = '/add-account';
    } else {
      icon = Icons.category_rounded;
      title = 'Add a category';
      subtitle = 'Create at least one category for your transactions.';
      cta = 'Add category';
      route = '/add-category';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.field,
              ),
              child: Icon(icon, size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: kTextStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: kTextStyle.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).pushNamed(route);
                if (context.mounted) {
                  context.read<AddTransactionCubit>().load();
                }
              },
              child: Text(cta, style: kTextStyle.copyWith(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
