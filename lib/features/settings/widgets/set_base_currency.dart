import 'package:finance_app/core/widgets/item_avatar.dart';
import 'package:finance_app/features/settings/cubit/base_currency_cubit.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Currency manager for the settings card: the list of currencies the user has
/// added (each with its rate to the base), with
///  * tap a currency  → make it the base (one tap; existing ones already have a
///    rate so nothing to type);
///  * pencil          → correct its rate (old transactions stay frozen);
///  * "+" (top-right) → a bottom sheet to add a new currency from the full list.
/// The active base is framed; only the first five show until expanded.
class SetBaseCurrency extends StatefulWidget {
  const SetBaseCurrency({super.key});

  @override
  State<SetBaseCurrency> createState() => _SetBaseCurrencyState();
}

class _SetBaseCurrencyState extends State<SetBaseCurrency> {
  static const _collapsedCount = 5;
  bool _expanded = false;

  /// Currencies the user has added (they carry a rate), base first then A→Z.
  List<Currency> _added(List<Currency> all) {
    final added = all
        .where((c) => c.currencyRateToBase != null)
        .toList()
      ..sort((a, b) {
        if (a.isBaseCurrency != b.isBaseCurrency) {
          return a.isBaseCurrency ? -1 : 1;
        }
        return a.currencyCode.compareTo(b.currencyCode);
      });
    return added;
  }

  Future<void> _openAddSheet() async {
    final cubit = context.read<BaseCurrencyCubit>();
    final state = cubit.state;
    final hasBase = state.baseSymbol != null;
    final addable =
        state.currencies.where((c) => c.currencyRateToBase == null).toList()
          ..sort((a, b) => a.currencyCode.compareTo(b.currencyCode));

    final picked = await showModalBottomSheet<Currency>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _AddCurrencySheet(currencies: addable),
    );
    if (picked == null || !mounted) return;

    if (!hasBase) {
      // First currency ever → it simply becomes the base (rate 1.0).
      cubit.selectCurrency(picked.currencyId);
      return;
    }
    // Adding a non-base currency: capture its rate to the current base.
    final rate = await _showRateDialog(context, picked, current: null);
    if (rate != null && mounted) cubit.editRate(picked.currencyId, rate);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BlocConsumer<BaseCurrencyCubit, BaseCurrencyState>(
      listenWhen: (prev, curr) =>
          prev.error != curr.error && curr.error != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l.somethingWentWrong}: ${state.error}',
              style: kTextStyle.copyWith(overflow: TextOverflow.visible),
            ),
            backgroundColor: Colors.red,
          ),
        );
      },
      builder: (context, state) {
        if (state.status == BaseCurrencyStatus.loading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (state.status == BaseCurrencyStatus.error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(l.somethingWentWrong),
            ),
          );
        }

        final added = _added(state.currencies);
        final showToggle = added.length > _collapsedCount;
        final visible = _expanded ? added : added.take(_collapsedCount).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: title + a "+" that opens the add-currency sheet.
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.baseCurrency,
                    style: kTextStyle.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _AddButton(onTap: _openAddSheet),
              ],
            ),
            const SizedBox(height: 4),
            if (added.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  l.addFirstCurrencyHint,
                  style: kTextStyle.copyWith(
                    fontSize: 13.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final c in visible)
                _CurrencyRow(
                  currency: c,
                  baseSymbol: state.baseSymbol ?? '',
                  onMakeBase: () => context
                      .read<BaseCurrencyCubit>()
                      .selectCurrency(c.currencyId),
                  onEdit: () async {
                    final cubit = context.read<BaseCurrencyCubit>();
                    final rate = await _showRateDialog(
                      context,
                      c,
                      current: c.currencyRateToBase,
                    );
                    if (rate != null) cubit.editRate(c.currencyId, rate);
                  },
                ),
            if (showToggle)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _expanded ? l.collapse : l.showAllCount(added.length),
                    style: kTextStyle.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The "+" affordance in the card header.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: primary.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(Icons.add_rounded, size: 22, color: primary),
        ),
      ),
    );
  }
}

