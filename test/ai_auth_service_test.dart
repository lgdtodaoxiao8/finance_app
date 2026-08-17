import 'dart:convert';

import 'package:finance_app/core/preferences/app_preferences.dart';
import 'package:finance_app/features/ai/ai_service.dart';
import 'package:finance_app/features/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _sampleResultJson() => {
  'summary': 'You spent less than last month.',
  'score': 72,
  'scoreLabel': 'On track',
  'insights': [
    {
      'title': 'Dining down',
      'detail': 'Eating out fell 20%.',
      'tone': 'positive',
    },
    {
      'title': 'Watch rent share',
      'detail': 'Rent is 40% of spend.',
      'tone': 'warning',
    },
  ],
  'tip': 'Move 10% to savings on payday.',
};

void main() {
  group('AuthService (backend not bound)', () {
    test('stays inert with no session', () {
      final auth = AuthService();
      expect(auth.isAvailable, isFalse);
      expect(auth.isSignedIn, isFalse);
      expect(auth.currentUser.value, isNull);
      auth.dispose();
    });

    test('signIn / signUp throw a friendly not-configured AuthFailure', () async {
      final auth = AuthService();
      final m = throwsA(
        isA<AuthFailure>().having(
          (e) => e.isNotConfigured,
          'isNotConfigured',
          isTrue,
        ),
      );
      await expectLater(auth.signIn('a@b.com', 'password'), m);
      await expectLater(auth.signUp('a@b.com', 'password'), m);
      auth.dispose();
    });

    test('AuthFailure carries the provider message', () {
      final f = AuthFailure('Invalid login credentials');
      expect(f.message, 'Invalid login credentials');
      expect(f.toString(), 'Invalid login credentials');
      expect(f.isNotConfigured, isFalse);
    });
  });

  group('AiService', () {
    late AppPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = AppPreferences(await SharedPreferences.getInstance());
    });

    test('cached is null when nothing is stored', () {
      expect(AiService(prefs).cached, isNull);
    });

    test('cached returns null on corrupt json (never throws)', () async {
      await prefs.setAiInsightsCache('sig', 'definitely not json');
      expect(AiService(prefs).cached, isNull);
    });

    test('cached parses a stored result', () async {
      await prefs.setAiInsightsCache('sig', jsonEncode(_sampleResultJson()));
      final cached = AiService(prefs).cached;
      expect(cached, isNotNull);
      expect(cached!.score, 72);
      expect(cached.scoreLabel, 'On track');
      expect(cached.insights, hasLength(2));
      expect(cached.insights.first.tone, 'positive');
      expect(cached.tip, 'Move 10% to savings on payday.');
    });

    test('signature is order-independent across categories', () {
      final ai = AiService(prefs);
      final a = {
        'language': 'en',
        'income': 1000,
        'expense': 600,
        'byCategory': [
          {'name': 'Food', 'amount': 300},
          {'name': 'Rent', 'amount': 300},
        ],
      };
      final b = {
        'language': 'en',
        'income': 1000,
        'expense': 600,
        'byCategory': [
          {'name': 'Rent', 'amount': 300},
          {'name': 'Food', 'amount': 300},
        ],
      };
      expect(ai.signatureFor(a), ai.signatureFor(b));
    });

    test('signature is sensitive to language and totals', () {
      final ai = AiService(prefs);
      final base = {
        'language': 'en',
        'income': 1000,
        'expense': 600,
        'byCategory': const [],
      };
      expect(
        ai.signatureFor(base),
        isNot(ai.signatureFor({...base, 'language': 'ru'})),
      );
      expect(
        ai.signatureFor(base),
        isNot(ai.signatureFor({...base, 'expense': 700})),
      );
    });

    test('classifyError maps common provider errors', () {
      final ai = AiService(prefs);
      expect(ai.classifyError('insufficient_quota'), AiFailureKind.noCredit);
      expect(ai.classifyError('HTTP 429 too many requests'), AiFailureKind.noCredit);
      expect(ai.classifyError('401 Unauthorized'), AiFailureKind.invalidKey);
      expect(ai.classifyError('Invalid API key'), AiFailureKind.invalidKey);
      expect(
        ai.classifyError('OPENAI_API_KEY is not set on the server'),
        AiFailureKind.keyNotSet,
      );
      expect(ai.classifyError('daily_limit'), AiFailureKind.dailyLimit);
      expect(ai.classifyError('some other error'), AiFailureKind.unknown);
    });

    test('ask throws backendOff when the backend is not configured', () async {
      final ai = AiService(prefs);
      if (!ai.isAvailable) {
        await expectLater(
          ai.ask(question: 'Can I afford this?', summary: const {'language': 'en'}),
          throwsA(
            isA<AiFailure>().having(
              (e) => e.kind,
              'kind',
              AiFailureKind.backendOff,
            ),
          ),
        );
      }
    });

    test('insights serves the cache on a signature match (no network)', () async {
      final ai = AiService(prefs);
      final summary = {
        'language': 'en',
        'income': 1000,
        'expense': 600,
        'byCategory': [
          {'name': 'Rent', 'amount': 600},
        ],
      };
      await prefs.setAiInsightsCache(
        ai.signatureFor(summary),
        jsonEncode(_sampleResultJson()),
      );
      if (ai.isAvailable) {
        // Backend configured: a matching signature must return the cached
        // result outright, never reaching the (unmocked) network.
        final result = await ai.insights(summary);
        expect(result.score, 72);
        expect(result.tip, 'Move 10% to savings on payday.');
      } else {
        // Backend not configured: the guard fires before the cache is read.
        await expectLater(
          ai.insights(summary),
          throwsA(
            isA<AiFailure>().having(
              (e) => e.kind,
              'kind',
              AiFailureKind.backendOff,
            ),
          ),
        );
      }
    });
  });
}
