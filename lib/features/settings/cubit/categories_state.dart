part of 'categories_cubit.dart';

class CategoriesState extends Equatable {
  const CategoriesState({
    this.status = ManageStatus.loading,
    this.categories = const [],
    this.message,
  });

  final ManageStatus status;
  final List<Category> categories;
  final String? message;

  CategoriesState copyWith({
    ManageStatus? status,
    List<Category>? categories,
    String? message,
  }) {
    return CategoriesState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, categories, message];
}
