import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations.dart';
import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/l10n/app_localizations_fr.dart';
import 'package:QuizzBuilder/providers/auth_provider.dart';
import 'package:QuizzBuilder/providers/duel_provider.dart';
import 'package:QuizzBuilder/providers/invitation_link_provider.dart';
import 'package:QuizzBuilder/providers/language_provider.dart';
import 'package:QuizzBuilder/ui/auth_screen.dart';
import 'package:QuizzBuilder/ui/duel/duel_join_screen.dart';

import 'support/duel_test_support.dart';

/// QB-C-022: the "Paste" button of both invitation code fields.
final _en = AppLocalizationsEn();
final _fr = AppLocalizationsFr();

const _button = Key('paste-invitation-code');

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// What the system clipboard holds (null: empty, or a refused read).
  String? clipboard;
  int reads = 0;

  setUp(() {
    clipboard = null;
    reads = 0;
  });

  void mockClipboard(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.getData') {
          reads++;
          return clipboard == null
              ? null
              : <String, Object?>{'text': clipboard};
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }

  Future<void> pumpJoin(
    WidgetTester tester, {
    String locale = 'en',
    String? initialCode,
  }) async {
    mockClipboard(tester);
    final server = FakeDuelServer(
      (r) => jsonResponse(200, {'count': 0, 'results': []}),
    );
    await tester.pumpWidget(
      duelApp(
        locale: locale,
        home: DuelJoinScreen(initialCode: initialCode),
        duel: DuelProvider(service: server.service),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpRegister(
    WidgetTester tester, {
    String locale = 'en',
    bool signUpMode = true,
  }) async {
    mockClipboard(tester);
    tester.view.physicalSize = const Size(1000, 2600);
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
    if (!signUpMode) return;
    await tester.tap(find.text((locale == 'fr' ? _fr : _en).register));
    await tester.pumpAndSettle();
  }

  Finder joinField() => find.byKey(const Key('join-code-field'));
  Finder registerField(AppLocalizations l) =>
      find.widgetWithText(TextFormField, l.invitationCodeOptional);

  String joinText(WidgetTester tester) =>
      tester.widget<TextField>(joinField()).controller!.text;

  group('"Join with a code" screen', () {
    testWidgets('a code alone, in any shape, fills the field normalized', (
      tester,
    ) async {
      await pumpJoin(tester);
      for (final copied in ['K7P3QX', 'K7P-3QX', '  k7p 3qx  ']) {
        clipboard = copied;
        await tester.tap(find.byKey(_button));
        await tester.pumpAndSettle();
        expect(joinText(tester), 'K7P3QX', reason: copied);
        await tester.enterText(joinField(), '');
      }
      expect(find.text(_en.noInvitationCodeInClipboard), findsNothing);
    });

    testWidgets(
      'a text holding an invitation link fills the field with its code',
      (tester) async {
        await pumpJoin(tester);
        clipboard =
            'Challenge me on QuizzBuilder! https://play.quizzbuilder.fr/d/m4n8ab or enter the code M4N-8AB';
        await tester.tap(find.byKey(_button));
        await tester.pumpAndSettle();
        expect(joinText(tester), 'M4N8AB');
      },
    );

    testWidgets(
      'the link of a live duel call is not an invitation: message, field untouched',
      (tester) async {
        await pumpJoin(tester, initialCode: 'ABC');
        clipboard = 'https://play.quizzbuilder.fr/d/K7P3QXZ9';
        await tester.tap(find.byKey(_button));
        await tester.pumpAndSettle();
        expect(find.text(_en.noInvitationCodeInClipboard), findsOneWidget);
        expect(joinText(tester), 'ABC');
      },
    );

    testWidgets(
      'empty clipboard, unrelated text: the message, field untouched',
      (tester) async {
        await pumpJoin(tester, initialCode: 'ABC');
        for (final copied in <String?>[null, '', 'hello, how are you?']) {
          clipboard = copied;
          await tester.tap(find.byKey(_button));
          await tester.pumpAndSettle();
          expect(
            find.text(_en.noInvitationCodeInClipboard),
            findsOneWidget,
            reason: '$copied',
          );
          expect(joinText(tester), 'ABC');
          ScaffoldMessenger.of(
            tester.element(find.byKey(_button)),
          ).clearSnackBars();
          await tester.pumpAndSettle();
        }
        expect(reads, 3);
      },
    );

    testWidgets('French: tooltip and message', (tester) async {
      await pumpJoin(tester, locale: 'fr');
      expect(find.byTooltip(_fr.pasteInvitationCode), findsOneWidget);
      expect(_fr.pasteInvitationCode, 'Coller');
      clipboard = null;
      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();
      expect(
        find.text("Aucun code d'invitation dans le presse-papiers."),
        findsOneWidget,
      );
    });

    testWidgets('English tooltip', (tester) async {
      await pumpJoin(tester);
      expect(find.byTooltip('Paste'), findsOneWidget);
    });
  });

  group('sign-up screen', () {
    testWidgets('a pasted code fills the optional field', (tester) async {
      await pumpRegister(tester);
      clipboard = 'k7p-3qx';
      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'K7P3QX'), findsOneWidget);
    });

    testWidgets('a pasted invitation link fills it with the code', (
      tester,
    ) async {
      await pumpRegister(tester);
      clipboard = 'https://play.quizzbuilder.fr/d/K7P3QX';
      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'K7P3QX'), findsOneWidget);
    });

    testWidgets('nothing usable: the message, the field stays empty', (
      tester,
    ) async {
      await pumpRegister(tester);
      clipboard = 'https://play.quizzbuilder.fr/d/K7P3QXZ9';
      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();
      expect(find.text(_en.noInvitationCodeInClipboard), findsOneWidget);
      expect(
        registerField(_en),
        findsOneWidget,
        reason: 'still the empty field with its hint',
      );
    });

    testWidgets(
      'the button is in sign-up mode only (no code field when signing in)',
      (tester) async {
        await pumpRegister(tester, signUpMode: false);
        expect(find.byKey(_button), findsNothing);
        await tester.tap(find.text(_en.register));
        await tester.pumpAndSettle();
        expect(find.byKey(_button), findsOneWidget);
      },
    );

    testWidgets(
      'the help line and the hint may wrap (they were cut on a 393 pt phone)',
      (tester) async {
        await pumpRegister(tester);
        Text textOf(String text) => tester.widget<Text>(find.text(text));
        expect(textOf(_en.invitationCodeHelp).maxLines, 3);
        expect(textOf(_en.invitationCodeOptional).maxLines, 2);
      },
    );

    testWidgets('French: tooltip and message', (tester) async {
      await pumpRegister(tester, locale: 'fr');
      expect(find.byTooltip('Coller'), findsOneWidget);
      clipboard = 'rien';
      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();
      expect(
        find.text("Aucun code d'invitation dans le presse-papiers."),
        findsOneWidget,
      );
    });
  });
}
