import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/data/repositories/currency_repository.dart';
import 'package:finance_app/features/accounts/view/account_balances_screen.dart';
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
          _NavCard(
            icon: Icons.account_balance_wallet_outlined,
            title: l.accounts,
            subtitle: l.accountsCardSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AccountBalancesScreen(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _NavCard(
            icon: Icons.widgets_outlined,
            title: l.widgetsTitle,
            subtitle: l.widgetsSubtitle,
            onTap: () => Navigator.of(context).pushNamed('/widget-config'),
          ),
          const SizedBox(height: 16),
          _Card(
            // SetBaseCurrency draws its own header (title + "+"), so the card
            // supplies no title of its own.
            child: BlocProvider(
              create: (_) => BaseCurrencyCubit(getIt<CurrencyRepository>()),
              child: const SetBaseCurrency(),
            ),
          ),
          const SizedBox(height: 16),
          const CategoriesSection(),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: kCardShadow,
          ),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
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
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: kTextStyle.copyWith(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

/// A plain rounded settings card. Its child renders its own header/content.
class _Card extends StatelessWidget {
  const _Card({required this.child});

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
      child: child,
    );
  }
}
