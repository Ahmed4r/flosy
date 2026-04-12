import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flosy/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService();

  static const String _androidServerClientId =
      '760463806679-4j99t7skliblv3dbvc8r395h3nvb4qbn.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

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
      await _ensureInitialized();

      final GoogleSignInAccount googleAccount = await _googleSignIn
          .authenticate();
      final String? idToken = googleAccount.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google Sign-In did not return an ID token. Check Firebase Google auth and OAuth client configuration.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final prefs = await SharedPreferences.getInstance();
      if (userCredential.user != null) {
        await prefs.setString('user_token', userCredential.user!.uid);
      }

      log('Google Sign-In successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      log('Error signing in with Google: $e');
      rethrow;
    }
  }
}
