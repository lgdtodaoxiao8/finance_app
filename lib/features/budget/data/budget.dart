/// A monthly spending limit. [categoryId] null = the overall budget (total
/// spending cap); otherwise a per-category limit. [amount] is in base currency.
class Budget {
  const Budget({required this.id, this.categoryId, required this.amount});

  final int id;
  final int? categoryId;
  final double amount;

  bool get isOverall => categoryId == null;
}
