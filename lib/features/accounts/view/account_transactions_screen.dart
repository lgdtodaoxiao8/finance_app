import 'dart:async';

import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/format.dart';
import 'package:finance_app/core/widgets/amount_text.dart';
import 'package:finance_app/core/widgets/empty_state.dart';
import 'package:finance_app/core/widgets/item_avatar.dart';
import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/accounts/account_math.dart';
import 'package:finance_app/features/settings/widgets/manage_section.dart';
import 'package:finance_app/features/transactions_list/widgets/transaction_tile.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Everything that ever touched one account: its balance/return header + the
/// full transaction history (as source or destination), newest first. Opened by
/// tapping an account anywhere. Edit/delete live in the app bar.
class AccountTransactionsScreen extends StatefulWidget {
  const AccountTransactionsScreen({super.key, required this.account});

  final Account account;

  @override
  State<AccountTransactionsScreen> createState() =>
      _AccountTransactionsScreenState();
}

class _AccountTransactionsScreenState
    extends State<AccountTransactionsScreen> {
  StreamSubscription<List<TransactionDetails>>? _txSub;
  StreamSubscription<List<Account>>? _accountsSub;
  StreamSubscription<List<dynamic>>? _currencySub;

  late Account _account = widget.account;
  List<TransactionDetails> _txns = const [];
  String? _symbol;
  double _balance = 0;

  @override
  void initState() {
    super.initState();
    _txSub = getIt<TransactionRepository>().watchAllWithDetails().listen(_apply);
    _accountsSub = getIt<AccountRepository>().watchAll().listen((accounts) {
      final match = accounts
          .where((a) => a.accountId == _account.accountId)
          .toList();
      if (match.isEmpty) {
        // Deleted (here or elsewhere) — leave the screen.
        if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
        return;
      }
      if (mounted) setState(() => _account = match.first);
    });
    _currencySub = getIt<CurrencyRepository>().watchAll().listen((currencies) {
      for (final c in currencies) {
        if (c.isBaseCurrency && mounted) {
          setState(() => _symbol = c.currencySymbol);
          return;
        }
      }
    });
  }

  void _apply(List<TransactionDetails> all) {
    final id = _account.accountId;
    final mine = all
        .where((t) => t.accountId == id || t.accountDestinationId == id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    var bal = 0.0;
    for (final t in mine) {
      final amt = t.amountInBase;
      if (t.isIncome && t.accountId == id) bal += amt;
      if (t.isExpense && t.accountId == id) bal -= amt;
      if (t.isTransfer) {
        if (t.accountId == id) bal -= amt;
        if (t.accountDestinationId == id) bal += amt;
      }
    }
    if (mounted) {
      setState(() {
        _txns = mine;
        _balance = bal;
      });
    }
  }

  @override
  void dispose() {
    _txSub?.cancel();
    _accountsSub?.cancel();
    _currencySub?.cancel();
    super.dispose();
  }

  Future<void> _edit() async {
    await Navigator.of(
      context,
    ).pushNamed('/add-account', arguments: _account);
    // The account stream refreshes the header on its own.
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final count = await getIt<AccountRepository>().transactionCount(
      _account.accountId,
    );
    if (!mounted) return;
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.cantDeleteAccountInUse(count))),
      );
      return;
    }
    await confirmDelete(
      context,
      what: _account.accountName,
      // Deletion makes the account disappear from the stream, and the listener
      // above pops the screen — so there's a single, race-free pop.
      onConfirm: () => getIt<AccountRepository>().delete(_account.accountId),
    );
  }

  // Groups the account's transactions by calendar day, newest first.
  List<MapEntry<DateTime, List<TransactionDetails>>> get _byDay {
    final map = <DateTime, List<TransactionDetails>>{};
    for (final t in _txns) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      (map[day] ??= <TransactionDetails>[]).add(t);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_account.accountName, style: kTextStyle.copyWith()),
        actions: [
          IconButton(
            tooltip: l.editAccountTitle,
            onPressed: _edit,
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: l.delete,
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _header(l),
          const SizedBox(height: 18),
          if (_txns.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: AppEmptyState(
                icon: Icons.receipt_long_rounded,
                title: l.noTransactions,
                subtitle: l.accountNoTransactions,
              ),
            )
          else
            for (final entry in _byDay) _dayCard(entry.key, entry.value),
        ],
      ),
    );
  }

  Widget _header(AppLocalizations l) {
    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final headline = accountNetValue(_account, _balance);
    final ret = investmentReturn(_account, _balance);
    final yearly = annualInterest(_account, _balance);
    final maturity = _account.maturityDate;
    final matured = maturity != null && maturity.isBefore(DateTime.now());

    final lines = <Widget>[];
    if (_account.isSavings && (_account.interestRate ?? 0) > 0) {
      lines.add(
        _line(
          Icons.percent_rounded,
          AppColors.positive,
          '${_fmtNum(_account.interestRate!)}%'
          '${yearly != null ? ' · ${l.savingsYield(formatMoney(yearly, _symbol))}' : ''}',
          cs,
        ),
      );
    }
    if (maturity != null) {
      lines.add(
        _line(
          Icons.event_rounded,
          matured ? AppColors.negative : cs.onSurfaceVariant,
          matured
              ? l.matured
              : l.maturesUntil(DateFormat.yMMMd(locale).format(maturity)),
          cs,
          color: matured ? AppColors.negative : null,
        ),
      );
    }
    if (_account.isInvestment) {
      final retColor = (ret ?? 0) >= 0 ? AppColors.positive : AppColors.negative;
      final pct = (ret != null && _balance != 0)
          ? (ret / _balance.abs() * 100)
          : null;
      lines.add(
        _line(
          (ret ?? 0) >= 0
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded,
          retColor,
          '${l.investedLabel}: ${formatMoney(_balance, _symbol)}'
          '${ret != null ? '  ·  ${ret >= 0 ? '+' : '−'}${formatMoney(ret.abs(), _symbol)}'
                '${pct != null ? ' (${pct >= 0 ? '+' : '−'}${_fmtNum(pct.abs())}%)' : ''}' : ''}',
          cs,
          color: ret != null ? retColor : null,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ItemAvatar(color: cs.primary, icon: _account.accountIcon, diameter: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _kindLabel(l),
                  style: kTextStyle.copyWith(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AmountText(
            headline,
            symbol: _symbol,
            adaptive: true,
            style: kTextStyle.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: headline < 0 ? AppColors.negative : cs.onSurface,
            ),
          ),
          if (lines.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...lines,
          ],
        ],
      ),
    );
  }

  Widget _line(IconData icon, Color iconColor, String text, ColorScheme cs,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: kTextStyle.copyWith(
                fontSize: 13,
                fontWeight: color != null ? FontWeight.w700 : FontWeight.w400,
                color: color ?? cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _kindLabel(AppLocalizations l) => _account.isSavings
      ? l.accountKindSavings
      : _account.isInvestment
      ? l.accountKindInvestment
      : l.accountKindGeneral;

  Widget _dayCard(DateTime day, List<TransactionDetails> items) {
    final locale = Localizations.localeOf(context).toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2, left: 2),
            child: Text(
              DateFormat.yMMMMd(locale).format(day),
              style: kTextStyle.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ...items.map((t) => TransactionTile(transaction: t)),
        ],
      ),
    );
  }

  static String _fmtNum(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(v.abs() < 1 ? 2 : 1);
}
