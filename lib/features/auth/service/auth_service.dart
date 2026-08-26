import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flosy/firebase_options.dart';

class AuthService {
  AuthService();

  static const String _androidServerClientId =
      '760463806679-4j99t7skliblv3dbvc8r395h3nvb4qbn.apps.googleusercontent.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized || kIsWeb) return;

    String? clientId;
    String? serverClientId;

    if (defaultTargetPlatform == TargetPlatform.android) {
      serverClientId = _androidServerClientId;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      clientId = DefaultFirebaseOptions.ios.iosClientId;
    }

    await _googleSignIn.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );

    _isInitialized = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      late UserCredential userCredential;

      // =========================
      // WEB
      // =========================
      if (kIsWeb) {
        final GoogleAuthProvider provider = GoogleAuthProvider();

        provider.setCustomParameters({'prompt': 'select_account'});

        userCredential = await _auth.signInWithPopup(provider);
      }
      // =========================
      // ANDROID / IOS
      // =========================
      else {
        await _ensureInitialized();

        final GoogleSignInAccount googleAccount = await _googleSignIn
            .authenticate();

        final String? idToken = googleAccount.authentication.idToken;

        if (idToken == null || idToken.isEmpty) {
          throw Exception('Google Sign-In did not return an ID token.');
        }

        final credential = GoogleAuthProvider.credential(idToken: idToken);

        userCredential = await _auth.signInWithCredential(credential);
      }

      // =========================
      // SAVE USER
      // =========================
      final user = userCredential.user;

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('user_token', user.uid);

        log(
          'Google Sign-In successful: '
          '${user.email}',
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      log(
        'Firebase Auth Error: '
        '${e.code} - ${e.message}',
      );

      rethrow;
    } catch (e) {
      log('Google Sign-In Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();

      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_token');
    } catch (e) {
      log('Sign out error: $e');
      rethrow;
    }
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
