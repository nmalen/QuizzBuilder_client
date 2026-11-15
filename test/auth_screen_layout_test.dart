import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations.dart';
import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/l10n/app_localizations_fr.dart';
import 'package:QuizzBuilder/providers/auth_provider.dart';
import 'package:QuizzBuilder/providers/invitation_link_provider.dart';
import 'package:QuizzBuilder/providers/language_provider.dart';
import 'package:QuizzBuilder/ui/auth_screen.dart';

import 'support/duel_test_support.dart';

/// QB-C-023: the sign-in / sign-up screen. The line that switches between the
/// two never overflows, and the NDSH logo never covers the form (it sits at
/// the bottom of the screen when the form fits, after the switch line inside
/// the scroll otherwise).
final _en = AppLocalizationsEn();
final _fr = AppLocalizationsFr();

const _widths = [320.0, 375.0, 393.0];
const _heights = [640.0, 852.0];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Finder logo() => find.byWidgetPredicate(
    (w) =>
        w is Image &&
        w.image is AssetImage &&
        (w.image as AssetImage).assetName.contains('Logo_NDSH'),
  );

  /// The switch line ("Already have an account?" + link): the `Wrap`.
  Finder switchLine() => find.byType(Wrap);

  /// Pumps the screen; returns the Flutter errors raised while laying it out.
  Future<List<String>> pumpScreen(
    WidgetTester tester, {
    required String locale,
    required Size size,
    required bool register,
  }) async {
    final raised = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (d) => raised.add(d.toString());
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(
            value: FakeAuthProvider(loggedIn: false),
          ),
          ChangeNotifierProvider<InvitationLinkProvider>.value(
            value: InvitationLinkProvider(),
          ),
          ChangeNotifierProvider<LanguageProvider>.value(
            value: LanguageProvider(),
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
          home: const AuthScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (register) {
      await tester.tap(
        find.descendant(
          of: switchLine(),
          matching: find.byType(GestureDetector),
        ),
      );
      await tester.pumpAndSettle();
    }
    FlutterError.onError = previous;
    return raised;
  }

  group('texts', () {
    test(
      'the two keys carry the question only; the link keeps the action word',
      () {
        expect(_fr.switchToLogin, 'Vous avez déjà un compte ?');
        expect(_fr.switchToRegister, "Vous n'avez pas de compte ?");
        expect(_en.switchToLogin, 'Already have an account?');
        expect(_en.switchToRegister, "Don't have an account?");
        expect(_fr.login, 'Connexion');
        expect(_fr.register, "S'inscrire");
        expect(_en.login, 'Login');
        expect(_en.register, 'Register');
      },
    );

    for (final locale in ['fr', 'en']) {
      final l = locale == 'fr' ? _fr : _en;
      testWidgets(
        '[$locale] sign-in mode: "${l.switchToRegister}" + link "${l.register}"',
        (tester) async {
          await pumpScreen(
            tester,
            locale: locale,
            size: const Size(393, 852),
            register: false,
          );
          final line = switchLine();
          expect(
            find.descendant(of: line, matching: find.text(l.switchToRegister)),
            findsOneWidget,
          );
          expect(
            find.descendant(of: line, matching: find.text(l.register)),
            findsOneWidget,
          );
          expect(
            find.descendant(of: line, matching: find.text(l.login)),
            findsNothing,
            reason: 'no doubled word',
          );
        },
      );

      testWidgets(
        '[$locale] sign-up mode: "${l.switchToLogin}" + link "${l.login}"',
        (tester) async {
          await pumpScreen(
            tester,
            locale: locale,
            size: const Size(393, 852),
            register: true,
          );
          final line = switchLine();
          expect(
            find.descendant(of: line, matching: find.text(l.switchToLogin)),
            findsOneWidget,
          );
          expect(
            find.descendant(of: line, matching: find.text(l.login)),
            findsOneWidget,
          );
          expect(
            find.descendant(of: line, matching: find.text(l.register)),
            findsNothing,
            reason: 'no doubled word',
          );
        },
      );
    }
  });

  group('no overflow, and the logo never covers the switch line', () {
    for (final locale in ['fr', 'en']) {
      for (final register in [false, true]) {
        for (final w in _widths) {
          for (final h in _heights) {
            final name =
                '[$locale ${register ? 'sign-up' : 'sign-in'} ${w.toInt()}x${h.toInt()}]';
            testWidgets(name, (tester) async {
              final raised = await pumpScreen(
                tester,
                locale: locale,
                size: Size(w, h),
                register: register,
              );
              expect(
                raised.where((e) => e.contains('overflowed')),
                isEmpty,
                reason: 'a RenderFlex overflowed',
              );
              expect(tester.takeException(), isNull);

              final logoRect = tester.getRect(logo());
              final lineRect = tester.getRect(switchLine());
              expect(
                logoRect.top,
                greaterThanOrEqualTo(lineRect.bottom),
                reason:
                    'logo $logoRect must come after the switch line $lineRect',
              );
              // And after every field of the form too.
              for (final field in find.byType(TextFormField).evaluate()) {
                final rect = tester.getRect(find.byWidget(field.widget));
                expect(
                  logoRect.top,
                  greaterThanOrEqualTo(rect.bottom),
                  reason: 'logo covers a field',
                );
              }
            });
          }
        }
      }
    }
  });

  group('where the logo is', () {
    testWidgets(
      'the form fits (sign-in, 393x852): the logo stays at the bottom of the screen',
      (tester) async {
        await pumpScreen(
          tester,
          locale: 'fr',
          size: const Size(393, 852),
          register: false,
        );
        final logoRect = tester.getRect(logo());
        expect(
          logoRect.bottom,
          852 - 24,
          reason: 'as before: 24 above the bottom edge',
        );
        expect(logoRect.size, const Size(120, 120));
        final scrollable = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        expect(
          scrollable.position.maxScrollExtent,
          0,
          reason: 'nothing to scroll',
        );
      },
    );

    testWidgets(
      'the form does not fit (sign-up, 393x640): the logo comes after the switch line, in the scroll',
      (tester) async {
        await pumpScreen(
          tester,
          locale: 'fr',
          size: const Size(393, 640),
          register: true,
        );
        final scrollable = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        expect(scrollable.position.maxScrollExtent, greaterThan(0));
        await tester.ensureVisible(logo());
        await tester.pumpAndSettle();
        final lineRect = tester.getRect(switchLine());
        final logoRect = tester.getRect(logo());
        expect(logoRect.top, greaterThanOrEqualTo(lineRect.bottom));
        expect(logoRect.bottom, lessThanOrEqualTo(640 + 0.01));
      },
    );

    testWidgets('the open keyboard does not move the logo onto the form', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        locale: 'en',
        size: const Size(393, 852),
        register: false,
      );
      final before = tester.getRect(logo());
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.getRect(logo()), before);
      expect(
        tester.getRect(logo()).top,
        greaterThanOrEqualTo(tester.getRect(switchLine()).bottom),
      );
    });
  });
}
