import 'package:flutter/material.dart';

/// A savings goal / jar: money set aside toward a target. [savedAmount] is real
/// money (counts toward net worth); [targetAmount]/[deadline] are optional.
class Goal {
  const Goal({
    required this.id,
    required this.name,
    this.targetAmount,
    required this.savedAmount,
    required this.color,
    required this.icon,
    this.deadline,
  });

  final int id;
  final String name;
  final double? targetAmount;
  final double savedAmount;
  final Color color;
  final IconData icon;
  final DateTime? deadline;

  bool get hasTarget => targetAmount != null && targetAmount! > 0;
  double get progress =>
      !hasTarget ? 0 : (savedAmount / targetAmount!).clamp(0.0, 1.0);
  double get remaining => !hasTarget ? 0 : (targetAmount! - savedAmount);
  bool get reached => hasTarget && savedAmount >= targetAmount!;
}
