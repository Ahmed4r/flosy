import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';

part 'auth_cubit_state.dart';

class AuthCubitCubit extends Cubit<AuthCubitState> {
  AuthCubitCubit() : super(AuthCubitInitial());
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> login(String username, String password) async {
    emit(AuthCubitLoading());
    try {
      // Disable reCAPTCHA for development/testing
      await auth.setSettings(appVerificationDisabledForTesting: true);

      await auth.signInWithEmailAndPassword(
        email: username,
        password: password,
      );
      emit(AuthCubitSuccess());
    } on FirebaseAuthException catch (e) {
      emit(AuthCubitError(_handleFirebaseAuthError(e.code)));
    } catch (e) {
      emit(AuthCubitError('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> register(String email, String password) async {
    emit(AuthCubitLoading());
    try {

      await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      emit(AuthCubitSuccess());
    } on FirebaseAuthException catch (e) {
      emit(AuthCubitError(_handleFirebaseAuthError(e.code)));
    } catch (e) {
      emit(AuthCubitError('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> logout() async {
    emit(AuthCubitLoading());
    try {
      await auth.signOut();
      emit(AuthCubitSuccess());
    } on FirebaseAuthException catch (e) {
      emit(AuthCubitError(_handleFirebaseAuthError(e.code)));
    } catch (e) {
      emit(AuthCubitError('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<String?> getCurrentUser() async {
    return auth.currentUser?.uid;
  }

  Future<void> resetPassword(String email) async {
    emit(AuthCubitLoading());
    try {
      await auth.sendPasswordResetEmail(email: email);
      emit(AuthCubitSuccess());
    } on FirebaseAuthException catch (e) {
      emit(AuthCubitError(_handleFirebaseAuthError(e.code)));
    } catch (e) {
      emit(AuthCubitError('An unexpected error occurred: ${e.toString()}'));
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
