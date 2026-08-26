import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flosy/features/auth/service/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';


part 'auth_cubit_state.dart';

class AuthCubit extends Cubit<AuthCubitState> {
  AuthCubit() : super(AuthInitial());

  FirebaseAuth? get _auth {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance;
  }

  final AuthService _authService = AuthService();

  String get _firebaseUnavailableMessage =>
      'Firebase authentication is not configured for this platform.';

  // =========================
  // EMAIL LOGIN
  // =========================

  Future<void> login(String email, String password) async {
    final auth = _auth;

    if (auth == null) {
      emit(AuthError(_firebaseUnavailableMessage));
      return;
    }

    emit(AuthLoading());

    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_token', user.uid);
      }

      emit(AuthSuccess());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_handleFirebaseAuthError(e.code)));
    } catch (e) {
      emit(AuthError('An unexpected error occurred: ${e.toString()}'));
    }
  }

  // =========================
  // REGISTER
  // =========================

  Future<void> register(String email, String password, {String? name}) async {
    final auth = _auth;

    if (auth == null) {
      emit(AuthError(_firebaseUnavailableMessage));
      return;
    }

    emit(AuthLoading());

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        if (name != null && name.trim().isNotEmpty) {
          await user.updateDisplayName(name.trim());
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_token', user.uid);
      }

      emit(AuthSuccess());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_handleFirebaseAuthError(e.code)));
    } catch (e) {
      emit(AuthError('An unexpected error occurred: ${e.toString()}'));
    }
  }

  // =========================
  // GOOGLE
  // =========================

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());

    try {
      final credential = await _authService.signInWithGoogle();

      if (credential.user != null) {
        emit(AuthSuccess());
      } else {
        emit(AuthError('Google Sign-In failed.'));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_handleFirebaseAuthError(e.code)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // =========================
  // LOGOUT
  // =========================

  Future<void> logout() async {
    emit(AuthLoading());

    try {
      await _authService.signOut();

      emit(AuthSuccess());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_handleFirebaseAuthError(e.code)));
    } catch (e) {
      emit(AuthError('An unexpected error occurred: ${e.toString()}'));
    }
  }

  // =========================
  // CURRENT USER
  // =========================

  Future<String?> getCurrentUser() async {
    return _auth?.currentUser?.uid;
  }

  // =========================
  // RESET PASSWORD
  // =========================

  Future<void> resetPassword(String email) async {
    final auth = _auth;

    if (auth == null) {
      emit(AuthError(_firebaseUnavailableMessage));
      return;
    }

    emit(AuthLoading());

    try {
      await auth.sendPasswordResetEmail(email: email.trim());

      emit(AuthSuccess());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_handleFirebaseAuthError(e.code)));
    } catch (e) {
      emit(AuthError('An unexpected error occurred: ${e.toString()}'));
    }
  }

  // =========================
  // FIREBASE ERROR HANDLER
  // =========================

  String _handleFirebaseAuthError(String code) {
    switch (code) {
      case 'weak-password':
        return 'weak_password'.tr();

      case 'email-already-in-use':
        return 'email_already_in_use'.tr();

      case 'invalid-email':
        return 'invalid_email'.tr();

      case 'user-not-found':
        return 'user_not_found'.tr();

      case 'wrong-password':
        return 'wrong_password'.tr();

      case 'invalid-credential':
        return 'invalid_credential'.tr();

      case 'user-disabled':
        return 'user_disabled'.tr();

      case 'too-many-requests':
        return 'too_many_requests'.tr();

      case 'operation-not-allowed':
        return 'operation_not_allowed'.tr();

      case 'network-request-failed':
        return 'network_request_failed'.tr();

      case 'invalid-phone-number':
        return 'invalid_phone_number'.tr();

      case 'missing-phone-number':
        return 'missing_phone_number'.tr();

      default:
        return '${'auth_error'.tr()}: $code';
    }
  }
}
