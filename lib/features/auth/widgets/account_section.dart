import 'package:finance_app/features/auth/auth_service.dart';
import 'package:finance_app/features/auth/data/app_user.dart';
import 'package:finance_app/features/auth/view/auth_screen.dart';
import 'package:finance_app/core/di/injector.dart';
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

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: const Icon(Icons.person_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Signed in',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
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
