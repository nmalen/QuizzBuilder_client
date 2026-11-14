import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations.dart';
import 'package:QuizzBuilder/providers/auth_provider.dart';
import 'package:QuizzBuilder/providers/catalog_provider.dart';
import 'package:QuizzBuilder/providers/connectivity_provider.dart';
import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/providers/invitation_link_provider.dart';
import 'package:QuizzBuilder/ui/game_mode_screen.dart';
import 'package:QuizzBuilder/ui/home_screen.dart';

import 'support/app_test_support.dart';
import 'support/duel_test_support.dart';

/// Titles of the four home tiles, top to bottom, per locale.
const _titles = {
  'fr': ['Défi quotidien', 'Partie classique', 'Duel', 'Boutique'],
  'en': ['Daily challenge', 'Classic game', 'Duel', 'Store'],
};

const _classicSubtitle = {
  'fr': 'Seul ou à plusieurs sur ce téléphone',
  'en': 'Alone or together on this phone',
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpHome(
    WidgetTester tester, {
    required String locale,
    Size size = const Size(800, 2400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final server = FakeDuelServer(
      (r) => jsonResponse(200, {'count': 0, 'results': []}),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: FakeAuthProvider()),
          ChangeNotifierProvider<CatalogProvider>.value(
            value: FakeCatalogProvider(),
          ),
          ChangeNotifierProvider<ConnectivityProvider>.value(
            value: FakeConnectivity(),
          ),
          ChangeNotifierProvider<DuelProvider>.value(
            value: DuelProvider(service: server.service),
          ),
          ChangeNotifierProvider<InvitationLinkProvider>.value(
            value: InvitationLinkProvider(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale(locale),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
  }

  for (final locale in ['fr', 'en']) {
    testWidgets('[$locale] the four tiles come in order: daily, classic, duel, store', (tester) async {
      await pumpHome(tester, locale: locale);
      final tops = <double>[];
      for (final title in _titles[locale]!) {
        expect(find.text(title), findsOneWidget, reason: title);
        tops.add(tester.getTopLeft(find.text(title)).dy);
      }
      final sorted = [...tops]..sort();
      expect(tops, sorted, reason: 'titles ${_titles[locale]} must run top to bottom');
      expect(find.text(_classicSubtitle[locale]!), findsOneWidget);
    });

    testWidgets('[$locale] the old classic-game wording is gone', (tester) async {
      await pumpHome(tester, locale: locale);
      for (final old in ['Jouer au Quiz', 'Play Quiz']) {
        expect(find.text(old), findsNothing);
      }
      expect(find.textContaining('défiez-vous'), findsNothing);
      expect(find.textContaining('challenge yourself'), findsNothing);
    });
  }

  testWidgets('the classic game tile still opens the Solo / Multiplayer choice', (tester) async {
    await pumpHome(tester, locale: 'fr');
    await tester.tap(find.text('Partie classique'));
    await tester.pumpAndSettle();
    expect(find.byType(GameModeScreen), findsOneWidget);
  });

  for (final locale in ['fr', 'en']) {
    testWidgets('[$locale] smallest screen (320 x 568): nothing on the home screen overflows', (tester) async {
      // Any RenderFlex overflow on the home screen (tiles, header, stats).
      final raised = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (d) => raised.add(d.toString());
      await pumpHome(tester, locale: locale, size: const Size(320, 568));
      FlutterError.onError = previous;
      for (final title in _titles[locale]!) {
        await tester.ensureVisible(find.text(title));
        expect(find.text(title), findsOneWidget);
      }
      expect(
        raised.where((e) => e.contains('overflowed')),
        isEmpty,
        reason: 'something overflowed',
      );
    });
  }
}
