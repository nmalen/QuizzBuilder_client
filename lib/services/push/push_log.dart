import 'package:flutter/foundation.dart';

/// One diagnostic line of the push notification chain, prefixed `[PUSH]`.
///
/// Goes through `debugPrint`, which also prints in a **release** build (iOS
/// system log, Android logcat). Callers pass states and kinds of failure only:
/// never the Firebase Installation ID (nor its length), an account id or a
/// player name.
void pushLog(String message) => debugPrint('[PUSH] $message');
