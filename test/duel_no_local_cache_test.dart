import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/ui/duel/duel_live_screen.dart';

import 'support/duel_live_support.dart';
import 'support/duel_scenario.dart';

/// Decision J1 and ETUDE § 4.2: the questions of a duel are never written to
/// the theme cache (`LocalDb`, sqflite) nor to any disk path the solo game or
/// its offline fallback reads. Two proofs: a whole game with every disk
/// channel watched, and a read of the sources.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a whole duel, from the room to the review, touches no database and no file', (tester) async {
    final calls = <String>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    for (final name in [
      'com.tekartik.sqflite', // LocalDb
      'plugins.flutter.io/path_provider', // any file location
      'plugins.flutter.io/path_provider_foundation',
    ]) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (call) async {
        calls.add('$name ${call.method}');
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(MethodChannel(name), null),
      );
    }

    final s = Scenario(questionCount: 3);
    var submitted = false;
    var finished = false;
    s.startsAt = s.serverNow.add(const Duration(seconds: 8));
    s.state = (now) => finished
        ? duelJson(
            serverTime: now,
            status: 'finished',
            startsAt: s.startsAt,
            mySubmitted: true,
            opponentSubmitted: true,
            result: resultJson(),
          )
        : duelJson(
            serverTime: now,
            status: 'playing',
            startsAt: s.startsAt,
            mySubmitted: submitted,
            challengedByMe: false,
          );
    s.intercept = (r) {
      if (r.method == 'POST' && r.path.endsWith('/answers/')) submitted = true;
      return null;
    };
    final provider = DuelProvider(service: s.server.service);
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpLive(
      tester,
      duel: provider,
      home: DuelLiveScreen(duelId: 1, now: s.clock.now),
    );
    addTearDown(() async => tester.pumpWidget(const SizedBox()));

    await elapse(tester, s.clock, const Duration(seconds: 12));
    await tester.tap(find.byKey(const ValueKey('duel-answer-1')));
    await tester.pump();
    expect(provider.questionsFor(1), isNotNull, reason: 'kept, in memory');

    await elapse(tester, s.clock, const Duration(seconds: 60));
    finished = true;
    await elapse(tester, s.clock, const Duration(seconds: 4));
    expect(find.byKey(const ValueKey('result-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('review-1')), findsOneWidget);

    expect(calls, isEmpty, reason: 'no sqflite and no file access at all');

    // The only other disk store the app uses, SharedPreferences, holds no
    // question either.
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      final value = '${prefs.get(key)}';
      expect(key.toLowerCase().contains('question'), isFalse, reason: key);
      expect(value.contains('Question EN'), isFalse, reason: key);
      expect(value.contains('Answer 1 of'), isFalse, reason: key);
    }

    await tester.pumpWidget(const SizedBox());
    expect(provider.questionsFor(1), isNull, reason: 'forgotten on leaving');
  });

  group('sources', () {
    final duelFiles = <String>[
      'lib/models/duel_live.dart',
      'lib/utils/duel_clock.dart',
      'lib/services/duel_service.dart',
      'lib/providers/duel_provider.dart',
      'lib/providers/invitation_link_provider.dart',
      ...Directory('lib/ui/duel')
          .listSync()
          .whereType<File>()
          .map((f) => f.path)
          .where((p) => p.endsWith('.dart')),
    ];

    test('the duel code never reaches the theme cache or a file', () {
      final forbidden = <Pattern>[
        'LocalDb',
        'local_db',
        'sqflite',
        'catalog_service',
        'catalog_provider',
        'insertQuestions',
        'getQuestionsByTheme',
        'path_provider',
        'writeAsString',
        'writeAsBytes',
        'openWrite',
        RegExp(r'\bFile\('),
      ];
      expect(duelFiles, hasLength(greaterThan(15)));
      for (final path in duelFiles) {
        final source = File(path).readAsStringSync();
        for (final word in forbidden) {
          expect(source.contains(word), isFalse, reason: '$path mentions $word');
        }
      }
    });

    test('SharedPreferences is used by the duel code only for the announced pairs', () {
      final users = [
        for (final path in duelFiles)
          if (File(path).readAsStringSync().contains('SharedPreferences')) path,
      ];
      expect(users, ['lib/providers/duel_provider.dart']);
      final source = File('lib/providers/duel_provider.dart').readAsStringSync();
      expect(
        RegExp(r'prefs\.(setStringList|setString|setInt|setBool)\(([^,]+),').allMatches(source).map((m) => m.group(2)!.trim()),
        everyElement(anyOf('_seenKey(userId)')),
      );
    });

    test('the solo game and the offline fallback know nothing of the duel', () {
      for (final path in [
        'lib/services/catalog_service.dart',
        'lib/db/local_db.dart',
        'lib/providers/catalog_provider.dart',
        'lib/ui/game_screen_solo.dart',
      ]) {
        final source = File(path).readAsStringSync().toLowerCase();
        expect(source.contains('duel'), isFalse, reason: path);
      }
    });

    test('a duel question has no right answer, and no model class reuses the solo Question', () {
      final model = File('lib/models/duel_live.dart').readAsStringSync();
      final playQuestion = model.substring(
        model.indexOf('class DuelQuestion {'),
        model.indexOf('class DuelQuestions {'),
      );
      expect(playQuestion.toLowerCase().contains('correct'), isFalse);
      expect(model.contains("models/question.dart"), isFalse);
    });
  });
}
