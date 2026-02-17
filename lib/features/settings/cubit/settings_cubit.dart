import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flosy/features/home/data/model/transaction_model.dart';
import 'package:flosy/features/home/presentation/services/db.dart';
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
  File? _image;
  File? get profileImage => _image;
  late SharedPreferences _prefs;
  bool _isSyncing = false;

  ThemeMode get currentThemeMode => _currentThemeMode;
  bool get isDarkMode => _isDarkMode;
  bool get faceIdEnabled => _faceIdEnabled;
  String get selectedCurrency => _selectedCurrency;
  bool get isSyncing => _isSyncing;

  Future<void> toggleSync(bool isSyncing) async {
    try {
      _isSyncing = isSyncing;
      await _prefs.setBool('is_syncing', isSyncing);
      emit(
        SettingsLoaded(
          themeMode: _currentThemeMode,
          isDarkMode: _isDarkMode,
          faceIdEnabled: _faceIdEnabled,
          selectedCurrency: _selectedCurrency,
          profileImage: _image,
          isSyncing: isSyncing,
        ),
      );
      if (isSyncing) {
        await syncTransactionsToCloud();
        log('Data synced to cloud successfully');
      }
    } catch (e) {
      log(e.toString());
      emit(SettingsError('Failed to sync data: ${e.toString()}'));
    }
  }

  Future<void> syncTransactionsToCloud() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final transactions = await dbService.getTransactions();

    final batch = FirebaseFirestore.instance.batch();

    for (final tx in transactions) {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(tx.id.toString());

      batch.set(docRef, tx.toMap(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> loadSettings() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // Load theme mode
      final themeModeIndex = _prefs.getInt('theme_mode') ?? 0;
      _currentThemeMode = ThemeMode.values[themeModeIndex];
      _isDarkMode = _prefs.getBool('is_dark_mode') ?? false;

      // Load other settings
      _faceIdEnabled = _prefs.getBool('face_id_enabled') ?? false;
      _selectedCurrency = _prefs.getString('selected_currency') ?? 'USD';
      _image = _prefs.getString('profile_image') != null
          ? File(_prefs.getString('profile_image')!)
          : null;
      _isSyncing = _prefs.getBool('is_syncing') ?? false;

      emit(
        SettingsLoaded(
          themeMode: _currentThemeMode,
          isDarkMode: _isDarkMode,
          faceIdEnabled: _faceIdEnabled,
          selectedCurrency: _selectedCurrency,
          profileImage: _image,
          isSyncing: _isSyncing,
        ),
      );
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> updateProfileImage(File? image) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;

      // Update the instance variable
      _image = image;

      // Force a new emission by creating a completely new state
      emit(SettingsLoading()); // Emit loading first

      // Save to SharedPreferences with the correct key
      if (image != null) {
        await _prefs.setString(
          'profile_image',
          image.path,
        ); // Changed from 'profile_image_path'
      } else {
        await _prefs.remove('profile_image');
      }

      // Emit the new state
      emit(
        SettingsLoaded(
          selectedCurrency: currentState.selectedCurrency,
          isDarkMode: currentState.isDarkMode,
          faceIdEnabled: currentState.faceIdEnabled,
          profileImage: image,
          themeMode: _currentThemeMode,
          isSyncing: _isSyncing,
        ),
      );
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    try {
      _isDarkMode = isDark;
      _currentThemeMode = isDark ? ThemeMode.dark : ThemeMode.light;

      await _prefs.setBool('is_dark_mode', _isDarkMode);
      await _prefs.setInt('theme_mode', _currentThemeMode.index);

      emit(
        SettingsLoaded(
          themeMode: _currentThemeMode,
          isDarkMode: _isDarkMode,
          faceIdEnabled: _faceIdEnabled,
          selectedCurrency: _selectedCurrency,
          profileImage: _image,
          isSyncing: _isSyncing,
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
              profileImage: _image,
              isSyncing: _isSyncing,
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
          profileImage: _image,
          isSyncing: _isSyncing,
        ),
      );
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> changeCurrency(String currency) async {
    try {
      _selectedCurrency = currency;
      await _prefs.setString('selected_currency', _selectedCurrency);
      emit(
        SettingsLoaded(
          themeMode: _currentThemeMode,
          isDarkMode: _isDarkMode,
          faceIdEnabled: _faceIdEnabled,
          selectedCurrency: _selectedCurrency,
          profileImage: _image,
          isSyncing: _isSyncing,
        ),
      );
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }
}
