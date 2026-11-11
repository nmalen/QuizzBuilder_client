import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:QuizzBuilder/l10n/app_localizations.dart';
import 'package:QuizzBuilder/l10n/app_localizations_en.dart';
import 'package:QuizzBuilder/providers/auth_provider.dart';
import 'package:QuizzBuilder/providers/invitation_link_provider.dart';
import 'package:QuizzBuilder/providers/language_provider.dart';
import 'package:QuizzBuilder/ui/auth_screen.dart';

import 'support/duel_test_support.dart';

final _l = AppLocalizationsEn();

class _RecordingAuth extends FakeAuthProvider {
  _RecordingAuth() : super(loggedIn: false);
  final calls = <String?>[];
  bool succeed = true;

  @override
  Future<bool> register({
    required String email,
    required String username,
    required String password1,
    required String password2,
    String? invitationCode,
  }) async {
    calls.add(invitationCode);
    return succeed;
  }
}

Future<void> _pump(
  WidgetTester tester,
  _RecordingAuth auth,
  InvitationLinkProvider links,
) async {
  tester.view.physicalSize = const Size(1000, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<InvitationLinkProvider>.value(value: links),
        ChangeNotifierProvider<LanguageProvider>.value(value: LanguageProvider()),
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
        home: const AuthScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _invitationField =>
    find.widgetWithText(TextFormField, _l.invitationCodeOptional);

Future<void> _switchToRegister(WidgetTester tester) async {
  await tester.tap(find.text(_l.register));
  await tester.pumpAndSettle();
}

Future<void> _fillForm(WidgetTester tester) async {
  await tester.enterText(find.widgetWithText(TextFormField, _l.email), 'a@b.co');
  await tester.enterText(find.widgetWithText(TextFormField, _l.username), 'abcd');
  await tester.enterText(find.widgetWithText(TextFormField, _l.password), '12345678');
  await tester.enterText(find.widgetWithText(TextFormField, _l.confirmPassword), '12345678');
}

Future<void> _submit(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ElevatedButton, _l.register));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the optional field exists in sign-up mode only', (tester) async {
    await _pump(tester, _RecordingAuth(), InvitationLinkProvider());
    expect(_invitationField, findsNothing);
    await _switchToRegister(tester);
    expect(_invitationField, findsOneWidget);
    expect(find.text(_l.invitationCodeHelp), findsOneWidget);
    expect(find.text(_l.invitationCodeBanner), findsNothing,
        reason: 'no banner without a link');
  });

  testWidgets('empty field: registration goes through with no code', (tester) async {
    final auth = _RecordingAuth();
    await _pump(tester, auth, InvitationLinkProvider());
    await _switchToRegister(tester);
    await _fillForm(tester);
    await _submit(tester);
    expect(auth.calls, [null]);
  });

  testWidgets('a code is normalized and sent', (tester) async {
    final auth = _RecordingAuth();
    await _pump(tester, auth, InvitationLinkProvider());
    await _switchToRegister(tester);
    await _fillForm(tester);
    await tester.enterText(_invitationField, 'k7p-3qx');
    await _submit(tester);
    expect(auth.calls, ['K7P3QX']);
  });

  testWidgets('a partial code blocks the submission with a message (D-B)', (tester) async {
    final auth = _RecordingAuth();
    await _pump(tester, auth, InvitationLinkProvider());
    await _switchToRegister(tester);
    await _fillForm(tester);
    await tester.enterText(_invitationField, 'K7P');
    await _submit(tester);
    expect(find.text(_l.invitationCodeLength), findsOneWidget);
    expect(auth.calls, isEmpty);

    await tester.enterText(_invitationField, '');
    await _submit(tester);
    expect(auth.calls, [null], reason: 'emptying the field unblocks it');
  });

  testWidgets('a code from a link: sign-up mode, code pre-filled, banner (D-C)', (tester) async {
    final links = InvitationLinkProvider()..setPendingCode('k7p3qx');
    await _pump(tester, _RecordingAuth(), links);
    expect(_invitationField, findsOneWidget);
    expect(find.text('K7P3QX'), findsOneWidget);
    expect(find.text(_l.invitationCodeBanner), findsOneWidget);
  });

  testWidgets('a link received while the screen is open switches to sign-up', (tester) async {
    final links = InvitationLinkProvider();
    await _pump(tester, _RecordingAuth(), links);
    expect(_invitationField, findsNothing);
    links.setPendingCode('K7P3QX');
    await tester.pumpAndSettle();
    expect(_invitationField, findsOneWidget);
    expect(find.text('K7P3QX'), findsOneWidget);
  });

  testWidgets('the sign-up mode is chosen once per link: switching to sign-in sticks', (tester) async {
    final links = InvitationLinkProvider()..setPendingCode('K7P3QX');
    await _pump(tester, _RecordingAuth(), links);
    await tester.tap(find.text(_l.login).last);
    await tester.pumpAndSettle();
    expect(_invitationField, findsNothing);
    expect(links.pendingCode, 'K7P3QX', reason: 'kept: the join flow resumes after sign-in');
  });

  testWidgets('a successful registration forgets the code kept from a link', (tester) async {
    final auth = _RecordingAuth();
    final links = InvitationLinkProvider()..setPendingCode('K7P3QX');
    await _pump(tester, auth, links);
    await _fillForm(tester);
    await _submit(tester);
    expect(auth.calls, ['K7P3QX']);
    expect(links.pendingCode, isNull);
  });

  testWidgets('a failed registration keeps the code', (tester) async {
    final auth = _RecordingAuth()..succeed = false;
    final links = InvitationLinkProvider()..setPendingCode('K7P3QX');
    await _pump(tester, auth, links);
    await _fillForm(tester);
    await _submit(tester);
    expect(links.pendingCode, 'K7P3QX');
  });
}
