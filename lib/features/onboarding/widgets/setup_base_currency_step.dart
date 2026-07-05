import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/features/settings/cubit/base_currency_cubit.dart';
import 'package:finance_app/features/settings/widgets/set_base_currency.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Final onboarding step: pick the base currency everything is measured in.
///
/// Reuses [SetBaseCurrency]; once a base currency exists the "Enter app"
/// button lights up and calls [onFinished].
class SetupBaseCurrencyStep extends StatelessWidget {
  const SetupBaseCurrencyStep({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BaseCurrencyCubit(getIt<CurrencyRepository>()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Set your base currency',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This is the currency your totals and charts are shown in. '
                'You can add more currencies later.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(kRadiusLg),
                  boxShadow: kCardShadow,
                ),
                child: const SetBaseCurrency(),
              ),
              const SizedBox(height: 24),
              BlocBuilder<BaseCurrencyCubit, BaseCurrencyState>(
                builder: (context, state) {
                  final ready = state.baseSymbol != null;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: ready ? onFinished : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        ready ? 'Enter the app' : 'Pick a currency to continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
