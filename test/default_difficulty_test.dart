import 'package:flutter/material.dart';
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
import 'package:QuizzBuilder/ui/game_mode_screen.dart';
import 'package:QuizzBuilder/ui/selected_themes_screen.dart';
import 'package:QuizzBuilder/ui/setup_solo_screen.dart';

final _theme = theme_model.Theme(
  id: 1,
  category: '1',
  nameEn: 'Theme 1',
  nameFr: 'Theme 1',
  descriptionEn: null,
  descriptionFr: null,
  isFree: true,
  isActive: true,
  questionsCount: 35,
  easyQuestionsCount: 10,
  mediumQuestionsCount: 20,
  hardQuestionsCount: 5,
  sourceUrl: null,
);

final _category = Category(
  id: 1,
  nameEn: 'Cat',
  nameFr: 'Cat',
  isActive: true,
  themesCount: 1,
);

class _FakeCatalog extends CatalogProvider {
  _FakeCatalog() : super(authService: AuthService());

  List<theme_model.Theme> _shown = [];

  @override
  List<theme_model.Theme> get themes => _shown;

  @override
  Future<void> loadThemesByCategories(List<int> categoryIds) async {
    _shown = [_theme];
    notifyListeners();
  }

  @override
  Future<void> loadCategories() async {}
}

class _FakeBuilder extends QuizzBuilderProvider {
  _FakeBuilder() : super(authService: AuthService());

  @override
  Future<void> refreshThemeAccess() async {}

  @override
  void syncThemesWithSelectedCategories(List<theme_model.Theme> allThemes) {}
}

class _FakeConnectivity extends ChangeNotifier implements ConnectivityProvider {
  @override
  bool get isOnline => true;
}

/// An entry point to the themes screen, from the app shell down to it.
typedef _Entry = Future<void> Function(WidgetTester tester);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _pumpApp(WidgetTester tester, Widget home) async {
  // Drop the previous tree so a rebuild starts from scratch, like a restart.
  await tester.pumpWidget(const SizedBox());
  final builder = _FakeBuilder()..toggleCategory(_category);
  builder.toggleTheme(_theme);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CatalogProvider>.value(value: _FakeCatalog()),
        ChangeNotifierProvider<QuizzBuilderProvider>.value(value: builder),
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
        home: home,
      ),
    ),
  );
  await _settle(tester);
}

Future<void> _startSolo(WidgetTester tester) async {
  await tester.tap(find.text('Start Game'));
  await _settle(tester);
}

final Map<String, _Entry> _entries = {
  'home -> solo setup -> themes': (tester) async {
    await _pumpApp(tester, const SetupSoloScreen());
    await _startSolo(tester);
  },
  'game mode -> solo setup -> themes': (tester) async {
    await _pumpApp(tester, const GameModeScreen());
    await tester.tap(find.text('Solo'));
    await _settle(tester);
    await _startSolo(tester);
  },
  'game mode -> multiplayer -> themes': (tester) async {
    await _pumpApp(tester, const GameModeScreen());
    await tester.tap(find.text('Multiplayer'));
    await _settle(tester);
  },
  'theme selector -> themes': (tester) async {
    await _pumpApp(tester, const SelectedThemesScreen(gameMode: 'solo'));
  },
};

/// Easy / Medium / Hard boxes: the first three Checkbox widgets on the screen.
List<bool> _levels(WidgetTester tester) => [
  for (var i = 0; i < 3; i++)
    tester.widget<Checkbox>(find.byType(Checkbox).at(i)).value!,
];

void main() {
  for (final entry in _entries.entries) {
    testWidgets('${entry.key}: only Easy is checked without a saved value', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await entry.value(tester);
      expect(_levels(tester), [true, false, false]);
      // The default itself is never written.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('selected_difficulties'), isFalse);
    });

    testWidgets('${entry.key}: a changed selection survives a restart', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await entry.value(tester);
      await tester.tap(find.text('Medium (20)'));
      await _settle(tester);
      expect(_levels(tester), [true, true, false]);

      final saved = (await SharedPreferences.getInstance()).getStringList(
        'selected_difficulties',
      );
      SharedPreferences.resetStatic();
      SharedPreferences.setMockInitialValues({'selected_difficulties': saved!});

      await entry.value(tester);
      expect(_levels(tester), [true, true, false]);
    });
  }
}
