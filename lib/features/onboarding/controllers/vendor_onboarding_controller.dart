import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../service/vendor_service.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/services/firebase_analytics_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

final vendorOnboardingControllerProvider = 
    StateNotifierProvider<VendorOnboardingController, VendorOnboardingState>((ref) {
  return VendorOnboardingController(ref);
});

class VendorOnboardingState {
  final bool isLoading;
  final String? errorMessage;
  final File? profileImage;
  final File? aadhaarFrontImage;
  final File? aadhaarBackImage;
  final File? panCardImage;
  final File? businessImage;
  final File? fssaiLicenseImage;
  final String? profileImageUrl;
  final String? aadhaarFrontImageUrl;
  final String? aadhaarBackImageUrl;
  final String? panCardImageUrl;
  final String? businessImageUrl;
  final String? fssaiLicenseImageUrl;

  const VendorOnboardingState({
    this.isLoading = false,
    this.errorMessage,
    this.profileImage,
    this.aadhaarFrontImage,
    this.aadhaarBackImage,
    this.panCardImage,
    this.businessImage,
    this.fssaiLicenseImage,
    this.profileImageUrl,
    this.aadhaarFrontImageUrl,
    this.aadhaarBackImageUrl,
    this.panCardImageUrl,
    this.businessImageUrl,
    this.fssaiLicenseImageUrl,
  });

  VendorOnboardingState copyWith({
    bool? isLoading,
    String? errorMessage,
    File? profileImage,
    File? aadhaarFrontImage,
    File? aadhaarBackImage,
    File? panCardImage,
    File? businessImage,
    File? fssaiLicenseImage,
    String? profileImageUrl,
    String? aadhaarFrontImageUrl,
    String? aadhaarBackImageUrl,
    String? panCardImageUrl,
    String? businessImageUrl,
    String? fssaiLicenseImageUrl,
  }) {
    return VendorOnboardingState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      profileImage: profileImage ?? this.profileImage,
      aadhaarFrontImage: aadhaarFrontImage ?? this.aadhaarFrontImage,
      aadhaarBackImage: aadhaarBackImage ?? this.aadhaarBackImage,
      panCardImage: panCardImage ?? this.panCardImage,
      businessImage: businessImage ?? this.businessImage,
      fssaiLicenseImage: fssaiLicenseImage ?? this.fssaiLicenseImage,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      aadhaarFrontImageUrl: aadhaarFrontImageUrl ?? this.aadhaarFrontImageUrl,
      aadhaarBackImageUrl: aadhaarBackImageUrl ?? this.aadhaarBackImageUrl,
      panCardImageUrl: panCardImageUrl ?? this.panCardImageUrl,
      businessImageUrl: businessImageUrl ?? this.businessImageUrl,
      fssaiLicenseImageUrl: fssaiLicenseImageUrl ?? this.fssaiLicenseImageUrl,
    );
  }
}

class VendorOnboardingController extends StateNotifier<VendorOnboardingState> {
  final Ref ref;

  VendorOnboardingController(this.ref) : super(const VendorOnboardingState());

  void setProfileImage(File? image) {
    // Clear any previous image first
    if (state.profileImage != null) {
      try {
        // Only delete if it's clearly a temporary file
        if (state.profileImage!.path.contains('temp_images') || 
            state.profileImage!.path.contains('cache')) {
          state.profileImage!.deleteSync();
// TODO: Replace with proper logging - print('🧹 Cleaned up old profile image');
        }
      } catch (e) {
// Warning print removed
      }
    }
    state = state.copyWith(profileImage: image);
// TODO: Replace with proper logging - print('📸 Profile image set: ${image?.path ?? 'null'}');
  }

  void setProfileImageUrl(String url) {
    state = state.copyWith(profileImageUrl: url);
// TODO: Replace with proper logging - print('📸 Profile image URL set: $url');
  }

  void setAadhaarFrontImage(File? image) {
    // Clear any previous image first
    if (state.aadhaarFrontImage != null) {
      try {
        // Only delete if it's clearly a temporary file
        if (state.aadhaarFrontImage!.path.contains('temp_images') || 
            state.aadhaarFrontImage!.path.contains('cache')) {
          state.aadhaarFrontImage!.deleteSync();
// TODO: Replace with proper logging - print('🧹 Cleaned up old aadhaar front image');
        }
      } catch (e) {
// Warning print removed
      }
    }
    state = state.copyWith(aadhaarFrontImage: image);
// TODO: Replace with proper logging - print('📸 Aadhaar front image set: ${image?.path ?? 'null'}');
  }

