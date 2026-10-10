import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations.dart';
import 'package:QuizzBuilder/models/category.dart';
import 'package:QuizzBuilder/models/question.dart';
import 'package:QuizzBuilder/models/theme.dart' as theme_model;
import 'package:QuizzBuilder/providers/auth_provider.dart';
import 'package:QuizzBuilder/providers/catalog_provider.dart';
import 'package:QuizzBuilder/providers/connectivity_provider.dart';
import 'package:QuizzBuilder/providers/quizz_builder_provider.dart';
import 'package:QuizzBuilder/services/auth_service.dart';
import 'package:QuizzBuilder/ui/game_screen_multiplayer.dart';
import 'package:QuizzBuilder/ui/game_screen_solo.dart';
import 'package:QuizzBuilder/ui/selected_themes_screen.dart';
import 'package:QuizzBuilder/ui/setup_multiplayer_screen.dart';

Question _question(int id, String difficulty) => Question(
      id: id,
      theme: 1,
      questionEn: 'Q$id',
      questionFr: 'Q$id',
      answer1En: 'a',
      answer1Fr: 'a',
      answer2En: 'b',
      answer2Fr: 'b',
      answer3En: 'c',
      answer3Fr: 'c',
      answer4En: 'd',
      answer4Fr: 'd',
      correctAnswer: 1,
      difficulty: difficulty,
      verificationReason: null,
      sourceUrl: null,
    );

List<Question> _pool({int easy = 0, int medium = 0, int hard = 0}) => [
      for (var i = 0; i < easy; i++) _question(100 + i, 'easy'),
      for (var i = 0; i < medium; i++) _question(200 + i, 'medium'),
      for (var i = 0; i < hard; i++) _question(300 + i, 'hard'),
    ];

class _FakeCatalog extends CatalogProvider {
  _FakeCatalog({this.questions = const [], this.fail = false, this.themeList = const []})
      : super(authService: AuthService());

  final List<Question> questions;
  final bool fail;
  final List<theme_model.Theme> themeList;
  List<theme_model.Theme> _shown = [];

  @override
  List<theme_model.Theme> get themes => _shown;

  @override
  Future<void> loadThemesByCategories(List<int> categoryIds) async {
    _shown = themeList;
    notifyListeners();
  }

  @override
  Future<void> loadCategories() async {}

  @override
  Future<List<Question>> loadQuestionsByThemes(List<int> themeIds) async {
    if (fail) throw Exception('boom');
    return List<Question>.from(questions);
  }
}

class _FakeBuilder extends QuizzBuilderProvider {
  _FakeBuilder() : super(authService: AuthService());

  @override
  Future<void> refreshThemeAccess() async {}

  @override
  Set<int> get selectedThemeIds => {1};
}

class _FakeConnectivity extends ChangeNotifier implements ConnectivityProvider {
  @override
  bool get isOnline => true;
}

Widget _app(Widget home, CatalogProvider catalog, {QuizzBuilderProvider? builder}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<CatalogProvider>.value(value: catalog),
      ChangeNotifierProvider<QuizzBuilderProvider>.value(value: builder ?? _FakeBuilder()),
      ChangeNotifierProvider<ConnectivityProvider>.value(value: _FakeConnectivity()),
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
      home: home,
    ),
  );
}

void _setSliders(WidgetTester tester, {required int players, required int questions}) {
  final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
  sliders[0].onChanged!(players.toDouble());
  sliders[1].onChanged!(questions.toDouble());
}

