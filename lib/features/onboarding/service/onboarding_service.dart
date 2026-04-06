import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sendotp_flutter_sdk/sendotp_flutter_sdk.dart';
import '../models/vendor.dart';

/// Onboarding Service — MSG91 OTP Widget SDK + Supabase
///
/// Auth flow:
///  1. sendOTP      → MSG91 sends SMS, returns reqId
///  2. verifyOTP    → MSG91 verifies OTP, returns access_token
///  3. msg91-auth   → edge fn verifies access_token, creates Supabase session
///  4. setSession   → Supabase client gets a valid session
///
/// user_profiles and vendors rows are seeded by the edge function.
class OnboardingService {
  final SupabaseClient _supabase;

  OnboardingService(this._supabase) {
    _initializeMSG91();
  }

  static const Duration _timeout = Duration(seconds: 30);

  void _initializeMSG91() {
    final widgetId = dotenv.env['MSG91_WIDGET_ID'] ?? '';
    final authToken = dotenv.env['MSG91_AUTH_TOKEN'] ?? '';
    if (widgetId.isNotEmpty && authToken.isNotEmpty) {
      OTPWidget.initializeWidget(widgetId, authToken);
    }
  }

  /// Send OTP via MSG91 Widget SDK.
  /// Returns the [reqId] on success — must be passed to [verifyOTP].
  Future<Either<String, String>> signInWithMobile(String phoneNumber) async {
    try {
      // MSG91 wants digits only with country code, no '+' prefix
      String identifier =
          phoneNumber.replaceAll('+', '').replaceAll(' ', '').trim();

      // Basic heuristic: if it's a 10-digit number, prepend 91 (India)
      if (identifier.length == 10 && !identifier.startsWith('91')) {
        identifier = '91$identifier';
      }

      print('📱 Sending OTP via MSG91 to: $identifier');

      final response =
          await OTPWidget.sendOTP({'identifier': identifier}).timeout(_timeout);

      if (response == null) {
        return left('Failed to send OTP. Please try again.');
      }

      // Log the full response to identify field names in debug builds
      print('MSG91 sendOTP response: $response');

      // The SDK response can be slightly inconsistent in its keys.
      // We check for success type first.
      final type = response['type']?.toString().toLowerCase();

      if (type != 'success') {
        final msg = response['message']?.toString() ?? 'Failed to send OTP';
        return left(msg);
      }

      // Extract the request ID. In the latest SDK, it often comes in the 'message' field
      // when the 'type' is 'success'.
      String reqId = '';

      // Try common keys for the request ID
      final possibleKeys = [
        'reqId',
        'request_id',
        'requestId',
        'req_id',
        'message'
      ];
      for (final key in possibleKeys) {
        final value = response[key]?.toString();
        if (value != null && value.isNotEmpty && value != 'success') {
          reqId = value;
          break;
        }
      }

      if (reqId.isEmpty) {
        print('⚠️ MSG91 sendOTP: reqId missing. Full response: $response');
        return left('Failed to initiate OTP. Please try again.');
      }

      print('✅ MSG91 OTP sent, reqId: $reqId');
      return right(reqId);
    } on TimeoutException {
      return left('Request timed out. Please check your connection.');
    } catch (e) {
      print('❌ Error sending OTP: $e');
      if (e.toString().contains('rate_limit') ||
          e.toString().contains('too many')) {
        return left('Too many OTP requests. Please wait and try again.');
      }
      return left('Failed to send OTP. Please try again.');
    }
  }

