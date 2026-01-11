import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'language_code';
  static const String _defaultLanguage = 'en';
  
  late SharedPreferences _prefs;
  String _languageCode = _defaultLanguage;

  String get languageCode => _languageCode;
  Locale get locale => Locale(_languageCode);

  /// Initialize language from preferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _languageCode = _prefs.getString(_languageKey) ?? _defaultLanguage;
    notifyListeners();
  }

  /// Set language and persist
  Future<void> setLanguage(String languageCode) async {
    if (languageCode == _languageCode) return;
    
    _languageCode = languageCode;
    await _prefs.setString(_languageKey, languageCode);
    notifyListeners();
  }

  /// Helper to get localized text
  String getLocalizedText(String textEn, String textFr) {
    return _languageCode == 'fr' ? textFr : textEn;
  }
}
