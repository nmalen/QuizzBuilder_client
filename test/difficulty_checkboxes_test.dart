import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations.dart';
import 'package:QuizzBuilder/models/category.dart';
import 'package:QuizzBuilder/models/theme.dart' as theme_model;
import 'package:QuizzBuilder/providers/auth_provider.dart';
import 'package:QuizzBuilder/providers/catalog_provider.dart';
import 'package:QuizzBuilder/providers/connectivity_provider.dart';
import 'package:QuizzBuilder/providers/quizz_builder_provider.dart';
import 'package:QuizzBuilder/services/auth_service.dart';
import 'package:QuizzBuilder/ui/selected_themes_screen.dart';

class _FakeCatalog extends CatalogProvider {
  _FakeCatalog(this.themeList) : super(authService: AuthService());

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
}

/// Builder whose entitlement can be revoked after selection and whose
/// category sync is a no-op, so a selected-but-inaccessible theme stays
/// selected (the situation the counts must exclude).
class _FakeBuilder extends QuizzBuilderProvider {
  _FakeBuilder() : super(authService: AuthService());

  final Set<int> blockedThemeIds = {};

  @override
  Future<void> refreshThemeAccess() async {}

  @override
  void syncThemesWithSelectedCategories(List<theme_model.Theme> allThemes) {}

  @override
  bool isThemeEntitled(theme_model.Theme theme) =>
      !blockedThemeIds.contains(theme.id);
}

class _FakeConnectivity extends ChangeNotifier implements ConnectivityProvider {
  @override
  bool get isOnline => true;
}

theme_model.Theme _theme(
  int id, {
  int easy = 0,
  int medium = 0,
  int hard = 0,
}) => theme_model.Theme(
  id: id,
  category: '1',
  nameEn: 'Theme $id',
  nameFr: 'Theme $id',
  descriptionEn: null,
  descriptionFr: null,
  isFree: true,
  isActive: true,
  questionsCount: easy + medium + hard,
  easyQuestionsCount: easy,
  mediumQuestionsCount: medium,
  hardQuestionsCount: hard,
  sourceUrl: null,
);

final _category = Category(
  id: 1,
  nameEn: 'Cat',
  nameFr: 'Cat',
  isActive: true,
  themesCount: 2,
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<_FakeBuilder> _pump(
  WidgetTester tester, {
  required List<theme_model.Theme> themes,
  List<theme_model.Theme>? selected,
  Set<int> blocked = const {},
  String locale = 'en',
  double textScale = 1.0,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final builder = _FakeBuilder();
  builder.toggleCategory(_category);
  for (final t in selected ?? themes) {
    builder.toggleTheme(t);
  }
  builder.blockedThemeIds.addAll(blocked);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CatalogProvider>.value(
          value: _FakeCatalog(themes),
        ),
        ChangeNotifierProvider<QuizzBuilderProvider>.value(value: builder),
        ChangeNotifierProvider<ConnectivityProvider>.value(
          value: _FakeConnectivity(),
        ),
        ChangeNotifierProvider<AuthProvider>.value(
          value: AuthProvider(authService: AuthService()),
        ),
      ],
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const SelectedThemesScreen(gameMode: 'solo'),
      ),
    ),
  );
  await _settle(tester);
  return builder;
}

Finder _box(int index) => find.byType(Checkbox).at(index);

bool _checked(WidgetTester tester, int index) =>
    tester.widget<Checkbox>(_box(index)).value!;

bool _enabled(WidgetTester tester, int index) =>
    tester.widget<Checkbox>(_box(index)).onChanged != null;

/// Difficulty boxes are the first three Checkbox widgets on the screen.
Future<void> _tapLabel(WidgetTester tester, String text) async {
  await tester.tap(find.textContaining(text));
  await _settle(tester);
}

Future<List<String>?> _savedDifficulties() async =>
    (await SharedPreferences.getInstance()).getStringList(
      'selected_difficulties',
    );

