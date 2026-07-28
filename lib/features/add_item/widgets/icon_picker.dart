import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/core/app_icons.dart';

/// Icon selection: quick group-filter chips over a scrollable grid. The
/// selected icon renders exactly as the item will everywhere else — a tinted
/// circle with the accent-coloured glyph (see ItemAvatar).
class IconPicker extends StatefulWidget {
  const IconPicker({
    super.key,
    required this.onSelectIcon,
    required this.accent,
    this.initialIcon,
  });

  final void Function(IconData) onSelectIcon;

  /// The item's colour — selection is shown as its tint + this colour.
  final Color accent;

  /// Pre-selected icon (keeps the picker in sync with the caller's state).
  final IconData? initialIcon;

  @override
  State<IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<IconPicker> {
  final Map<String, List<IconData>> categorizedIcons = {
    "Finance": [
      AppIcons.account_balance,
      AppIcons.account_balance_wallet,
      AppIcons.credit_card,
      AppIcons.payments,
      AppIcons.attach_money,
      AppIcons.savings,
      AppIcons.receipt,
      AppIcons.receipt_long,
      AppIcons.trending_up,
      AppIcons.trending_down,
      AppIcons.percent,
      AppIcons.show_chart,
      AppIcons.data_object,
      AppIcons.balance,
      AppIcons.loyalty,
      AppIcons.point_of_sale,
      AppIcons.swap_horiz,
      AppIcons.contactless,
      AppIcons.verified_user,
      AppIcons.report_problem,
      AppIcons.fact_check,
      AppIcons.autorenew,
      AppIcons.calendar_month,
      AppIcons.lock,
      AppIcons.star_rate,
      AppIcons.hourglass_empty,
      AppIcons.support,
      AppIcons.fingerprint,
      AppIcons.gavel,
      AppIcons.table_view,
      AppIcons.description,
      AppIcons.perm_identity,
      AppIcons.delete,
    ],
    "Movement": [
      AppIcons.commute,
      AppIcons.flight,
      AppIcons.flight_takeoff,
      AppIcons.directions_car,
      AppIcons.train,
      AppIcons.directions_bus,
      AppIcons.directions_boat,
      AppIcons.local_taxi,
      AppIcons.pedal_bike,
      AppIcons.electric_scooter,
      AppIcons.sailing,
      AppIcons.local_shipping,
      AppIcons.map,
      AppIcons.local_gas_station,
      AppIcons.two_wheeler,
      AppIcons.traffic,
      AppIcons.local_parking,
      AppIcons.speed,
      AppIcons.ev_station,
      AppIcons.electric_car,
      AppIcons.anchor,
      AppIcons.terrain,
      AppIcons.luggage,
      AppIcons.hotel,
    ],
    "Food": [
      AppIcons.restaurant,
      AppIcons.coffee,
      AppIcons.fastfood,
      AppIcons.local_cafe,
      AppIcons.lunch_dining,
      AppIcons.restaurant_menu,
      AppIcons.local_pizza,
      AppIcons.bakery_dining,
      AppIcons.icecream,
      AppIcons.menu_book,
      AppIcons.sports_bar,
      AppIcons.local_bar,
      AppIcons.liquor,
      AppIcons.emoji_food_beverage,
      AppIcons.cookie,
    ],
    "Retail": [
      AppIcons.shopping_cart,
      AppIcons.shopping_bag,
      AppIcons.shopping_basket,
      AppIcons.store,
      AppIcons.local_mall,
      AppIcons.card_giftcard,
      AppIcons.diamond,
      AppIcons.local_florist,
      AppIcons.add_business,
    ],
    "Housing": [
      AppIcons.house,
      AppIcons.apartment,
      AppIcons.garage,
      AppIcons.home_work,
      AppIcons.add_home,
      AppIcons.room,
      AppIcons.king_bed,
      AppIcons.fireplace,
      AppIcons.family_restroom,
      AppIcons.pool,
      AppIcons.room_service,
      AppIcons.child_friendly,
      AppIcons.escalator_warning,
      AppIcons.cleaning_services,
      AppIcons.local_laundry_service,
      AppIcons.pest_control_rodent,
      AppIcons.water_drop,
      AppIcons.outlet,
      AppIcons.device_thermostat,
      AppIcons.solar_power,
      AppIcons.nightlight_round,
    ],
    "Health": [
      AppIcons.medical_services,
      AppIcons.local_hospital,
      AppIcons.vaccines,
      AppIcons.health_and_safety,
      AppIcons.fitness_center,
      AppIcons.pregnant_woman,
      AppIcons.psychology,
      AppIcons.healing,
      AppIcons.self_improvement,
      AppIcons.face_retouching_natural,
      AppIcons.accessible,
      AppIcons.emergency,
      AppIcons.sos,
      AppIcons.smoke_free,
      AppIcons.vape_free,
    ],
    "Other": [
      AppIcons.face,
      AppIcons.thumb_up,
      AppIcons.lightbulb,
      AppIcons.build,
      AppIcons.view_list,
      AppIcons.work,
      AppIcons.print,
      AppIcons.analytics,
      AppIcons.watch_later,
      AppIcons.code,
      AppIcons.pets,
      AppIcons.explore,
      AppIcons.bookmark,
      AppIcons.touch_app,
      AppIcons.supervisor_account,
      AppIcons.leaderboard,
      AppIcons.alarm,
      AppIcons.rocket_launch,
      AppIcons.book,
      AppIcons.bug_report,
      AppIcons.translate,
      AppIcons.extension,
      AppIcons.record_voice_over,
      AppIcons.dangerous,
      AppIcons.group_work,
      AppIcons.settings_phone,
      AppIcons.offline_bolt,
      AppIcons.important_devices,
      AppIcons.opacity,
      AppIcons.rocket,
      AppIcons.terminal,
      AppIcons.fit_screen,
      AppIcons.settings_voice,
      AppIcons.request_page,
      AppIcons.markunread_mailbox,
      AppIcons.camera_enhance,
      AppIcons.onetwothree,
      AppIcons.event_repeat,
      AppIcons.satellite_alt,
      AppIcons.public,
      AppIcons.school,
      AppIcons.engineering,
      AppIcons.construction,
      AppIcons.science,
      AppIcons.female,
      AppIcons.male,
      AppIcons.real_estate_agent,
      AppIcons.architecture,
      AppIcons.cruelty_free,
      AppIcons.heart_broken,
      AppIcons.woman,
      AppIcons.man,
      AppIcons.pages,
      AppIcons.thunderstorm,
      AppIcons.create,
      AppIcons.mail,
      AppIcons.flash_on,
      AppIcons.auto_fix_high,
      AppIcons.phone,
      AppIcons.stay_current_portrait,
      AppIcons.rss_feed,
      AppIcons.volunteer_activism,
      AppIcons.factory,
      AppIcons.agriculture,
      AppIcons.phone_iphone,
      AppIcons.smart_display,
      AppIcons.security,
      AppIcons.laptop,
      AppIcons.router,
      AppIcons.watch,
      AppIcons.light_mode,
      AppIcons.devices,
      AppIcons.widgets,
      AppIcons.battery_charging_full,
      AppIcons.flashlight_on,
      AppIcons.network_wifi,
      AppIcons.event,
      AppIcons.celebration,
      AppIcons.park,
      AppIcons.local_activity,
      AppIcons.sports_esports,
      AppIcons.sports_basketball,
      AppIcons.sports_tennis,
      AppIcons.hiking,
      AppIcons.tour,
      AppIcons.golf_course,
      AppIcons.church,
      AppIcons.videocam,
      AppIcons.mic,
      AppIcons.personal_video,
      AppIcons.tv,
      AppIcons.videogame_asset,
      AppIcons.speaker_group,
      AppIcons.theater_comedy,
      AppIcons.cake,
      AppIcons.emoji_emotions,
      AppIcons.groups,
    ],
  };

  /// null = all groups.
  String? _group;
  late IconData _selectedIcon;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.initialIcon ?? categorizedIcons.values.first.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onSelectIcon(_selectedIcon);
    });
  }

  String _groupLabel(AppLocalizations l, String? key) {
    return switch (key) {
      null => l.iconGroupAll,
      'Finance' => l.iconGroupFinance,
      'Movement' => l.iconGroupMovement,
      'Food' => l.iconGroupFood,
      'Retail' => l.iconGroupRetail,
      'Housing' => l.iconGroupHousing,
      'Health' => l.iconGroupHealth,
      _ => l.iconGroupOther,
    };
  }

  List<IconData> get _icons => _group == null
      ? categorizedIcons.values.expand((i) => i).toList()
      : categorizedIcons[_group]!;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.iconPicker,
          style: kTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final group in <String?>[null, ...categorizedIcons.keys])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      _groupLabel(l, group),
                      style: kTextStyle.copyWith(
                        fontSize: 13,
                        fontWeight: _group == group
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    selected: _group == group,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => setState(() => _group = group),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 244,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: kCardShadow,
          ),
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: _icons.length,
            itemBuilder: (ctx, index) {
              final icon = _icons[index];
              final selected = icon == _selectedIcon;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedIcon = icon);
                  widget.onSelectIcon(icon);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? widget.accent.withValues(alpha: 0.15)
                        : null,
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: selected ? widget.accent : scheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
