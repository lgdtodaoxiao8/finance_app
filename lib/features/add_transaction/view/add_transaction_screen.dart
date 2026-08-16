import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/add_transaction/cubit/add_transaction_cubit.dart';
import 'package:finance_app/features/add_transaction/widgets/type_switcher.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Route arguments for a brand-new transaction opened pre-filled (e.g. from a
/// home-screen widget quick-add). Distinct from a [TransactionDetails] argument,
/// which opens the screen in edit mode.
class AddTxArgs {
  const AddTxArgs({this.categoryId, this.amount, this.type});

  /// Pre-selected category.
  final int? categoryId;

  /// Pre-filled amount (e.g. built on the widget).
  final double? amount;

  /// 'expense' | 'income' — the widget flow this was logged from.
  final String? type;
}

class AddTransaction extends StatelessWidget {
  const AddTransaction({super.key});

  @override
  Widget build(BuildContext context) {
    // Route arguments: a TransactionDetails edits an existing transaction; an
    // AddTxArgs pre-fills a new one (widget quick-add); null starts blank.
    final args = ModalRoute.of(context)?.settings.arguments;
    final existing = args is TransactionDetails ? args : null;
    final prefill = args is AddTxArgs ? args : null;

    return BlocProvider(
      create: (_) => AddTransactionCubit(
        getIt<AccountRepository>(),
        getIt<CategoryRepository>(),
        getIt<CurrencyRepository>(),
        getIt<TransactionRepository>(),
        existing: existing,
        presetType: prefill?.type,
        presetCategoryId: prefill?.categoryId,
      ),
      child: _AddTransactionView(
        isEditing: existing != null,
        prefillAmount: prefill?.amount,
      ),
    );
  }
}

class _AddTransactionView extends StatefulWidget {
  const _AddTransactionView({required this.isEditing, this.prefillAmount});

  final bool isEditing;
  final double? prefillAmount;

  @override
  State<_AddTransactionView> createState() => _AddTransactionViewState();
}

class _AddTransactionViewState extends State<_AddTransactionView> {
  final _amountController = TextEditingController();
  final _amountFocus = FocusNode();
  String _note = '';
  bool _prefilled = false;

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  double? get _amount {
    final raw = _amountController.text.trim().replaceAll(',', '.');
    final v = double.tryParse(raw);
    return (v == null || v <= 0) ? null : v;
  }

  // --- lookups -------------------------------------------------------------
  Currency? _currency(AddTransactionState s) =>
      _byId(s.currencies, s.currencyId, (c) => c.currencyId);
  Category? _category(AddTransactionState s) =>
      _byId(s.categories, s.categoryId, (c) => c.categoryId);
  Account? _account(AddTransactionState s, int? id) =>
      _byId(s.accounts, id, (a) => a.accountId);

  T? _byId<T>(List<T> list, int? id, int Function(T) idOf) {
    if (id == null) return null;
    for (final e in list) {
      if (idOf(e) == id) return e;
    }
    return null;
  }

