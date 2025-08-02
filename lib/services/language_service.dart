import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  // Available languages
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('ms'), // Bahasa Melayu
    Locale('zh'), // Mandarin (Simplified Chinese)
    Locale('ta'), // Tamil
  ];

  // Language display names
  static const Map<String, String> languageNames = {
    'en': 'English',
    'ms': 'Bahasa Melayu',
    'zh': '中文',
    'ta': 'தமிழ்',
  };

  // Language flags or icons (optional)
  static const Map<String, String> languageFlags = {
    'en': '🇺🇸',
    'ms': '🇲🇾',
    'zh': '🇨🇳',
    'ta': '🇮🇳',
  };

  Locale _currentLocale = const Locale('en'); // Default to English
  
  Locale get currentLocale => _currentLocale;
  
  String get currentLanguageCode => _currentLocale.languageCode;
  
  String get currentLanguageName => languageNames[currentLanguageCode] ?? 'English';
  
  String get currentLanguageFlag => languageFlags[currentLanguageCode] ?? '🇺🇸';

  /// Initialize the language service and load saved language preference
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString(_languageKey);
    
    if (savedLanguageCode != null) {
      final savedLocale = supportedLocales.firstWhere(
        (locale) => locale.languageCode == savedLanguageCode,
        orElse: () => const Locale('en'),
      );
      _currentLocale = savedLocale;
    }
    
    notifyListeners();
  }

  /// Change the current language and persist the selection
  Future<void> changeLanguage(String languageCode) async {
    final newLocale = supportedLocales.firstWhere(
      (locale) => locale.languageCode == languageCode,
      orElse: () => const Locale('en'),
    );
    
    if (newLocale.languageCode != _currentLocale.languageCode) {
      _currentLocale = newLocale;
      
      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      
      notifyListeners();
    }
  }

  /// Change language by Locale object
  Future<void> changeLocale(Locale locale) async {
    await changeLanguage(locale.languageCode);
  }

  /// Get language name for a specific language code
  String getLanguageName(String languageCode) {
    return languageNames[languageCode] ?? 'Unknown';
  }

  /// Get language flag for a specific language code
  String getLanguageFlag(String languageCode) {
    return languageFlags[languageCode] ?? '🏳️';
  }

  /// Check if a language code is supported
  bool isLanguageSupported(String languageCode) {
    return supportedLocales.any((locale) => locale.languageCode == languageCode);
  }

  /// Get all available language options for UI display
  List<LanguageOption> getLanguageOptions() {
    return supportedLocales.map((locale) => LanguageOption(
      code: locale.languageCode,
      name: languageNames[locale.languageCode] ?? 'Unknown',
      flag: languageFlags[locale.languageCode] ?? '🏳️',
      locale: locale,
      isSelected: locale.languageCode == _currentLocale.languageCode,
    )).toList();
  }
}

/// Language option model for UI display
class LanguageOption {
  final String code;
  final String name;
  final String flag;
  final Locale locale;
  final bool isSelected;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.flag,
    required this.locale,
    required this.isSelected,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageOption &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}