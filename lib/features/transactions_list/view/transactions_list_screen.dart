import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/widgets/amount_text.dart';
import 'package:finance_app/core/widgets/empty_state.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/transactions_list/cubit/transactions_list_cubit.dart';
import 'package:finance_app/features/transactions_list/period_grouping.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionsListScreen extends StatelessWidget {
  const TransactionsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TransactionsListCubit(
        getIt<TransactionRepository>(),
        getIt<CurrencyRepository>(),
      ),
      child: const _TransactionsListView(),
    );
  }
}

class _TransactionsListView extends StatelessWidget {
  const _TransactionsListView();

  Future<void> _pickCustomRange(BuildContext context) async {
    final cubit = context.read<TransactionsListCubit>();
    final today = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year + 1),
      initialDateRange:
          cubit.state.customRange ??
          DateTimeRange(
            start: today.subtract(const Duration(days: 7)),
            end: today,
          ),
    );
    if (picked != null) cubit.selectCustomRange(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    return Scaffold(
      appBar: AppBar(
        title: Text(l.transactionsTitle, style: kTextStyle.copyWith()),
        actions: [
          IconButton(
            // The list refreshes automatically (reactive stream) once the add
            // screen writes a transaction.
            onPressed: () =>
                Navigator.of(context).pushNamed('/add-transaction'),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: BlocBuilder<TransactionsListCubit, TransactionsListState>(
        builder: (context, state) {
          if (state.status == TransactionsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == TransactionsStatus.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(l.somethingWentWrong),
              ),
            );
          }

          final groups = state.groups;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PresetChips(
                        preset: state.preset,
                        onSelect: (p) => context
                            .read<TransactionsListCubit>()
                            .selectPreset(p),
                        onPickCustom: () => _pickCustomRange(context),
                      ),
                      const SizedBox(height: 8),
                      _PeriodSummary(
                        label: formatAuto(state.range, state.preset, l, locale),
                        income: state.totals['income'] ?? 0,
                        expense: state.totals['expense'] ?? 0,
                        baseSymbol: state.baseSymbol ?? '',
                      ),
                    ],
                  ),
                ),
              ),
              if (groups.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: l.noTransactions,
                    subtitle: l.nothingInPeriod,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _GroupCard(group: groups[i]),
                    childCount: groups.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PresetChips extends StatelessWidget {
  const _PresetChips({
    required this.preset,
    required this.onSelect,
    required this.onPickCustom,
  });

  final PeriodPreset preset;
  final void Function(PeriodPreset) onSelect;
  final Future<void> Function() onPickCustom;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      children: PeriodPreset.values.map((p) {
        final selected = p == preset;
        return ChoiceChip(
          label: Text(
            periodChipLabel(l, p),
            style: kTextStyle.copyWith(
              color: selected
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          selected: selected,
          onSelected: (selected) {
            if (!selected) return;
            if (p == PeriodPreset.custom) {
              onPickCustom();
            } else {
              onSelect(p);
            }
          },
        );
      }).toList(),
    );
  }
}

class _PeriodSummary extends StatelessWidget {
  const _PeriodSummary({
    required this.label,
    required this.income,
    required this.expense,
    required this.baseSymbol,
  });

  final String label;
  final double income;
  final double expense;
  final String baseSymbol;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            style: kTextStyle.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AmountText(
              income,
              symbol: baseSymbol,
              signed: true,
              style: kTextStyle.copyWith(
                color: AppColors.positive,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            AmountText(
              -expense,
              symbol: baseSymbol,
              signed: true,
              style: kTextStyle.copyWith(
                color: AppColors.negative,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});

  final TransactionGroup group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(kRadiusLg),
          boxShadow: kCardShadow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (group.title != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2, left: 2),
                child: Text(
                  group.title!,
                  style: kTextStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ...group.items.map((t) => _TransactionTile(transaction: t)),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final TransactionDetails transaction;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final code = t.currencyCode ?? '';

    final primary = t.isTransfer
        ? (t.accountDestinationName ?? '')
        : (t.categoryName ?? '');
    final secondary = t.accountName ?? '';

    final Color amountColor = t.isExpense
        ? AppColors.negative
        : t.isIncome
        ? AppColors.positive
        : Theme.of(context).colorScheme.onSurface;
    final time =
        '${t.date.hour.toString().padLeft(2, '0')}:'
        '${t.date.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () => Navigator.of(
        context,
      ).pushNamed('/add-transaction', arguments: t),
      borderRadius: BorderRadius.circular(kRadiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.categoryColor,
              ),
              child: Icon(t.categoryIcon, color: t.categoryIconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: kTextStyle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: kTextStyle.copyWith(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AmountText(
                  t.isExpense ? -t.amount : t.amount,
                  symbol: code,
                  signed: !t.isTransfer,
                  style: kTextStyle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: kTextStyle.copyWith(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
