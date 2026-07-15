import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/features/auth/auth_service.dart';
import 'package:finance_app/features/auth/data/app_user.dart';
import 'package:finance_app/features/auth/view/auth_screen.dart';
import 'package:finance_app/features/sync/sync_service.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Settings card for the account: sign-in prompt, or signed-in identity with a
/// quiet automatic-sync status. Sync itself is invisible — it runs on its own.
class AccountSection extends StatelessWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = getIt<AuthService>();
    // Rebuild once the backend finishes wiring up (post-launch), so this never
    // gets stuck on the initial "not ready" state.
    return ValueListenableBuilder<bool>(
      valueListenable: auth.isReady,
      builder: (context, _, _) {
        if (!auth.isAvailable) {
          return _Card(
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).cloudSyncNotSetUp,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return ValueListenableBuilder<AppUser?>(
          valueListenable: auth.currentUser,
          builder: (context, user, _) {
            if (user == null) return const _SignedOut();
            return _SignedIn(user: user, auth: auth);
          },
        );
      },
    );
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          const Icon(Icons.cloud_sync_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context).signInToSync,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
            ),
            child: Text(AppLocalizations.of(context).signIn),
          ),
        ],
      ),
    );
  }
}

class _SignedIn extends StatelessWidget {
  const _SignedIn({required this.user, required this.auth});

  final AppUser user;
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    final sync = getIt<SyncService>();
    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).signedIn,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Text(
                      user.email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => auth.signOut(),
                child: Text(AppLocalizations.of(context).signOut),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.divider),
          // Sync is automatic — this is a quiet status line, not a button.
          ValueListenableBuilder<bool>(
            valueListenable: sync.isSyncing,
            builder: (context, syncing, _) {
              return Row(
                children: [
                  if (syncing)
                    const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(
                      Icons.cloud_done_rounded,
                      size: 20,
                      color: AppColors.positive,
                    ),
                  const SizedBox(width: 10),
                  Text(
                    syncing
                        ? AppLocalizations.of(context).syncing
                        : AppLocalizations.of(context).syncedAutomatically,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: kCardShadow,
      ),
      child: child,
    );
  }
}