  void setAadhaarFrontImageUrl(String url) {
// TODO: Replace with proper logging - print('🔵 setAadhaarFrontImageUrl called with: $url');
    state = state.copyWith(aadhaarFrontImageUrl: url);
// TODO: Replace with proper logging - print('🔵 State updated, aadhaarFrontImageUrl is now: ${state.aadhaarFrontImageUrl}');
  }

  void setAadhaarBackImage(File? image) {
    // Clear any previous image first
    if (state.aadhaarBackImage != null) {
      try {
        // Only delete if it's clearly a temporary file
        if (state.aadhaarBackImage!.path.contains('temp_images') || 
            state.aadhaarBackImage!.path.contains('cache')) {
          state.aadhaarBackImage!.deleteSync();
// TODO: Replace with proper logging - print('🧹 Cleaned up old aadhaar back image');
        }
      } catch (e) {
// Warning print removed
      }
    }
    state = state.copyWith(aadhaarBackImage: image);
// TODO: Replace with proper logging - print('📸 Aadhaar back image set: ${image?.path ?? 'null'}');
  }

  void setAadhaarBackImageUrl(String url) {
// TODO: Replace with proper logging - print('🔵 setAadhaarBackImageUrl called with: $url');
    state = state.copyWith(aadhaarBackImageUrl: url);
// TODO: Replace with proper logging - print('🔵 State updated, aadhaarBackImageUrl is now: ${state.aadhaarBackImageUrl}');
  }

  void setPanCardImage(File? image) {
    // Clear any previous image first
    if (state.panCardImage != null) {
      try {
        // Only delete if it's clearly a temporary file
        if (state.panCardImage!.path.contains('temp_images') || 
            state.panCardImage!.path.contains('cache')) {
          state.panCardImage!.deleteSync();
// TODO: Replace with proper logging - print('🧹 Cleaned up old pan card image');
        }
      } catch (e) {
// Warning print removed
      }
    }
    state = state.copyWith(panCardImage: image);
// TODO: Replace with proper logging - print('📸 PAN card image set: ${image?.path ?? 'null'}');
  }

  void setPanCardImageUrl(String url) {
// TODO: Replace with proper logging - print('🔵 setPanCardImageUrl called with: $url');
    state = state.copyWith(panCardImageUrl: url);
// TODO: Replace with proper logging - print('🔵 State updated, panCardImageUrl is now: ${state.panCardImageUrl}');
  }

  void setBusinessImage(File? image) {
    // Clear any previous image first
    if (state.businessImage != null) {
      try {
        // Only delete if it's clearly a temporary file
        if (state.businessImage!.path.contains('temp_images') || 
            state.businessImage!.path.contains('cache')) {
          state.businessImage!.deleteSync();
// TODO: Replace with proper logging - print('🧹 Cleaned up old business image');
        }
      } catch (e) {
// Warning print removed
      }
    }
    state = state.copyWith(businessImage: image);
// TODO: Replace with proper logging - print('📸 Business image set: ${image?.path ?? 'null'}');
  }

  void setBusinessImageUrl(String url) {
// TODO: Replace with proper logging - print('🔵 setBusinessImageUrl called with: $url');
    state = state.copyWith(businessImageUrl: url);
// TODO: Replace with proper logging - print('🔵 State updated, businessImageUrl is now: ${state.businessImageUrl}');
  }

