import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AppleAuthService {
  static final AppleAuthService _instance = AppleAuthService._internal();
  factory AppleAuthService() => _instance;
  AppleAuthService._internal();

  /// Generates a cryptographically secure random nonce, to be included in a
  /// credential request.
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Initiates the Apple Sign-In process and authenticates with Supabase.
  /// Returns the AuthResponse from Supabase if successful, otherwise null.
  /// Includes app type to differentiate between vendor and customer apps.
  Future<AuthResponse?> signInWithApple({String appType = 'vendor'}) async {
    try {
      if (kDebugMode) {
        print('🔵 [AppleAuth] Starting Apple Sign-In process for $appType app');
      }

      // Generate nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request credential from Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Check if identity token is available
      if (appleCredential.identityToken == null) {
        throw 'Failed to get identity token from Apple.';
      }

      // Sign in to Supabase with Apple ID token
      final authResponse = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: appleCredential.identityToken!,
        nonce: rawNonce,
      );

      // Create user profile with app type after successful Apple sign-in
      if (authResponse.user != null) {
        await _createUserProfile(authResponse.user!.id, appType);
      }

      return authResponse;
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [AppleAuth] Error during Apple Sign-In: $e');
      }
      rethrow;
    }
  }

  /// Signs the user out from Supabase (Apple doesn't require separate sign-out).
  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [AppleAuth] Sign-out error: $e');
      }
    }
  }

  /// Helper method to create user profile with app type
  Future<void> _createUserProfile(String userId, String appType) async {
    try {
      await SupabaseConfig.client.rpc('create_user_profile', params: {
        'user_id': userId,
        'app_type': appType,
      });
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [AppleAuth] Failed to create user profile: $e');
      }
      // Don't throw - this is not critical for auth flow
    }
  }

  bool get isSignedIn => SupabaseConfig.client.auth.currentUser != null;

  User? get currentUser => SupabaseConfig.client.auth.currentUser;
}
