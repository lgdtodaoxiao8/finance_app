import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/widgets/item_avatar.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/features/add_item/cubit/add_account_cubit.dart';
import 'package:finance_app/features/add_item/widgets/icon_picker.dart';
import 'package:finance_app/features/add_transaction/widgets/widgets.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:finance_app/core/app_icons.dart';

/// Creates an account — or edits one when it's passed as the route argument.
/// Live preview header (avatar + name), currency, icon — the same flow
/// language as the category screen.
class AddAccountScreen extends StatelessWidget {
  const AddAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final initial = ModalRoute.of(context)?.settings.arguments as Account?;
    return BlocProvider(
      create: (_) => AddAccountCubit(
        getIt<AccountRepository>(),
        getIt<CurrencyRepository>(),
        initial: initial,
      ),
      child: _AddAccountView(initial: initial),
    );
  }
}

class _AddAccountView extends StatefulWidget {
  const _AddAccountView({this.initial});

  final Account? initial;

  @override
  State<_AddAccountView> createState() => _AddAccountViewState();
}

class _AddAccountViewState extends State<_AddAccountView> {
  late final _name = TextEditingController(
    text: widget.initial?.accountName ?? '',
  );

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _valid {
    final name = _name.text.trim();
    return name.isNotEmpty && name.length <= 30;
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
    final l = AppLocalizations.of(context);
    return BlocConsumer<AddAccountCubit, AddAccountState>(
      listenWhen: (p, c) => p.savedId != c.savedId || p.error != c.error,
      listener: (context, state) {
        if (state.savedId != null) {
          Navigator.of(context).pop(state.savedId);
        } else if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l.somethingWentWrong}: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<AddAccountCubit>();
        final accent = Theme.of(context).colorScheme.primary;
        final icon = state.icon ?? AppIcons.account_balance_wallet;
        final editing = widget.initial != null;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              editing ? l.editAccountTitle : l.newAccountTitle,
              style: kTextStyle.copyWith(fontSize: 20),
            ),
          ),
          body: state.status == AddAccountStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : state.status == AddAccountStatus.error
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(l.somethingWentWrong),
                  ),
                )
              : SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: kCardShadow,
                              ),
                              child: Row(
                                children: [
                                  ItemAvatar(
                                    color: accent,
                                    icon: icon,
                                    diameter: 64,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextField(
                                      controller: _name,
                                      maxLength: 30,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      style: kTextStyle.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: l.name,
                                        counterText: '',
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
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
                              label: l.accountCurrency,
                            ),
                            const SizedBox(height: 20),
                            IconPicker(
                              onSelectIcon: cubit.setIcon,
                              initialIcon: icon,
                              accent: accent,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: state.sending || !_valid
                                ? null
                                : () => cubit.save(_name.text.trim()),
                            child: state.sending
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(editing ? l.save : l.add),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
