import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/settings/app_settings.dart';
import 'package:finance_app/core/settings/settings_service.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// User preferences card: theme, language, start of week and privacy. Every
/// change is written through [SettingsService], so it persists locally and
/// syncs to the cloud automatically.
class PreferencesSection extends StatelessWidget {
  const PreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final service = getIt<SettingsService>();
    final l = AppLocalizations.of(context);

    return ValueListenableBuilder<AppSettings>(
      valueListenable: service.settings,
      builder: (context, s, _) {
        return _Card(
          title: l.sectionPreferences,
          children: [
            _Row(
              icon: PhosphorIconsFill.circleHalf,
              label: l.theme,
              child: _Segmented<AppThemeMode>(
                value: s.themeMode,
                options: [
                  (AppThemeMode.system, l.themeSystem),
                  (AppThemeMode.light, l.themeLight),
                  (AppThemeMode.dark, l.themeDark),
                ],
                onChanged: service.setThemeMode,
              ),
            ),
            _Row(
              icon: PhosphorIconsFill.translate,
              label: l.language,
              child: _Segmented<String?>(
                value: s.languageCode,
                options: [
                  (null, l.languageSystem),
                  ('en', l.languageEnglish),
                  ('ru', l.languageRussian),
                ],
                onChanged: service.setLanguage,
              ),
            ),
            _Row(
              icon: PhosphorIconsFill.calendar,
              label: l.weekStart,
              child: _Segmented<bool>(
                value: s.weekStartsMonday,
                options: [
                  (true, l.weekStartMonday),
                  (false, l.weekStartSunday),
                ],
                onChanged: service.setWeekStartsMonday,
              ),
            ),
            SwitchListTile.adaptive(
              value: s.hideAmounts,
              onChanged: service.setHideAmounts,
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(PhosphorIconsFill.eyeSlash),
              title: Text(
                l.hideAmounts,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                l.hideAmountsSubtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A labelled row: leading icon + label on the left, a control on the right,
/// wrapping the control below on narrow widths.
class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.child});

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// A compact pill-style segmented control. [value] selects the active option.
class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(kRadiusSm),
      ),
      child: Row(
        children: [
          for (final (optValue, label) in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(optValue),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: optValue == value
                        ? scheme.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(kRadiusSm - 3),
                    boxShadow: optValue == value ? kCardShadow : null,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: optValue == value
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: optValue == value
                          ? scheme.onSurface
                          : scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Card shell matching the other settings sections but theme-aware.
class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }
}
