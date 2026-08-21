import 'package:finance_app/data/models/transaction_details.dart';
import 'package:finance_app/models/main_model.dart';

/// Shared money math for accounts and net worth (all in the base currency).
///
/// The one rule that keeps everything consistent: an account's *contribution
/// balance* is derived purely from transactions (income + transfers in − expense
/// − transfers out). Investment market moves are NOT transactions — they live in
/// the account's [Account.currentValue] — so they only ever affect NET WORTH and
/// the RETURN figure, never the income/expense analytics.

/// Per-account contribution balance keyed by account id.
Map<int, double> perAccountBalance(
  List<Account> accounts,
  List<TransactionDetails> txns,
) {
  final bal = <int, double>{for (final a in accounts) a.accountId: 0.0};
  for (final t in txns) {
    final amt = t.amountInBase;
    final src = t.accountId;
    final dst = t.accountDestinationId;
    if (t.isIncome && src != null) bal[src] = (bal[src] ?? 0) + amt;
    if (t.isExpense && src != null) bal[src] = (bal[src] ?? 0) - amt;
    if (t.isTransfer) {
      if (src != null) bal[src] = (bal[src] ?? 0) - amt;
      if (dst != null) bal[dst] = (bal[dst] ?? 0) + amt;
    }
  }
  return bal;
}

/// The value [a] contributes to net worth: its tracked current market value when
/// it's an investment with one set, otherwise its [contributionBalance].
double accountNetValue(Account a, double contributionBalance) {
  if (a.isInvestment && a.currentValue != null) return a.currentValue!;
  return contributionBalance;
}

/// Total net worth: general/savings counted by contribution balance,
/// investments by current value (falling back to contributions if unset).
double netWorth(List<Account> accounts, List<TransactionDetails> txns) {
  final bal = perAccountBalance(accounts, txns);
  var total = 0.0;
  for (final a in accounts) {
    total += accountNetValue(a, bal[a.accountId] ?? 0);
  }
  return total;
}

/// Investment return (current value − contributions), or null when [a] isn't an
/// investment or has no value set yet.
double? investmentReturn(Account a, double contributionBalance) {
  if (!a.isInvestment || a.currentValue == null) return null;
  return a.currentValue! - contributionBalance;
}

/// Projected annual interest for a savings/deposit account at its rate, or null
/// when it isn't a savings account or has no rate.
double? annualInterest(Account a, double balance) {
  if (!a.isSavings || a.interestRate == null || a.interestRate! <= 0) {
    return null;
  }
  return balance * a.interestRate! / 100;
}