  void setFssaiLicenseImage(File? image) {
    // Clear any previous image first
    if (state.fssaiLicenseImage != null) {
      try {
        // Only delete if it's clearly a temporary file
        if (state.fssaiLicenseImage!.path.contains('temp_images') ||
            state.fssaiLicenseImage!.path.contains('cache')) {
          state.fssaiLicenseImage!.deleteSync();
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    }
    state = state.copyWith(fssaiLicenseImage: image);
  }

  void setFssaiLicenseImageUrl(String url) {
    state = state.copyWith(fssaiLicenseImageUrl: url);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<bool> submitVendorApplication({
    required String fullName,
    required String serviceArea,
    required String pincode,
    required String serviceType,
    required String vendorType,
    required String businessName,
    required String aadhaarNumber,
    required String bankAccountNumber,
    required String bankIfscCode,
    required String additionalAddress,
    String? fcmToken,
    String? gstNumber,
    String? fssaiLicenseNumber,
    String? bankName,
    String? accountHolderName,
    double? latitude,
    double? longitude,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please login again.');
      }
      
// TODO: Replace with proper logging - print('🔵 Starting vendor application submission for user: ${user.id}');
      
      // Validate that we have either files OR URLs for required documents
      final documentsStatus = {
        'profile': state.profileImageUrl != null || state.profileImage != null,
        'aadhaar_front': state.aadhaarFrontImageUrl != null || state.aadhaarFrontImage != null,
        'aadhaar_back': state.aadhaarBackImageUrl != null || state.aadhaarBackImage != null,
        'pan_card': state.panCardImageUrl != null || state.panCardImage != null,
        'business': state.businessImageUrl != null || state.businessImage != null,
      };
      
// TODO: Replace with proper logging - print('🔍 Document validation status:');
// TODO: Replace with proper logging - print('  aadhaar_front: URL=${state.aadhaarFrontImageUrl != null}, File=${state.aadhaarFrontImage != null}');
// TODO: Replace with proper logging - print('    URL value: ${state.aadhaarFrontImageUrl}');
// TODO: Replace with proper logging - print('    File value: ${state.aadhaarFrontImage?.path}');
// TODO: Replace with proper logging - print('  aadhaar_back: URL=${state.aadhaarBackImageUrl != null}, File=${state.aadhaarBackImage != null}');
// TODO: Replace with proper logging - print('    URL value: ${state.aadhaarBackImageUrl}');
// TODO: Replace with proper logging - print('    File value: ${state.aadhaarBackImage?.path}');
// TODO: Replace with proper logging - print('  pan_card: URL=${state.panCardImageUrl != null}, File=${state.panCardImage != null}');
// TODO: Replace with proper logging - print('    URL value: ${state.panCardImageUrl}');
// TODO: Replace with proper logging - print('    File value: ${state.panCardImage?.path}');
// TODO: Replace with proper logging - print('  profile: URL=${state.profileImageUrl != null}, File=${state.profileImage != null}');
// TODO: Replace with proper logging - print('    URL value: ${state.profileImageUrl}');
// TODO: Replace with proper logging - print('    File value: ${state.profileImage?.path}');
      
      documentsStatus.forEach((type, hasDocument) {
// TODO: Replace with proper logging - print('  $type: hasDocument=$hasDocument');
      });
      
      // Check required documents
      final missingDocs = <String>[];
      if (!documentsStatus['aadhaar_front']!) {
        missingDocs.add('Aadhaar Front');
// TODO: Replace with proper logging - print('🔴 Missing Aadhaar Front - URL: ${state.aadhaarFrontImageUrl}, File: ${state.aadhaarFrontImage?.path}');
      }
      if (!documentsStatus['aadhaar_back']!) {
        missingDocs.add('Aadhaar Back');
// TODO: Replace with proper logging - print('🔴 Missing Aadhaar Back - URL: ${state.aadhaarBackImageUrl}, File: ${state.aadhaarBackImage?.path}');
      }
      if (!documentsStatus['pan_card']!) {
        missingDocs.add('PAN Card');
// TODO: Replace with proper logging - print('🔴 Missing PAN Card - URL: ${state.panCardImageUrl}, File: ${state.panCardImage?.path}');
      }
      if (!documentsStatus['business']!) {
        missingDocs.add('Business Picture');
// TODO: Replace with proper logging - print('🔴 Missing Business Picture - URL: ${state.businessImageUrl}, File: ${state.businessImage?.path}');
      }
      
      if (missingDocs.isNotEmpty) {
// TODO: Replace with proper logging - print('🔴 Validation failed - Missing documents: $missingDocs');
        throw Exception('Missing required documents: ${missingDocs.join(', ')}. Please upload all required documents.');
      }
      
// TODO: Replace with proper logging - print('🟢 All required documents are available, proceeding with submission...');
      
      // For submission, we'll pass URLs if available, otherwise files
      final vendorService = ref.read(vendorServiceProvider);

      // Call the service with a mix of URLs and files
      await vendorService.createVendorAndDocumentsWithUrls(
        // Vendor details
        fullName: fullName,
        authUserId: user.id,
        serviceArea: serviceArea,
        pincode: pincode,
        serviceType: serviceType,
        vendorType: vendorType,
        businessName: businessName,
        aadhaarNumber: aadhaarNumber,
        bankAccountNumber: bankAccountNumber,
        bankIfscCode: bankIfscCode,
        additionalAddress: additionalAddress,
        fcmToken: fcmToken,
        gstNumber: gstNumber,
        fssaiLicenseNumber: fssaiLicenseNumber,
        bankName: bankName,
        accountHolderName: accountHolderName,
        latitude: latitude,
        longitude: longitude,
        // Images - URLs take priority
        profileImageUrl: state.profileImageUrl,
        profileImageFile: state.profileImage,
        aadhaarFrontImageUrl: state.aadhaarFrontImageUrl,
        aadhaarFrontFile: state.aadhaarFrontImage,
        aadhaarBackImageUrl: state.aadhaarBackImageUrl,
        aadhaarBackFile: state.aadhaarBackImage,
        panCardImageUrl: state.panCardImageUrl,
        panCardFile: state.panCardImage,
        businessImageUrl: state.businessImageUrl,
        businessImageFile: state.businessImage,
        fssaiLicenseImageUrl: state.fssaiLicenseImageUrl,
        fssaiLicenseImageFile: state.fssaiLicenseImage,
      );

      print('🔍 CONTROLLER DEBUG: businessImageUrl = ${state.businessImageUrl}');
      print('🔍 CONTROLLER DEBUG: businessImage file = ${state.businessImage}');

// TODO: Replace with proper logging - print('🟢 Vendor application submitted successfully in controller!');
      
      // Track successful onboarding completion
      FirebaseAnalyticsService().logOnboardingCompleted(
        timeSpent: const Duration(minutes: 5), // Approximate time
        totalSteps: 1, // Single form submission
      );
      
      // Track vendor registration as sign up
      FirebaseAnalyticsService().logSignUp(method: 'vendor_onboarding');
      
      // Set user properties
      FirebaseAnalyticsService().setUserProperties(
        userId: user.id,
        userType: 'vendor',
        businessType: serviceType,
        location: '$serviceArea, $pincode',
      );
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Error submitting vendor application in controller: $e');
      
      // Track onboarding error
      FirebaseAnalyticsService().logError(
        errorType: 'onboarding_submission_failed',
        errorMessage: e.toString(),
        screenName: 'vendor_onboarding',
      );
      
      String userMessage;
      if (e.toString().contains('already a verified vendor')) {
        userMessage = 'You are already a verified vendor! Please check your app - you should be able to see the home screen.';
      } else if (e.toString().contains('registration is already complete')) {
        userMessage = 'Your vendor registration is already under review. Please wait for verification to complete.';
      } else if (e.toString().contains('duplicate key value violates unique constraint')) {
        userMessage = 'This email is already registered. If this is your account, please contact support.';
      } else if (e.toString().contains('email address is already registered')) {
        userMessage = 'This email is already registered with another account. Please use a different email.';
      } else if (e.toString().contains('image file is missing') || 
                 e.toString().contains('Please re-select the image')) {
        userMessage = 'One or more images are missing. Please re-select all images and try again.';
      } else if (e.toString().contains('corrupted') || e.toString().contains('empty')) {
        userMessage = 'One or more images are corrupted. Please select different images and try again.';
      } else if (e.toString().contains('Failed to save') || 
                 e.toString().contains('persistent storage')) {
        userMessage = 'Failed to save images. Please free up some storage space and try again.';
      } else {
        userMessage = 'Failed to submit application. Please try again. If the problem persists, contact support.';
      }
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: userMessage,
      );
      return false;
    }
  }

  Future<File?> _ensureFilePersistence(File file, String type) async {
    try {
      // Create a more persistent directory for vendor uploads
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String uploadsDir = path.join(appDir.path, 'vendor_uploads');
      await Directory(uploadsDir).create(recursive: true);
      
      // Create a new filename with timestamp to avoid conflicts
      final String fileName = 'vendor_${type}_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
      final String persistentPath = path.join(uploadsDir, fileName);
      
      // Copy the file to the more persistent location
      final File persistentFile = await file.copy(persistentPath);
      
      // Verify the copy was successful
      if (await persistentFile.exists()) {
        final size = await persistentFile.length();
// TODO: Replace with proper logging - print('🟢 Created persistent copy of $type: $persistentPath ($size bytes)');
        return persistentFile;
      } else {
// TODO: Replace with proper logging - print('🔴 Failed to create persistent copy of $type');
        return file; // Return original file as fallback
      }
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Error creating persistent copy of $type: $e');
      // Return original file as fallback
      return file;
    }
  }

  String? _getUrlForType(String type) {
    if (type == 'profile') {
      return state.profileImageUrl;
    } else if (type == 'aadhaar_front') {
      return state.aadhaarFrontImageUrl;
    } else if (type == 'aadhaar_back') {
      return state.aadhaarBackImageUrl;
    } else if (type == 'pan_card') {
      return state.panCardImageUrl;
    } else if (type == 'business') {
      return state.businessImageUrl;
    }
    return null;
  }

  File? _getFileForType(String type) {
    if (type == 'profile') {
      return state.profileImage;
    } else if (type == 'aadhaar_front') {
      return state.aadhaarFrontImage;
    } else if (type == 'aadhaar_back') {
      return state.aadhaarBackImage;
    } else if (type == 'pan_card') {
      return state.panCardImage;
    } else if (type == 'business') {
      return state.businessImage;
    }
    return null;
  }
} 