import 'package:finance_app/features/add_item/widgets/widgets.dart';
import 'package:finance_app/features/settings/cubit/base_currency_cubit.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:finance_app/l10n/app_localizations.dart';
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
    if (value == null) return AppLocalizations.of(context).mustBeNumber;
    if (value == 0) return AppLocalizations.of(context).cannotBeZero;
    if (value < 0) return AppLocalizations.of(context).cannotBeNegative;
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
    if (rate == null || rate <= 0) {
      return AppLocalizations.of(context).exchangeRateToBase;
    }
    final rateText = rate % 1 == 0 ? rate.toInt().toString() : rate.toString();
    return AppLocalizations.of(context).rateEquals(
      state.baseSymbol ?? '',
      rateText,
      state.selected?.currencySymbol ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BaseCurrencyCubit, BaseCurrencyState>(
      listenWhen: (prev, curr) =>
          prev.error != curr.error && curr.error != null,
      listener: (context, state) {
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
      },
      builder: (context, state) {
        if (state.status == BaseCurrencyStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == BaseCurrencyStatus.error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(AppLocalizations.of(context).somethingWentWrong),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PopupDropdownConstant(
              currentId: state.selectedId,
              onSelect: context.read<BaseCurrencyCubit>().selectCurrency,
              values: [for (final c in state.currencies) c.toMap()],
              label: AppLocalizations.of(context).allCurrencies,
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
                          hint: AppLocalizations.of(context).rateHint,
                          label: AppLocalizations.of(context).rateToBase,
                          autofocus: true,
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
            // The Save button only exists while there's something to save: a
            // rate to enter, or an in-flight / just-finished save (so its
            // spinner + success tick still show). Otherwise it collapses away
            // instead of sitting empty under the dropdown.
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: (state.needToEnterRate || state.sending || state.success)
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _SaveButton(
                          state: state,
                          onPressed: () => _submit(state),
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
            // Correct the rate of any non-base currency (rates drift over time).
            // Old transactions stay frozen at their logged rate — see editRate.
            _RatesSection(
              currencies: state.currencies,
              baseSymbol: state.baseSymbol ?? '',
              onEdit: (id, rate) =>
                  context.read<BaseCurrencyCubit>().editRate(id, rate),
            ),
          ],
        );
      },
    );
  }
}

/// A list of every non-base currency's editable rate, shown under the base
/// picker. Hidden when there are no other currencies with a rate.
class _RatesSection extends StatelessWidget {
  const _RatesSection({
    required this.currencies,
    required this.baseSymbol,
    required this.onEdit,
  });

  final List<Currency> currencies;
  final String baseSymbol;
  final void Function(int id, double rate) onEdit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final others = currencies
        .where((c) => c.currencyRateToBase != null && !c.isBaseCurrency)
        .toList();
    if (others.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text(
          l.exchangeRates,
          style: kTextStyle.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        for (final c in others)
          _RateRow(currency: c, baseSymbol: baseSymbol, onEdit: onEdit),
      ],
    );
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow({
    required this.currency,
    required this.baseSymbol,
    required this.onEdit,
  });

  final Currency currency;
  final String baseSymbol;
  final void Function(int id, double rate) onEdit;

  static String _fmt(double r) => r % 1 == 0
      ? r.toInt().toString()
      : r.toStringAsFixed(r < 1 ? 4 : 2);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rate = currency.currencyRateToBase ?? 0;
    final code = currency.currencyCode.isNotEmpty
        ? currency.currencyCode
        : currency.currencySymbol;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.ratePerUnit(code, _fmt(rate), baseSymbol),
              style: kTextStyle.copyWith(fontSize: 14),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: l.editRate,
            onPressed: () => _showEditRateDialog(context, currency, rate, onEdit),
            icon: Icon(
              Icons.edit_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Prompts for a corrected rate ("1 [code] = X [base]") and applies it. The
/// controller is disposed only after the dialog fully closes.
Future<void> _showEditRateDialog(
  BuildContext context,
  Currency currency,
  double current,
  void Function(int id, double rate) onEdit,
) async {
  final l = AppLocalizations.of(context);
  final controller = TextEditingController(
    text: current % 1 == 0 ? current.toInt().toString() : current.toString(),
  );
  final result = await showDialog<double>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('${l.editRate} · ${currency.currencyCode}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l.rateToBase,
              hintText: l.rateHint,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l.editRateNote,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () {
            final v = double.tryParse(controller.text.replaceAll(',', '.'));
            Navigator.pop(ctx, (v != null && v > 0) ? v : null);
          },
          child: Text(l.save),
        ),
      ],
    ),
  );
  controller.dispose();
  if (result != null) onEdit(currency.currencyId, result);
}

/// The morphing "Save" action for a base-currency change: label → spinner while
/// saving → tick on success.
class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.state, required this.onPressed});

  final BaseCurrencyState state;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final busy = state.sending || state.success;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      onPressed: busy ? null : onPressed,
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
                AppLocalizations.of(context).save,
                style: kTextStyle.copyWith(),
                key: const ValueKey('default'),
              ),
      ),
    );
  }
}
