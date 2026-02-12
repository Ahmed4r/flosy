import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(SettingsInitial());

  final LocalAuthentication _localAuth = LocalAuthentication();
  ThemeMode _currentThemeMode = ThemeMode.system;
  bool _isDarkMode = false;
  bool _faceIdEnabled = false;
  String _selectedCurrency = 'USD';

  ThemeMode get currentThemeMode => _currentThemeMode;
  bool get isDarkMode => _isDarkMode;
  bool get faceIdEnabled => _faceIdEnabled;
  String get selectedCurrency => _selectedCurrency;

  Future<void> loadSettings() async {
    emit(SettingsLoading());
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load theme mode
      final themeModeIndex = prefs.getInt('theme_mode') ?? 0;
      _currentThemeMode = ThemeMode.values[themeModeIndex];
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;

      // Load other settings
      _faceIdEnabled = prefs.getBool('face_id_enabled') ?? false;
      _selectedCurrency = prefs.getString('selected_currency') ?? 'USD';

      emit(
        SettingsLoaded(
          themeMode: _currentThemeMode,
          isDarkMode: _isDarkMode,
          faceIdEnabled: _faceIdEnabled,
          selectedCurrency: _selectedCurrency,
        ),
      );
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = isDark;
      _currentThemeMode = isDark ? ThemeMode.dark : ThemeMode.light;

      await prefs.setBool('is_dark_mode', _isDarkMode);
      await prefs.setInt('theme_mode', _currentThemeMode.index);

      emit(
        SettingsLoaded(
          themeMode: _currentThemeMode,
          isDarkMode: _isDarkMode,
          faceIdEnabled: _faceIdEnabled,
          selectedCurrency: _selectedCurrency,
        ),
      );
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<bool> checkBiometricAvailability() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool canAuthenticate = await checkBiometricAvailability();

      if (!canAuthenticate) {
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to enable biometric login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  Future<void> toggleFaceId(bool enabled) async {
    try {
      if (enabled) {
        // Check if biometric is available
        final canAuthenticate = await checkBiometricAvailability();
        if (!canAuthenticate) {
          emit(
            SettingsError(
              'Biometric authentication is not available on this device',
            ),
          );
          return;
        }

        // Authenticate before enabling
        final authenticated = await authenticateWithBiometrics();
        if (!authenticated) {
          emit(SettingsError('Authentication failed'));
          // Re-emit current state without changing the value
          emit(
            SettingsLoaded(
              themeMode: _currentThemeMode,
              isDarkMode: _isDarkMode,
              faceIdEnabled: _faceIdEnabled,
              selectedCurrency: _selectedCurrency,
            ),
          );
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      _faceIdEnabled = enabled;
      await prefs.setBool('face_id_enabled', _faceIdEnabled);

      emit(
        SettingsLoaded(
          themeMode: _currentThemeMode,
          isDarkMode: _isDarkMode,
          faceIdEnabled: _faceIdEnabled,
          selectedCurrency: _selectedCurrency,
        ),
      );
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> changeCurrency(String currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedCurrency = currency;
      await prefs.setString('selected_currency', _selectedCurrency);

      emit(
        SettingsLoaded(
          themeMode: _currentThemeMode,
          isDarkMode: _isDarkMode,
          faceIdEnabled: _faceIdEnabled,
          selectedCurrency: _selectedCurrency,
        ),
      );
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }
}
