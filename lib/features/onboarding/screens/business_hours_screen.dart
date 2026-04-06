import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_analytics_service.dart';
import '../../../core/config/supabase_config.dart';
import '../providers/vendor_provider.dart';
import '../models/vendor.dart';

class BusinessHoursScreen extends ConsumerStatefulWidget {
  const BusinessHoursScreen({super.key});

  @override
  ConsumerState<BusinessHoursScreen> createState() => _BusinessHoursScreenState();
}

class _BusinessHoursScreenState extends ConsumerState<BusinessHoursScreen>
    with TickerProviderStateMixin {
  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();

    // Track screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAnalyticsService().logScreenView(screenName: 'business_hours_screen');
      _loadExistingBusinessHours();
    });
  }

  Future<void> _loadExistingBusinessHours() async {
    try {
      final vendorService = ref.read(vendorServiceProvider);
      final currentUser = SupabaseConfig.client.auth.currentUser;
      
      if (currentUser != null) {
        final vendor = await vendorService.getVendorByUserId(currentUser.id);
        
        if (vendor != null && vendor.startTime != null && vendor.closeTime != null) {
          setState(() {
            _openTime = _parseTimeString(vendor.startTime!);
            _closeTime = _parseTimeString(vendor.closeTime!);
          });
        }
      }
    } catch (e) {
// TODO: Replace with proper logging - print('Failed to load existing business hours: $e');
    }
  }

  TimeOfDay _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
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
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatTimeTo12Hour(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    
    if (hour == 0) {
      return '12:$minute AM';
    } else if (hour < 12) {
      return '$hour:$minute AM';
    } else if (hour == 12) {
      return '12:$minute PM';
    } else {
      return '${hour - 12}:$minute PM';
    }
  }

  Future<void> _selectTime(bool isOpenTime) async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: isOpenTime ? _openTime ?? TimeOfDay.now() : _closeTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              dayPeriodBorderSide: const BorderSide(color: AppTheme.primaryColor),
              dayPeriodColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              dayPeriodTextColor: AppTheme.primaryColor,
              hourMinuteColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              hourMinuteTextColor: AppTheme.primaryColor,
              dialHandColor: AppTheme.primaryColor,
              dialBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              dialTextColor: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        if (isOpenTime) {
          _openTime = selectedTime;
        } else {
          _closeTime = selectedTime;
        }
      });
    }
  }

  Future<void> _saveBusinessHours() async {
    if (_openTime == null || _closeTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both open and close times'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Track business hours submission
      FirebaseAnalyticsService().logFeatureUsed(
        featureName: 'business_hours_submit',
        screenName: 'business_hours_screen',
      );

      // Save business hours to vendor profile
      final vendorService = ref.read(vendorServiceProvider);
      final startTime = _formatTimeOfDay(_openTime!);
      final closeTime = _formatTimeOfDay(_closeTime!);
      
      await vendorService.updateOrCreateVendor(
        Vendor(
          startTime: startTime,
          closeTime: closeTime,
        ),
      );

      if (mounted) {
        // Navigate to the next screen in the onboarding flow
        context.go('/vendor-onboarding');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save business hours: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Header
                  _buildHeader(),
                  
                  const SizedBox(height: 40),
                  
                  // Business Hours Section
                  _buildBusinessHoursSection(),
                  
                  const SizedBox(height: 40),
                  
                  // Continue Button
                  _buildContinueButton(),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.access_time,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Business Hours',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Set your working hours',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBusinessHoursSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'When are you available?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This helps customers know when they can contact you',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Open Time
          _buildTimeField(
            title: 'Open Time',
            time: _openTime,
            onTap: () => _selectTime(true),
            icon: Icons.wb_sunny_outlined,
          ),
          
          const SizedBox(height: 20),
          
          // Close Time
          _buildTimeField(
            title: 'Close Time',
            time: _closeTime,
            onTap: () => _selectTime(false),
            icon: Icons.nightlight_outlined,
          ),
          
          const SizedBox(height: 20),
          
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can update these hours later in your business settings',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeField({
    required String title,
    required TimeOfDay? time,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  time != null ? _formatTimeTo12Hour(time) : 'Select $title.toLowerCase()',
                  style: TextStyle(
                    fontSize: 16,
                    color: time != null ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveBusinessHours,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
    );
  }
}
