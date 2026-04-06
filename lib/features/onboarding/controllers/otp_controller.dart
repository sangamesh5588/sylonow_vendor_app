import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../providers/otp_provider.dart';
import '../helpers/otp_helper.dart';
import '../../../core/utils/error_utils.dart';

final otpControllerProvider = StateNotifierProvider<OtpController, OtpState>((ref) {
  return OtpController(ref);
});

class OtpState {
  final String otp;
  final int remainingSeconds;
  final bool isLoading;
  final bool isTimerActive;
  final String? errorMessage;

  const OtpState({
    this.otp = '',
    this.remainingSeconds = 60,
    this.isLoading = false,
    this.isTimerActive = true,
    this.errorMessage,
  });

  OtpState copyWith({
    String? otp,
    int? remainingSeconds,
    bool? isLoading,
    bool? isTimerActive,
    String? errorMessage,
  }) {
    return OtpState(
      otp: otp ?? this.otp,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isLoading: isLoading ?? this.isLoading,
      isTimerActive: isTimerActive ?? this.isTimerActive,
      errorMessage: errorMessage,
    );
  }
}

class OtpController extends StateNotifier<OtpState> {
  final Ref ref;
  Timer? _timer;

  OtpController(this.ref) : super(const OtpState()) {
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void updateOtp(String otp) {
    state = state.copyWith(otp: otp, errorMessage: null);
  }

  void _startTimer() {
    _timer?.cancel();
    state = state.copyWith(remainingSeconds: 60, isTimerActive: true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        timer.cancel();
        state = state.copyWith(isTimerActive: false);
      }
    });
  }

  Future<void> sendInitialOtp(String phoneNumber) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await ref.read(otpNotifierProvider.notifier).resendOtp(
        OtpHelper.formatPhoneNumber(phoneNumber),
      );
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      // Handle rate limiting specifically for initial send
      if (errorMessage.contains('rate_limit') || errorMessage.contains('wait')) {
        errorMessage = 'Please wait a few seconds before requesting OTP';
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
      );
    } finally {
      // Always ensure loading state is cleared
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<bool> verifyOtp(String phoneNumber) async {
    if (!OtpHelper.isValidOtp(state.otp)) {
      state = state.copyWith(errorMessage: 'Please enter a valid 6-digit OTP');
      return false;
    }

    try {
// TODO: Replace with proper logging - print('🔍 OTP Controller: Starting verification for phone: $phoneNumber');
      state = state.copyWith(isLoading: true, errorMessage: null);

      final otpNotifier = ref.read(otpNotifierProvider.notifier);
      final formattedPhone = OtpHelper.formatPhoneNumber(phoneNumber);

      final isVerified = await otpNotifier.verifyOtp(
        phoneNumber: formattedPhone,
        otp: state.otp,
      );

      if (isVerified) {
        print('🟢 OTP Controller: Verification successful');
      } else {
        print('🔴 OTP Controller: Verification failed');
        // Extract error message from state if it was set by the notifier
        final notifierState = ref.read(otpNotifierProvider);
        String? notifierError;
        notifierState.whenOrNull(
          error: (error, _) => notifierError = error.toString(),
        );
        state = state.copyWith(
          errorMessage: notifierError ?? 'Invalid OTP. Please try again.',
        );
      }

      return isVerified;
    } catch (e) {
// Error print removed
      // Use ErrorUtils to get user-friendly error message
      final errorMessage = ErrorUtils.getOtpErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
      );
      return false;
    } finally {
      // Always ensure loading state is cleared
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> resendOtp(String phoneNumber) async {
    if (state.isTimerActive) {
      state = state.copyWith(
        errorMessage: 'Please wait ${state.remainingSeconds} seconds before requesting a new OTP',
      );
      return;
    }

    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      await ref.read(otpNotifierProvider.notifier).resendOtp(
        OtpHelper.formatPhoneNumber(phoneNumber),
      );

      _startTimer();
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      // Handle rate limiting specifically
      if (errorMessage.contains('rate_limit') || errorMessage.contains('wait')) {
        errorMessage = 'Please wait a few seconds before requesting another OTP';
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
      );
    } finally {
      // Always ensure loading state is cleared
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void reset() {
    _timer?.cancel();
    state = const OtpState();
  }
}