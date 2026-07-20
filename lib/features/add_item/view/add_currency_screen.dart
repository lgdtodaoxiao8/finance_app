import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/widgets/item_avatar.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/features/add_item/cubit/add_currency_cubit.dart';
import 'package:finance_app/features/add_item/widgets/widgets.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Adds a currency (or sets the base one on first run): pick from the list,
/// give the exchange rate — the header shows the picked symbol live.
class AddCurrencyScreen extends StatelessWidget {
  const AddCurrencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddCurrencyCubit(getIt<CurrencyRepository>()),
      child: const _AddCurrencyView(),
    );
  }
}

class _AddCurrencyView extends StatefulWidget {
  const _AddCurrencyView();

  @override
  State<_AddCurrencyView> createState() => _AddCurrencyViewState();
}

class _AddCurrencyViewState extends State<_AddCurrencyView> {
  final _rateKey = GlobalKey<CustomTextFieldState>();

  double? _parseRate(String text) => double.tryParse(text.replaceAll(',', '.'));

  String? _validateRate(String text) {
    final value = _parseRate(text);
    if (value == null) return AppLocalizations.of(context).mustBeNumber;
    if (value <= 0) return AppLocalizations.of(context).mustBeMoreThanZero;
    return null;
  }

  void _save(AddCurrencyState state) {
    if (!state.baseIsNotSet) {
      final valid = _rateKey.currentState?.validate() ?? false;
      if (!valid) return;
    }
    context.read<AddCurrencyCubit>().save();
  }

  String _counterText(AddCurrencyState state) {
    if (state.rate <= 0) return AppLocalizations.of(context).exchangeRateToBase;
    final rateText = state.rate % 1 == 0
        ? state.rate.toInt().toString()
        : state.rate.toString();
    return '1 ${state.baseSymbol ?? ''}  =  '
        '$rateText ${state.selected?.currencySymbol ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BlocConsumer<AddCurrencyCubit, AddCurrencyState>(
      listenWhen: (p, c) => p.savedId != c.savedId || p.error != c.error,
      listener: (context, state) {
        if (state.savedId != null) {
          Navigator.of(context).pop(state.savedId);
        } else if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${l.somethingWentWrong}: ${state.error}',
                style: kTextStyle.copyWith(overflow: TextOverflow.visible),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<AddCurrencyCubit>();
        final accent = Theme.of(context).colorScheme.primary;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              state.baseIsNotSet ? l.setBaseCurrencyTitle : l.newCurrencyTitle,
              style: kTextStyle.copyWith(fontSize: 20),
            ),
          ),
          body: state.status == AddCurrencyStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : state.status == AddCurrencyStatus.error
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
                                    label:
                                        state.selected?.currencySymbol ?? '¤',
                                    diameter: 64,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          state.selected?.currencyName ?? '—',
                                          style: kTextStyle.copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (state.selected != null)
                                          Text(
                                            state.selected!.currencyCode,
                                            style: kTextStyle.copyWith(
                                              fontSize: 13,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            PopupDropdownConstant(
                              currentId: state.selectedId,
                              onSelect: cubit.selectCurrency,
                              values: [
                                for (final c in state.currencies) c.toMap(),
                              ],
                              label: l.allCurrencies,
                            ),
                            const SizedBox(height: 16),
                            if (!state.baseIsNotSet)
                              CustomTextField(
                                key: _rateKey,
                                hint: l.rateHint,
                                label: l.rateToBase,
                                textPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                fieldFontSize: 15,
                                errorTextPadding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 4,
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validate: _validateRate,
                                onChanged: () {
                                  final text =
                                      _rateKey.currentState?.text ?? '';
                                  cubit.setRate(_parseRate(text));
                                },
                                counterTextPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                counter: _counterText(state),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: state.sending
                                ? null
                                : () => _save(state),
                            child: state.sending
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l.add),
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
