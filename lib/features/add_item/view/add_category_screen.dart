import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/features/add_item/cubit/add_category_cubit.dart';
import 'package:finance_app/features/add_item/widgets/widgets.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddCategoryScreen extends StatelessWidget {
  const AddCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddCategoryCubit(getIt<CategoryRepository>()),
      child: const _AddCategoryView(),
    );
  }
}

class _AddCategoryView extends StatefulWidget {
  const _AddCategoryView();

  @override
  State<_AddCategoryView> createState() => _AddCategoryViewState();
}

class _AddCategoryViewState extends State<_AddCategoryView> {
  final _nameKey = GlobalKey<CustomTextFieldState>();

  String? _nameValidator(String value) {
    if (value.length < 4) return AppLocalizations.of(context).mustBeAtLeast4;
    if (value.length > 30) return AppLocalizations.of(context).maximum30;
    return null;
  }

  void _save() {
    final nameValid = _nameKey.currentState?.validate() ?? false;
    if (!nameValid) return;
    context.read<AddCategoryCubit>().save(_nameKey.currentState!.text);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddCategoryCubit, AddCategoryState>(
      listenWhen: (p, c) => p.savedId != c.savedId || p.error != c.error,
      listener: (context, state) {
        if (state.savedId != null) {
          Navigator.of(context).pop(state.savedId);
        } else if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context).somethingWentWrong}: ${state.error}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<AddCategoryCubit>();
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            shadowColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            title: Text(
              AppLocalizations.of(context).newCategoryTitle,
              style: kTextStyle.copyWith(
                fontSize: 22,
                color: const Color(0xFF242528),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: ElevatedButton(
                  onPressed: state.sending ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: state.sending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context).add,
                          style: kTextStyle.copyWith(),
                        ),
                ),
              ),
            ],
          ),
          body: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 13, 20, 20),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      key: _nameKey,
                      errorTextPadding: const EdgeInsets.only(left: 20, top: 3),
                      prefixBackgroundColor: state.color,
                      prefixIcon: state.icon,
                      prefixIconColor: state.iconColor,
                      hint: AppLocalizations.of(context).name,
                      validate: _nameValidator,
                    ),
                    Divider(
                      height: 2,
                      thickness: 2,
                      color: Theme.of(context).dividerColor,
                      indent: 25,
                      endIndent: 25,
                    ),
                    const SizedBox(height: 10),
                    BlackAndWhiteSlider(onColorChanged: cubit.setIconColor),
                    const SizedBox(height: 10),
                    ColorPickerr(onColorChanged: cubit.setColor),
                    const SizedBox(height: 10),
                    IconPicker(
                      onSelectIcon: cubit.setIcon,
                      backgroundColor: state.color,
                      iconColor: state.iconColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
