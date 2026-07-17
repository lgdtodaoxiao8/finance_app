import 'package:finance_app/core/preferences/app_preferences.dart';
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

  group('AppPreferences widget shortcuts', () {
    test('stores, sorts by order, and reads back', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = AppPreferences(await SharedPreferences.getInstance());

      expect(prefs.getWidgetShortcuts(), isEmpty);

      await prefs.setWidgetShortcuts(const [
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
      ]);

      final read = prefs.getWidgetShortcuts();
      expect(read.map((s) => s.id).toList(), ['first', 'second']);
      expect(read.first.amount, 5);
    });

    test('returns empty on corrupt data', () async {
      SharedPreferences.setMockInitialValues({
        'widget_shortcuts': 'not json',
      });
      final prefs = AppPreferences(await SharedPreferences.getInstance());
      expect(prefs.getWidgetShortcuts(), isEmpty);
    });
  });
}
