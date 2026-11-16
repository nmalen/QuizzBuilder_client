import 'package:flutter/foundation.dart';

/// One diagnostic line of the push notification chain, prefixed `[PUSH]`.
///
/// Goes through `debugPrint`, which also prints in a **release** build (iOS
/// system log, Android logcat). Callers pass states and kinds of failure only:
/// never the Firebase Installation ID (nor its length), an account id or a
/// player name.
void pushLog(String message) => debugPrint('[PUSH] $message');

/// Longest part of a native error message kept in the journal.
const int _maxFailureMessage = 160;

/// A run of this many URL-safe base64 characters could be a Firebase
/// Installation ID (22 characters) or a token: it never reaches the journal,
final RegExp _tokenLike = RegExp(r'[A-Za-z0-9_-]{20,}');

/// unless it is plainly a word: CamelCase letters (`IllegalStateException`)
/// or lowercase snake_case (a manifest key). A random FID has next to no
/// chance of looking like either (about 1 in 10^8), while error messages are
/// full of them and they are what makes the message useful.
final RegExp _plainWord = RegExp(r'^(?:(?:[A-Z][a-z]+)+|[a-z]+(?:_[a-z]+)+)$');

/// What to journal about a failed native call: its [code] and its [message]
/// (what the native SDK says), with every token-like run replaced and the whole
/// cut short. The SDK messages are fixed sentences, but nothing proves they can
/// never quote a FID (an error URL may), hence the redaction.
String describeNativeFailure(String type, {String? code, String? message}) {
  final parts = <String>[type];
  if (code != null && code.isNotEmpty) parts.add('code=$code');
  final text = message
      ?.replaceAllMapped(
        _tokenLike,
        (m) => _plainWord.hasMatch(m[0]!) ? m[0]! : '<redacted>',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (text != null && text.isNotEmpty) {
    parts.add(
      'message="${text.length > _maxFailureMessage ? '${text.substring(0, _maxFailureMessage)}…' : text}"',
    );
  }
  return parts.join(' ');
}
