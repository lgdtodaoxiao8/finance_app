import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/features/add_item/cubit/add_currency_cubit.dart';
import 'package:finance_app/features/add_item/widgets/widgets.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    return '1 ${state.baseSymbol ?? ''}  is equal  '
        '$rateText ${state.selected?.currencySymbol ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddCurrencyCubit, AddCurrencyState>(
      listenWhen: (p, c) => p.savedId != c.savedId || p.error != c.error,
      listener: (context, state) {
        if (state.savedId != null) {
          Navigator.of(context).pop(state.savedId);
        } else if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context).somethingWentWrong}: '
                '${state.error}',
                style: kTextStyle.copyWith(overflow: TextOverflow.visible),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<AddCurrencyCubit>();
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            shadowColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            title: Text(
              state.baseIsNotSet
                  ? AppLocalizations.of(context).setBaseCurrencyTitle
                  : AppLocalizations.of(context).newCurrencyTitle,
              style: kTextStyle.copyWith(
                fontSize: 22,
                color: const Color(0xFF242528),
              ),
            ),
          ),
          body: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: state.status == AddCurrencyStatus.loading
                  ? const Center(child: CircularProgressIndicator())
                  : state.status == AddCurrencyStatus.error
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          AppLocalizations.of(context).somethingWentWrong,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PopupDropdownConstant(
                          currentId: state.selectedId,
                          onSelect: cubit.selectCurrency,
                          values: [for (final c in state.currencies) c.toMap()],
                          label: AppLocalizations.of(context).allCurrencies,
                        ),
                        const SizedBox(height: 15),
                        if (!state.baseIsNotSet) ...[
                          CustomTextField(
                            key: _rateKey,
                            hint: AppLocalizations.of(context).rateHint,
                            label: AppLocalizations.of(context).rateToBase,
                            textPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            fieldFontSize: 15,
                            errorTextPadding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 4,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validate: _validateRate,
                            onChanged: () {
                              final text = _rateKey.currentState?.text ?? '';
                              cubit.setRate(_parseRate(text));
                            },
                            counterTextPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            counter: _counterText(state),
                          ),
                          const SizedBox(height: 20),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: state.sending
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: Text(
                                AppLocalizations.of(context).cancel,
                                style: kTextStyle.copyWith(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                              ),
                              onPressed: state.sending
                                  ? null
                                  : () => _save(state),
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
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
