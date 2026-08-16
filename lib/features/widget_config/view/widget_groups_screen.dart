import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/preferences/app_preferences.dart';
import 'package:finance_app/features/widget_bridge/widget_service.dart';
import 'package:finance_app/features/widget_config/data/widget_flow.dart';
import 'package:finance_app/features/widget_config/data/widget_group.dart';
import 'package:finance_app/features/widget_config/view/widget_config_screen.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Lists the quick-add widget groups (named category sets). Each home-screen
/// widget instance binds to one group via iOS "Edit Widget", so two widgets
/// can show different categories.
class WidgetGroupsScreen extends StatefulWidget {
  const WidgetGroupsScreen({super.key});

  @override
  State<WidgetGroupsScreen> createState() => _WidgetGroupsScreenState();
}

class _WidgetGroupsScreenState extends State<WidgetGroupsScreen> {
  List<WidgetGroup> _groups = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _groups = getIt<AppPreferences>().getWidgetGroups());
  }

  /// The default group's name is stored empty; show a localized label.
  String _groupName(AppLocalizations l, WidgetGroup g) =>
      g.name.isNotEmpty ? g.name : l.widgetGroupDefault;

  Future<void> _save(List<WidgetGroup> groups) async {
    await getIt<AppPreferences>().setWidgetGroups(groups);
    await getIt<WidgetService>().publishOnce();
    _load();
  }

  /// Adding a group first picks its flow (expense vs income) — that decides
  /// which home-screen widget kind ("Quick Expense" / "Quick Income") will
  /// offer it — then its name.
  Future<void> _addGroup() async {
    final flow = await _pickFlow(context);
    if (flow == null || !mounted) return;
    final name = await _promptName(context, initial: '');
    if (name == null || name.isEmpty) return;
    final group = WidgetGroup(
      id: 'g${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      flow: flow,
    );
    await _save([..._groups, group]);
    if (mounted) _openGroup(group);
  }

  /// A small chooser: does this widget set log expenses or income?
  Future<WidgetFlow?> _pickFlow(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return showModalBottomSheet<WidgetFlow>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text(
                  l.widgetFlowQuestion,
                  style: kTextStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ListTile(
                onTap: () => Navigator.pop(ctx, WidgetFlow.expense),
                leading: CircleAvatar(
                  backgroundColor: AppColors.negative.withValues(alpha: 0.12),
                  // Up arrow = expense (money out), matching the app.
                  child: const Icon(
                    Icons.arrow_upward_rounded,
                    color: AppColors.negative,
                  ),
                ),
                title: Text(l.widgetFlowExpense),
                subtitle: Text(l.widgetFlowExpenseHint),
              ),
              ListTile(
                onTap: () => Navigator.pop(ctx, WidgetFlow.income),
                leading: CircleAvatar(
                  backgroundColor: AppColors.positive.withValues(alpha: 0.14),
                  // Down arrow = income (money in), matching the app.
                  child: const Icon(
                    Icons.arrow_downward_rounded,
                    color: AppColors.positive,
                  ),
                ),
                title: Text(l.widgetFlowIncome),
                subtitle: Text(l.widgetFlowIncomeHint),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _rename(WidgetGroup g) async {
    final name = await _promptName(context, initial: g.name);
    if (name == null || name.isEmpty) return;
    await _save([
      for (final x in _groups) x.id == g.id ? x.copyWith(name: name) : x,
    ]);
  }

  Future<void> _delete(WidgetGroup g) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteItemQuestion(_groupName(l, g))),
        content: Text(l.actionCannotBeUndone),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _save(_groups.where((x) => x.id != g.id).toList());
  }

  Future<void> _openGroup(WidgetGroup g) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WidgetConfigScreen(groupId: g.id),
      ),
    );
    _load(); // reflect edits made inside
  }

  Future<String?> _promptName(
    BuildContext context, {
    required String initial,
  }) {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.widgetGroupName),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 24,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: l.widgetGroupNameHint,
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.widgetsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            l.widgetGroupsIntro,
            style: kTextStyle.copyWith(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: kCardShadow,
            ),
            child: Column(
              children: [
                for (var i = 0; i < _groups.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: theme.dividerColor,
                    ),
                  _groupTile(l, theme, _groups[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _addGroup,
            icon: const Icon(Icons.add),
            label: Text(l.widgetAddGroup),
          ),
        ],
      ),
    );
  }

  Widget _groupTile(AppLocalizations l, ThemeData theme, WidgetGroup g) {
    final isDefault = g.id == AppPreferences.defaultWidgetGroupId;
    final isIncome = g.flow.isIncome;
    // Income groups read green with an upward arrow; expense groups keep the
    // neutral widget glyph.
    final accent = isIncome ? AppColors.positive : theme.colorScheme.primary;
    return ListTile(
      onTap: () => _openGroup(g),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: accent.withValues(alpha: isIncome ? 0.14 : 0.12),
        child: Icon(
          // Down arrow = income (money in); expense keeps the neutral glyph.
          isIncome ? Icons.arrow_downward_rounded : Icons.widgets_rounded,
          size: 18,
          color: accent,
        ),
      ),
      title: Text(
        _groupName(l, g),
        style: kTextStyle.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${isIncome ? l.widgetFlowIncome : l.widgetFlowExpense}'
        ' · ${l.widgetGroupCategories(g.shortcuts.length)}',
        style: kTextStyle.copyWith(
          fontSize: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The default group is always available and can't be renamed/deleted.
          if (!isDefault) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _rename(g),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _delete(g),
            ),
          ],
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
