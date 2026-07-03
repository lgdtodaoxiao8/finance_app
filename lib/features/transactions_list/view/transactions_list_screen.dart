import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/transactions_list/cubit/transactions_list_cubit.dart';
import 'package:finance_app/features/transactions_list/period_grouping.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionsListScreen extends StatelessWidget {
  const TransactionsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TransactionsListCubit(getIt<TransactionRepository>()),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: Text('List', style: kTextStyle.copyWith()),
        backgroundColor: const Color(0xFFF7F7FA),
        centerTitle: true,
        scrolledUnderElevation: 0,
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
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Text('Something went wrong'),
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
                        label: formatAuto(state.range, state.preset),
                        income: state.totals['income'] ?? 0,
                        expense: state.totals['expense'] ?? 0,
                      ),
                    ],
                  ),
                ),
              ),
              if (groups.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Нет транзакций в выбранном диапазоне',
                      style: kTextStyle.copyWith(),
                    ),
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
    return Wrap(
      spacing: 8,
      children: PeriodPreset.values.map((p) {
        return ChoiceChip(
          label: Text(periodChipLabels[p]!, style: kTextStyle.copyWith()),
          selected: p == preset,
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
  });

  final String label;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(label, style: kTextStyle.copyWith()),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+${income.toStringAsFixed(2)}',
              style: kTextStyle.copyWith(
                color: Colors.green[400],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '-${expense.toStringAsFixed(2)}',
              style: kTextStyle.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        color: Colors.white,
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (group.title != null) ...[
                Text(
                  group.title!,
                  style: kTextStyle.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
              ],
              ...group.items.map((t) => _TransactionTile(transaction: t)),
            ],
          ),
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

    Widget amountText;
    if (t.isExpense) {
      amountText = Text(
        '- ${t.amount} $code',
        style: kTextStyle.copyWith(
          color: Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.w500,
        ),
      );
    } else if (t.isIncome) {
      amountText = Text(
        '+ ${t.amount} $code',
        style: kTextStyle.copyWith(
          color: Colors.green[500],
          fontWeight: FontWeight.w500,
        ),
      );
    } else {
      amountText = Text(
        '${t.amount} $code',
        style: kTextStyle.copyWith(fontWeight: FontWeight.w500),
      );
    }

    return ListTile(
      leading: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: t.categoryColor,
        ),
        child: Icon(t.categoryIcon, color: t.categoryIconColor, size: 25),
      ),
      title: amountText,
      subtitle: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(text: t.accountName ?? ''),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(
                t.isIncome
                    ? Icons.arrow_left_rounded
                    : Icons.arrow_right_rounded,
                size: 20,
                color: Colors.grey,
              ),
            ),
            TextSpan(
              text: t.isTransfer
                  ? (t.accountDestinationName ?? '')
                  : (t.categoryName ?? ''),
            ),
          ],
        ),
      ),
      trailing: Text(
        '${t.date.hour.toString().padLeft(2, '0')}:'
        '${t.date.minute.toString().padLeft(2, '0')}',
        style: kTextStyle.copyWith(),
      ),
    );
  }
}
