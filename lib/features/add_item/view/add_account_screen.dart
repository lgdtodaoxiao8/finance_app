import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/features/add_item/cubit/add_account_cubit.dart';
import 'package:finance_app/features/add_item/widgets/widgets.dart';
import 'package:finance_app/features/add_transaction/widgets/widgets.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddAccountScreen extends StatelessWidget {
  const AddAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddAccountCubit(
        getIt<AccountRepository>(),
        getIt<CurrencyRepository>(),
      ),
      child: const _AddAccountView(),
    );
  }
}

class _AddAccountView extends StatefulWidget {
  const _AddAccountView();

  @override
  State<_AddAccountView> createState() => _AddAccountViewState();
}

class _AddAccountViewState extends State<_AddAccountView> {
  final _nameKey = GlobalKey<CustomTextFieldState>();

  String? _nameValidator(String value) {
    if (value.length < 4) return AppLocalizations.of(context).mustBeAtLeast4;
    if (value.length > 30) return AppLocalizations.of(context).maximum30;
    return null;
  }

  void _save() {
    final nameValid = _nameKey.currentState?.validate() ?? false;
    if (!nameValid) return;
    context.read<AddAccountCubit>().save(_nameKey.currentState!.text);
  }

  Future<int> _addNewCurrency() async {
    final cubit = context.read<AddAccountCubit>();
    final result = await Navigator.of(context).pushNamed('/add-currency');
    await cubit.loadCurrencies();
    if (result is int && result > 0) {
      cubit.setCurrency(result);
      return result;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddAccountCubit, AddAccountState>(
      listenWhen: (p, c) => p.savedId != c.savedId || p.error != c.error,
      listener: (context, state) {
        if (state.savedId != null) {
          Navigator.of(context).pop(state.savedId);
        } else if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context).somethingWentWrong}: ${state.error}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<AddAccountCubit>();
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            shadowColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            title: Text(
              AppLocalizations.of(context).newAccountTitle,
              style: kTextStyle.copyWith(
                fontSize: 22,
                color: const Color(0xFF242528),
                fontWeight: FontWeight.w500,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: ElevatedButton(
                  onPressed: state.sending ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: state.sending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context).add,
                          style: kTextStyle.copyWith(),
                        ),
                ),
              ),
            ],
          ),
          body: state.status == AddAccountStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : state.status == AddAccountStatus.error
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      AppLocalizations.of(context).somethingWentWrong,
                    ),
                  ),
                )
              : ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 13, 20, 20),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(2),
                            child: CustomTextField(
                              key: _nameKey,
                              errorTextPadding: const EdgeInsets.only(
                                left: 20,
                                top: 3,
                              ),
                              prefixIcon: state.icon,
                              prefixPadding: EdgeInsets.zero,
                              prefixIconColor: const Color(0xFF202020),
                              validate: _nameValidator,
                              hint: AppLocalizations.of(context).name,
                            ),
                          ),
                          Divider(
                            height: 2,
                            thickness: 2,
                            color: Theme.of(context).dividerColor,
                            indent: 25,
                            endIndent: 25,
                          ),
                          const SizedBox(height: 12),
                          PopupDropdown(
                            expand: true,
                            borderCircularRadius: 20,
                            colorFilling: const Color(0xFFEDEDF2),
                            currentValue: state.selectedCurrencyId,
                            tableType: Tables.currency,
                            onSelect: cubit.setCurrency,
                            onAddNew: _addNewCurrency,
                            values: [
                              for (final c in state.currencies) c.toMap(),
                            ],
                            label: AppLocalizations.of(context).accountCurrency,
                          ),
                          const SizedBox(height: 15),
                          IconPicker(onSelectIcon: cubit.setIcon),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
