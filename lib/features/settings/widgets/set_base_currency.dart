import 'package:finance_app/features/add_item/widgets/widgets.dart';
import 'package:finance_app/features/settings/cubit/base_currency_cubit.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SetBaseCurrency extends StatefulWidget {
  const SetBaseCurrency({super.key});

  @override
  State<SetBaseCurrency> createState() => _SetBaseCurrencyState();
}

class _SetBaseCurrencyState extends State<SetBaseCurrency> {
  final _rateKey = GlobalKey<CustomTextFieldState>();

  double? _parseRate(String text) => double.tryParse(text.replaceAll(',', '.'));

  String? _validateRate(String text) {
    final value = _parseRate(text);
    if (value == null) return 'Must be a number';
    if (value == 0) return 'Can not be null';
    if (value < 0) return 'Can not be negative';
    return null;
  }

  void _submit(BaseCurrencyState state) {
    if (state.needToEnterRate) {
      final valid = _rateKey.currentState?.validate() ?? false;
      if (!valid) return;
    }
    context.read<BaseCurrencyCubit>().submit();
  }

  String _counterText(BaseCurrencyState state) {
    final rate = state.rateToBase;
    if (rate == null || rate <= 0) return 'Exchange rate to base cur.';
    final rateText = rate % 1 == 0 ? rate.toInt().toString() : rate.toString();
    return '1 ${state.baseSymbol ?? ''}  is equal  '
        '$rateText ${state.selected?.currencySymbol ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BaseCurrencyCubit, BaseCurrencyState>(
      listenWhen: (prev, curr) => prev.error != curr.error && curr.error != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Something went wrong while setting default currency: '
              '${state.error}',
              style: kTextStyle.copyWith(overflow: TextOverflow.visible),
            ),
            backgroundColor: Colors.red,
          ),
        );
      },
      builder: (context, state) {
        if (state.status == BaseCurrencyStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == BaseCurrencyStatus.error) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Text('Something went wrong'),
            ),
          );
        }

        final busy = state.sending || state.success;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PopupDropdownConstant(
              currentId: state.selectedId,
              onSelect: context.read<BaseCurrencyCubit>().selectCurrency,
              values: [for (final c in state.currencies) c.toMap()],
              label: 'All currencies',
            ),
            const SizedBox(height: 15),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: ClipRect(
                child: state.needToEnterRate
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: CustomTextField(
                          key: _rateKey,
                          hint: 'e.g. 1.25 or 0.73',
                          label: 'Rate to base',
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
                            context.read<BaseCurrencyCubit>().setRate(
                              _parseRate(text),
                            );
                          },
                          counterTextPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          counter: _counterText(state),
                        ),
                      )
                    : const SizedBox(width: double.infinity, height: 0),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: busy ? null : () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: kTextStyle.copyWith()),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: busy ? null : () => _submit(state),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: state.sending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : state.success
                        ? const Icon(
                            Icons.check_rounded,
                            key: ValueKey('success'),
                            color: Colors.white,
                          )
                        : Text(
                            'Add',
                            style: kTextStyle.copyWith(),
                            key: const ValueKey('default'),
                          ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