ElevatedButton _continueButton(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Continue'));

/// The themes screen trips a pre-existing debug-only ListTile/DecoratedBox
/// assertion (white tile over ink); ignore only that one so it does not mask
/// the behaviour under test.
void _ignoreKnownListTileAssertion() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('ListTile background color')) return;
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('setup screen', () {
    testWidgets('shortage with 2 players: button disabled, red line and advice', (tester) async {
      await tester.pumpWidget(_app(
        const SetupMultiplayerScreen(difficulties: ['easy']),
        _FakeCatalog(questions: _pool(easy: 10, hard: 40)),
      ));
      await tester.pumpAndSettle();
      _setSliders(tester, players: 2, questions: 10);
      await tester.pump();

      expect(find.text('10 questions available · 20 needed (2 × 10)'), findsOneWidget);
      expect(
        find.text('Reduce to 5 questions per player, or select more themes or levels.'),
        findsOneWidget,
      );
      expect(_continueButton(tester).onPressed, isNull);
      final line = tester.widget<Text>(find.text('10 questions available · 20 needed (2 × 10)'));
      expect(line.style?.color, Colors.red[700]);
    });

    testWidgets('shortage with 4 players and too few questions: reduce-players advice', (tester) async {
      await tester.pumpWidget(_app(
        const SetupMultiplayerScreen(difficulties: ['easy']),
        _FakeCatalog(questions: _pool(easy: 10)),
      ));
      await tester.pumpAndSettle();
      _setSliders(tester, players: 4, questions: 10);
      await tester.pump();

      expect(
        find.text('Reduce the number of players, or select more themes or levels.'),
        findsOneWidget,
      );
      expect(_continueButton(tester).onPressed, isNull);
    });

    testWidgets('enough questions: button enabled, no error advice', (tester) async {
      await tester.pumpWidget(_app(
        const SetupMultiplayerScreen(difficulties: ['hard']),
        _FakeCatalog(questions: _pool(easy: 2, hard: 40)),
      ));
      await tester.pumpAndSettle();
      _setSliders(tester, players: 3, questions: 10);
      await tester.pump();

      expect(find.text('40 questions available · 30 needed (3 × 10)'), findsOneWidget);
      expect(_continueButton(tester).onPressed, isNotNull);
    });

    testWidgets('1 player: info line only, button enabled', (tester) async {
      await tester.pumpWidget(_app(
        const SetupMultiplayerScreen(difficulties: ['easy']),
        _FakeCatalog(questions: _pool(easy: 3)),
      ));
      await tester.pumpAndSettle();
      _setSliders(tester, players: 1, questions: 10);
      await tester.pump();

      expect(find.text('3 questions available · 10 needed (1 × 10)'), findsOneWidget);
      expect(find.textContaining('Reduce'), findsNothing);
      expect(_continueButton(tester).onPressed, isNotNull);
    });

    testWidgets('count uses only the ticked difficulties', (tester) async {
      await tester.pumpWidget(_app(
        const SetupMultiplayerScreen(difficulties: ['easy', 'medium']),
        _FakeCatalog(questions: _pool(easy: 4, medium: 6, hard: 50)),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('10 questions available'), findsOneWidget);
    });
  });

  group('game screen', () {
    testWidgets('shortage shows the readable text and a back button', (tester) async {
      await tester.pumpWidget(_app(
        const GameScreenMultiplayer(
          playerCount: 2,
          questionCount: 10,
          difficulties: ['easy'],
        ),
        _FakeCatalog(questions: _pool(easy: 10, hard: 40)),
      ));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Not enough questions for this game. You need 20 (2 players × 10 '
          'questions each) but your themes and levels only provide 10. Reduce '
          'the number of players or questions, or select more themes or levels.',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(ElevatedButton, 'Go back'), findsOneWidget);
    });

    testWidgets('loading failure shows a localized message, not the raw exception', (tester) async {
      await tester.pumpWidget(_app(
        const GameScreenMultiplayer(playerCount: 2, questionCount: 5, difficulties: ['easy']),
        _FakeCatalog(fail: true),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('boom'), findsNothing);
      expect(find.textContaining('Something went wrong. Please try again.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Go back'), findsOneWidget);
    });
  });

  group('ticked difficulties reach the game', () {
    testWidgets('setup -> multiplayer game', (tester) async {
      await tester.pumpWidget(_app(
        const SetupMultiplayerScreen(difficulties: ['hard']),
        _FakeCatalog(questions: _pool(easy: 40, hard: 40)),
      ));
      await tester.pumpAndSettle();
      _setSliders(tester, players: 2, questions: 5);
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      final game = tester.widget<GameScreenMultiplayer>(find.byType(GameScreenMultiplayer));
      expect(game.difficulties, ['hard']);
    });

    testWidgets('setup -> 1 player (solo) game', (tester) async {
      await tester.pumpWidget(_app(
        const SetupMultiplayerScreen(difficulties: ['medium', 'hard']),
        _FakeCatalog(questions: _pool(medium: 20, hard: 20)),
      ));
      await tester.pumpAndSettle();
      _setSliders(tester, players: 1, questions: 5);
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      final game = tester.widget<GameScreenSolo>(find.byType(GameScreenSolo));
      expect(game.difficulties, ['medium', 'hard']);
    });

    testWidgets('themes screen (multiplayer) -> setup', (tester) async {
      _ignoreKnownListTileAssertion();
      SharedPreferences.setMockInitialValues({
        'selected_difficulties': ['medium', 'hard'],
      });
      final builder = QuizzBuilderProvider(authService: AuthService());
      final category = Category(
        id: 1,
        nameEn: 'Cat',
        nameFr: 'Cat',
        isActive: true,
        themesCount: 1,
      );
      final theme = theme_model.Theme(
        id: 1,
        category: '1',
        nameEn: 'Theme',
        nameFr: 'Theme',
        descriptionEn: null,
        descriptionFr: null,
        isFree: true,
        isActive: true,
        questionsCount: 30,
        easyQuestionsCount: 10,
        mediumQuestionsCount: 10,
        hardQuestionsCount: 10,
        sourceUrl: null,
      );
      builder.toggleCategory(category);
      builder.syncThemesWithSelectedCategories([theme]);

      await tester.pumpWidget(_app(
        const SelectedThemesScreen(gameMode: 'multiplayer'),
        _FakeCatalog(questions: _pool(medium: 10, hard: 10), themeList: [theme]),
        builder: builder,
      ));
      await _settle(tester);

      final start = find.widgetWithText(ElevatedButton, 'Start Quiz');
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();

      final setup = tester.widget<SetupMultiplayerScreen>(find.byType(SetupMultiplayerScreen));
      expect(setup.difficulties.toSet(), {'medium', 'hard'});
    });
  });

  group('themes screen banner', () {
    Future<void> pumpThemes(WidgetTester tester, String gameMode) async {
      _ignoreKnownListTileAssertion();
      final builder = QuizzBuilderProvider(authService: AuthService());
      final category = Category(
        id: 1,
        nameEn: 'Cat',
        nameFr: 'Cat',
        isActive: true,
        themesCount: 1,
      );
      final theme = theme_model.Theme(
        id: 1,
        category: '1',
        nameEn: 'Theme',
        nameFr: 'Theme',
        descriptionEn: null,
        descriptionFr: null,
        isFree: true,
        isActive: true,
        questionsCount: 30,
        easyQuestionsCount: 30,
        sourceUrl: null,
      );
      builder.toggleCategory(category);
      builder.syncThemesWithSelectedCategories([theme]);
      await tester.pumpWidget(_app(
        SelectedThemesScreen(gameMode: gameMode),
        _FakeCatalog(themeList: [theme]),
        builder: builder,
      ));
      await _settle(tester);
    }

    const bannerStart = 'Multiplayer: each player gets their own questions.';

    testWidgets('present in multiplayer, values from the slider bounds', (tester) async {
      await pumpThemes(tester, 'multiplayer');
      expect(find.textContaining(bannerStart), findsOneWidget);
      expect(find.textContaining('up to 80 questions (4 players × 20)'), findsOneWidget);
    });

    testWidgets('absent in solo', (tester) async {
      await pumpThemes(tester, 'solo');
      expect(find.textContaining(bannerStart), findsNothing);
    });
  });
}
