import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/widgets/item_avatar.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/features/settings/cubit/categories_cubit.dart';
import 'package:finance_app/features/settings/cubit/manage_status.dart';
import 'package:finance_app/features/settings/widgets/manage_section.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CategoriesCubit(getIt<CategoryRepository>()),
      child: const _CategoriesView(),
    );
  }
}

class _CategoriesView extends StatelessWidget {
  const _CategoriesView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoriesCubit, CategoriesState>(
      listenWhen: (p, c) => c.message != null && p.message != c.message,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message!)),
        );
        context.read<CategoriesCubit>().clearMessage();
      },
      builder: (context, state) {
        return ManageSection(
          title: AppLocalizations.of(context).categories,
          onAdd: () => Navigator.of(context).pushNamed('/add-category'),
          loading: state.status == ManageStatus.loading,
          emptyLabel: AppLocalizations.of(context).noCategoriesYet,
          isEmpty: state.categories.isEmpty,
          children: [
            for (final category in state.categories)
              ManageTile(
                leading: ItemAvatar(
                  color: category.categoryColor,
                  icon: category.categoryIcon,
                  diameter: 34,
                ),
                title: category.categoryName,
                onDelete: () => confirmDelete(
                  context,
                  what: category.categoryName,
                  onConfirm: () => context.read<CategoriesCubit>().delete(
                    category.categoryId,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
