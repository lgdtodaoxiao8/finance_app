enum AccountType { cash, bank, card, investment, loan }

class Account {
  Account({
    required this.id,
    required this.userId,
    required this.accountType,
    required this.currency,
    required this.name,
  });

  final String id;
  final String userId;
  final AccountType accountType;
  final String currency;
  final String name;
}
