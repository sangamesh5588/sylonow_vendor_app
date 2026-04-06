import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  Future<void> initialize() async {
    // For version 6.2.1, no special initialization is needed
    // GoogleSignIn 7.0+ requires initialization, but 6.2.1 doesn't
  }

  /// Initiates the Google Sign-In process and authenticates with Supabase.
  /// Returns the AuthResponse from Supabase if successful, otherwise null.
  /// Now includes app type to differentiate between vendor and customer apps.
  Future<AuthResponse?> signInWithGoogle({String appType = 'vendor'}) async {
    try {
      if (kDebugMode) {
        print('🔵 [GoogleAuth] Starting Google Sign-In process for $appType app');
      }

      // Configure GoogleSignIn with proper scopes (version 6.2.1 approach)
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      if (kDebugMode) {
        print('🔵 [GoogleAuth] GoogleSignIn configured with scopes: ${googleSignIn.scopes}');
      }

      // Try silent sign-in first, then interactive sign-in if needed
      if (kDebugMode) {
        print('🔵 [GoogleAuth] Attempting silent sign-in...');
      }
      GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();

      if (googleUser != null) {
        if (kDebugMode) {
          print('🟢 [GoogleAuth] Silent sign-in successful for: ${googleUser.email}');
        }
      } else {
        if (kDebugMode) {
          print('🔵 [GoogleAuth] Silent sign-in failed, starting interactive sign-in...');
        }
        googleUser = await googleSignIn.signIn();
      }

      if (googleUser == null) {
        if (kDebugMode) {
          print('🔴 [GoogleAuth] Google Sign-In was cancelled by user');
        }
        throw 'Google Sign-In was cancelled by user.';
      }

      if (kDebugMode) {
        print('🟢 [GoogleAuth] Interactive sign-in successful for: ${googleUser.email}');
        print('🔵 [GoogleAuth] User details - ID: ${googleUser.id}, Display Name: ${googleUser.displayName}');
      }

      // 3. Obtain the authentication details from the request.
      if (kDebugMode) {
        print('🔵 [GoogleAuth] Obtaining authentication details...');
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (kDebugMode) {
        print('🔵 [GoogleAuth] Auth details obtained - Access Token: ${googleAuth.accessToken?.substring(0, 10)}..., ID Token: ${googleAuth.idToken?.substring(0, 10)}...');
      }

      // Throw an error if the ID token is missing.
      if (googleAuth.idToken == null) {
        if (kDebugMode) {
          print('🔴 [GoogleAuth] ID token is null!');
        }
        throw 'Failed to get ID token from Google.';
      }

      if (kDebugMode) {
        print('🔵 [GoogleAuth] Signing in to Supabase with Google ID token...');
      }
      // 3. Use the ID token to sign in to Supabase.
      final authResponse = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
      );

      if (kDebugMode) {
        print('🟢 [GoogleAuth] Supabase sign-in successful');
        print('🔵 [GoogleAuth] User ID: ${authResponse.user?.id}');
        print('🔵 [GoogleAuth] User Email: ${authResponse.user?.email}');
        print('🔵 [GoogleAuth] Session: ${authResponse.session != null ? 'Valid' : 'Null'}');
        print('═══════════════════════════════════════════════════════');
        print('🟢 LOGGED IN WITH:');
        print('   User ID: ${authResponse.user?.id}');
        print('   Email: ${authResponse.user?.email}');
        print('   Name: ${authResponse.user?.userMetadata?['full_name'] ?? authResponse.user?.userMetadata?['name'] ?? 'N/A'}');
        print('═══════════════════════════════════════════════════════');
      }

      // 🔴 NEW: Create user profile with app type after successful Google sign-in
      if (authResponse.user != null) {
        if (kDebugMode) {
          print('🔵 [GoogleAuth] Creating user profile for app type: $appType');
        }
        await _createUserProfile(authResponse.user!.id, appType);

        // Create vendor record for vendor app
        if (appType == 'vendor') {
          if (kDebugMode) {
            print('🔵 [GoogleAuth] Creating vendor record');
          }
          await _createVendorRecord(
            authResponse.user!.email ?? '',
            authResponse.user!.phone ?? '',
            authResponse.user!.userMetadata?['full_name'] as String? ?? authResponse.user!.userMetadata?['name'] as String? ?? '',
          );
        }
      }

      if (kDebugMode) {
        print('🟢 [GoogleAuth] Google Sign-In process completed successfully');
      }
      return authResponse;
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [GoogleAuth] Error during Google Sign-In: $e');
        print('🔴 [GoogleAuth] Error type: ${e.runtimeType}');
        if (e is Exception) {
          print('🔴 [GoogleAuth] Exception details: $e');
        }
      }
      // Re-throw with the error for proper handling in the UI
      rethrow;
    }
  }

  /// Signs the user out from both Google and Supabase.
  Future<void> signOut() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      await googleSignIn.signOut();
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Sign-out error: $e');
    }
  }

  // 🔴 NEW: Helper method to create user profile with app type
  Future<void> _createUserProfile(String userId, String appType) async {
    try {
      if (kDebugMode) {
        print('🔵 [GoogleAuth] Calling create_user_profile RPC function...');
      }
      await SupabaseConfig.client.rpc('create_user_profile', params: {
        'user_id': userId,
        'app_type': appType,
      });

      if (kDebugMode) {
        print('🟢 [GoogleAuth] User profile created with app type: $appType');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [GoogleAuth] Failed to create user profile: $e');
        print('🔴 [GoogleAuth] Profile creation error type: ${e.runtimeType}');
      }
      // Don't throw - this is not critical for auth flow
    }
  }

  // 🔴 NEW: Helper method to create vendor record for Google Auth users
  Future<void> _createVendorRecord(String email, String phone, String fullName) async {
    try {
      if (kDebugMode) {
        print('🔵 [GoogleAuth] Calling create_vendor_for_auth_user RPC function...');
      }
      final vendorId = await SupabaseConfig.client.rpc('create_vendor_for_auth_user', params: {
        'p_email': email.isNotEmpty ? email : null,
        'p_phone': phone.isNotEmpty ? phone : null,
        'p_full_name': fullName.isNotEmpty ? fullName : null,
      });

      if (kDebugMode) {
        print('🟢 [GoogleAuth] Vendor record created/retrieved with ID: $vendorId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [GoogleAuth] Failed to create vendor record: $e');
        print('🔴 [GoogleAuth] Vendor creation error type: ${e.runtimeType}');
      }
      // Don't throw - allow user to continue to onboarding
    }
  }

  bool get isSignedIn => SupabaseConfig.client.auth.currentUser != null;
  
  User? get currentUser => SupabaseConfig.client.auth.currentUser;
} 