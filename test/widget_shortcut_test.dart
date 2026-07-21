import 'dart:convert';

import 'package:finance_app/core/preferences/app_preferences.dart';
import 'package:finance_app/features/widget_config/data/widget_group.dart';
import 'package:finance_app/features/widget_config/data/widget_shortcut.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WidgetShortcut JSON', () {
    test('round-trips every mode', () {
      final shortcuts = [
        const WidgetShortcut(
          id: 'a',
          categoryId: 1,
          mode: WidgetShortcutMode.fixed,
          amount: 2.5,
          order: 0,
        ),
        const WidgetShortcut(
          id: 'b',
          categoryId: 2,
          mode: WidgetShortcutMode.presets,
          presets: [10, 20, 50],
          order: 1,
        ),
        const WidgetShortcut(
          id: 'c',
          categoryId: 3,
          mode: WidgetShortcutMode.open,
          order: 2,
        ),
      ];

      for (final s in shortcuts) {
        final restored = WidgetShortcut.fromJson(s.toJson());
        expect(restored.id, s.id);
        expect(restored.categoryId, s.categoryId);
        expect(restored.mode, s.mode);
        expect(restored.amount, s.amount);
        expect(restored.presets, s.presets);
        expect(restored.order, s.order);
      }
    });

    test('unknown mode falls back to open', () {
      final restored = WidgetShortcut.fromJson({
        'id': 'x',
        'categoryId': 1,
        'mode': 'nonsense',
        'presets': [],
      });
      expect(restored.mode, WidgetShortcutMode.open);
    });
  });

  group('AppPreferences widget groups', () {
    test('stores groups; shortcuts sort by order', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = AppPreferences(await SharedPreferences.getInstance());

      // With no data the default group exists but is empty.
      final initial = prefs.getWidgetGroups();
      expect(initial, hasLength(1));
      expect(initial.first.id, AppPreferences.defaultWidgetGroupId);
      expect(initial.first.shortcuts, isEmpty);

      await prefs.setWidgetGroups([
        const WidgetGroup(
          id: AppPreferences.defaultWidgetGroupId,
          name: '',
          shortcuts: [
            WidgetShortcut(
              id: 'second',
              categoryId: 2,
              mode: WidgetShortcutMode.open,
              order: 1,
            ),
            WidgetShortcut(
              id: 'first',
              categoryId: 1,
              mode: WidgetShortcutMode.fixed,
              amount: 5,
              order: 0,
            ),
          ],
        ),
        const WidgetGroup(id: 'work', name: 'Work'),
      ]);

      final groups = prefs.getWidgetGroups();
      expect(groups.map((g) => g.id).toList(), [
        AppPreferences.defaultWidgetGroupId,
        'work',
      ]);
      expect(groups.first.shortcuts.map((s) => s.id).toList(), [
        'first',
        'second',
      ]);
      expect(groups.first.shortcuts.first.amount, 5);
    });

    test('migrates the legacy single list into the default group', () async {
      SharedPreferences.setMockInitialValues({
        'widget_shortcuts': jsonEncode([
          const WidgetShortcut(
            id: 'a',
            categoryId: 1,
            mode: WidgetShortcutMode.fixed,
            amount: 9,
          ).toJson(),
        ]),
      });
      final prefs = AppPreferences(await SharedPreferences.getInstance());
      final groups = prefs.getWidgetGroups();
      expect(groups, hasLength(1));
      expect(groups.first.id, AppPreferences.defaultWidgetGroupId);
      expect(groups.first.shortcuts.single.id, 'a');
    });
  });
}
