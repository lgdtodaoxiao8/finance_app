import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/widgets/item_avatar.dart';
import 'package:finance_app/data/repositories/category_repository.dart';
import 'package:finance_app/features/add_item/cubit/add_category_cubit.dart';
import 'package:finance_app/features/add_item/widgets/icon_picker.dart';
import 'package:finance_app/features/add_item/widgets/tint_color_picker.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Creates a category. One colour drives the whole look: the icon takes it
/// saturated, the circle behind is the same colour tinted (no alpha control) —
/// the live preview at the top shows exactly what every list will render.
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
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Re-evaluate the save button as the user types.
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _valid {
    final name = _name.text.trim();
    return name.isNotEmpty && name.length <= 30;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BlocConsumer<AddCategoryCubit, AddCategoryState>(
      listenWhen: (p, c) => p.savedId != c.savedId || p.error != c.error,
      listener: (context, state) {
        if (state.savedId != null) {
          Navigator.of(context).pop(state.savedId);
        } else if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l.somethingWentWrong}: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<AddCategoryCubit>();
        return Scaffold(
          appBar: AppBar(
            title: Text(
              l.newCategoryTitle,
              style: kTextStyle.copyWith(fontSize: 20),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    children: [
                      _PreviewHeader(
                        avatar: ItemAvatar(
                          color: state.color,
                          icon: state.icon,
                          diameter: 64,
                        ),
                        controller: _name,
                        hint: l.name,
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel(l.colorPicker),
                      const SizedBox(height: 12),
                      TintColorPicker(
                        color: state.color,
                        onChanged: cubit.setColor,
                      ),
                      const SizedBox(height: 24),
                      IconPicker(
                        onSelectIcon: cubit.setIcon,
                        initialIcon: state.icon,
                        backgroundColor: ItemAvatar.tint(state.color),
                        iconColor: state.color,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: state.sending || !_valid
                          ? null
                          : () => cubit.save(_name.text.trim()),
                      child: state.sending
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l.add),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Live result preview: the avatar every list will show + the name field
/// beside it, styled as the headline it becomes.
class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({
    required this.avatar,
    required this.controller,
    required this.hint,
  });

  final Widget avatar;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: kCardShadow,
      ),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: 30,
              textCapitalization: TextCapitalization.sentences,
              style: kTextStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: hint,
                counterText: '',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: kTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }
}
