import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/services/firebase_notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/vendor_onboarding_controller.dart';
import '../providers/vendor_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/image_upload_widget.dart';
import '../widgets/map_location_picker.dart';

class VendorOnboardingScreen extends ConsumerStatefulWidget {
  const VendorOnboardingScreen({super.key});

  @override
  ConsumerState<VendorOnboardingScreen> createState() =>
      _VendorOnboardingScreenState();
}

class _VendorOnboardingScreenState
    extends ConsumerState<VendorOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Form Controllers
  final _fullNameController = TextEditingController();
  final _serviceAreaController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _aadhaarNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankIfscController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _additionalAddressController = TextEditingController();
  final _fssaiLicenseController = TextEditingController();

  String? _selectedVendorType;
  int _currentPage = 0;

  // Location data
  double? _latitude;
  double? _longitude;
  bool _isLocationLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _serviceAreaController.dispose();
    _pincodeController.dispose();
    _businessNameController.dispose();
    _aadhaarNumberController.dispose();
    _bankNameController.dispose();
    _accountHolderNameController.dispose();
    _bankAccountController.dispose();
    _bankIfscController.dispose();
    _gstNumberController.dispose();
    _additionalAddressController.dispose();
    _fssaiLicenseController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable location services in your device settings.';
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Show prominent disclosure dialog before requesting permission
        final shouldRequestPermission = await _showLocationPermissionDialog();
        if (!shouldRequestPermission) {
          throw 'Location permission is required to automatically fill your service area.';
        }

        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permission denied. Please allow location access to use this feature.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied. Please enable location access in app settings.';
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      // Get address from coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark placemark = placemarks.first;
          String address = '';

          if (placemark.subLocality != null &&
              placemark.subLocality!.isNotEmpty) {
            address += placemark.subLocality!;
          }

          if (placemark.locality != null && placemark.locality!.isNotEmpty) {
            if (address.isNotEmpty) address += ', ';
            address += placemark.locality!;
          }

          if (placemark.administrativeArea != null &&
              placemark.administrativeArea!.isNotEmpty) {
            if (address.isNotEmpty) address += ', ';
            address += placemark.administrativeArea!;
          }

          if (address.isNotEmpty) {
            _serviceAreaController.text = address;
          }

          // Update pincode if available
          if (placemark.postalCode != null &&
              placemark.postalCode!.isNotEmpty) {
            _pincodeController.text = placemark.postalCode!;
          }
        }
      } catch (e) {
// TODO: Replace with proper logging - print('Failed to get address from coordinates: $e');
        // Still save coordinates even if reverse geocoding fails
        _serviceAreaController.text =
            'Current Location (${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)})';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.location_on, color: Colors.white),
                SizedBox(width: 12),
                Text('Current location fetched successfully!'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(e.toString())),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.of(context).push<MapLocationResult>(
      MaterialPageRoute(
        builder: (_) => MapLocationPicker(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;

        // Build service area from area + city + state
        final parts = <String>[
          if (result.area != null && result.area!.isNotEmpty) result.area!,
          if (result.city != null && result.city!.isNotEmpty) result.city!,
          if (result.state != null && result.state!.isNotEmpty) result.state!,
        ];
        _serviceAreaController.text =
            parts.isNotEmpty ? parts.join(', ') : result.address;

        if (result.pincode != null && result.pincode!.isNotEmpty) {
          _pincodeController.text = result.pincode!;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.location_on, color: Colors.white),
              SizedBox(width: 12),
              Text('Location selected from map!'),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<bool> _showLocationPermissionDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppTheme.primaryColor,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Location Permission',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sylonow Partner needs access to your location to:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildPermissionReason(
                Icons.pin_drop,
                'Automatically fill your service area',
                'We\'ll use your current location to help set up your service area during onboarding.',
              ),
              const SizedBox(height: 12),
              _buildPermissionReason(
                Icons.people,
                'Help customers find you',
                'Your location helps nearby customers discover your services.',
              ),
              const SizedBox(height: 12),
              _buildPermissionReason(
                Icons.verified_user,
                'Verify your business location',
                'This helps us confirm your business operates in the area you specify.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'We only access your location when you tap "Use Current Location"',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Not Now',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Allow Location',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Widget _buildPermissionReason(
      IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(vendorOnboardingControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleLogout,
        ),
        title: const Text(
          'Vendor Registration',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / 4,
              backgroundColor: AppTheme.dividerColor,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentPage = index),
          children: [
            _buildBasicInfoPage(),
            _buildBusinessInfoPage(),
            _buildBankAccountPage(),
            _buildDocumentsPage(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_currentPage > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.primaryColor),
                  ),
                  child: const Text(
                    'Previous',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (_currentPage > 0) const SizedBox(width: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: onboardingState.isLoading ? null : _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppTheme.textOnPrimary,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: onboardingState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _currentPage == 3 ? 'Submit Application' : 'Next',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Basic Information',
            'Tell us about yourself',
            Icons.person,
          ),
          const SizedBox(height: 24),

          // Profile Picture Upload
          _buildProfilePictureSection(),
          const SizedBox(height: 24),

          CustomTextField(
            controller: _fullNameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Full name is required';
              return null;
            },
          ),
          const SizedBox(height: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _serviceAreaController,
                      label: 'Service Area',
                      hint: 'e.g., Bangalore, JP Nagar',
                      prefixIcon: Icons.location_on_outlined,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Service area is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed:
                        _isLocationLoading ? null : _fetchCurrentLocation,
                    icon: _isLocationLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.my_location, size: 20),
                    label:
                        Text(_isLocationLoading ? 'Getting...' : 'Use Current'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'We\'ll use your current location to help customers find you nearby',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _openMapPicker,
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text(
                      'Pick on Map',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _pincodeController,
            label: 'Pincode',
            hint: 'Enter your pincode',
            prefixIcon: Icons.pin_drop_outlined,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Pincode is required';
              if (value!.length != 6) return 'Enter a valid 6-digit pincode';
              return null;
            },
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _additionalAddressController,
            label: 'Additional Address Detail',
            hint: 'e.g., Landmark, Building name, Floor number',
            prefixIcon: Icons.home_outlined,
            maxLines: 2,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Additional address detail is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          _buildVendorTypeSelection(),
        ],
      ),
    );
  }

  Widget _buildBusinessPictureSection() {
    final onboardingState = ref.watch(vendorOnboardingControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Business Picture',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload a photo of your shop or office',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _pickBusinessImage,
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.primarySurface,
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: onboardingState.businessImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        onboardingState.businessImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 32,
                          color: AppTheme.textSecondaryColor,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add Business Photo',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFssaiLicensePictureSection() {
    final onboardingState = ref.watch(vendorOnboardingControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FSSAI License Picture (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload a photo of your FSSAI license certificate',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _pickFssaiLicenseImage,
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.primarySurface,
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: onboardingState.fssaiLicenseImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        onboardingState.fssaiLicenseImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 32,
                          color: AppTheme.textSecondaryColor,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add FSSAI License Photo',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business Details Section
          _buildSectionHeader(
            'Business Details',
            'Provide your business information',
            Icons.business,
          ),
          const SizedBox(height: 16),
          // Business Picture Upload
          _buildBusinessPictureSection(),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _businessNameController,
            label: 'Business Name',
            hint: 'Enter your business name',
            prefixIcon: Icons.business_outlined,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Business name is required';
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _aadhaarNumberController,
            label: 'Aadhaar Number',
            hint: 'Enter 12-digit Aadhaar number',
            prefixIcon: Icons.credit_card_outlined,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Aadhaar number is required';
              if (value!.length != 12) {
                return 'Enter a valid 12-digit Aadhaar number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _gstNumberController,
            label: 'GST Number (Optional)',
            hint: 'Enter GST number if applicable',
            prefixIcon: Icons.receipt_outlined,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _fssaiLicenseController,
            label: 'FSSAI License Number (Optional)',
            hint: 'Enter 14-digit FSSAI license number',
            prefixIcon: Icons.verified_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          // FSSAI License Picture Upload
          _buildFssaiLicensePictureSection(),
        ],
      ),
    );
  }

  Widget _buildBankAccountPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bank Account Details Section
          _buildSectionHeader(
            'Bank Account Details',
            'Provide your bank information as per passbook',
            Icons.account_balance,
          ),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _bankNameController,
            label: 'Bank Name',
            hint: 'Enter your bank name',
            prefixIcon: Icons.account_balance_outlined,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Bank name is required';
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _accountHolderNameController,
            label: 'Account Holder Name',
            hint: 'Enter name as per passbook',
            prefixIcon: Icons.person_outlined,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Account holder name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _bankAccountController,
            label: 'Bank Account Number',
            hint: 'Enter your bank account number',
            prefixIcon: Icons.numbers_outlined,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Bank account number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _bankIfscController,
            label: 'Bank IFSC Code',
            hint: 'Enter IFSC code',
            prefixIcon: Icons.code_outlined,
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'IFSC code is required';
              if (value!.length != 11) {
                return 'Enter a valid 11-character IFSC code';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsPage() {
    final onboardingState = ref.watch(vendorOnboardingControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Documents Upload',
            'Upload required documents for verification',
            Icons.upload_file,
          ),
          const SizedBox(height: 24),
          ImageUploadWidget(
            title: 'Aadhaar Front Image',
            subtitle: 'Upload clear image of Aadhaar front side',
            image: onboardingState.aadhaarFrontImage,
            documentType: 'aadhaar_front',
            onImageSelected: (image) {
              ref
                  .read(vendorOnboardingControllerProvider.notifier)
                  .setAadhaarFrontImage(image);
            },
            onImageUploaded: (url) {
              ref
                  .read(vendorOnboardingControllerProvider.notifier)
                  .setAadhaarFrontImageUrl(url);
            },
          ),
          const SizedBox(height: 20),
          ImageUploadWidget(
            title: 'Aadhaar Back Image',
            subtitle: 'Upload clear image of Aadhaar back side',
            image: onboardingState.aadhaarBackImage,
            documentType: 'aadhaar_back',
            onImageSelected: (image) {
              ref
                  .read(vendorOnboardingControllerProvider.notifier)
                  .setAadhaarBackImage(image);
            },
            onImageUploaded: (url) {
              ref
                  .read(vendorOnboardingControllerProvider.notifier)
                  .setAadhaarBackImageUrl(url);
            },
          ),
          const SizedBox(height: 20),
          ImageUploadWidget(
            title: 'PAN Card Image',
            subtitle: 'Upload clear image of PAN card',
            image: onboardingState.panCardImage,
            documentType: 'pan_card',
            onImageSelected: (image) {
              ref
                  .read(vendorOnboardingControllerProvider.notifier)
                  .setPanCardImage(image);
            },
            onImageUploaded: (url) {
              ref
                  .read(vendorOnboardingControllerProvider.notifier)
                  .setPanCardImageUrl(url);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primarySurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePictureSection() {
    final onboardingState = ref.watch(vendorOnboardingControllerProvider);

    return Center(
      child: GestureDetector(
        onTap: _pickProfileImage,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primarySurface,
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: onboardingState.profileImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: Image.file(
                    onboardingState.profileImage!,
                    fit: BoxFit.cover,
                  ),
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 32,
                      color: AppTheme.textSecondaryColor,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add Photo',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        final File imageFile = File(image.path);

        // Try to upload immediately to Supabase
        try {
          final user = SupabaseConfig.client.auth.currentUser;
          if (user != null) {
            final fileName =
                'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final filePath = '${user.id}/$fileName';

// TODO: Replace with proper logging - print('🔵 Uploading profile image to Supabase...');

            await SupabaseConfig.client.storage.from('profile-pictures').upload(
                filePath, imageFile,
                fileOptions: const FileOptions(upsert: true));

            final String publicUrl = SupabaseConfig.client.storage
                .from('profile-pictures')
                .getPublicUrl(filePath);

// TODO: Replace with proper logging - print('🟢 Profile image uploaded successfully: $publicUrl');

            ref
                .read(vendorOnboardingControllerProvider.notifier)
                .setProfileImageUrl(publicUrl);

            // Keep the local file for preview
            ref
                .read(vendorOnboardingControllerProvider.notifier)
                .setProfileImage(imageFile);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Profile photo uploaded successfully!'),
                    ],
                  ),
                  backgroundColor: AppTheme.successColor,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            }

            return;
          }
        } catch (uploadError) {
// TODO: Replace with proper logging - print('🔴 Profile image upload failed, using local storage: $uploadError');
        }

        // Fallback to local storage if upload fails
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName =
            'vendor_profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
        final String permanentPath =
            path.join(appDir.path, 'vendor_uploads', fileName);

        // Create directory if it doesn't exist
        await Directory(path.dirname(permanentPath)).create(recursive: true);

        // Copy the file to permanent location
        final File permanentFile = await File(image.path).copy(permanentPath);

        // Verify the copy was successful
        if (!await permanentFile.exists()) {
          throw Exception('Failed to save profile image to persistent storage');
        }

        final persistentSize = await permanentFile.length();
        if (persistentSize == 0) {
          throw Exception('Profile image file became corrupted during save');
        }

// TODO: Replace with proper logging - print('📸 Profile image copied to permanent location: $permanentPath ($persistentSize bytes)');

        ref
            .read(vendorOnboardingControllerProvider.notifier)
            .setProfileImage(permanentFile);
      }
    } catch (e) {
// TODO: Replace with proper logging - print('📸 Error picking profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _pickBusinessImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);

        // Try to upload immediately to Supabase
        try {
          final user = SupabaseConfig.client.auth.currentUser;
          if (user != null) {
            final fileName =
                'business_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final filePath = '${user.id}/$fileName';

// TODO: Replace with proper logging - print('🔵 Uploading business image to Supabase...');

            await SupabaseConfig.client.storage
                .from('business-pictures')
                .upload(filePath, imageFile,
                    fileOptions: const FileOptions(upsert: true));

            final String publicUrl = SupabaseConfig.client.storage
                .from('business-pictures')
                .getPublicUrl(filePath);

            print('🟢 Business image uploaded successfully!');
            print('🔍 Business Picture URL: $publicUrl');

            ref
                .read(vendorOnboardingControllerProvider.notifier)
                .setBusinessImageUrl(publicUrl);

            print('🔍 Business image URL set in state: $publicUrl');

            // Keep the local file for preview
            ref
                .read(vendorOnboardingControllerProvider.notifier)
                .setBusinessImage(imageFile);

            print('🔍 Business image file set in state');

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Business photo uploaded successfully!'),
                    ],
                  ),
                  backgroundColor: AppTheme.successColor,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            }

            return;
          }
        } catch (uploadError) {
// TODO: Replace with proper logging - print('🔴 Business image upload failed, using local storage: $uploadError');
        }

        // Fallback to local storage if upload fails
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName =
            'vendor_business_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
        final String permanentPath =
            path.join(appDir.path, 'vendor_uploads', fileName);

        // Create directory if it doesn't exist
        await Directory(path.dirname(permanentPath)).create(recursive: true);

        // Copy the file to permanent location
        final File permanentFile = await File(image.path).copy(permanentPath);

        // Verify the copy was successful
        if (!await permanentFile.exists()) {
          throw Exception(
              'Failed to save business image to persistent storage');
        }

        final persistentSize = await permanentFile.length();
        if (persistentSize == 0) {
          throw Exception('Business image file became corrupted during save');
        }

// TODO: Replace with proper logging - print('📸 Business image copied to permanent location: $permanentPath ($persistentSize bytes)');

        ref
            .read(vendorOnboardingControllerProvider.notifier)
            .setBusinessImage(permanentFile);
      }
    } catch (e) {
// TODO: Replace with proper logging - print('📸 Error picking business image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select business image: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _pickFssaiLicenseImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);

        // Try to upload immediately to Supabase
        try {
          final user = SupabaseConfig.client.auth.currentUser;
          if (user != null) {
            final fileName =
                'fssai_license_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final filePath = '${user.id}/$fileName';

            await SupabaseConfig.client.storage.from('vendor-documents').upload(
                filePath, imageFile,
                fileOptions: const FileOptions(upsert: true));

            final String publicUrl = SupabaseConfig.client.storage
                .from('vendor-documents')
                .getPublicUrl(filePath);

            ref
                .read(vendorOnboardingControllerProvider.notifier)
                .setFssaiLicenseImageUrl(publicUrl);

            // Keep the local file for preview
            ref
                .read(vendorOnboardingControllerProvider.notifier)
                .setFssaiLicenseImage(imageFile);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('FSSAI license photo uploaded successfully!'),
                    ],
                  ),
                  backgroundColor: AppTheme.successColor,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            }

            return;
          }
        } catch (uploadError) {
          // Fallback to local storage if upload fails
        }

        // Fallback to local storage if upload fails
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName =
            'vendor_fssai_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
        final String permanentPath =
            path.join(appDir.path, 'vendor_uploads', fileName);

        // Create directory if it doesn't exist
        await Directory(path.dirname(permanentPath)).create(recursive: true);

        // Copy the file to permanent location
        final File permanentFile = await File(image.path).copy(permanentPath);

        // Verify the copy was successful
        if (!await permanentFile.exists()) {
          throw Exception(
              'Failed to save FSSAI license image to persistent storage');
        }

        final persistentSize = await permanentFile.length();
        if (persistentSize == 0) {
          throw Exception(
              'FSSAI license image file became corrupted during save');
        }

        ref
            .read(vendorOnboardingControllerProvider.notifier)
            .setFssaiLicenseImage(permanentFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select FSSAI license image: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      // Show confirmation dialog
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Logout'),
            content: const Text(
                'Are you sure you want to logout? Your progress will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style:
                    TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
                child: const Text('Logout'),
              ),
            ],
          );
        },
      );

      if (shouldLogout == true && mounted) {
        // Sign out from Supabase (this will clear the token)
        await SupabaseConfig.client.auth.signOut();

        // Clear any local state
        ref.invalidate(vendorProvider);
        ref.invalidate(vendorOnboardingControllerProvider);

        // Navigate to login/welcome screen
        if (mounted) {
          context.go('/welcome');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _handleNext() {
    if (_currentPage < 3) {
      if (_validateCurrentPage()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _submitApplication();
    }
  }

  String _getVendorTypeLabel(String vendorType) {
    switch (vendorType) {
      case 'theater_provider':
        return 'Theater Provider';
      case 'decoration_provider':
      default:
        return 'Decoration Provider';
    }
  }

  Future<void> _onVendorTypeSelected(String vendorType) async {
    if (_selectedVendorType == vendorType) return;

    final vendorTypeLabel = _getVendorTypeLabel(vendorType);
    final isConfirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Vendor Type'),
          content: Text(
            'Are you sure you selected $vendorTypeLabel? This should match your app type.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Yes, Continue'),
            ),
          ],
        );
      },
    );

    if (!mounted || isConfirmed != true) return;

    setState(() {
      _selectedVendorType = vendorType;
    });
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0:
        final isFormValid = _formKey.currentState?.validate() ?? false;
        if (!isFormValid) return false;

        // Check vendor type selection
        if (_selectedVendorType == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select your vendor type'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          return false;
        }
        return true;
      case 1:
        return _formKey.currentState?.validate() ?? false;
      case 2:
        return _formKey.currentState?.validate() ?? false;
      case 3:
        final state = ref.read(vendorOnboardingControllerProvider);
        if ((state.aadhaarFrontImage == null &&
                state.aadhaarFrontImageUrl == null) ||
            (state.aadhaarBackImage == null &&
                state.aadhaarBackImageUrl == null) ||
            (state.panCardImage == null && state.panCardImageUrl == null)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please upload all required documents'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _submitApplication() async {
    if (!_validateCurrentPage()) return;

    final controller = ref.read(vendorOnboardingControllerProvider.notifier);

    // Get FCM token from Firebase notification service
    String? fcmToken;
    try {
      final firebaseService = FirebaseNotificationService();
      fcmToken = firebaseService.fcmToken;
// TODO: Replace with proper logging - print('🔑 FCM Token for vendor signup: $fcmToken');
    } catch (e) {
// Warning print removed
      // Continue without FCM token - it will be updated later when notifications are initialized
    }

    final success = await controller.submitVendorApplication(
      fullName: _fullNameController.text.trim(),
      serviceArea: _serviceAreaController.text.trim(),
      pincode: _pincodeController.text.trim(),
      serviceType: 'sylonow_vendor',
      vendorType: _selectedVendorType!,
      businessName: _businessNameController.text.trim(),
      aadhaarNumber: _aadhaarNumberController.text.trim(),
      bankAccountNumber: _bankAccountController.text.trim(),
      bankIfscCode: _bankIfscController.text.trim(),
      gstNumber: _gstNumberController.text.trim().isEmpty
          ? null
          : _gstNumberController.text.trim(),
      fssaiLicenseNumber: _fssaiLicenseController.text.trim().isEmpty
          ? null
          : _fssaiLicenseController.text.trim(),
      bankName: _bankNameController.text.trim().isEmpty
          ? null
          : _bankNameController.text.trim(),
      accountHolderName: _accountHolderNameController.text.trim().isEmpty
          ? null
          : _accountHolderNameController.text.trim(),
      additionalAddress: _additionalAddressController.text.trim(),
      fcmToken: fcmToken,
      latitude: _latitude,
      longitude: _longitude,
    );

    // Check if widget is still mounted before proceeding
    if (!mounted) {
// Warning print removed
      return;
    }

    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Application submitted successfully!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Wait for success message to be visible
      await Future.delayed(const Duration(milliseconds: 1000));

      // Check mounted again before continuing
      if (!mounted) {
// Warning print removed
        return;
      }

      try {
        // Force refresh the vendor provider and wait for it to complete
// TODO: Replace with proper logging - print('🔄 Refreshing vendor state after successful submission...');
        await ref.read(vendorProvider.notifier).refreshVendor();

        // Check mounted again after async operation
        if (!mounted) {
// Warning print removed
          return;
        }

        // Wait a bit more to ensure state propagation
        await Future.delayed(const Duration(milliseconds: 500));

        // Final mounted check before navigation
        if (!mounted) {
// Warning print removed
          return;
        }

        // Navigate to pending verification directly instead of letting router decide
// TODO: Replace with proper logging - print('🚀 Navigating to pending verification...');
        context.go('/pending-verification');
      } catch (e) {
// TODO: Replace with proper logging - print('🔴 Error during post-submission processing: $e');
        // If there's an error, still try to navigate if mounted
        if (mounted) {
          context.go('/pending-verification');
        }
      }
    } else {
      // Show error message if submission failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to submit application. Please try again.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Widget _buildVendorTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vendor Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildVendorTypeCard(
                title: 'Decoration Provider',
                description: 'Event decoration and planning services',
                icon: Icons.celebration_rounded,
                value: 'decoration_provider',
                isSelected: _selectedVendorType == 'decoration_provider',
                onTap: () {
                  _onVendorTypeSelected('decoration_provider');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildVendorTypeCard(
                title: 'Theater Provider',
                description: 'Private theater and cinema services',
                icon: Icons.theaters_rounded,
                value: 'theater_provider',
                isSelected: _selectedVendorType == 'theater_provider',
                onTap: () {
                  _onVendorTypeSelected('theater_provider');
                },
              ),
            ),
          ],
        ),
        if (_selectedVendorType == null)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Please select your vendor type',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.errorColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVendorTypeCard({
    required String title,
    required String description,
    required IconData icon,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
