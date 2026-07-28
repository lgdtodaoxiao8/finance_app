import 'package:finance_app/l10n/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
      PhosphorIconsFill.bank,
      PhosphorIconsFill.wallet,
      PhosphorIconsFill.creditCard,
      PhosphorIconsFill.money,
      PhosphorIconsFill.coins,
      PhosphorIconsFill.piggyBank,
      PhosphorIconsFill.receipt,
      PhosphorIconsFill.chartLineUp,
      PhosphorIconsFill.chartLineDown,
      PhosphorIconsFill.percent,
      PhosphorIconsFill.chartBar,
      PhosphorIconsFill.vault,
      PhosphorIconsFill.handCoins,
      PhosphorIconsFill.currencyDollar,
      PhosphorIconsFill.currencyCircleDollar,
      PhosphorIconsFill.invoice,
      PhosphorIconsFill.scales,
      PhosphorIconsFill.tag,
      PhosphorIconsFill.sealPercent,
      PhosphorIconsFill.calendarCheck,
      PhosphorIconsFill.lockKey,
      PhosphorIconsFill.star,
      PhosphorIconsFill.hourglass,
      PhosphorIconsFill.lifebuoy,
      PhosphorIconsFill.fingerprint,
      PhosphorIconsFill.gavel,
      PhosphorIconsFill.table,
      PhosphorIconsFill.fileText,
      PhosphorIconsFill.identificationCard,
      PhosphorIconsFill.arrowsLeftRight,
    ],
    "Movement": [
      PhosphorIconsFill.car,
      PhosphorIconsFill.carProfile,
      PhosphorIconsFill.airplane,
      PhosphorIconsFill.airplaneTilt,
      PhosphorIconsFill.train,
      PhosphorIconsFill.bus,
      PhosphorIconsFill.boat,
      PhosphorIconsFill.taxi,
      PhosphorIconsFill.bicycle,
      PhosphorIconsFill.scooter,
      PhosphorIconsFill.sailboat,
      PhosphorIconsFill.truck,
      PhosphorIconsFill.mapPin,
      PhosphorIconsFill.gasPump,
      PhosphorIconsFill.motorcycle,
      PhosphorIconsFill.trafficSign,
      PhosphorIconsFill.gauge,
      PhosphorIconsFill.anchor,
      PhosphorIconsFill.mountains,
      PhosphorIconsFill.suitcase,
      PhosphorIconsFill.mapTrifold,
      PhosphorIconsFill.roadHorizon,
      PhosphorIconsFill.compass,
    ],
    "Food": [
      PhosphorIconsFill.forkKnife,
      PhosphorIconsFill.coffee,
      PhosphorIconsFill.hamburger,
      PhosphorIconsFill.pizza,
      PhosphorIconsFill.cookingPot,
      PhosphorIconsFill.wine,
      PhosphorIconsFill.beerBottle,
      PhosphorIconsFill.beerStein,
      PhosphorIconsFill.martini,
      PhosphorIconsFill.iceCream,
      PhosphorIconsFill.cookie,
      PhosphorIconsFill.bread,
      PhosphorIconsFill.cake,
      PhosphorIconsFill.cheese,
      PhosphorIconsFill.carrot,
      PhosphorIconsFill.orangeSlice,
      PhosphorIconsFill.avocado,
      PhosphorIconsFill.popcorn,
    ],
    "Retail": [
      PhosphorIconsFill.shoppingCart,
      PhosphorIconsFill.shoppingBag,
      PhosphorIconsFill.basket,
      PhosphorIconsFill.storefront,
      PhosphorIconsFill.bagSimple,
      PhosphorIconsFill.gift,
      PhosphorIconsFill.diamond,
      PhosphorIconsFill.flower,
      PhosphorIconsFill.tShirt,
      PhosphorIconsFill.pants,
      PhosphorIconsFill.dress,
      PhosphorIconsFill.sneaker,
      PhosphorIconsFill.handbag,
      PhosphorIconsFill.watch,
      PhosphorIconsFill.sunglasses,
    ],
    "Housing": [
      PhosphorIconsFill.house,
      PhosphorIconsFill.houseLine,
      PhosphorIconsFill.buildings,
      PhosphorIconsFill.couch,
      PhosphorIconsFill.bed,
      PhosphorIconsFill.lightbulb,
      PhosphorIconsFill.plug,
      PhosphorIconsFill.drop,
      PhosphorIconsFill.wrench,
      PhosphorIconsFill.toolbox,
      PhosphorIconsFill.broom,
      PhosphorIconsFill.paintRoller,
      PhosphorIconsFill.key,
      PhosphorIconsFill.door,
      PhosphorIconsFill.armchair,
      PhosphorIconsFill.television,
      PhosphorIconsFill.wifiHigh,
      PhosphorIconsFill.thermometer,
      PhosphorIconsFill.hammer,
      PhosphorIconsFill.plant,
    ],
    "Health": [
      PhosphorIconsFill.heartbeat,
      PhosphorIconsFill.heart,
      PhosphorIconsFill.firstAid,
      PhosphorIconsFill.firstAidKit,
      PhosphorIconsFill.pill,
      PhosphorIconsFill.syringe,
      PhosphorIconsFill.tooth,
      PhosphorIconsFill.barbell,
      PhosphorIconsFill.personSimpleRun,
      PhosphorIconsFill.stethoscope,
      PhosphorIconsFill.brain,
      PhosphorIconsFill.bandaids,
      PhosphorIconsFill.virus,
      PhosphorIconsFill.flask,
      PhosphorIconsFill.eye,
      PhosphorIconsFill.ear,
    ],
    "Other": [
      PhosphorIconsFill.star,
      PhosphorIconsFill.gift,
      PhosphorIconsFill.gameController,
      PhosphorIconsFill.musicNotes,
      PhosphorIconsFill.filmSlate,
      PhosphorIconsFill.bookOpen,
      PhosphorIconsFill.graduationCap,
      PhosphorIconsFill.pawPrint,
      PhosphorIconsFill.phone,
      PhosphorIconsFill.deviceMobile,
      PhosphorIconsFill.laptop,
      PhosphorIconsFill.camera,
      PhosphorIconsFill.headphones,
      PhosphorIconsFill.palette,
      PhosphorIconsFill.globe,
      PhosphorIconsFill.sun,
      PhosphorIconsFill.umbrella,
      PhosphorIconsFill.ticket,
      PhosphorIconsFill.trophy,
      PhosphorIconsFill.dog,
      PhosphorIconsFill.cat,
      PhosphorIconsFill.tree,
      PhosphorIconsFill.briefcase,
      PhosphorIconsFill.gearSix,
      PhosphorIconsFill.sparkle,
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
