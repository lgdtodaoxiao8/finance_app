import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/features/settings/cubit/base_currency_cubit.dart';
import 'package:finance_app/features/settings/widgets/widgets.dart';
import 'package:finance_app/features/auth/widgets/account_section.dart';
import 'package:finance_app/features/settings/widgets/preferences_section.dart';
import 'package:finance_app/features/subscription/widgets/premium_upgrade_card.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.settingsTitle, style: kTextStyle.copyWith()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const PremiumUpgradeCard(),
          const SizedBox(height: 16),
          const AccountSection(),
          const SizedBox(height: 16),
          const PreferencesSection(),
          const SizedBox(height: 16),
          _Card(
            title: l.baseCurrency,
            child: BlocProvider(
              create: (_) => BaseCurrencyCubit(getIt<CurrencyRepository>()),
              child: const SetBaseCurrency(),
            ),
          ),
          const SizedBox(height: 16),
          const AccountsSection(),
          const SizedBox(height: 16),
          const CategoriesSection(),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: kTextStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
