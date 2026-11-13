import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

/// Names of [difficulties] (`easy`, `medium`, `hard`) in the app language,
/// joined by commas.
String duelDifficultyNames(AppLocalizations l, Iterable<String> difficulties) {
  String name(String d) => switch (d) {
    'easy' => l.easy,
    'medium' => l.medium,
    'hard' => l.hard,
    _ => d,
  };
  return difficulties.map(name).join(', ');
}

/// Date shown to the player, in the app language and the device time zone.
String duelDate(BuildContext context, DateTime? date) {
  if (date == null) return '';
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMMMd(locale).format(date.toLocal());
}

/// Date and time shown to the player.
String duelDateTime(BuildContext context, DateTime? date) {
  if (date == null) return '';
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMMMd(locale).add_Hm().format(date.toLocal());
}

/// Hour, minute and second (e.g. `18:52:07`), in the device time zone.
String duelTimeWithSeconds(BuildContext context, DateTime? date) {
  if (date == null) return '';
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.Hms(locale).format(date.toLocal());
}

/// Hour and minute (e.g. `18:52`), in the device time zone.
String duelTime(BuildContext context, DateTime? date) {
  if (date == null) return '';
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.Hm(locale).format(date.toLocal());
}