  // --- actions -------------------------------------------------------------
  void _submit(AddTransactionCubit cubit) {
    final blocker = cubit.state.validationError;
    if (blocker != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_blockerText(blocker))),
      );
      return;
    }
    final amount = _amount;
    if (amount == null) return;
    cubit.add(amount: amount, note: _note);
  }

  String _blockerText(TransactionBlocker blocker) {
    final l = AppLocalizations.of(context);
    return switch (blocker) {
      TransactionBlocker.noAccount => l.blockerNoAccount,
      TransactionBlocker.noCategory => l.blockerNoCategory,
      TransactionBlocker.noCurrency => l.blockerNoCurrency,
      TransactionBlocker.noSecondAccount => l.blockerNoSecondAccount,
      TransactionBlocker.sameAccounts => l.blockerSameAccounts,
    };
  }

  Future<void> _confirmDelete(AddTransactionCubit cubit) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteTransactionQuestion, style: kTextStyle.copyWith()),
        content: Text(l.actionCannotBeUndone, style: kTextStyle.copyWith()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel, style: kTextStyle.copyWith()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l.delete,
              style: kTextStyle.copyWith(color: Theme.of(context).colorScheme.error),
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
      body: BlocConsumer<AddTransactionCubit, AddTransactionState>(
        listenWhen: (p, c) => !p.saved && c.saved,
        listener: (context, state) => Navigator.of(context).pop(),
        builder: (context, state) {
          final cubit = context.read<AddTransactionCubit>();
          if (state.status == AddTransactionStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == AddTransactionStatus.error) {
            return _CenteredMessage(
              text: AppLocalizations.of(context).somethingWentWrong,
            );
          }
          if (!state.isReady) {
            return SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    onClose: () => Navigator.of(context).pop(),
                    switcher: null,
                    onDelete: null,
                  ),
                  Expanded(child: _OnboardingGate(state: state)),
                ],
              ),
            );
          }

          // One-time prefill of amount + note when editing (state is ready now).
          if (!_prefilled) {
            _prefilled = true;
            if (state.initialAmount != null) {
              // Show the decimal separator the input uses (comma) rather than
              // the raw dot from the stored double.
              _amountController.text = state.initialAmount!.replaceAll('.', ',');
            } else if (widget.prefillAmount != null &&
                widget.prefillAmount! > 0) {
              // Amount already built on the widget — continue where it left off.
              final a = widget.prefillAmount!;
              _amountController.text = (a == a.roundToDouble()
                      ? a.toInt().toString()
                      : a.toString())
                  .replaceAll('.', ',');
            }
            _note = state.initialNote ?? '';
          }

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(
                  onClose: () => Navigator.of(context).pop(),
                  switcher: TypeSwitcher(
                    value: state.type,
                    onChanged: (type, index) {
                      _amountFocus.requestFocus();
                      cubit.setType(type, index);
                    },
                  ),
                  onDelete: widget.isEditing
                      ? () => _confirmDelete(cubit)
                      : null,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _amountLine(context, state, cubit),
                        const SizedBox(height: 22),
                        _sentence(context, state, cubit),
                        const SizedBox(height: 18),
                        _noteAffordance(context),
                      ],
                    ),
                  ),
                ),
                _saveBar(context, state, cubit),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- amount line ---------------------------------------------------------
  /// Shared style for the hero amount field (input + hint) so the on-screen
  /// text and the width measurement below stay in lock-step.
  static final TextStyle _amountTextStyle = kTextStyle.copyWith(
    fontSize: 50,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
  );

  /// Width the amount field should occupy so it hugs its text (like the old
  /// IntrinsicWidth did) without triggering an intrinsic re-measure of the
  /// TextField. Falls back to the '0' hint width when empty; a few px of slack
  /// keeps the caret from being clipped after the last glyph.
  double _amountFieldWidth(BuildContext context) {
    final text = _amountController.text.isEmpty ? '0' : _amountController.text;
    final painter = TextPainter(
      text: TextSpan(text: text, style: _amountTextStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return painter.width + 3;
  }

  Widget _amountLine(
    BuildContext context,
    AddTransactionState state,
    AddTransactionCubit cubit,
  ) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final currency = _currency(state);
    final category = _category(state);
    // Transfer has no visible category, so its caret uses the neutral type
    // accent instead of the hidden fallback category's colour.
    final caret =
        (state.type != 'transfer' ? category?.categoryColor : null) ??
        TypeSwitcher.solid(state.type);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          currency?.currencySymbol ?? '',
          style: kTextStyle.copyWith(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: onSurface,
          ),
        ),
        const SizedBox(width: 6),
        // Auto-width via a measured SizedBox rather than IntrinsicWidth: an
        // IntrinsicWidth around a TextField crashes ('_dependents.isEmpty')
        // when the keyboard reappears (e.g. dismissing the note sheet) and the
        // still-mounted field gets an intrinsic re-measure on the viewInsets
        // change. A fixed width relayouts without any intrinsic pass.
        SizedBox(
          width: _amountFieldWidth(context),
          child: TextField(
            controller: _amountController,
            focusNode: _amountFocus,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            cursorColor: caret,
            onChanged: (_) => setState(() {}),
            style: _amountTextStyle.copyWith(color: onSurface),
            decoration: InputDecoration.collapsed(
              hintText: '0',
              hintStyle: _amountTextStyle.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _pickCurrency(context, state, cubit),
          child: Text(
            currency?.currencyCode ?? '',
            style: _dotted(const Color(0xFF6B7178), size: 16),
          ),
        ),
      ],
    );
  }

  // --- the sentence --------------------------------------------------------
  Widget _sentence(
    BuildContext context,
    AddTransactionState state,
    AddTransactionCubit cubit,
  ) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final neutral = Theme.of(context).colorScheme.onSurface;

    final dateToken = _token(
      label: _dateLabel(state.date ?? DateTime.now(), l, locale),
      color: neutral,
      onTap: () => _pickDate(context, state, cubit),
    );

    Widget accountToken(int? id, {required bool destination}) {
      final acc = _account(state, id);
      return _token(
        label: acc?.accountName ?? l.chooseAccount,
        color: neutral,
        icon: acc?.accountIcon,
        iconColor: muted,
        onTap: () =>
            _pickAccount(context, state, cubit, destination: destination),
      );
    }

    List<Widget> line1;
    List<Widget> line2;

    if (state.type == 'transfer') {
      line1 = [
        _connector('${l.txFrom} ', muted),
        accountToken(state.accountId, destination: false),
      ];
      line2 = [
        _connector('${l.txTo} ', muted),
        accountToken(state.accountDestinationId, destination: true),
        _connector(', ', muted),
        dateToken,
      ];
    } else {
      final isIncome = state.type == 'income';
      final category = _category(state);
      final categoryToken = _token(
        label: category?.categoryName ?? l.chooseCategory,
        color: category?.categoryColor ?? muted,
        icon: category?.categoryIcon,
        onTap: () => _pickCategory(context, state, cubit),
      );
      line1 = isIncome
          ? [categoryToken]
          : [_connector('${l.txOn} ', muted), categoryToken];
      line2 = [
        _connector('${isIncome ? l.txTo : l.txFrom} ', muted),
        accountToken(state.accountId, destination: false),
        _connector(', ', muted),
        dateToken,
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: line1),
        const SizedBox(height: 8),
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: line2),
      ],
    );
  }

  Widget _connector(String text, Color color) => Text(
    text,
    style: kTextStyle.copyWith(fontSize: 22, fontWeight: FontWeight.w500, color: color),
  );

  Widget _token({
    required String label,
    required Color color,
    IconData? icon,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 19, color: iconColor ?? color),
            const SizedBox(width: 3),
          ],
          Text(label, style: _dotted(color)),
        ],
      ),
    );
  }

  TextStyle _dotted(Color color, {double size = 22, FontWeight w = FontWeight.w700}) {
    return kTextStyle.copyWith(
      fontSize: size,
      fontWeight: w,
      color: color,
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.dotted,
      decorationColor: color.withValues(alpha: 0.45),
      decorationThickness: 2,
    );
  }

  Widget _noteAffordance(BuildContext context) {
    final l = AppLocalizations.of(context);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final hasNote = _note.trim().isNotEmpty;
    return GestureDetector(
      onTap: () => _editNote(context),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasNote ? Icons.sticky_note_2_outlined : Icons.add,
            size: 17,
            color: muted,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              hasNote ? _note : l.sentenceNote,
              style: kTextStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- save bar ------------------------------------------------------------
  Widget _saveBar(
    BuildContext context,
    AddTransactionState state,
    AddTransactionCubit cubit,
  ) {
    final l = AppLocalizations.of(context);
    final color = TypeSwitcher.solid(state.type);
    final enabled = _amount != null && !state.sending;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: SizedBox(
        height: 52,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: color,
            disabledBackgroundColor: color.withValues(alpha: 0.4),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: enabled ? () => _submit(cubit) : null,
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
                  widget.isEditing ? l.save : l.add,
                  style: kTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  // --- pickers -------------------------------------------------------------
  Future<void> _pickCategory(
    BuildContext context,
    AddTransactionState state,
    AddTransactionCubit cubit,
  ) async {
    final wantIncome = state.type == 'income';
    final cats = state.categories.where((c) => c.isIncome == wantIncome).toList();
    _amountFocus.unfocus();
    await _sheet(
      context,
      child: _ChipPicker(
        title: AppLocalizations.of(context).selectCategory,
        items: [
          for (final c in cats)
            _PickItem(
              id: c.categoryId,
              label: c.categoryName,
              color: c.categoryColor,
              icon: c.categoryIcon,
              selected: c.categoryId == state.categoryId,
            ),
        ],
        onPick: (id) {
          cubit.setCategory(id);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _pickAccount(
    BuildContext context,
    AddTransactionState state,
    AddTransactionCubit cubit, {
    required bool destination,
  }) async {
    final current = destination ? state.accountDestinationId : state.accountId;
    _amountFocus.unfocus();
    await _sheet(
      context,
      child: _ChipPicker(
        title: AppLocalizations.of(context).chooseAccount,
        items: [
          for (final a in state.accounts)
            _PickItem(
              id: a.accountId,
              label: a.accountName,
              color: AppColors.iconMuted,
              icon: a.accountIcon,
              selected: a.accountId == current,
            ),
        ],
        onPick: (id) {
          if (destination) {
            cubit.setAccountDestination(id);
          } else {
            cubit.setAccount(id);
          }
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _pickCurrency(
    BuildContext context,
    AddTransactionState state,
    AddTransactionCubit cubit,
  ) async {
    _amountFocus.unfocus();
    await _sheet(
      context,
      child: _ChipPicker(
        title: AppLocalizations.of(context).currency,
        items: [
          for (final c in state.currencies)
            _PickItem(
              id: c.currencyId,
              label: '${c.currencyCode} · ${c.currencySymbol}',
              color: AppColors.iconMuted,
              selected: c.currencyId == state.currencyId,
            ),
        ],
        onPick: (id) {
          cubit.setCurrency(id);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    AddTransactionState state,
    AddTransactionCubit cubit,
  ) async {
    final now = DateTime.now();
    final current = state.date ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: now.copyWith(year: now.year - 20),
      lastDate: now,
    );
    if (picked != null) {
      cubit.setDate(DateTime(
        picked.year,
        picked.month,
        picked.day,
        current.hour,
        current.minute,
        current.second,
      ));
    }
  }

  Future<void> _editNote(BuildContext context) async {
    _amountFocus.unfocus();
    // The note field lives in its own StatefulWidget so its
    // TextEditingController is disposed by that widget's own dispose() — which
    // runs only after the sheet's exit animation completes and the element
    // unmounts. Disposing it inline right after `await` fired while the sheet
    // was still rebuilding during the close transition, so EditableText
    // re-listened to a disposed controller ("used after being disposed").
    final result = await _sheet<String>(
      context,
      child: _NoteSheet(initialText: _note),
    );
    if (result != null) setState(() => _note = result);
  }

  Future<T?> _sheet<T>(BuildContext context, {required Widget child}) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: SafeArea(top: false, child: child),
      ),
    );
  }

  String _dateLabel(DateTime date, AppLocalizations l, String locale) {
    final now = DateTime.now();
    final sameDay =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (sameDay) return l.today;
    return DateFormat('d MMM', locale).format(date);
  }
}

// --- shared little pieces ---------------------------------------------------

/// The note editor shown in a bottom sheet. Owns its [TextEditingController] so
/// the controller outlives the sheet's close animation (disposing it inline in
/// the caller crashed EditableText with "used after being disposed"). Returns
/// the trimmed note via [Navigator.pop]; barrier-dismiss returns null (no
/// change).
class _NoteSheet extends StatefulWidget {
  const _NoteSheet({required this.initialText});

  final String initialText;

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      // The sheet's own context → reactive to the keyboard's viewInsets.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            minLines: 1,
            style: kTextStyle.copyWith(fontSize: 16),
            decoration: InputDecoration(
              hintText: l.note,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusSm),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
            child: Text(l.done, style: kTextStyle.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose, required this.switcher, required this.onDelete});

  final VoidCallback onClose;
  final Widget? switcher;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (switcher != null) switcher!,
          if (onDelete != null)
            IconButton(
              tooltip: AppLocalizations.of(context).delete,
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Center(
    child: Text(text, style: kTextStyle.copyWith(), softWrap: true),
  );
}

class _PickItem {
  const _PickItem({
    required this.id,
    required this.label,
    required this.color,
    this.icon,
    required this.selected,
  });
  final int id;
  final String label;
  final Color color;
  final IconData? icon;
  final bool selected;
}

class _ChipPicker extends StatelessWidget {
  const _ChipPicker({
    required this.title,
    required this.items,
    required this.onPick,
  });

  final String title;
  final List<_PickItem> items;
  final void Function(int id) onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: kTextStyle.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final it in items) _chip(context, it)],
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, _PickItem it) {
    return GestureDetector(
      onTap: () => onPick(it.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: it.color.withValues(alpha: it.selected ? 0.18 : 0.10),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: it.selected ? it.color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (it.icon != null) ...[
              Icon(it.icon, size: 17, color: it.color),
              const SizedBox(width: 7),
            ],
            Text(
              it.label,
              style: kTextStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: it.selected ? it.color : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown instead of the form when prerequisites are missing, guiding the user
/// through the first-time setup (base currency -> account -> category).
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

    final l = AppLocalizations.of(context);
    if (state.needsBaseCurrency) {
      icon = Icons.currency_exchange_rounded;
      title = l.setupBaseCurrencyTitle;
      subtitle = l.setupBaseCurrencyBody;
      cta = l.setupBaseCurrencyAction;
      route = '/add-currency';
    } else if (state.needsAccount) {
      icon = Icons.account_balance_wallet_rounded;
      title = l.setupAccountTitle;
      subtitle = l.setupAccountBody;
      cta = l.setupAccountAction;
      route = '/add-account';
    } else {
      icon = Icons.category_rounded;
      title = l.setupCategoryTitle;
      subtitle = l.setupCategoryBody;
      cta = l.setupCategoryAction;
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
              style: kTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: kTextStyle.copyWith(fontSize: 14, color: AppColors.textSecondary),
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
