import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../onboarding/providers/vendor_provider.dart';

class BusinessDetailsScreen extends ConsumerStatefulWidget {
  const BusinessDetailsScreen({super.key});

  @override
  ConsumerState<BusinessDetailsScreen> createState() =>
      _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends ConsumerState<BusinessDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;

  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  void _initializeFields() {
    if (_isInitialized) return;

    final vendor = ref.read(vendorProvider).value;
    if (vendor != null) {
      _businessNameController.text = vendor.businessName ?? '';

      // Initialize time fields
      if (vendor.startTime != null) {
        final parts = vendor.startTime!.split(':');
        _openTime =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }

      if (vendor.closeTime != null) {
        final parts = vendor.closeTime!.split(':');
        _closeTime =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }

      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
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
      initialTime: isOpenTime
          ? _openTime ?? TimeOfDay.now()
          : _closeTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              dayPeriodBorderSide:
                  const BorderSide(color: AppTheme.primaryColor),
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

  Future<void> _updateBusinessDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final vendor = ref.read(vendorProvider).value;
      if (vendor == null) {
        throw Exception('Vendor data not available');
      }

      // Create updated vendor object
      final updatedVendor = vendor.copyWith(
        businessName: _businessNameController.text.trim(),
        startTime: _openTime != null ? _formatTimeOfDay(_openTime!) : null,
        closeTime: _closeTime != null ? _formatTimeOfDay(_closeTime!) : null,
      );

      // Use vendor service to update the business details
      final vendorService = ref.read(vendorServiceProvider);
      await vendorService.updateOrCreateVendor(updatedVendor);

      // Refresh the vendor data
      ref.invalidate(vendorProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business details updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update business details: ${e.toString()}'),
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
    final vendorAsync = ref.watch(vendorProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      body: vendorAsync.when(
        data: (vendor) {
          _initializeFields();
          return Column(
            children: [
              // Header
              _buildHeader(context),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // Business Information Section
                        _buildSectionHeader('Business Information'),
                        const SizedBox(height: 16),
                        _buildBusinessInformation(),

                        const SizedBox(height: 32),

                        // Business Hours Section
                        _buildSectionHeader('Business Hours'),
                        const SizedBox(height: 16),
                        _buildBusinessHours(),

                        const SizedBox(height: 32),

                        // Update Button
                        _buildUpdateButton(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load business data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => ref.invalidate(vendorProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 20, 20, 24),
      color: AppTheme.primaryColor,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const Expanded(
            child: Text(
              'Business Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }

  Widget _buildBusinessInformation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          // Business Name
          TextFormField(
            controller: _businessNameController,
            decoration: const InputDecoration(
              labelText: 'Business Name',
              prefixIcon: Icon(Icons.business_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your business name';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessHours() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          // Open Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Start Time slot',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectTime(true),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 20,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _openTime != null
                            ? _formatTimeTo12Hour(_openTime!)
                            : 'Select open time',
                        style: TextStyle(
                          fontSize: 16,
                          color: _openTime != null
                              ? AppTheme.textPrimaryColor
                              : AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Close Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'End time slot',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectTime(false),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 20,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _closeTime != null
                            ? _formatTimeTo12Hour(_closeTime!)
                            : 'Select close time',
                        style: TextStyle(
                          fontSize: 16,
                          color: _closeTime != null
                              ? AppTheme.textPrimaryColor
                              : AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateBusinessDetails,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Update Business Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
