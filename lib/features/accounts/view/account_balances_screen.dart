import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/format.dart';
import 'package:finance_app/core/widgets/amount_text.dart';
import 'package:finance_app/core/widgets/empty_state.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/features/accounts/account_math.dart';
import 'package:finance_app/features/accounts/view/account_transactions_screen.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

/// Net worth broken down per account, grouped by purpose (Spending / Savings /
/// Investments). Balances are all-time, in the base currency. Savings accounts
/// show their rate + projected interest and can log earned interest; investment
/// accounts track a current value and show the return. Local.
class AccountBalancesScreen extends StatefulWidget {
  const AccountBalancesScreen({super.key});

  @override
  State<AccountBalancesScreen> createState() => _AccountBalancesScreenState();
}

class _AccountBalancesScreenState extends State<AccountBalancesScreen> {
  bool _loading = true;
  String? _symbol;
  int? _baseCurrencyId;
  double _total = 0;
  int _count = 0;
  List<_AccountRow> _general = const [];
  List<_AccountRow> _savings = const [];
  List<_AccountRow> _investments = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accounts = await getIt<AccountRepository>().getAll();
    final txns = await getIt<TransactionRepository>().getAllWithDetails();
    final base = await getIt<CurrencyRepository>().getBase();

    final bal = perAccountBalance(accounts, txns);
    final rows = [
      for (final a in accounts) _AccountRow(a, bal[a.accountId] ?? 0),
    ];
    int byValue(_AccountRow a, _AccountRow b) =>
        b.netValue.compareTo(a.netValue);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _symbol = base?.currencySymbol;
      _baseCurrencyId = base?.currencyId;
      _total = netWorth(accounts, txns);
      _count = accounts.length;
      _general = rows.where((r) => r.account.isGeneral).toList()..sort(byValue);
      _savings = rows.where((r) => r.account.isSavings).toList()..sort(byValue);
      _investments = rows.where((r) => r.account.isInvestment).toList()
        ..sort(byValue);
    });
  }

  // --- actions ---------------------------------------------------------------

  Future<void> _updateValue(_AccountRow r) async {
    final l = AppLocalizations.of(context);
    final result = await showDialog<double>(
      context: context,
      builder: (_) => _NumberDialog(
        title: '${l.updateValueTitle} · ${r.account.accountName}',
        initial: r.account.currentValue ?? r.balance,
        symbol: _symbol,
      ),
    );
    if (result == null) return;
    await getIt<AccountRepository>().setCurrentValue(r.account.accountId, result);
    await _load();
  }

  Future<void> _addAccount() async {
    await Navigator.of(context).pushNamed('/add-account');
    await _load();
  }

  Future<void> _openAccount(Account account) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AccountTransactionsScreen(account: account),
      ),
    );
    await _load();
  }

  Future<void> _logInterest(_AccountRow r) async {
    final l = AppLocalizations.of(context);
    final rate = r.account.interestRate ?? 0;
    // Prefill with one month of interest at the account's rate.
    final suggested = rate > 0 ? r.balance * rate / 100 / 12 : 0.0;
    final result = await showDialog<double>(
      context: context,
      builder: (_) => _NumberDialog(
        title: '${l.logInterestTitle} · ${r.account.accountName}',
        initial: (suggested * 100).roundToDouble() / 100,
        symbol: _symbol,
        note: l.logInterestNote,
      ),
    );
    if (result == null || result <= 0) return;
    final baseId = _baseCurrencyId;
    if (baseId == null) return;
    final categoryId = await getIt<CategoryRepository>().ensureCategory(
      name: l.interestCategoryName,
      kind: 'income',
      color: AppColors.positive.toARGB32(),
      iconCodePoint: SolarIconsBold.moneyBag.codePoint,
    );
    await getIt<TransactionRepository>().add(
      accountId: r.account.accountId,
      categoryId: categoryId,
      currencyId: baseId,
      amount: result,
      date: DateTime.now(),
      type: 'income',
    );
    await _load();
  }

  // --- build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.accounts),
        actions: [
          IconButton(
            tooltip: l.add,
            onPressed: _addAccount,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _count == 0
          ? Center(
              child: AppEmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: l.noAccountsYet,
                subtitle: l.addAccountInSettings,
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                _hero(l),
                const SizedBox(height: 20),
                if (_general.isNotEmpty)
                  _section(l.sectionSpending, _general, _generalRow),
                if (_savings.isNotEmpty)
                  _section(l.sectionSavings, _savings, _savingsRow),
                if (_investments.isNotEmpty)
                  _section(
                    l.sectionInvestments,
                    _investments,
                    _investmentRow,
                  ),
              ],
            ),
    );
  }

  Widget _hero(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: kCardShadow,
      ),
      child: Column(
        children: [
          Text(
            l.totalBalance,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 6),
          AmountText(
            _total,
            symbol: _symbol,
            adaptive: true,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.acrossNAccounts(_count),
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _section(
    String title,
    List<_AccountRow> rows,
    Widget Function(_AccountRow) rowBuilder,
  ) {
    final subtotal = rows.fold<double>(0, (s, r) => s + r.netValue);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: kTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AmountText(
                subtotal,
                symbol: _symbol,
                style: kTextStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        for (final r in rows) rowBuilder(r),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _card({required Widget child, VoidCallback? onTap}) {
    final decorated = Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: kCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
    return decorated;
  }

  Widget _avatar(IconData icon, Color color) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: color),
  );

  Widget _titleRow(_AccountRow r, double amount, {Color? amountColor}) {
    final negative = amount < 0;
    return Row(
      children: [
        _avatar(
          r.account.accountIcon,
          negative ? AppColors.negative : AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            r.account.accountName,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
          ),
        ),
        AmountText(
          amount,
          symbol: _symbol,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: amountColor ??
                (negative
                    ? AppColors.negative
                    : Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ],
    );
  }

  Widget _generalRow(_AccountRow r) {
    final maxAbs = _general
        .map((e) => e.balance.abs())
        .fold<double>(1, (a, b) => a > b ? a : b);
    final negative = r.balance < 0;
    final color = negative ? AppColors.negative : AppColors.primary;
    return _card(
      onTap: () => _openAccount(r.account),
      child: Column(
        children: [
          _titleRow(r, r.balance),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                FractionallySizedBox(
                  widthFactor: maxAbs == 0
                      ? 0
                      : (r.balance.abs() / maxAbs).clamp(0.03, 1.0),
                  child: Container(height: 6, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _savingsRow(_AccountRow r) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final rate = r.account.interestRate;
    final yearly = annualInterest(r.account, r.balance);
    final maturity = r.account.maturityDate;
    final matured = maturity != null && maturity.isBefore(DateTime.now());
    return _card(
      onTap: () => _openAccount(r.account),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleRow(r, r.balance),
          if (rate != null && rate > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.percent_rounded,
                  size: 15,
                  color: AppColors.positive,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${_fmtNum(rate)}%'
                    '${yearly != null ? ' · ${l.savingsYield(formatMoney(yearly, _symbol))}' : ''}',
                    style: kTextStyle.copyWith(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (maturity != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  size: 15,
                  color: matured ? AppColors.negative : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  matured ? l.matured : l.maturesUntil(_fmtDate(maturity)),
                  style: kTextStyle.copyWith(
                    fontSize: 13,
                    color: matured ? AppColors.negative : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: _actionButton(
              icon: Icons.add_rounded,
              label: l.logInterest,
              onTap: () => _logInterest(r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _investmentRow(_AccountRow r) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final value = r.account.currentValue ?? r.balance;
    final ret = investmentReturn(r.account, r.balance);
    final retColor = (ret ?? 0) >= 0 ? AppColors.positive : AppColors.negative;
    final pct = (ret != null && r.balance != 0)
        ? (ret / r.balance.abs() * 100)
        : null;
    return _card(
      onTap: () => _openAccount(r.account),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleRow(r, value),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${l.investedLabel}: ${formatMoney(r.balance, _symbol)}',
                style: kTextStyle.copyWith(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (ret != null) ...[
                const SizedBox(width: 10),
                Icon(
                  ret >= 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                  color: retColor,
                ),
                Flexible(
                  child: Text(
                    '${ret >= 0 ? '+' : '−'}${formatMoney(ret.abs(), _symbol)}'
                    '${pct != null ? ' (${pct >= 0 ? '+' : '−'}${_fmtNum(pct.abs())}%)' : ''}',
                    style: kTextStyle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: retColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: _actionButton(
              icon: Icons.refresh_rounded,
              label: l.updateValue,
              onTap: () => _updateValue(r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: kTextStyle.copyWith(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
      ),
    );
  }

  static String _fmtNum(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(v.abs() < 1 ? 2 : 1);

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _AccountRow {
  const _AccountRow(this.account, this.balance);
  final Account account;

  /// Contribution balance (base currency) from transactions.
  final double balance;

  /// What this account contributes to net worth (investment value or balance).
  double get netValue => accountNetValue(account, balance);
}

/// A small numeric-entry dialog (owns its controller, disposed in [dispose] so
/// it survives the close animation — see the currency rate dialog for the same
/// pattern). Returns the entered value, or null on cancel.
class _NumberDialog extends StatefulWidget {
  const _NumberDialog({
    required this.title,
    required this.initial,
    this.symbol,
    this.note,
  });

  final String title;
  final double initial;
  final String? symbol;
  final String? note;

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial == 0
        ? ''
        : (widget.initial % 1 == 0
              ? widget.initial.toInt().toString()
              : widget.initial.toString()),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(suffixText: widget.symbol),
          ),
          if (widget.note != null) ...[
            const SizedBox(height: 10),
            Text(
              widget.note!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
            Navigator.pop(context, v);
          },
          child: Text(l.save),
        ),
      ],
    );
  }
}
