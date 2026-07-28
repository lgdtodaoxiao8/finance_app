import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Small gradient "PREMIUM" pill used to flag paywalled features and slides.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key, this.label = 'PREMIUM'});

  final String label;

  static const gradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF7C3AED)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(PhosphorIconsFill.sparkle, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
