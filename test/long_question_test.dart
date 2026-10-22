import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:QuizzBuilder/l10n/app_localizations.dart';
import 'package:QuizzBuilder/models/question.dart';
import 'package:QuizzBuilder/providers/auth_provider.dart';
import 'package:QuizzBuilder/providers/catalog_provider.dart';
import 'package:QuizzBuilder/providers/connectivity_provider.dart';
import 'package:QuizzBuilder/providers/quizz_builder_provider.dart';
import 'package:QuizzBuilder/services/auth_service.dart';
import 'package:QuizzBuilder/ui/game_screen_multiplayer.dart';
import 'package:QuizzBuilder/ui/game_screen_solo.dart';

final String _longText = List.generate(
  60,
  (i) => 'word$i',
).join(' ');

Question _question(int id) => Question(
      id: id,
      theme: 1,
      questionEn: _longText,
      questionFr: _longText,
      answer1En: 'a',
      answer1Fr: 'a',
      answer2En: 'b',
      answer2Fr: 'b',
      answer3En: 'c',
      answer3Fr: 'c',
      answer4En: 'd',
      answer4Fr: 'd',
      correctAnswer: 1,
      difficulty: 'easy',
      verificationReason: null,
      sourceUrl: null,
    );

class _FakeCatalog extends CatalogProvider {
  _FakeCatalog() : super(authService: AuthService());

  @override
  Future<List<Question>> loadQuestionsByThemes(List<int> themeIds) async => [
        for (var i = 0; i < 4; i++) _question(i),
      ];
}

class _FakeBuilder extends QuizzBuilderProvider {
  _FakeBuilder() : super(authService: AuthService());

  @override
  Set<int> get selectedThemeIds => {1};
}

class _FakeConnectivity extends ChangeNotifier implements ConnectivityProvider {
  @override
  bool get isOnline => true;
}

Widget _app(Widget home) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<CatalogProvider>.value(value: _FakeCatalog()),
      ChangeNotifierProvider<QuizzBuilderProvider>.value(value: _FakeBuilder()),
      ChangeNotifierProvider<ConnectivityProvider>.value(
        value: _FakeConnectivity(),
      ),
      ChangeNotifierProvider<AuthProvider>.value(
        value: AuthProvider(authService: AuthService()),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.3),
        ),
        child: child!,
      ),
      home: home,
    ),
  );
}

Future<void> _expectFullQuestion(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app(screen));
  await tester.pumpAndSettle();

  final finder = find.text(_longText);
  expect(finder, findsOneWidget);
  final text = tester.widget<Text>(finder);
  expect(text.maxLines, isNull);
  expect(text.overflow, isNot(TextOverflow.ellipsis));
  expect(tester.renderObject<RenderParagraph>(finder).didExceedMaxLines, isFalse);
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('solo game shows a very long question in full at 320 dp x1.3', (
    tester,
  ) async {
    await _expectFullQuestion(
      tester,
      const GameScreenSolo(questionCount: 2, difficulties: ['easy']),
    );
  });

  testWidgets('multiplayer game shows a very long question in full at 320 dp x1.3', (
    tester,
  ) async {
    await _expectFullQuestion(
      tester,
      const GameScreenMultiplayer(
        playerCount: 2,
        questionCount: 2,
        difficulties: ['easy'],
      ),
    );
  });
}
