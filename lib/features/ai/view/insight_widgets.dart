import 'package:finance_app/core/format.dart';
import 'package:finance_app/core/widgets/amount_text.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// One category slice used by the insight detail screens.
class CategoryBar {
  const CategoryBar({
    required this.name,
    required this.amount,
    required this.share,
    required this.color,
  });

  final String name;
  final double amount;
  final double share; // 0..1 of total expense
  final Color color;
}

/// Small labelled stat tile (Income / Expense / …).
class MiniStat extends StatelessWidget {
  const MiniStat({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A category row: name + amount + share bar + percentage.
class CategoryBarRow extends StatelessWidget {
  const CategoryBarRow({super.key, required this.bar, required this.symbol});

  final CategoryBar bar;
  final String? symbol;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: bar.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  bar.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Text(
                '${(bar.share * 100).round()}%',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 10),
              Text(
                AmountText.maskString(compactMoney(bar.amount, symbol)),
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  color: cs.onSurface.withValues(alpha: 0.08),
                ),
                FractionallySizedBox(
                  widthFactor: bar.share.clamp(0.0, 1.0),
                  child: Container(height: 6, color: bar.color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
