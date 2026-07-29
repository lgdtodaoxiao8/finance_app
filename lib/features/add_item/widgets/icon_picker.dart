import 'package:finance_app/l10n/app_localizations.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

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
      SolarIconsBold.wallet,
      SolarIconsBold.wallet2,
      SolarIconsBold.walletMoney,
      SolarIconsBold.card,
      SolarIconsBold.card2,
      SolarIconsBold.moneyBag,
      SolarIconsBold.banknote,
      SolarIconsBold.banknote2,
      SolarIconsBold.safe2,
      SolarIconsBold.safeCircle,
      SolarIconsBold.bill,
      SolarIconsBold.billList,
      SolarIconsBold.cashOut,
      SolarIconsBold.dollarMinimalistic,
      SolarIconsBold.cardTransfer,
      SolarIconsBold.cardReceive,
      SolarIconsBold.cardSend,
      SolarIconsBold.chart,
      SolarIconsBold.chartSquare,
      SolarIconsBold.calendar,
      SolarIconsBold.star,
      SolarIconsBold.verifiedCheck,
      SolarIconsBold.lockKeyholeMinimalistic,
    ],
    "Movement": [
      SolarIconsBold.bus,
      SolarIconsBold.tram,
      SolarIconsBold.scooter,
      SolarIconsBold.kickScooter,
      SolarIconsBold.bicycling,
      SolarIconsBold.skateboard,
      SolarIconsBold.rocket,
      SolarIconsBold.wheel,
      SolarIconsBold.ferrisWheel,
      SolarIconsBold.globus,
      SolarIconsBold.fuel,
      SolarIconsBold.gasStation,
      SolarIconsBold.ticket,
    ],
    "Food": [
      SolarIconsBold.cupHot,
      SolarIconsBold.cup,
      SolarIconsBold.teaCup,
      SolarIconsBold.cupPaper,
      SolarIconsBold.chefHat,
      SolarIconsBold.chefHatMinimalistic,
      SolarIconsBold.donut,
      SolarIconsBold.donutBitten,
      SolarIconsBold.bottle,
      SolarIconsBold.wineglass,
      SolarIconsBold.wineglassTriangle,
    ],
    "Retail": [
      SolarIconsBold.bag,
      SolarIconsBold.bag2,
      SolarIconsBold.bag3,
      SolarIconsBold.bag4,
      SolarIconsBold.bag5,
      SolarIconsBold.bagCheck,
      SolarIconsBold.bagHeart,
      SolarIconsBold.bagSmile,
      SolarIconsBold.cart,
      SolarIconsBold.cart_2,
      SolarIconsBold.cart_3,
      SolarIconsBold.shop,
      SolarIconsBold.shopMinimalistic,
      SolarIconsBold.gift,
    ],
    "Housing": [
      SolarIconsBold.home2,
      SolarIconsBold.homeAngle_2,
      SolarIconsBold.sofa,
      SolarIconsBold.armchair,
      SolarIconsBold.bed,
      SolarIconsBold.lamp,
      SolarIconsBold.floorLamp,
      SolarIconsBold.plugCircle,
      SolarIconsBold.tv,
      SolarIconsBold.temperature,
      SolarIconsBold.wifiRouter,
      SolarIconsBold.key,
      SolarIconsBold.keyMinimalistic,
      SolarIconsBold.washingMachine,
      SolarIconsBold.smartVacuumCleaner,
      SolarIconsBold.lightbulb,
    ],
    "Health": [
      SolarIconsBold.heartPulse,
      SolarIconsBold.pills,
      SolarIconsBold.pill,
      SolarIconsBold.jarOfPills,
      SolarIconsBold.medicalKit,
      SolarIconsBold.virus,
      SolarIconsBold.dna,
      SolarIconsBold.bones,
      SolarIconsBold.stethoscope,
      SolarIconsBold.dumbbell,
      SolarIconsBold.dumbbells,
      SolarIconsBold.running,
      SolarIconsBold.handPills,
      SolarIconsBold.health,
    ],
    "Other": [
      SolarIconsBold.star,
      SolarIconsBold.stars,
      SolarIconsBold.gift,
      SolarIconsBold.gamepad,
      SolarIconsBold.gamepadMinimalistic,
      SolarIconsBold.musicNotes,
      SolarIconsBold.musicNote,
      SolarIconsBold.camera,
      SolarIconsBold.videocamera,
      SolarIconsBold.clapperboard,
      SolarIconsBold.clapperboardPlay,
      SolarIconsBold.book,
      SolarIconsBold.bookmark,
      SolarIconsBold.palette,
      SolarIconsBold.paw,
      SolarIconsBold.ticket,
      SolarIconsBold.confetti,
      SolarIconsBold.balloon,
      SolarIconsBold.notebook,
      SolarIconsBold.laptop,
      SolarIconsBold.smartphone,
      SolarIconsBold.diploma,
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
