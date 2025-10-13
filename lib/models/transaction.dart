enum TransactionType { income, expense, transfer, adjustment }

class Transaction {
  Transaction({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.date,
    required this.amount,
    required this.currency,
    required this.name,
    required this.transactionType,
    required this.description,
    required this.categoryId,
    this.accountDestination,
  }) : isAccepted = true;

  final String id;
  final String userId;
  final String accountId;
  final DateTime date;
  final double amount;
  final String currency;
  final String name;
  final TransactionType transactionType;
  final String description;
  final String categoryId;
  final String? accountDestination;
  bool isAccepted;

  void switchAccetpting() {
    isAccepted = !isAccepted;
  }
}
