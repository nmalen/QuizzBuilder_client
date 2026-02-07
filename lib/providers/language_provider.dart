import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'language_code';
  static const String _defaultLanguage = 'en';
  static const List<String> _supportedLanguages = ['en', 'fr'];
  
  late SharedPreferences _prefs;
  String _languageCode = _defaultLanguage;

  String get languageCode => _languageCode;
  Locale get locale => Locale(_languageCode);

  /// Initialize language from preferences or device locale
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Check if user has previously selected a language
    final savedLanguage = _prefs.getString(_languageKey);
    
    if (savedLanguage != null) {
      // Use the previously saved language
      _languageCode = savedLanguage;
    } else {
      // Detect device locale and use if supported
      _languageCode = _getDeviceLanguage();
    }
    
    notifyListeners();
  }

  /// Get device language from system locale
  String _getDeviceLanguage() {
    final deviceLocale = ui.window.locale;
    final deviceLanguage = deviceLocale.languageCode.toLowerCase();
    
    // Check if device language is supported
    if (_supportedLanguages.contains(deviceLanguage)) {
      return deviceLanguage;
    }
    
    // Default to English if device language is not supported
    return _defaultLanguage;
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
