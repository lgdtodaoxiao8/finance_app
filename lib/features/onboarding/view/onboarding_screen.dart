import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/preferences/app_preferences.dart';
import 'package:finance_app/features/onboarding/data/onboarding_slide.dart';
import 'package:finance_app/features/onboarding/widgets/onboarding_slide_view.dart';
import 'package:finance_app/features/onboarding/widgets/setup_base_currency_step.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// First-run experience: a short marketing carousel followed by base-currency
/// setup. Calls [onFinished] once the user has a base currency and is ready to
/// enter the app.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  /// Index of the (final) base-currency setup page.
  int get _setupIndex => onboardingSlides.length;
  int get _pageCount => onboardingSlides.length + 1;
  bool get _onSetupPage => _index == _setupIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(int page) => _controller.animateToPage(
    page,
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeInOut,
  );

  Future<void> _complete() async {
    await getIt<AppPreferences>().setOnboardingSeen(true);
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip → jump to setup (base currency is mandatory, can't skip it).
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _onSetupPage ? 0 : 1,
                  child: TextButton(
                    onPressed: _onSetupPage ? null : () => _animateTo(_setupIndex),
                    child: const Text('Skip'),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  for (final slide in onboardingSlides)
                    OnboardingSlideView(slide: slide),
                  SetupBaseCurrencyStep(onFinished: _complete),
                ],
              ),
            ),
            _BottomBar(
              index: _index,
              pageCount: _pageCount,
              // Hide the CTA on the setup page (it has its own button).
              showCta: !_onSetupPage,
              isLastSlide: _index == onboardingSlides.length - 1,
              onNext: () => _animateTo(_index + 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.index,
    required this.pageCount,
    required this.showCta,
    required this.isLastSlide,
    required this.onNext,
  });

  final int index;
  final int pageCount;
  final bool showCta;
  final bool isLastSlide;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < pageCount; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: i == index ? 22 : 8,
                  decoration: BoxDecoration(
                    color: i == index
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: showCta ? 1 : 0,
              child: ElevatedButton(
                onPressed: showCta ? onNext : null,
                child: Text(
                  isLastSlide ? 'Get started' : 'Next',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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
