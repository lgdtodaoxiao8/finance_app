import 'package:finance_app/core/di/injector.dart';
import 'package:finance_app/core/widgets/premium_badge.dart';
import 'package:finance_app/features/ai/ai_service.dart';
import 'package:finance_app/features/ai/data/spending_summary.dart';
import 'package:finance_app/features/auth/auth_service.dart';
import 'package:finance_app/features/auth/data/app_user.dart';
import 'package:finance_app/features/auth/view/auth_screen.dart';
import 'package:finance_app/theme/theme.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// "Ask your money" — a bounded chat over the user's own spending. Premium +
/// signed-in (the Edge Function needs a JWT and every question is a live call).
/// The exchange is capped to one question plus a single follow-up, then resets;
/// the real spend cap lives server-side (see the ask-money function).
class AskMoneyScreen extends StatefulWidget {
  const AskMoneyScreen({super.key});

  @override
  State<AskMoneyScreen> createState() => _AskMoneyScreenState();
}

enum _Kind { user, ai, error }

class _Msg {
  const _Msg(this.kind, this.text);
  final _Kind kind;
  final String text;
}

class _AskMoneyScreenState extends State<AskMoneyScreen> {
  final _ai = getIt<AiService>();
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  final List<_Msg> _messages = [];
  bool _sending = false;
  int? _remaining;

  /// Successful user questions this round (0, 1, or 2). The exchange is capped
  /// at 2 — one question and one follow-up — then the user must start over.
  int _asked = 0;

  /// The first turn, kept so a follow-up stays in context.
  String? _firstQuestion;
  String? _firstAnswer;

  bool get _atLimit => _asked >= 2;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String raw) async {
    final question = raw.trim();
    if (question.isEmpty || _sending || _atLimit) return;

    // Capture the locale before any await (context is unsafe across async gaps).
    final language = Localizations.localeOf(context).languageCode;
    final followUp = _asked == 1;

    setState(() {
      _messages.add(_Msg(_Kind.user, question));
      _sending = true;
      _controller.clear();
    });
    _scrollToEnd();

    try {
      final summary = await buildSpendingSummary(language: language);
      final answer = await _ai.ask(
        question: question,
        summary: summary,
        prior: followUp && _firstQuestion != null && _firstAnswer != null
            ? (question: _firstQuestion!, answer: _firstAnswer!)
            : null,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(_Msg(_Kind.ai, answer.answer));
        _remaining = answer.remaining;
        _asked += 1;
        if (!followUp) {
          _firstQuestion = question;
          _firstAnswer = answer.answer;
        }
      });
      _scrollToEnd();
    } on AiFailure catch (e) {
      if (!mounted) return;
      // The question didn't count (we only increment on success), so the user
      // can retry. Show the error as a coach-side note.
      setState(() => _messages.add(_Msg(_Kind.error, _localizedFailure(e))));
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _messages.add(
          _Msg(
            _Kind.error,
            AppLocalizations.of(context).somethingWentWrongDetail('$e'),
          ),
        ),
      );
      _scrollToEnd();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _reset() {
    setState(() {
      _messages.clear();
      _asked = 0;
      _firstQuestion = null;
      _firstAnswer = null;
    });
  }

  String _localizedFailure(AiFailure e) {
    final l = AppLocalizations.of(context);
    return switch (e.kind) {
      AiFailureKind.backendOff => l.aiErrorBackendOff,
      AiFailureKind.noCredit => l.aiErrorNoCredit,
      AiFailureKind.invalidKey => l.aiErrorInvalidKey,
      AiFailureKind.keyNotSet => l.aiErrorKeyNotSet,
      AiFailureKind.dailyLimit => l.aiErrorDailyLimit,
      AiFailureKind.badResponse => l.aiErrorBadResponse,
      AiFailureKind.unknown => l.somethingWentWrongDetail(e.detail ?? ''),
    };
  }

  @override
  Widget build(BuildContext context) {
    final auth = getIt<AuthService>();
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).askYourMoney)),
      body: ValueListenableBuilder<AppUser?>(
        valueListenable: auth.currentUser,
        builder: (context, user, _) {
          if (user == null) return const _SignInPrompt();
          return _buildChat(context);
        },
      ),
    );
  }

  Widget _buildChat(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? _Intro(onPick: _send)
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: _messages.length + (_sending ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == _messages.length) return const _Thinking();
                    return _Bubble(msg: _messages[i]);
                  },
                ),
        ),
        if (_remaining != null && !_atLimit)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              l.askMoneyQuestionsLeft(_remaining!),
              style: TextStyle(
                fontSize: 11.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        _atLimit
            ? _DoneBar(onReset: _reset)
            : _InputBar(
                controller: _controller,
                sending: _sending,
                hint: _asked == 1 ? l.askMoneyFollowUpHint : l.askMoneyHint,
                onSend: () => _send(_controller.text),
              ),
      ],
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.onPick});
  final void Function(String) onPick;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final starters = [l.askMoneyStarter1, l.askMoneyStarter2, l.askMoneyStarter3];
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      children: [
        Center(child: PremiumBadge(label: l.askMoneyBadge)),
        const SizedBox(height: 22),
        Text(
          l.askMoneyIntroTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.askMoneyIntroSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l.askMoneyTryAsking,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        for (final s in starters)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => onPick(s),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(kRadiusMd),
                  border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 17,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s,
                        style: TextStyle(fontSize: 14.5, color: cs.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final _Msg msg;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (msg.kind == _Kind.user) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: Text(
            msg.text,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.4,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    final isError = msg.kind == _Kind.error;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 32),
        padding: const EdgeInsets.fromLTRB(15, 12, 15, 13),
        decoration: BoxDecoration(
          color: isError
              ? AppColors.negative.withValues(alpha: 0.12)
              : cs.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: isError ? null : kCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isError
                      ? Icons.error_outline_rounded
                      : Icons.auto_awesome_rounded,
                  size: 13,
                  color: isError ? AppColors.negative : AppColors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  AppLocalizations.of(context).aiCoach,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isError ? AppColors.negative : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.5,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thinking extends StatelessWidget {
  const _Thinking();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: kCardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 15,
              width: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context).askMoneyThinking,
              style: TextStyle(fontSize: 13.5, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.hint,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool sending;
  final String hint;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !sending,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                maxLength: 500,
                buildCounter:
                    (_, {required currentLength, required isFocused, maxLength}) =>
                        null,
                decoration: InputDecoration(
                  hintText: hint,
                  filled: true,
                  fillColor: cs.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: cs.onSurface.withValues(alpha: 0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: cs.onSurface.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: sending ? null : onSend,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  gradient: PremiumBadge.gradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoneBar extends StatelessWidget {
  const _DoneBar({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.askMoneyDone,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l.askMoneyNewQuestion),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_sync_rounded,
              size: 40,
              color: AppColors.primary,
            ),
            const SizedBox(height: 14),
            Text(
              l.askMoneySignInRequired,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
              ),
              child: Text(l.signIn),
            ),
          ],
        ),
      ),
    );
  }
}
