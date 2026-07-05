import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/preferences/app_preferences.dart';
import 'package:finance_app/features/onboarding/view/onboarding_screen.dart';
import 'package:finance_app/features/root_node/root_node.dart';
import 'package:flutter/material.dart';

/// Decides what the app opens on: the first-run onboarding flow, or the main
/// app. Once onboarding completes it swaps to [RootNodeScreen] in place.
class LaunchGate extends StatefulWidget {
  const LaunchGate({super.key});

  @override
  State<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<LaunchGate> {
  late bool _onboardingDone = getIt<AppPreferences>().onboardingSeen;

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone) return const RootNodeScreen();
    return OnboardingScreen(
      onFinished: () => setState(() => _onboardingDone = true),
    );
  }
}
