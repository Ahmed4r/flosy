import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_cubit_state.dart';

class AuthCubit extends Cubit<AuthCubitState> {
  AuthCubit() : super(AuthInitial());
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> login(String username, String password) async {
    emit(AuthLoading());
    try {
      await auth.signInWithEmailAndPassword(
        email: username,
        password: password,
      );

      final user = auth.currentUser;
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

  Future<void> register(String email, String password) async {
    emit(AuthLoading());
    try {
      await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = auth.currentUser;
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

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await auth.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_token');

      emit(AuthSuccess());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_handleFirebaseAuthError(e.code)));
    } catch (e) {
      emit(AuthError('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<String?> getCurrentUser() async {
    return auth.currentUser?.uid;
  }

  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    try {
      await auth.sendPasswordResetEmail(email: email);
      emit(AuthSuccess());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_handleFirebaseAuthError(e.code)));
    } catch (e) {
      emit(AuthError('An unexpected error occurred: ${e.toString()}'));
    }
  }

  /// Handle Firebase authentication errors with user-friendly messages
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