/// One added-currency row. Tapping it makes the currency the base (unless it
/// already is); the base row is framed and shows a "Base" tag instead of a rate.
class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({
    required this.currency,
    required this.baseSymbol,
    required this.onMakeBase,
    required this.onEdit,
  });

  final Currency currency;
  final String baseSymbol;
  final VoidCallback onMakeBase;
  final VoidCallback onEdit;

  static String _fmt(double r) => r % 1 == 0
      ? r.toInt().toString()
      : r.toStringAsFixed(r < 1 ? 4 : 2);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isBase = currency.isBaseCurrency;
    final rate = currency.currencyRateToBase ?? 0;
    final code = currency.currencyCode.isNotEmpty
        ? currency.currencyCode
        : currency.currencySymbol;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kRadiusSm),
        color: isBase ? cs.primary.withValues(alpha: 0.06) : null,
        border: isBase
            ? Border.all(color: cs.primary.withValues(alpha: 0.9), width: 1.5)
            : Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // Tapping the current base does nothing; others rebase in one tap.
          onTap: isBase ? null : onMakeBase,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                ItemAvatar(
                  color: cs.primary,
                  label: currency.currencySymbol.isNotEmpty
                      ? currency.currencySymbol
                      : code,
                  diameter: 38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        code,
                        style: kTextStyle.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!isBase)
                        Text(
                          l.ratePerUnit(code, _fmt(rate), baseSymbol),
                          style: kTextStyle.copyWith(
                            fontSize: 12.5,
                            color: cs.onSurfaceVariant,
                          ),
                        )
                      else if (currency.currencyName.isNotEmpty)
                        Text(
                          currency.currencyName,
                          style: kTextStyle.copyWith(
                            fontSize: 12.5,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isBase)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(kRadiusSm),
                    ),
                    child: Text(
                      l.baseTag,
                      style: kTextStyle.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  )
                else
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: l.editRate,
                    onPressed: onEdit,
                    icon: Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: cs.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet that lists every currency not yet added, with a search box.
/// Pops with the chosen [Currency].
class _AddCurrencySheet extends StatefulWidget {
  const _AddCurrencySheet({required this.currencies});

  final List<Currency> currencies;

  @override
  State<_AddCurrencySheet> createState() => _AddCurrencySheetState();
}

class _AddCurrencySheetState extends State<_AddCurrencySheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final q = _query.trim().toLowerCase();
    final items = q.isEmpty
        ? widget.currencies
        : widget.currencies
              .where(
                (c) =>
                    c.currencyCode.toLowerCase().contains(q) ||
                    c.currencyName.toLowerCase().contains(q) ||
                    c.currencySymbol.toLowerCase().contains(q),
              )
              .toList();

    return Padding(
      // Keep the field above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.addCurrency,
                      style: kTextStyle.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        hintText: l.searchCurrency,
                        filled: true,
                        fillColor: cs.onSurface.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(kRadiusSm),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final c = items[i];
                    final code = c.currencyCode.isNotEmpty
                        ? c.currencyCode
                        : c.currencySymbol;
                    return ListTile(
                      leading: ItemAvatar(
                        color: cs.primary,
                        label: c.currencySymbol.isNotEmpty
                            ? c.currencySymbol
                            : code,
                        diameter: 38,
                      ),
                      title: Text(
                        code,
                        style: kTextStyle.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: c.currencyName.isNotEmpty
                          ? Text(
                              c.currencyName,
                              style: kTextStyle.copyWith(
                                fontSize: 12.5,
                                color: cs.onSurfaceVariant,
                              ),
                            )
                          : null,
                      onTap: () => Navigator.pop(context, c),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Prompts for a currency's rate ("1 [code] = X [base]"). Returns the entered
/// rate, or null on cancel. Used both to correct an existing rate and to set the
/// rate of a newly added currency.
Future<double?> _showRateDialog(
  BuildContext context,
  Currency currency, {
  required double? current,
}) {
  return showDialog<double>(
    context: context,
    builder: (_) => _EditRateDialog(currency: currency, current: current),
  );
}

/// The rate dialog owns its own text controller and disposes it in its
/// [dispose] — which runs only after the dialog's exit animation finishes.
/// (Disposing a controller right after `await showDialog` throws "used after
/// being disposed" because the field still rebuilds during the close.)
class _EditRateDialog extends StatefulWidget {
  const _EditRateDialog({required this.currency, required this.current});

  final Currency currency;
  final double? current;

  @override
  State<_EditRateDialog> createState() => _EditRateDialogState();
}

class _EditRateDialogState extends State<_EditRateDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.current == null
        ? ''
        : widget.current! % 1 == 0
        ? widget.current!.toInt().toString()
        : widget.current!.toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final adding = widget.current == null;
    return AlertDialog(
      title: Text(
        '${adding ? l.addCurrency : l.editRate} · ${widget.currency.currencyCode}',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () {
            final v = double.tryParse(_controller.text.replaceAll(',', '.'));
            Navigator.pop(context, (v != null && v > 0) ? v : null);
          },
          child: Text(l.save),
        ),
      ],
    );
  }
}
