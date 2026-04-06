import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/firebase_analytics_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/guest_auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/otp_provider.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _phoneFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isPhoneFocused = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();

    // Listen to focus changes
    _phoneFocusNode.addListener(() {
      setState(() {
        _isPhoneFocused = _phoneFocusNode.hasFocus;
      });
    });

    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAnalyticsService().logScreenView(screenName: 'phone_screen');
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
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      _fadeController.forward();
      _slideController.forward();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Track phone sign-in attempt
      FirebaseAnalyticsService().logFeatureUsed(
        featureName: 'phone_number_submit',
        screenName: 'phone_screen',
      );

      // Clear guest session before phone authentication
      await ref.read(guestAuthNotifierProvider.notifier).signOutGuest();

      final phoneNumber = "+91${_phoneController.text.trim()}";
      // ignore: avoid_print
      print('📱 Submitting phone number: $phoneNumber');

      final result =
          await ref.read(otpNotifierProvider.notifier).sendOtp(phoneNumber);

      if (!mounted) return;

      result.fold(
        (error) {
          // ignore: avoid_print
          print('❌ Phone sign-in error: $error');

          // Track phone sign-in error
          FirebaseAnalyticsService().logError(
            errorType: 'phone_signin_failed',
            errorMessage: error,
            screenName: 'phone_screen',
          );

          // If OTP was recently requested, still allow moving to verification.
          if (_canProceedToOtpScreen(error)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'OTP was recently requested. Please enter the latest OTP.'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            context.go('/verify-otp', extra: phoneNumber);
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
        (reqId) {
          // ignore: avoid_print
          print(
              '✅ OTP sent successfully, reqId: $reqId, navigating to verify-otp screen');

          // Track successful OTP sent
          FirebaseAnalyticsService().logCustomEvent(
            eventName: 'otp_sent',
            parameters: {
              'method': 'phone',
              'screen_name': 'phone_screen',
              'req_id': reqId,
            },
          );

          // ignore: avoid_print
          print(
              '🚀 Navigating to /verify-otp with phone: $phoneNumber, reqId: $reqId');
          context
              .go('/verify-otp', extra: {'phone': phoneNumber, 'reqId': reqId});
        },
      );
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('💥 Unexpected error in _handleSubmit: $e');
      // ignore: avoid_print
      print('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _canProceedToOtpScreen(String error) {
    final message = error.toLowerCase();
    return message.contains('too many otp requests') ||
        message.contains('please wait') ||
        message.contains('rate limit') ||
        message.contains('retry after');
  }

  Future<void> _handleGuestLogin() async {
    // Track guest login button click
    FirebaseAnalyticsService().logFeatureUsed(
      featureName: 'guest_login_button',
      screenName: 'phone_screen',
    );

    // Show business type selection dialog
    final businessType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Select Business Type',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose the type of service you want to explore:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.theaters, color: Color(0xFF667eea)),
              title: const Text('Private Theater'),
              subtitle: const Text('Mini theaters & screening rooms'),
              onTap: () => Navigator.of(context).pop('Private Theater'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.grey, width: 1),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.celebration, color: Color(0xFF667eea)),
              title: const Text('Event Decorator'),
              subtitle: const Text('Party & event decoration services'),
              onTap: () => Navigator.of(context).pop('Event Decorator'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.grey, width: 1),
              ),
            ),
          ],
        ),
      ),
    );

    if (businessType != null && mounted) {
      // Sign in as guest
      await ref
          .read(guestAuthNotifierProvider.notifier)
          .signInAsGuest(businessType);

      // Wait for SharedPreferences to save
      await Future.delayed(const Duration(milliseconds: 100));

      // Track guest login with business type
      FirebaseAnalyticsService().logCustomEvent(
        eventName: 'guest_login',
        parameters: {
          'business_type': businessType,
          'source': 'phone_screen',
        },
      );

      if (mounted) {
        // Refresh the guest provider to pick up the change
        final _ = ref.refresh(isGuestUserProvider);
        // Small delay to let the provider update before navigation
        await Future.delayed(const Duration(milliseconds: 50));
        if (mounted) {
          context.go('/home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: const Text(
          'Enter your mobile number',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section

                _buildPhoneInput(),

                const SizedBox(height: 24),

                // Continue Button
                _buildContinueButton(),

                const SizedBox(height: 30),

                // Terms and Privacy
                const Spacer(),
                _buildTermsText(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter your mobile number',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'We\'ll send you a verification code to confirm your number',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondaryColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Text(
            'Mobile Number',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Text(
            'We currently support only +91 Indian numbers',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _isPhoneFocused
                  ? AppTheme.primaryColor
                  : AppTheme.borderColor,
              width: _isPhoneFocused ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            children: [
              // Country Code Section
              Row(
                children: [
                  SizedBox(
                      width: 24,
                      height: 24,
                      child: Image.asset('assets/images/flag.png')),
                  const SizedBox(width: 8),
                  const Text(
                    '+91',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                width: 8,
              ),
              Container(
                height: 24,
                width: 1,
                color: AppTheme.borderColor,
              ),

              const SizedBox(width: 8),

              // Phone Number Input
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                  decoration: const InputDecoration(
                    hintText: '9876543210',
                    fillColor: Colors.transparent,
                    hintStyle: TextStyle(
                      color: AppTheme.textDisabledColor,
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your mobile number';
                    }
                    if (value.length != 10) {
                      return 'Please enter a valid 10-digit mobile number';
                    }
                    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                      return 'Please enter only numbers';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppTheme.textOnPrimary,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: _isLoading
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
                      'Continue',
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
      ),
    );
  }

  Widget _buildGuestLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _handleGuestLogin,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.primaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            SizedBox(width: 12),
            Text(
              'Continue as Guest',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
            children: [
              TextSpan(
                text: 'By continuing, you agree to our ',
              ),
              TextSpan(
                text: 'Terms of Service',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(text: ' and '),
              TextSpan(
                text: 'Privacy Policy',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
