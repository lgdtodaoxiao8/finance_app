import 'package:finance_app/features/add_item/widgets/widgets.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'package:finance_app/theme/theme.dart';

class IconPicker extends StatefulWidget {
  const IconPicker({
    super.key,
    required this.onSelectIcon,
    this.backgroundColor,
    this.iconColor,
  });

  final void Function(IconData) onSelectIcon;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  State<IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<IconPicker> {
  final Map<String, List<IconData>> categorizedIcons = {
    "Finance": [
      Icons.account_balance_rounded,
      Icons.account_balance_wallet_rounded,
      Icons.credit_card_rounded,
      Icons.payments_rounded,
      Icons.attach_money_rounded,
      Icons.savings_rounded,
      Icons.receipt_rounded,
      Icons.receipt_long_rounded,
      Icons.trending_up_rounded,
      Icons.trending_down_rounded,
      Icons.percent_rounded,
      Icons.show_chart_rounded,
      Icons.data_object_rounded,
      Icons.balance_rounded,
      Icons.loyalty_rounded,
      Icons.point_of_sale_rounded,
      Icons.swap_horiz_rounded,
      Icons.contactless_rounded,
      Icons.verified_user_rounded,
      Icons.report_problem_rounded,
      Icons.fact_check_rounded,
      Icons.autorenew_rounded,
      Icons.calendar_month_rounded,
      Icons.lock_rounded,
      Icons.star_rate_rounded,
      Icons.hourglass_empty_rounded,
      Icons.support_rounded,
      Icons.fingerprint_rounded,
      Icons.gavel_rounded,
      Icons.table_view_rounded,
      Icons.description_rounded,
      Icons.perm_identity_rounded,
      Icons.delete_rounded,
    ],
    "Movement": [
      Icons.commute_rounded,
      Icons.flight_rounded,
      Icons.flight_takeoff_rounded,
      Icons.directions_car_rounded,
      Icons.train_rounded,
      Icons.directions_bus_rounded,
      Icons.directions_boat_rounded,
      Icons.local_taxi_rounded,
      Icons.pedal_bike_rounded,
      Icons.electric_scooter_rounded,
      Icons.sailing_rounded,
      Icons.local_shipping_rounded,
      Icons.map_rounded,
      Icons.local_gas_station_rounded,
      Icons.two_wheeler_rounded,
      Icons.traffic_rounded,
      Icons.local_parking_rounded,
      Icons.speed_rounded,
      Icons.ev_station_rounded,
      Icons.electric_car_rounded,
      Icons.anchor_rounded,
      Icons.terrain_rounded,
      Icons.luggage_rounded,
      Icons.hotel_rounded,
    ],
    "Food": [
      Icons.restaurant_rounded,
      Icons.coffee_rounded,
      Icons.fastfood_rounded,
      Icons.local_cafe_rounded,
      Icons.lunch_dining_rounded,
      Icons.restaurant_menu_rounded,
      Icons.local_pizza_rounded,
      Icons.bakery_dining_rounded,
      Icons.icecream_rounded,
      Icons.menu_book_rounded,
      Icons.sports_bar_rounded,
      Icons.local_bar_rounded,
      Icons.liquor_rounded,
      Icons.emoji_food_beverage_rounded,
      Icons.cookie_rounded,
    ],
    "Retail": [
      Icons.shopping_cart_rounded,
      Icons.shopping_bag_rounded,
      Icons.shopping_basket_rounded,
      Icons.store_rounded,
      Icons.local_mall_rounded,
      Icons.card_giftcard_rounded,
      Icons.diamond_rounded,
      Icons.local_florist_rounded,
      Icons.add_business_rounded,
    ],
    "Housing": [
      Icons.house_rounded,
      Icons.apartment_rounded,
      Icons.garage_rounded,
      Icons.home_work_rounded,
      Icons.add_home_rounded,
      Icons.room_rounded,
      Icons.king_bed_rounded,
      Icons.fireplace_rounded,
      Icons.family_restroom_rounded,
      Icons.pool_rounded,
      Icons.room_service_rounded,
      Icons.child_friendly_rounded,
      Icons.escalator_warning_rounded,
      Icons.cleaning_services_rounded,
      Icons.local_laundry_service_rounded,
      Icons.pest_control_rodent_rounded,
      Icons.water_drop_rounded,
      Icons.outlet_rounded,
      Icons.device_thermostat_rounded,
      Icons.solar_power_rounded,
      Icons.nightlight_round_rounded,
    ],
    "Health": [
      Icons.medical_services_rounded,
      Icons.local_hospital_rounded,
      Icons.vaccines_rounded,
      Icons.health_and_safety_rounded,
      Icons.fitness_center_rounded,
      Icons.pregnant_woman_rounded,
      Icons.psychology_rounded,
      Icons.healing_rounded,
      Icons.self_improvement_rounded,
      Icons.face_retouching_natural_rounded,
      Icons.accessible_rounded,
      Icons.emergency_rounded,
      Icons.sos_rounded,
      Icons.smoke_free_rounded,
      Icons.vape_free_rounded,
    ],
    "Other": [
      Icons.face_rounded,
      Icons.thumb_up_rounded,
      Icons.lightbulb_rounded,
      Icons.build_rounded,
      Icons.view_list_rounded,
      Icons.work_rounded,
      Icons.print_rounded,
      Icons.analytics_rounded,
      Icons.watch_later_rounded,
      Icons.code_rounded,
      Icons.pets_rounded,
      Icons.explore_rounded,
      Icons.bookmark_rounded,
      Icons.touch_app_rounded,
      Icons.supervisor_account_rounded,
      Icons.leaderboard_rounded,
      Icons.alarm_rounded,
      Icons.rocket_launch_rounded,
      Icons.book_rounded,
      Icons.bug_report_rounded,
      Icons.translate_rounded,
      Icons.extension_rounded,
      Icons.record_voice_over_rounded,
      Icons.dangerous_rounded,
      Icons.group_work_rounded,
      Icons.settings_phone_rounded,
      Icons.offline_bolt_rounded,
      Icons.important_devices_rounded,
      Icons.opacity_rounded,
      Icons.rocket_rounded,
      Icons.terminal_rounded,
      Icons.fit_screen_rounded,
      Icons.settings_voice_rounded,
      Icons.request_page_rounded,
      Icons.markunread_mailbox_rounded,
      Icons.camera_enhance_rounded,
      Icons.onetwothree_rounded,
      Icons.event_repeat_rounded,
      Icons.satellite_alt_rounded,
      Icons.public_rounded,
      Icons.school_rounded,
      Icons.engineering_rounded,
      Icons.construction_rounded,
      Icons.science_rounded,
      Icons.female_rounded,
      Icons.male_rounded,
      Icons.real_estate_agent_rounded,
      Icons.architecture_rounded,
      Icons.cruelty_free_rounded,
      Icons.heart_broken_rounded,
      Icons.woman_rounded,
      Icons.man_rounded,
      Icons.pages_rounded,
      Icons.thunderstorm_rounded,
      Icons.create_rounded,
      Icons.mail_rounded,
      Icons.flash_on_rounded,
      Icons.auto_fix_high_rounded,
      Icons.phone_rounded,
      Icons.stay_current_portrait_rounded,
      Icons.rss_feed_rounded,
      Icons.volunteer_activism_rounded,
      Icons.factory_rounded,
      Icons.agriculture_rounded,
      Icons.phone_iphone_rounded,
      Icons.smart_display_rounded,
      Icons.security_rounded,
      Icons.laptop_rounded,
      Icons.router_rounded,
      Icons.watch_rounded,
      Icons.light_mode_rounded,
      Icons.devices_rounded,
      Icons.widgets_rounded,
      Icons.battery_charging_full_rounded,
      Icons.flashlight_on_rounded,
      Icons.network_wifi_rounded,
      Icons.event_rounded,
      Icons.celebration_rounded,
      Icons.park_rounded,
      Icons.local_activity_rounded,
      Icons.sports_esports_rounded,
      Icons.sports_basketball_rounded,
      Icons.sports_tennis_rounded,
      Icons.hiking_rounded,
      Icons.tour_rounded,
      Icons.golf_course_rounded,
      Icons.church_rounded,
      Icons.videocam_rounded,
      Icons.mic_rounded,
      Icons.personal_video_rounded,
      Icons.tv_rounded,
      Icons.videogame_asset_rounded,
      Icons.speaker_group_rounded,
      Icons.theater_comedy_rounded,
      Icons.cake_rounded,
      Icons.emoji_emotions_rounded,
      Icons.groups_rounded,
    ],
  };

  bool isOpened = true;

  IconData? _selectedIcon;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();

    _selectedIcon = categorizedIcons.values.toList()[0][0];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSelectIcon(_selectedIcon!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.field,
      ),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        padding: isOpened
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: isOpened
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: InkWell(
            onTap: () => setState(() => isOpened = !isOpened),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context).iconPicker,
                  style: kTextStyle.copyWith(
                    fontSize: 16,
                    color: const Color(0xFF242528),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down_rounded),
              ],
            ),
          ),
          secondChild: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PopupDropdownSimple(
                      height: 40,
                      width: 200,
                      currentValue: _selectedCategory,
                      onSelect: (value) {
                        setState(() => _selectedCategory = value);
                      },
                      values: ['All', ...categorizedIcons.keys],
                      label: AppLocalizations.of(context).iconCategories,
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: MediaQuery.of(context).size.height * 0.28,
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 1 / 1,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemBuilder: (ctx, index) {
                    late final IconData icon;
                    if (_selectedCategory == 'All') {
                      icon = categorizedIcons.values
                          .expand((i) => i)
                          .toList()[index];
                    } else {
                      icon = categorizedIcons[_selectedCategory]![index];
                    }

                    final isSelect = _selectedIcon == icon;
                    return GestureDetector(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelect
                              ?
                                // ? Colors.blue.withValues(alpha: 0.1)
                                widget.backgroundColor ??
                                    const Color(
                                      0xFF6084CC,
                                    ).withValues(alpha: 0.2)
                              : null,
                          shape: BoxShape.circle,

                          // border: isSelect
                          //     ? Border.all(
                          //         color: Colors.blue,
                          //         width: 2,
                          //       )
                          //     : null,
                          border: isSelect && widget.backgroundColor == null
                              ? Border.all(
                                  color: const Color(
                                    0xFF6084CC,
                                  ).withValues(alpha: .7),
                                  width: 3,
                                )
                              : null,
                        ),
                        child: Icon(
                          icon,
                          size: isSelect ? 33 : 30,
                          color: isSelect ? widget.iconColor : null,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedIcon = icon;
                        });
                        widget.onSelectIcon(icon);
                      },
                    );
                  },
                  itemCount: _selectedCategory == 'All'
                      ? categorizedIcons.values.expand((i) => i).length
                      : categorizedIcons[_selectedCategory]!.length,
                ),
              ),

              IconButton(
                onPressed: () => setState(() => isOpened = !isOpened),
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
