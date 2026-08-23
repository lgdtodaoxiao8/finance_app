import 'dart:async';

import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/format.dart';
import 'package:finance_app/core/widgets/amount_input_dialog.dart';
import 'package:finance_app/core/widgets/amount_text.dart';
import 'package:finance_app/core/widgets/item_avatar.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/goal_repository.dart';
import 'package:finance_app/features/goals/data/goal.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

/// The Goals ("копилки") block of the Plans hub: named savings jars with a
/// target and progress, topped up / drawn down by hand. Self-contained.
class GoalsSection extends StatefulWidget {
  const GoalsSection({super.key});

  @override
  State<GoalsSection> createState() => _GoalsSectionState();
}

class _GoalsSectionState extends State<GoalsSection> {
  static const _palette = [
    AppColors.primary,
    Color(0xFF1FB574),
    Color(0xFFF5A623),
    Color(0xFF7C3AED),
    Color(0xFFF04E5E),
    Color(0xFF00A9B7),
  ];

  StreamSubscription<List<Goal>>? _goalSub;
  StreamSubscription<List<dynamic>>? _currencySub;

  List<Goal> _goals = const [];
  String? _symbol;

  @override
  void initState() {
    super.initState();
    _goalSub = getIt<GoalRepository>().watchAll().listen(
      (g) => mounted ? setState(() => _goals = g) : null,
    );
    _currencySub = getIt<CurrencyRepository>().watchAll().listen((currencies) {
      for (final c in currencies) {
        if (c.isBaseCurrency && mounted) {
          setState(() => _symbol = c.currencySymbol);
          return;
        }
      }
    });
  }

  @override
  void dispose() {
    _goalSub?.cancel();
    _currencySub?.cancel();
    super.dispose();
  }

  Future<void> _adjust(Goal g, {required bool add}) async {
    final l = AppLocalizations.of(context);
    final amount = await showAmountInput(
      context,
      title: add ? '${l.topUp} · ${g.name}' : '${l.withdraw} · ${g.name}',
      symbol: _symbol,
      confirmLabel: add ? l.topUp : l.withdraw,
    );
    if (amount == null || amount <= 0) return;
    await getIt<GoalRepository>().adjustSaved(g.id, add ? amount : -amount);
  }

  Future<void> _addOrEdit([Goal? existing]) async {
    final result = await showModalBottomSheet<_GoalDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _GoalEditor(
        existing: existing,
        palette: _palette,
        symbol: _symbol,
      ),
    );
    if (result == null || !mounted) return;
    if (result.delete && existing != null) {
      await getIt<GoalRepository>().delete(existing.id);
      return;
    }
    if (existing == null) {
      await getIt<GoalRepository>().add(
        name: result.name,
        targetAmount: result.target,
        color: result.color.toARGB32(),
        iconCodePoint: SolarIconsBold.moneyBag.codePoint,
      );
    } else {
      await getIt<GoalRepository>().update(
        id: existing.id,
        name: result.name,
        targetAmount: result.target,
        color: result.color.toARGB32(),
        iconCodePoint: existing.icon.codePoint,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final totalSaved = _goals.fold<double>(0, (s, g) => s + g.savedAmount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.goalsTitle,
                style: kTextStyle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (_goals.isNotEmpty)
              Text(
                '${l.setAside}: ${formatMoney(totalSaved, _symbol)}',
                style: kTextStyle.copyWith(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (final g in _goals) _goalCard(l, g),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _addOrEdit(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l.addGoal),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _goalCard(AppLocalizations l, Goal g) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: kCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _addOrEdit(g),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    ItemAvatar(color: g.color, icon: g.icon, diameter: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g.name,
                            style: kTextStyle.copyWith(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (g.reached)
                            Text(
                              l.goalReached,
                              style: kTextStyle.copyWith(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.positive,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AmountText(
                          g.savedAmount,
                          symbol: _symbol,
                          style: kTextStyle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: g.color,
                          ),
                        ),
                        if (g.hasTarget)
                          Text(
                            '/ ${formatMoney(g.targetAmount!, _symbol)}',
                            style: kTextStyle.copyWith(
                              fontSize: 12.5,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (g.hasTarget) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          color: cs.onSurface.withValues(alpha: 0.08),
                        ),
                        FractionallySizedBox(
                          widthFactor: g.progress,
                          child: Container(height: 8, color: g.color),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _adjust(g, add: true),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(l.topUp),
                        style: TextButton.styleFrom(foregroundColor: cs.primary),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _adjust(g, add: false),
                        icon: const Icon(Icons.remove_rounded, size: 18),
                        label: Text(l.withdraw),
                        style: TextButton.styleFrom(
                          foregroundColor: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalDraft {
  const _GoalDraft({
    required this.name,
    this.target,
    required this.color,
    this.delete = false,
  });
  final String name;
  final double? target;
  final Color color;
  final bool delete;
}

class _GoalEditor extends StatefulWidget {
  const _GoalEditor({
    required this.existing,
    required this.palette,
    required this.symbol,
  });

  final Goal? existing;
  final List<Color> palette;
  final String? symbol;

  @override
  State<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends State<_GoalEditor> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _target = TextEditingController(
    text: widget.existing?.targetAmount == null
        ? ''
        : (widget.existing!.targetAmount! % 1 == 0
              ? widget.existing!.targetAmount!.toInt().toString()
              : widget.existing!.targetAmount!.toString()),
  );
  late Color _color = widget.existing?.color ?? widget.palette.first;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ItemAvatar(color: _color, icon: SolarIconsBold.moneyBag, diameter: 44),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _name,
                  autofocus: widget.existing == null,
                  textCapitalization: TextCapitalization.sentences,
                  style: kTextStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: l.newGoalTitle,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _target,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l.targetAmountField,
              suffixText: widget.symbol,
              filled: true,
              fillColor: cs.onSurface.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusSm),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            children: [
              for (final c in widget.palette)
                GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: _color == c
                          ? Border.all(color: cs.onSurface, width: 2.5)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              if (widget.existing != null)
                TextButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _GoalDraft(name: '', color: _color, delete: true),
                  ),
                  child: Text(
                    l.delete,
                    style: const TextStyle(color: AppColors.negative),
                  ),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _name.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(
                        context,
                        _GoalDraft(
                          name: _name.text.trim(),
                          target: double.tryParse(
                            _target.text.replaceAll(',', '.'),
                          ),
                          color: _color,
                        ),
                      ),
                child: Text(widget.existing == null ? l.add : l.save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
