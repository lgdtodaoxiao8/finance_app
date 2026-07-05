import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/features/auth/auth_service.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';

/// Email + password sign in / sign up. On success it pops back to wherever it
/// was pushed from (Settings account section), where the reactive
/// [AuthService.currentUser] updates the UI.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = getIt<AuthService>();

  bool _isSignUp = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_isSignUp) {
        await _auth.signUp(email, password);
      } else {
        await _auth.signIn(email, password);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Something went wrong. $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isSignUp ? 'Create account' : 'Sign in')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          Text(
            _isSignUp ? 'Create your account' : 'Welcome back',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sync your data across phone and web, and keep it safely backed up.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          _Field(
            controller: _email,
            hint: 'you@email.com',
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _Field(
            controller: _password,
            hint: '••••••••',
            label: 'Password',
            obscure: true,
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.negative, fontSize: 13.5),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isSignUp ? 'Create account' : 'Sign in',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _isSignUp = !_isSignUp;
                      _error = null;
                    }),
              child: Text(
                _isSignUp
                    ? 'Already have an account? Sign in'
                    : 'New here? Create an account',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.label,
    this.obscure = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.field,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kRadiusSm),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
