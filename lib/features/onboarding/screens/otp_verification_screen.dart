import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:sylonow_vendor/core/theme/app_theme.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/services/firebase_analytics_service.dart';
import '../../../core/providers/guest_auth_provider.dart';
import '../controllers/otp_controller.dart';
import '../helpers/otp_helper.dart';
import '../providers/otp_provider.dart';
import '../providers/vendor_provider.dart';
import '../../splash/providers/splash_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String reqId;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.reqId,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // Defer the initial OTP sending to avoid provider modification during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Track screen view
        FirebaseAnalyticsService()
            .logScreenView(screenName: 'otp_verification_screen');

        // Set the reqId received from PhoneScreen
        ref.read(otpNotifierProvider.notifier).setReqId(widget.reqId);

        // If we don't have a reqId (shouldn't happen), then send initial OTP
        if (widget.reqId.isEmpty) {
          _sendInitialOtpSafely();
        } else {
          print(
              '🟡 OTP already sent via PhoneScreen, skipping initial send in VerifyScreen');
        }
      }
    });
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _handleBack() async {
    // Check if widget is mounted before showing dialog
    if (!mounted) return;

    // Show confirmation dialog before going back
    final shouldGoBack = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Go Back?'),
          content: const Text(
            'If you go back, you will need to request a new OTP. Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Go Back',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
        );
      },
    );

    // If user confirmed, clean up and navigate back
    if (shouldGoBack == true) {
      // Check mounted again after dialog dismissal
      if (!mounted) return;

      try {
        ref.read(otpControllerProvider.notifier).reset();
      } catch (e) {
        // Ignore error if widget was disposed
      }

      if (mounted) {
        context.go('/phone');
      }
    }
  }

  Future<void> _sendInitialOtp() async {
    await ref
        .read(otpControllerProvider.notifier)
        .sendInitialOtp(widget.phoneNumber);
  }

  Future<void> _sendInitialOtpSafely() async {
    try {
      // Check if OTP was already sent recently to prevent rate limiting
      final controller = ref.read(otpControllerProvider.notifier);
      final currentState = ref.read(otpControllerProvider);

      // If timer is still active from previous session, don't send again
      if (currentState.isTimerActive && currentState.remainingSeconds > 50) {
// TODO: Replace with proper logging - print('🟡 OTP already sent recently, skipping initial send');
        return;
      }

      await controller.sendInitialOtp(widget.phoneNumber);
    } catch (e) {
// Warning print removed
      // Don't show error to user for initial send failures
    }
  }

  Future<void> _verifyOtp() async {
    if (_isVerifying) return;

    setState(() => _isVerifying = true);

    try {
      // Track OTP verification attempt
      FirebaseAnalyticsService().logFeatureUsed(
        featureName: 'otp_verification_submit',
        screenName: 'otp_verification_screen',
      );

      // ... existing code ...
      // (Skipping connection tests for brevity in search/replace)

      final controller = ref.read(otpControllerProvider.notifier);
      final isVerified = await controller.verifyOtp(widget.phoneNumber);

      if (isVerified && mounted) {
        try {
          // OTP verified successfully - proceed with navigation
          print('🟢 OTP verified, proceeding with navigation');

          // Always proceed since OTP is verified
          // Clear guest session after successful authentication
          print('🔵 OTP Success: Clearing guest session...');
          await ref.read(guestAuthNotifierProvider.notifier).signOutGuest();

          // Wait for SharedPreferences to be cleared
          await Future.delayed(const Duration(milliseconds: 100));

          // Invalidate the guest provider to refresh the state immediately
          ref.invalidate(isGuestUserProvider);
          ref.invalidate(guestAuthNotifierProvider);

          // Wait for the guest provider to refresh and pick up the cleared state
          await Future.delayed(const Duration(milliseconds: 150));

          // Verify guest state is cleared
          final isStillGuest = await ref.read(isGuestUserProvider.future);
          print('🔵 OTP Success: Guest state after clear: $isStillGuest');
          print('🔵 OTP Success: Phone number verified: ${widget.phoneNumber}');

          // Track successful phone login
          FirebaseAnalyticsService().logLogin(method: 'phone');

          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('OTP verified successfully!'),
                backgroundColor: AppTheme.successColor,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }

          // Force refresh vendor data after successful login
          try {
            // Use invalidate to trigger a complete rebuild of the vendor provider
            ref.invalidate(vendorProvider);

            // Wait a bit for the invalidation to take effect
            await Future.delayed(const Duration(milliseconds: 500));

            // Now manually refresh to ensure we get fresh data
            await ref.read(vendorProvider.notifier).refreshVendor();
          } catch (e) {
            // Ignore refresh errors
          }

          // Force navigation to trigger router redirect logic
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) {
            print('🔵 OTP Success: Resetting splash animation state');
            // Reset splash animation state so splash screen can re-run and trigger redirect
            ref.read(splashAnimationCompletedProvider.notifier).state = false;

            print(
                '🔵 OTP Success: Navigating to splash to trigger router redirect');
            context.go('/splash');
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isVerifying = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Authentication service error: $e'),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else if (mounted) {
        // Verification failed
        setState(() => _isVerifying = false);
        final errorMessage = ref.read(otpControllerProvider).errorMessage ??
            'Invalid OTP. Please try again.';
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        OtpHelper.showErrorSnackBar(context,
            'Authentication service error. Please restart the app and try again.');
      }
    }
  }

  Future<void> _resendOtp() async {
    // Track OTP resend
    FirebaseAnalyticsService().logFeatureUsed(
      featureName: 'otp_resend',
      screenName: 'otp_verification_screen',
    );

    // Enhanced debugging for initialization issues
// TODO: Replace with proper logging - print('🔍 OTP Resend Debug Info:');
// TODO: Replace with proper logging - print('  - SupabaseConfig.isInitialized: ${SupabaseConfig.isInitialized}');

    // Check if Supabase is actually working
    final isWorking = await SupabaseConfig.isSupabaseWorking();
// TODO: Replace with proper logging - print('  - SupabaseConfig.isSupabaseWorking: $isWorking');

    if (!isWorking) {
// TODO: Replace with proper logging - print('🔴 Supabase not working - attempting state sync...');

      final syncSuccess = await SupabaseConfig.syncState();
      if (!syncSuccess) {
// Error print removed
        if (mounted) {
          OtpHelper.showErrorSnackBar(context,
              'Authentication service is not available. Please restart the app and try again.');
        }
        return;
      }
// TODO: Replace with proper logging - print('🟢 Supabase state sync successful');
    }

    try {
      final controller = ref.read(otpControllerProvider.notifier);
      await controller.resendOtp(widget.phoneNumber);

      final state = ref.read(otpControllerProvider);
      if (state.errorMessage == null && mounted) {
        OtpHelper.showSuccessSnackBar(
            context, 'OTP has been resent successfully!');
      }
    } catch (e) {
// Error print removed
      if (mounted) {
        OtpHelper.showErrorSnackBar(context,
            'Failed to resend OTP. Please check your connection and try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpControllerProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    // Listen for errors and show them
    ref.listen<OtpState>(otpControllerProvider, (previous, next) {
      if (next.errorMessage != null && mounted) {
        OtpHelper.showErrorSnackBar(context, next.errorMessage!);
        ref.read(otpControllerProvider.notifier).clearError();
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.grey.shade50,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: _handleBack,
          ),
        ),
        body: SafeArea(
          child: AutofillGroup(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth > 400 ? 24.0 : 16.0,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              SizedBox(height: isSmallScreen ? 5 : 10),
                              _buildHeader(isSmallScreen),
                              SizedBox(height: isSmallScreen ? 16 : 30),
                              _buildPhoneIllustration(isSmallScreen),
                              SizedBox(height: isSmallScreen ? 16 : 30),
                              _buildTimerChip(otpState),
                              SizedBox(height: isSmallScreen ? 20 : 30),
                              _buildOtpInput(otpState, screenWidth),
                              SizedBox(height: isSmallScreen ? 16 : 24),
                              _buildResendButton(otpState),
                              const Spacer(),
                              _buildVerifyButton(otpState),
                              SizedBox(height: isSmallScreen ? 16 : 30),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Column(
      children: [
        Text(
          'Verify mobile number',
          style: TextStyle(
            fontSize: isSmallScreen ? 24 : 28,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'We have sent a verification code to\n'),
              TextSpan(
                text: OtpHelper.maskPhoneNumber(widget.phoneNumber),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: '. Enter the code in below boxes'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneIllustration(bool isSmallScreen) {
    final size = isSmallScreen ? 140.0 : 180.0;
    return SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          'assets/images/hand_otp.png',
          fit: BoxFit.contain,
        ));
  }

  Widget _buildTimerChip(OtpState otpState) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: otpState.isTimerActive
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: otpState.isTimerActive
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 18,
            color: otpState.isTimerActive ? AppTheme.primaryColor : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            otpState.isTimerActive
                ? '${OtpHelper.formatTime(otpState.remainingSeconds)} seconds'
                : 'Timer expired',
            style: TextStyle(
              fontSize: 16,
              color:
                  otpState.isTimerActive ? AppTheme.primaryColor : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpInput(OtpState otpState, double screenWidth) {
    // Calculate responsive field dimensions for 6-digit OTP
    final fieldWidth = screenWidth > 400 ? 48.0 : (screenWidth - 80) / 6;
    final fieldHeight = screenWidth > 400 ? 58.0 : 52.0;

    return SizedBox(
      width: double.infinity,
      child: PinCodeTextField(
        appContext: context,
        length: 6,
        animationType: AnimationType.fade,
        pinTheme: PinTheme(
          shape: PinCodeFieldShape.box,
          borderRadius: BorderRadius.circular(12),
          fieldHeight: fieldHeight,
          fieldWidth: fieldWidth,
          borderWidth: 2,
          activeColor: AppTheme.primaryColor,
          inactiveColor: AppTheme.primaryColor.withValues(alpha: 0.3),
          selectedColor: AppTheme.primaryColor,
          activeFillColor: Colors.white,
          inactiveFillColor: Colors.white,
          selectedFillColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        ),
        textStyle: TextStyle(
          fontSize: screenWidth > 400 ? 22 : 20,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
        animationDuration: const Duration(milliseconds: 300),
        backgroundColor: Colors.transparent,
        enableActiveFill: true,
        cursorColor: AppTheme.primaryColor,
        keyboardType: TextInputType.number,
        // Enable OTP autofill
        enablePinAutofill: true,
        autoFocus: true,
        // Configure text input for SMS autofill
        textInputAction: TextInputAction.done,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        boxShadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        onChanged: (value) {
          ref.read(otpControllerProvider.notifier).updateOtp(value);
          // Auto-verify when 6 digits are entered via autofill
          if (value.length == 6) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && value.length == 6) {
                _verifyOtp();
              }
            });
          }
        },
        onCompleted: (pin) => _verifyOtp(),
        beforeTextPaste: (text) {
          // Allow pasting numeric values only and auto-extract OTP from SMS
          if (text != null) {
            // Extract 6-digit number from SMS text
            final otpMatch = RegExp(r'\b\d{6}\b').firstMatch(text);
            if (otpMatch != null) {
              final extractedOtp = otpMatch.group(0)!;
              // Update the OTP in controller
              ref.read(otpControllerProvider.notifier).updateOtp(extractedOtp);
              return true;
            }
            // Fallback to digits only
            final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
            return digitsOnly.length <= 6;
          }
          return false;
        },
      ),
    );
  }

  Widget _buildResendButton(OtpState otpState) {
    return TextButton(
      onPressed: otpState.isTimerActive ? null : _resendOtp,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        'Resend OTP',
        style: TextStyle(
          fontSize: 16,
          color: otpState.isTimerActive ? Colors.grey : AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildVerifyButton(OtpState otpState) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: otpState.isLoading ? null : _verifyOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: otpState.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Verify & Proceed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
