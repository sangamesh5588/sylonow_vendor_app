import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:sylonow_vendor/features/onboarding/providers/onboarding_provider.dart';

final otpNotifierProvider =
    StateNotifierProvider<OtpNotifier, AsyncValue<void>>((ref) {
  return OtpNotifier(ref);
});

class OtpNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  // reqId returned by MSG91 sendOTP — required for verifyOTP
  String _reqId = '';

  OtpNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<Either<String, String>> sendOtp(String phoneNumber) async {
    try {
      state = const AsyncValue.loading();
      final service = ref.read(onboardingServiceProvider);
      final result = await service.signInWithMobile(phoneNumber);

      return result.fold(
        (error) {
          state = AsyncValue.error(error, StackTrace.current);
          return left(error);
        },
        (reqId) {
          _reqId = reqId;
          state = const AsyncValue.data(null);
          return right(reqId);
        },
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return left(e.toString());
    }
  }

  void setReqId(String reqId) {
    _reqId = reqId;
  }

  Future<bool> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      state = const AsyncValue.loading();

      final service = ref.read(onboardingServiceProvider);
      final result = await service.verifyOTP(phoneNumber, otp, _reqId);

      return result.fold(
        (error) {
          print('❌ OTP verification error from service: $error');
          state = AsyncValue.error(error, StackTrace.current);
          return false;
        },
        (data) {
          print('✅ OTP verified successfully, data: $data');
          state = const AsyncValue.data(null);
          return true;
        },
      );
    } catch (e, stackTrace) {
      print('🔴 OTP verification error: $e');
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> resendOtp(String phoneNumber) async {
    try {
      state = const AsyncValue.loading();

      final service = ref.read(onboardingServiceProvider);
      final result = await service.signInWithMobile(phoneNumber);

      result.fold(
        (error) => throw Exception(error),
        (reqId) {
          _reqId = reqId; // Store reqId for the upcoming verifyOtp call
          state = const AsyncValue.data(null);
        },
      );
    } catch (e, stackTrace) {
      print('Error in resendOtp: $e');
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}
