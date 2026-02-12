// lib/core/services/biometric_service.dart
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  static Future<bool> isFaceIdEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('face_id_enabled') ?? false;
  }

  static Future<bool> canUseBiometrics() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> authenticateWithFaceId({
    String reason = 'Please authenticate to access the app',
  }) async {
    try {
      final bool canAuthenticate = await canUseBiometrics();
      if (!canAuthenticate) return false;

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true, // Only biometric, no PIN/pattern fallback
        ),
      );

      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> authenticateWithFallback({
    String reason = 'Please authenticate to access the app',
  }) async {
    try {
      final bool canAuthenticate = await canUseBiometrics();
      if (!canAuthenticate) return false;

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/pattern fallback
        ),
      );

      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }
}