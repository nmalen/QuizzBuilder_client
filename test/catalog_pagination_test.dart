import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/services/catalog_service.dart';
import 'package:QuizzBuilder/ui/premium_theme_unlock_screen.dart';

import 'support/duel_test_support.dart';
import 'support/theme_unlock_support.dart';

/// QB-C-017: `GET themes/` is paginated by the server (50 per page, 70 themes
/// in the catalog). Whatever reads "all the themes" must read every page.
final _l = AppLocalizationsEn();

Map<String, Object?> _themeJson(int id, {bool free = false}) => {
  'id': id,
  'category': '1',
  'name_en': 'Theme $id',
  'name_fr': 'Thème $id',
  'is_free': free,
  'is_active': true,
  'questions_count': 10,
  'source_url': null,
};

/// The exact shape of the server: `{count, next, previous, results}`.
http.Response _page(List<Map<String, Object?>> rows, {String? next, String? previous, int? count}) =>
    jsonResponse(200, {
      'count': count ?? rows.length,
      'next': next,
      'previous': previous,
      'results': rows,
    });

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// A fake server of [total] themes in pages of [size]; every GET recorded.
  ({MockClient client, List<Uri> seen}) server(
    int total, {
    int size = 50,
    bool free = false,
    int? failOnPage,
  }) {
    final seen = <Uri>[];
    final all = [for (var i = 1; i <= total; i++) _themeJson(i, free: free)];
    final client = MockClient((request) async {
      seen.add(request.url);
      final page = int.tryParse(request.url.queryParameters['page'] ?? '') ?? 1;
      if (page == failOnPage) return jsonResponse(500, null);
      final from = (page - 1) * size;
      if (from >= all.length) return jsonResponse(404, {'detail': 'Invalid page.'});
      final to = (from + size).clamp(0, all.length);
      return _page(
        all.sublist(from, to),
        count: total,
        // Behind Apache the link can carry another scheme and lose the prefix:
        // the app must not use it.
        next: to < all.length ? 'http://booksnotify.com/api/v1/themes/?page=${page + 1}' : null,
        previous: page > 1 ? 'http://booksnotify.com/api/v1/themes/?page=${page - 1}' : null,
      );
    });
    return (client: client, seen: seen);
  }

  CatalogService service() => CatalogService(authService: FakeAuthService());

  group('getAllThemes reads every page', () {
    test('70 themes in two pages: all 70, in order', () async {
      final s = server(70);
      final themes = await http.runWithClient(() => service().getAllThemes(), () => s.client);
      expect(themes.length, 70);
      expect(themes.map((t) => t.id), [for (var i = 1; i <= 70; i++) i]);
      expect(themes.any((t) => t.id == 60), isTrue, reason: 'a page 2 theme');
    });

    test('pages are asked on the known base URL, never on the next link', () async {
      final s = server(70);
      await http.runWithClient(() => service().getAllThemes(), () => s.client);
      expect(s.seen.length, 2);
      for (final uri in s.seen) {
        expect(uri.scheme, 'https');
        expect(uri.host, 'booksnotify.com');
        expect(uri.path, '/quizzbuilder/api/v1/themes/');
      }
      expect(s.seen[0].queryParameters.containsKey('page'), isFalse, reason: 'the first page is asked as before');
      expect(s.seen[1].queryParameters['page'], '2');
    });

    test('is_free is kept on every page', () async {
      final s = server(70, free: true);
      final themes = await http.runWithClient(() => service().getAllThemes(isFree: true), () => s.client);
      expect(themes.length, 70);
      for (final uri in s.seen) {
        expect(uri.queryParameters['is_free'], 'true');
      }
      expect(s.seen[1].queryParameters['page'], '2');
    });

    test('exactly one full page: no second request, no failure', () async {
      final s = server(50);
      final themes = await http.runWithClient(() => service().getAllThemes(), () => s.client);
      expect(themes.length, 50);
      expect(s.seen.length, 1);
    });

    test('three pages', () async {
      final s = server(120);
      final themes = await http.runWithClient(() => service().getAllThemes(), () => s.client);
      expect(themes.length, 120);
      expect(s.seen.length, 3);
    });

    test('a bare list (no pagination) is still accepted, with one request', () async {
      final seen = <Uri>[];
      final client = MockClient((request) async {
        seen.add(request.url);
        return jsonResponse(200, [for (var i = 1; i <= 3; i++) _themeJson(i)]);
      });
      final themes = await http.runWithClient(() => service().getAllThemes(), () => client);
      expect(themes.length, 3);
      expect(seen.length, 1);
    });

    test('a page in error: the same error as before, no partial list', () async {
      final s = server(70, failOnPage: 2);
      await expectLater(
        http.runWithClient(() => service().getAllThemes(), () => s.client),
        throwsA(
          predicate((e) => e is Exception && e.toString() == 'Exception: Error: Exception: Failed to load themes: 500'),
        ),
      );
    });

    test('a first page in error: the same error as before', () async {
      final client = MockClient((_) async => jsonResponse(500, null));
      await expectLater(
        http.runWithClient(() => service().getAllThemes(), () => client),
        throwsA(
          predicate((e) => e.toString() == 'Exception: Error: Exception: Failed to load themes: 500'),
        ),
      );
    });

    test('a next link that never ends: bounded, and an error, not a partial list', () async {
      final seen = <Uri>[];
      final client = MockClient((request) async {
        seen.add(request.url);
        return _page(
          [_themeJson(seen.length)],
          next: 'http://booksnotify.com/api/v1/themes/?page=${seen.length + 1}',
        );
      });
      await expectLater(
        http.runWithClient(() => service().getAllThemes(), () => client),
        throwsA(isA<Exception>()),
      );
      expect(seen.length, CatalogService.maxThemePages);
    });

    test('an unexpected payload is still refused', () async {
      final client = MockClient((_) async => http.Response(jsonEncode('nope'), 200));
      await expectLater(
        http.runWithClient(() => service().getAllThemes(), () => client),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('what the screens see', () {
    Future<void> open(
      WidgetTester tester,
      FakeCreditStore store, {
      int? focus,
    }) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final builder = FakeCreditBuilder(store);
      final catalog = FakeCreditCatalog();
      await tester.pumpWidget(
        creditStoreShell(
          builder: builder,
          catalog: catalog,
          child: duelApp(
            duel: DuelProvider(service: FakeDuelServer((_) => jsonResponse(404, null)).service),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => PremiumThemeUnlockScreen(duelChallengeThemeId: focus),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      addTearDown(() async => tester.pumpWidget(const SizedBox()));
    }

    // 70 premium themes: ids 100..169, 50 per page; 160 sits on page 2.
    FakeCreditStore bigCatalog() => FakeCreditStore()
      ..catalog.clear()
      ..pageSize = 50
      ..addPremiumThemes(70);

    testWidgets('"this theme" mode finds a theme of page 2, as the player taps it', (tester) async {
      final store = bigCatalog();
      await http.runWithClient(() async {
        await open(tester, store, focus: 160);
        expect(find.text(_l.unlockThemeUnavailable), findsNothing);
        expect(find.byType(PremiumThemeUnlockScreen), findsOneWidget);
        expect(find.text('Premium 160'), findsOneWidget);
        expect(find.text(_l.unlockThemeAction), findsOneWidget);
      }, () => store.client);
    });

    testWidgets('the full unlock screen counts and lists the 70 premium themes', (tester) async {
      final store = bigCatalog();
      await http.runWithClient(() async {
        await open(tester, store);
        expect(find.text(_l.storeLockedPaidThemesCount(70)), findsOneWidget);
        // The last one is on page 2 (the list builds lazily: scroll to it).
        await tester.scrollUntilVisible(find.text('Premium 169'), 400, scrollable: find.byType(Scrollable).last);
        expect(find.text('Premium 169'), findsOneWidget);
      }, () => store.client);
    });

    test('an unknown theme id is still reported unavailable, only after every page was read', () async {
      // Guards the other side: reading all the pages does not make a theme up.
      final store = bigCatalog();
      final themes = await http.runWithClient(() => service().getAllThemes(), () => store.client);
      expect(themes.length, 70);
      expect(themes.any((t) => t.id == 9999), isFalse);
      expect(store.catalogRequests.length, 2);
    });
  });
}
