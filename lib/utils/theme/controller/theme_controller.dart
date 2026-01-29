import 'package:flutter/material.dart';
import 'package:new_flutter_firebase_webrtc/utils/theme/theme.dart';

class ThemeNotifier extends ChangeNotifier {
  AppThemeMode _currentTheme = AppThemeMode.dark;
  AppThemeMode get currentTheme => _currentTheme;

  ThemeData get themeData {
    switch (_currentTheme) {
      case AppThemeMode.light:
        return TAppTheme.lightTheme;
      case AppThemeMode.dark:
        return TAppTheme.darkTheme;
      case AppThemeMode.green:
        return TAppTheme.greenTheme;
    }
  }

  void switchTheme(AppThemeMode newTheme) {
    _currentTheme = newTheme;
    notifyListeners(); // Triggers rebuild
  }
}