  /// Verify OTP via MSG91, then exchange for a Supabase session.
  ///
  /// [reqId] is the value returned from [signInWithMobile].
  Future<Either<String, Map<String, dynamic>>> verifyOTP(
    String phoneNumber,
    String otp,
    String reqId,
  ) async {
    try {
      print('🔐 Verifying OTP via MSG91, reqId: $reqId, otp: $otp');

      final verifyResponse = await OTPWidget.verifyOTP(
        {'reqId': reqId, 'otp': otp},
      ).timeout(_timeout);

      if (verifyResponse == null) {
        return left('Verification failed. Please try again.');
      }

      print('MSG91 verifyOTP response: $verifyResponse');

      final type = verifyResponse['type']?.toString().toLowerCase();
      final status = verifyResponse['status']?.toString().toLowerCase();

      if (type != 'success' && status != 'success') {
        print('❌ MSG91 verification failed: $verifyResponse');
        final msg = verifyResponse['message']?.toString() ??
            'Invalid OTP. Please try again.';
        return left(msg);
      }

      // In the MSG91 Widget SDK, the access token is returned in the 'message' field on success
      String msg91Token = verifyResponse['access_token']?.toString() ?? '';
      if (msg91Token.isEmpty && type == 'success') {
        msg91Token = verifyResponse['message']?.toString() ?? '';
      }

      if (msg91Token.isEmpty) {
        return left('Verification failed: No access token received.');
      }

      print('✅ MSG91 token received: ${msg91Token.substring(0, 10)}...');

      // Exchange MSG91 verified token for a Supabase session
      final phone = phoneNumber.startsWith('+') ? phoneNumber : '+$phoneNumber';

      final sessionResp = await _supabase.functions.invoke(
        'msg91-auth',
        body: {'msg91_access_token': msg91Token, 'phone': phone},
      ).timeout(_timeout);

      // Extract session data safely (handle both Map and String responses)
      Map<String, dynamic> sessionData;
      if (sessionResp.data is Map) {
        sessionData = sessionResp.data as Map<String, dynamic>;
      } else if (sessionResp.data is String) {
        try {
          sessionData =
              jsonDecode(sessionResp.data as String) as Map<String, dynamic>;
        } catch (e) {
          print('❌ Error decoding session JSON: $e');
          return left('Failed to parse server response.');
        }
      } else {
        return left('Unexpected response from server.');
      }

      if (sessionResp.status != 200) {
        final error = sessionData['error']?.toString() ??
            sessionData['message']?.toString() ??
            'Authentication failed. Please try again.';
        return left(error);
      }

      final refreshToken = sessionData['refresh_token']?.toString() ?? '';
      if (refreshToken.isEmpty) {
        return left('Authentication failed: No refresh token received.');
      }

      // Establish Supabase session
      await _supabase.auth.setSession(refreshToken);

      print('✅ Supabase session established');
      return right({
        'userId': (sessionData['user'] as Map<String, dynamic>)['id'],
        'phone': phone,
      });
    } on TimeoutException {
      return left(
        'Verification timed out. Please check your connection and try again.',
      );
    } catch (e) {
      print('❌ Error verifying OTP: $e');
      return left('Verification failed. Please try again.');
    }
  }

  /// Resend OTP — uses MSG91 SDK retryOTP if possible.
  Future<Either<String, String>> resendOtp(String phoneNumber,
      {String? reqId}) async {
    if (reqId != null && reqId.isNotEmpty) {
      try {
        print('🔁 Retrying OTP via MSG91, reqId: $reqId');
        // retryChannel 11 is SMS
        final response =
            await OTPWidget.retryOTP({'reqId': reqId, 'retryChannel': 11})
                .timeout(_timeout);

        if (response != null &&
            response['type']?.toString().toLowerCase() == 'success') {
          print('✅ MSG91 OTP resent via retry');
          return right(reqId);
        }
      } catch (e) {
        print('⚠️ Retry OTP failed: $e. Falling back to new OTP.');
      }
    }
    return signInWithMobile(phoneNumber);
  }

  // ── Vendor data methods ─────────────────────────────────────────────────

  /// Check if a vendor record exists for this phone.
  Future<Either<Unit, Vendor>> checkVendorExists(String phoneNumber) async {
    try {
      final response = await _supabase
          .from('vendors')
          .select()
          .eq('phone', phoneNumber)
          .maybeSingle();

      if (response == null) return left(unit);
      return right(Vendor.fromJson(response));
    } catch (e) {
      print('❌ Error checking vendor existence: $e');
      return left(unit);
    }
  }

  /// Update vendor details (after initial onboarding).
  Future<Either<String, Vendor>> updateVendorDetails({
    required String vendorId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _supabase
          .from('vendors')
          .update(data)
          .eq('id', vendorId)
          .select()
          .single();

      return right(Vendor.fromJson(response));
    } catch (e) {
      print('❌ Error updating vendor: $e');
      return left('Failed to update vendor details. Please try again.');
    }
  }

  /// Upload a document to Supabase Storage.
  Future<Either<String, String>> uploadDocument({
    required String path,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final fullPath = '$path/$fileName';
      await _supabase.storage.from('vendor-documents').uploadBinary(
            fullPath,
            bytes,
          );
      final url =
          _supabase.storage.from('vendor-documents').getPublicUrl(fullPath);
      return right(url);
    } catch (e) {
      print('❌ Error uploading document: $e');
      return left('Failed to upload document. Please try again.');
    }
  }
}