void main() {
  final themes = [
    _theme(1, easy: 10, medium: 20, hard: 5),
    _theme(2, easy: 100, medium: 300, hard: 80),
  ];

  testWidgets('three checkboxes with FR and EN labels; tapping toggles state', (
    tester,
  ) async {
    await _pump(
      tester,
      themes: themes,
      prefs: {
        'selected_difficulties': ['easy'],
      },
    );
    expect(find.text('Easy (110)'), findsOneWidget);
    expect(find.text('Medium (320)'), findsOneWidget);
    expect(find.text('Hard (85)'), findsOneWidget);
    expect(_checked(tester, 0), isTrue);
    expect(_checked(tester, 1), isFalse);

    await _tapLabel(tester, 'Medium');
    expect(_checked(tester, 1), isTrue);
    await _tapLabel(tester, 'Medium');
    expect(_checked(tester, 1), isFalse);
  });

  testWidgets('French labels', (tester) async {
    await _pump(tester, themes: themes, locale: 'fr');
    expect(find.text('Facile (110)'), findsOneWidget);
    expect(find.text('Moyen (320)'), findsOneWidget);
    expect(find.text('Difficile (85)'), findsOneWidget);
  });

  testWidgets('the only checked level is disabled and cannot be unchecked', (
    tester,
  ) async {
    await _pump(
      tester,
      themes: themes,
      prefs: {
        'selected_difficulties': ['easy'],
      },
    );
    expect(_enabled(tester, 0), isFalse);
    expect(_enabled(tester, 1), isTrue);

    // Tapping the locked box or its label changes nothing.
    await tester.tap(_box(0));
    await _settle(tester);
    await _tapLabel(tester, 'Easy');
    expect(_checked(tester, 0), isTrue);
    expect(await _savedDifficulties(), ['easy']);

    // Checking another level unlocks the first one.
    await _tapLabel(tester, 'Hard');
    expect(_enabled(tester, 0), isTrue);
    expect(_enabled(tester, 2), isTrue);
    await _tapLabel(tester, 'Easy');
    expect(_checked(tester, 0), isFalse);
    // Back to a single checked level: it is locked again.
    expect(_enabled(tester, 2), isFalse);
  });

  testWidgets(
    'per-level counts exclude inaccessible themes; checked sum equals total',
    (tester) async {
      final third = _theme(3, easy: 1000, medium: 2000, hard: 3000);
      await _pump(
        tester,
        themes: [...themes, third],
        blocked: {3},
        prefs: {
          'selected_difficulties': ['easy', 'hard'],
        },
      );
      expect(find.text('Easy (110)'), findsOneWidget);
      expect(find.text('Medium (320)'), findsOneWidget);
      expect(find.text('Hard (85)'), findsOneWidget);
      // Checked levels easy + hard: 110 + 85 = 195 on the total line.
      expect(find.text('195/${35 + 480 + 6000}'), findsOneWidget);
    },
  );

  testWidgets('no selected theme: labels without numbers', (tester) async {
    await _pump(tester, themes: themes, selected: const []);
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'^(Easy|Medium|Hard) \(')),
      findsNothing,
    );
  });

  testWidgets(
    'saved value follows the checkboxes; counts follow theme selection',
    (tester) async {
      final builder = await _pump(
        tester,
        themes: themes,
        prefs: {
          'selected_difficulties': ['easy'],
        },
      );
      await _tapLabel(tester, 'Medium');
      expect(Set.of((await _savedDifficulties())!), {'easy', 'medium'});
      await _tapLabel(tester, 'Easy');
      expect(await _savedDifficulties(), ['medium']);

      builder.toggleTheme(themes[1]);
      await tester.pump();
      // Re-enter counting through a level tap.
      await _tapLabel(tester, 'Hard');
      expect(find.text('Easy (10)'), findsOneWidget);
      expect(find.text('Medium (20)'), findsOneWidget);
      expect(find.text('Hard (5)'), findsOneWidget);
    },
  );

  testWidgets(
    '320 dp wide with text scale 1.3: wraps, nothing truncated or overflowing',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await _pump(
        tester,
        themes: themes,
        locale: 'fr',
        textScale: 1.3,
      );
      for (final label in ['Facile (110)', 'Moyen (320)', 'Difficile (85)']) {
        final finder = find.text(label);
        expect(finder, findsOneWidget);
        final box = tester.getRect(finder);
        expect(box.left, greaterThanOrEqualTo(0));
        expect(box.right, lessThanOrEqualTo(320));
        final text = tester.renderObject<RenderParagraph>(finder);
        expect(text.didExceedMaxLines, isFalse);
      }
      for (var i = 0; i < 3; i++) {
        expect(tester.getSize(_box(i)).height, greaterThanOrEqualTo(40));
      }
    },
  );

  for (final scenario in [
    (name: 'themes selected, free tiles', selected: true, blocked: <int>{}),
    (name: 'no theme selected', selected: false, blocked: <int>{}),
    (name: 'locked tile', selected: true, blocked: {2}),
  ]) {
    for (final locale in ['en', 'fr']) {
      testWidgets(
        '320 dp wide with text scale 1.3 ($locale, ${scenario.name}): no overflow',
        (tester) async {
          tester.view.physicalSize = const Size(320, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);
          await _pump(
            tester,
            themes: themes,
            selected: scenario.selected ? themes : const [],
            blocked: scenario.blocked,
            locale: locale,
            textScale: 1.3,
          );
          expect(find.byType(CheckboxListTile), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
