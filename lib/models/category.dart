class Category {
  Category({
    required this.id,
    required this.userId,
    required this.name,
    this.parentId,
    this.budgetMonthly,
    required this.color,
  });

  final String id;
  final String userId;
  final String name;
  final String? parentId; //для вложенных категорий
  double? budgetMonthly;
  String color;
}
