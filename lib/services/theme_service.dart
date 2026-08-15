import 'package:flutter/material.dart';
import 'package:yiw_field_report/services/offline_service.dart';

/// Holds the app-wide theme mode and persists it to the Hive `settings` box.
///
/// `AppTheme.darkTheme` already existed in this project but was unreachable
/// because `app.dart` hardcoded `ThemeMode.light`.
class ThemeService extends ChangeNotifier {
  static const String _settingKey = 'darkMode';

  final OfflineService _offlineService;
  bool _isDarkMode = false;

  ThemeService(this._offlineService);

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Reads the saved preference. Call once during startup.
  Future<void> load() async {
    try {
      final saved = await _offlineService.getSetting(_settingKey);
      _isDarkMode = saved == true;
      notifyListeners();
    } catch (e) {
      debugPrint('ThemeService: could not load theme preference: $e');
    }
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
    await _offlineService.saveSetting(_settingKey, value);
  }
}
