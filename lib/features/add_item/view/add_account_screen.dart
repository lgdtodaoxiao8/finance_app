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
import 'package:solar_icons/solar_icons.dart';

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
  late final _rate = TextEditingController(text: _numText(widget.initial?.interestRate));
  late final _value = TextEditingController(text: _numText(widget.initial?.currentValue));

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _rate.dispose();
    _value.dispose();
    super.dispose();
  }

  bool get _valid {
    final name = _name.text.trim();
    return name.isNotEmpty && name.length <= 30;
  }

  static String _numText(double? v) => v == null
      ? ''
      : (v % 1 == 0 ? v.toInt().toString() : v.toString());

  double? _parse(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';

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

  /// Account-type chips + the fields that belong to the chosen type (savings:
  /// rate + maturity; investment: current value).
  Widget _kindSection(
    AddAccountState state,
    AddAccountCubit cubit,
    AppLocalizations l,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.accountType,
          style: kTextStyle.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _kindChip(state, cubit, 'general', l.accountKindGeneral,
                Icons.account_balance_wallet_rounded),
            _kindChip(state, cubit, 'savings', l.accountKindSavings,
                Icons.savings_rounded),
            _kindChip(state, cubit, 'investment', l.accountKindInvestment,
                Icons.trending_up_rounded),
          ],
        ),
        if (state.isSavings) ...[
          const SizedBox(height: 16),
          _numField(
            controller: _rate,
            label: l.interestRateField,
            suffix: '%',
            onChanged: (v) => cubit.setInterestRate(_parse(v)),
          ),
          const SizedBox(height: 12),
          _maturityRow(state, cubit, l),
        ],
        if (state.isInvestment) ...[
          const SizedBox(height: 16),
          _numField(
            controller: _value,
            label: l.currentValueField,
            onChanged: (v) => cubit.setCurrentValue(_parse(v)),
          ),
        ],
      ],
    );
  }

  Widget _kindChip(
    AddAccountState state,
    AddAccountCubit cubit,
    String value,
    String label,
    IconData icon,
  ) {
    final cs = Theme.of(context).colorScheme;
    final selected = state.kind == value;
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? cs.primary : cs.onSurfaceVariant,
      ),
      label: Text(label),
      onSelected: (_) {
        cubit.setKind(value);
        // Re-apply the field's current text so switching back to this kind
        // keeps whatever the user had typed.
        if (value == 'savings') cubit.setInterestRate(_parse(_rate.text));
        if (value == 'investment') cubit.setCurrentValue(_parse(_value.text));
      },
    );
  }

  Widget _numField({
    required TextEditingController controller,
    required String label,
    String? suffix,
    required ValueChanged<String> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: cs.onSurface.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusSm),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _maturityRow(
    AddAccountState state,
    AddAccountCubit cubit,
    AppLocalizations l,
  ) {
    final cs = Theme.of(context).colorScheme;
    final date = state.maturityDate;
    return InkWell(
      borderRadius: BorderRadius.circular(kRadiusSm),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? now.add(const Duration(days: 365)),
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 30),
        );
        if (picked != null) cubit.setMaturityDate(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(kRadiusSm),
        ),
        child: Row(
          children: [
            Icon(Icons.event_rounded, size: 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Text(
              l.maturityField,
              style: kTextStyle.copyWith(
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              date == null ? l.maturityNotSet : _fmtDate(date),
              style: kTextStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (date != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => cubit.setMaturityDate(null),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
        final icon = state.icon ?? SolarIconsBold.wallet;
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
                            _kindSection(state, cubit, l),
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
