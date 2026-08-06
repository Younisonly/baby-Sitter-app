import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:babysitter/core/localization/app_localization.dart';
import 'package:babysitter/core/network/error_handler.dart';

class SocialAuthService {
  SocialAuthService._();

  static String _generateNonce([int length = 32]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
  }

  static String _sha256Of(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  static Future<String> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw AppException(
        message: AppLocalization.request_cancelled,
        code: 'GOOGLE_CANCELLED',
      );
    }

    final googleAuth = await googleUser.authentication;
    if (googleAuth.idToken == null) {
      throw AppException(
        message: AppLocalization.unexpected_error,
        code: 'GOOGLE_TOKEN_ERROR',
      );
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final idToken = await userCredential.user!.getIdToken();
    if (idToken == null) {
      throw AppException(
        message: AppLocalization.unexpected_error,
        code: 'FIREBASE_TOKEN_ERROR',
      );
    }

    return idToken;
  }

  static Future<String> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256Of(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final credential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final idToken = await userCredential.user!.getIdToken();
    if (idToken == null) {
      throw AppException(
        message: AppLocalization.unexpected_error,
        code: 'APPLE_TOKEN_ERROR',
      );
    }

    return idToken;
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }

  static bool get isAppleSignInAvailable {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return true;
    }
    return false;
  }
}
