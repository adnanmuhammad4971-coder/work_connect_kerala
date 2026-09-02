import 'package:flutter/material.dart';

class AppStateProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isMalayalam = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isMalayalam => _isMalayalam;

  // ================= THEME TOGGLE =================
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // ================= LANGUAGE TOGGLE =================
  void toggleLanguage() {
    _isMalayalam = !_isMalayalam;
    notifyListeners();
  }

  void setLanguage(bool isMalayalam) {
    _isMalayalam = isMalayalam;
    notifyListeners();
  }

  // ================= TRANSLATION HELPER =================
  String tr(String english, String malayalam) {
    return _isMalayalam ? malayalam : english;
  }

  /// Helper to extract clean localized category name
  String formatCategory(String rawName) {
    if (!rawName.contains('(')) return rawName;
    final parts = rawName.split('(');
    final eng = parts[0].trim();
    final mal = parts[1].replaceAll(')', '').trim();
    return _isMalayalam ? '$mal ($eng)' : eng;
  }

  // ================= DYNAMIC THEME COLORS =================
  Color get scaffoldBg => isDarkMode ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC);
  Color get cardBg => isDarkMode ? const Color(0xFF1E293B) : Colors.white;
  Color get surfaceBg => isDarkMode ? const Color(0xFF131C2E) : const Color(0xFFFFFFFF);
  Color get textPrimary => isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  Color get textSecondary => isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get textMuted => isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
  Color get borderCol => isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get inputBg => isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
  Color get navBg => isDarkMode ? const Color(0xFF070B14) : Colors.white;
  Color get bannerBgStart => isDarkMode ? const Color(0xFF060D17) : const Color(0xFF0F172A);
  Color get bannerBgEnd => isDarkMode ? const Color(0xFF0F2338) : const Color(0xFF1E293B);
  Color get primaryAccent => isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0F4C81);
}
