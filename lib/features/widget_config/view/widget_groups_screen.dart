import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/preferences/app_preferences.dart';
import 'package:finance_app/features/widget_bridge/widget_service.dart';
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

  Future<void> _addGroup() async {
    final name = await _promptName(context, initial: '');
    if (name == null || name.isEmpty) return;
    final group = WidgetGroup(
      id: 'g${DateTime.now().millisecondsSinceEpoch}',
      name: name,
    );
    await _save([..._groups, group]);
    if (mounted) _openGroup(group);
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
    return ListTile(
      onTap: () => _openGroup(g),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        child: Icon(
          Icons.widgets_rounded,
          size: 18,
          color: theme.colorScheme.primary,
        ),
      ),
      title: Text(
        _groupName(l, g),
        style: kTextStyle.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        l.widgetGroupCategories(g.shortcuts.length),
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
