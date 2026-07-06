import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/format.dart';
import 'package:finance_app/core/widgets/empty_state.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/models/main_model.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Net worth broken down per account, reached by tapping the Total balance
/// card. Balances are all-time, expressed in the base currency. Local.
class AccountBalancesScreen extends StatefulWidget {
  const AccountBalancesScreen({super.key});

  @override
  State<AccountBalancesScreen> createState() => _AccountBalancesScreenState();
}

class _AccountBalancesScreenState extends State<AccountBalancesScreen> {
  bool _loading = true;
  String? _symbol;
  double _total = 0;
  List<_AccountBalance> _accounts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accounts = await getIt<AccountRepository>().getAll();
    final txns = await getIt<TransactionRepository>().getAllWithDetails();
    final base = await getIt<CurrencyRepository>().getBase();

    final balances = <int, double>{for (final a in accounts) a.accountId: 0};
    for (final t in txns) {
      final amt = t.amountInBase;
      final src = t.accountId;
      final dst = t.accountDestinationId;
      if (t.isIncome && src != null) {
        balances[src] = (balances[src] ?? 0) + amt;
      }
      if (t.isExpense && src != null) {
        balances[src] = (balances[src] ?? 0) - amt;
      }
      if (t.isTransfer) {
        if (src != null) balances[src] = (balances[src] ?? 0) - amt;
        if (dst != null) balances[dst] = (balances[dst] ?? 0) + amt;
      }
    }

    final list =
        accounts
            .map(
              (a) => _AccountBalance(
                account: a,
                balance: balances[a.accountId] ?? 0,
              ),
            )
            .toList()
          ..sort((a, b) => b.balance.compareTo(a.balance));
    final total = balances.values.fold<double>(0, (a, b) => a + b);

    if (mounted) {
      setState(() {
        _loading = false;
        _symbol = base?.currencySymbol;
        _total = total;
        _accounts = list;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
          ? const Center(
              child: AppEmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'No accounts yet',
                subtitle: 'Add an account in Settings to track balances',
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                _hero(),
                const SizedBox(height: 20),
                Text(
                  'Your accounts',
                  style: kTextStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final a in _accounts) _row(a),
              ],
            ),
    );
  }

  Widget _hero() {
    // Largest positive balance, used to scale the per-account bars.
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
          const Text(
            'Total balance',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            formatMoney(_total, _symbol),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'across ${_accounts.length} '
            '${_accounts.length == 1 ? 'account' : 'accounts'}',
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _row(_AccountBalance a) {
    final maxAbs = _accounts.isEmpty
        ? 1.0
        : _accounts.map((e) => e.balance.abs()).reduce((x, y) => x > y ? x : y);
    final negative = a.balance < 0;
    final color = negative ? AppColors.negative : AppColors.primary;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: kCardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(a.account.accountIcon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  a.account.accountName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                formatMoney(a.balance, _symbol),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: negative ? AppColors.negative : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 6, color: AppColors.field),
                FractionallySizedBox(
                  widthFactor: maxAbs == 0
                      ? 0
                      : (a.balance.abs() / maxAbs).clamp(0.03, 1.0),
                  child: Container(height: 6, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountBalance {
  const _AccountBalance({required this.account, required this.balance});
  final Account account;
  final double balance;
}
