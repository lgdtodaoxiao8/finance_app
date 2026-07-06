import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/features/auth/auth_service.dart';
import 'package:finance_app/features/auth/data/app_user.dart';
import 'package:finance_app/features/auth/view/auth_screen.dart';
import 'package:finance_app/features/subscription/widgets/premium_gate.dart';
import 'package:finance_app/features/sync/sync_service.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Settings card for the account: sign-in prompt, signed-in identity + sign
/// out, or a gentle "coming soon" when the backend isn't configured.
class AccountSection extends StatelessWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = getIt<AuthService>();

    if (!auth.isAvailable) {
      return const _Card(
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: AppColors.textTertiary),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cloud sync isn\'t set up yet',
                style: TextStyle(
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
          const Expanded(
            child: Text(
              'Sign in to sync across devices',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
            ),
            child: const Text('Sign in'),
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

  Future<void> _syncNow(BuildContext context) async {
    // Sync is a premium feature — opens the paywall if the user isn't premium.
    if (!await ensurePremium(context)) return;
    try {
      await getIt<SyncService>().sync();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    }
  }

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
                    const Text(
                      'Signed in',
                      style: TextStyle(
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => auth.signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.divider),
          ValueListenableBuilder<bool>(
            valueListenable: sync.isSyncing,
            builder: (context, syncing, _) {
              return Row(
                children: [
                  const Icon(
                    Icons.cloud_done_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Cloud sync',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (syncing)
                    const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    FilledButton.tonal(
                      onPressed: () => _syncNow(context),
                      child: const Text('Sync now'),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: kCardShadow,
      ),
      child: child,
    );
  }
}
