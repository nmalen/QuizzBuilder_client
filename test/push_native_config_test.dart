import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:QuizzBuilder/services/push/push_log.dart';

import 'support/push_test_support.dart';

/// Removes the XML comments, so a switch that is only commented out does not
/// count as set.
String _withoutComments(String xml) =>
    xml.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

void main() {
  // `FirebaseMessaging.register()` (the only way this app gets its Firebase
  // Installation ID) refuses to run unless the native SDK is told to use
  // installation IDs: on Android it throws an IllegalStateException at once, on
  // iOS it answers an invalid-request error. Neither can be seen from Dart, so
  // the switches are pinned here.
  group('the native switch that lets register() run', () {
    test(
      'Android: the manifest enables firebase_messaging_installation_id_enabled',
      () {
        final manifest = _withoutComments(
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
        );
        final switchedOn = RegExp(
          r'<meta-data\b[^>]*android:name="firebase_messaging_installation_id_enabled"'
          r'[^>]*android:value="true"',
          dotAll: true,
        );
        final switchedOnReversed = RegExp(
          r'<meta-data\b[^>]*android:value="true"[^>]*'
          r'android:name="firebase_messaging_installation_id_enabled"',
          dotAll: true,
        );
        expect(
          switchedOn.hasMatch(manifest) ||
              switchedOnReversed.hasMatch(manifest),
          isTrue,
          reason:
              'without it register() fails in ~1 ms and no device is ever registered',
        );
        final application = manifest.indexOf('<application');
        final meta = manifest.indexOf(
          'firebase_messaging_installation_id_enabled',
        );
        expect(
          meta,
          greaterThan(application),
          reason: 'it belongs inside <application>',
        );
      },
    );

    test(
      'iOS: Info.plist sets FirebaseMessagingInstallationIdEnabled to true',
      () {
        final plist = _withoutComments(
          File('ios/Runner/Info.plist').readAsStringSync(),
        );
        expect(
          RegExp(
            r'<key>FirebaseMessagingInstallationIdEnabled</key>\s*<true\s*/>',
          ).hasMatch(plist),
          isTrue,
          reason:
              'without it registerWithCompletion answers an invalid-request error',
        );
      },
    );
  });

  group('describeNativeFailure', () {
    test('keeps the type, the code and a short message', () {
      expect(
        describeNativeFailure(
          'FirebaseException',
          code: 'unknown',
          message: 'API disabled. Please enable it.',
        ),
        'FirebaseException code=unknown message="API disabled. Please enable it."',
      );
    });

    test('says only the type when the error has nothing else', () {
      expect(describeNativeFailure('StateError'), 'StateError');
      expect(
        describeNativeFailure('StateError', code: '', message: '  '),
        'StateError',
      );
    });

    test('never lets a token-like run through: not even a quoted FID', () {
      final text = describeNativeFailure(
        'FirebaseException',
        code: 'unknown',
        message:
            'PUT /v1/installations/$fakeInstallationId/authTokens failed: 401',
      );
      expect(text, isNot(contains(fakeInstallationId)));
      expect(text, contains('<redacted>'));
      expect(text, contains('401'), reason: 'the useful part stays');

      // A real-looking 22-character FID, with no hyphen to help.
      const realLooking = 'cQ3xYz9AbCdEfGhIjKlMnO';
      expect(
        describeNativeFailure('E', message: 'bad $realLooking here'),
        isNot(contains(realLooking)),
      );
    });

    test('keeps the words that make the message useful', () {
      final text = describeNativeFailure(
        'FirebaseException',
        code: 'unknown',
        message:
            'java.lang.IllegalStateException: API disabled. Add <meta-data '
            'android:name="firebase_messaging_installation_id_enabled" />',
      );
      expect(text, contains('java.lang.IllegalStateException'));
      expect(text, contains('firebase_messaging_installation_id_enabled'));
      expect(text, isNot(contains('<redacted>')));
    });

    test(
      'a FID is redacted whatever its alphabet, even with digits only or no hyphen',
      () {
        for (final fid in [
          'cQ3xYz9AbCdEfGhIjKlMnO',
          'dkjhgfdsapoiuytrewqlmn',
          'e12345678901234567890_',
          'fAbCdEfGhIjKlMnOpQrStU',
        ]) {
          expect(
            describeNativeFailure('E', message: 'x $fid y'),
            isNot(contains(fid)),
            reason: fid,
          );
        }
      },
    );

    test('flattens line breaks and cuts a long message', () {
      final text = describeNativeFailure(
        'E',
        message: 'line one\n  line two ${'x ' * 200}',
      );
      expect(text, isNot(contains('\n')));
      expect(text, contains('line one line two'));
      expect(text.length, lessThan(220));
      expect(text, endsWith('…"'));
    });
  });
}
