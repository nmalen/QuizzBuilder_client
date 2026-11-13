import '../l10n/app_localizations.dart';

/// Longest wait the API can announce for the sign-up limit (one hour).
const int registerMaxRetryAfterSeconds = 3600;

/// The message shown when sign-up is refused by the rate limit (HTTP 429).
///
/// [retryAfterSeconds] is the API's `details.retry_after_seconds`. Within
/// 1–3600 it becomes "less than a minute" (up to 60 s) or a number of minutes
/// rounded **up**; missing or outside that range it becomes a vague "in a
/// little while". The server's English text is never used.
String registerThrottledText(AppLocalizations l, int? retryAfterSeconds) {
  final seconds = retryAfterSeconds;
  final String wait;
  if (seconds == null || seconds < 1 || seconds > registerMaxRetryAfterSeconds) {
    wait = l.registerThrottledWaitUnknown;
  } else if (seconds <= 60) {
    wait = l.registerThrottledWaitShort;
  } else {
    wait = l.registerThrottledWait((seconds + 59) ~/ 60);
  }
  return l.registerThrottledMessage(wait);
}
