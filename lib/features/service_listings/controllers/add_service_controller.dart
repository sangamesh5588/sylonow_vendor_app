import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_listing.dart';
import '../providers/service_listing_provider.dart';
import '../service/service_listing_service.dart';
import '../../onboarding/providers/vendor_provider.dart';

final addServiceControllerProvider = Provider<AddServiceController>((ref) {
  return AddServiceController(ref);
});

class AddServiceController {
  final Ref _ref;
  
  AddServiceController(this._ref);

  ServiceListingService get _service => _ref.read(serviceListingServiceProvider);

  // Form Controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final originalPriceController = TextEditingController();
  final offerPriceController = TextEditingController();
  final promotionalTagController = TextEditingController();
  final customizationNoteController = TextEditingController();
  final pincodeController = TextEditingController();
  final inclusionController = TextEditingController();
  final exclusionController = TextEditingController();
  final customAmenityController = TextEditingController();
  final freeServiceKmController = TextEditingController();
  final extraChargesPerKmController = TextEditingController();

  // Form Keys
  final formKey = GlobalKey<FormState>();

  // Selection Controllers
  String? selectedCategory;
  String? selectedSetupTime;
  String? selectedBookingNotice;
  List<String> selectedThemeTags = [];
  List<String> selectedServiceEnvironments = [];
  List<String> selectedVenueTypes = [];
  List<String> pincodes = [];
  List<String> inclusions = [];
  List<String> exclusions = [];
  List<String> customAmenities = [];
  bool customizationAvailable = false;
  bool serviceAllOverBangalore = false;
  bool providesBanner = false;

  // Media Controllers
  List<String> photos = [];
  String? coverPhoto;
  String? videoUrl;
  bool isUploadingMedia = false;

  // Categories loaded from database
  List<String> categories = [];
  bool isCategoriesLoading = true;

  Future<void> loadCategories() async {
    isCategoriesLoading = true;
    categories = await _service.fetchActiveCategories();
    isCategoriesLoading = false;
  }
  List<String> get themeTags => _service.getThemeTags();
  List<String> get serviceEnvironments => _service.getServiceEnvironments();
  List<String> get setupTimeOptions => _service.getSetupTimeOptions();
  List<String> get bookingNoticeOptions => _service.getBookingNoticeOptions();
  List<String> get venueTypes => _service.getVenueTypes();

  // Validation
  String? validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Title is required';
    }
    if (value.length > 100) {
      return 'Title must be less than 100 characters';
    }
    return null;
  }

  String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    final price = double.tryParse(value);
    if (price == null || price <= 0) {
      return 'Enter a valid price';
    }
    return null;
  }

  String? validateOfferPrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Offer price is required';
    }
    final offerPrice = double.tryParse(value);
    final originalPrice = double.tryParse(originalPriceController.text);
    
    if (offerPrice == null || offerPrice <= 0) {
      return 'Enter a valid offer price';
    }
    if (originalPrice != null && offerPrice > originalPrice) {
      return 'Offer price cannot be greater than original price';
    }
    return null;
  }

  String? validatePincode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Pincode is required';
    }
    if (value.length != 6) {
      return 'Pincode must be 6 digits';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Pincode must contain only digits';
    }
    return null;
  }

  String? validateFreeServiceKm(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    final km = double.tryParse(value);
    if (km == null || km < 0) {
      return 'Enter a valid distance';
    }
    if (km > 1000) {
      return 'Distance cannot exceed 1000 KM';
    }
    return null;
  }

  String? validateExtraChargesPerKm(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    final charge = double.tryParse(value);
    if (charge == null || charge < 0) {
      return 'Enter a valid charge amount';
    }
    if (charge > 1000) {
      return 'Charge cannot exceed ₹1000 per KM';
    }
    return null;
  }

  // Theme tag management
  void toggleThemeTag(String tag) {
    if (selectedThemeTags.contains(tag)) {
      selectedThemeTags.remove(tag);
    } else {
      selectedThemeTags.add(tag);
    }
  }

  // Service environment management
  void toggleServiceEnvironment(String environment) {
    if (selectedServiceEnvironments.contains(environment)) {
      selectedServiceEnvironments.remove(environment);
    } else {
      selectedServiceEnvironments.add(environment);
    }
  }

  // Venue type management
  void toggleVenueType(String venueType) {
    if (selectedVenueTypes.contains(venueType)) {
      selectedVenueTypes.remove(venueType);
    } else {
      selectedVenueTypes.add(venueType);
    }
  }

  // Pincode management
  void addPincode() {
    final pincode = pincodeController.text.trim();
    if (pincode.isNotEmpty && !pincodes.contains(pincode)) {
      if (pincodes.length < 20) {
        pincodes.add(pincode);
        pincodeController.clear();
      }
    }
  }

  void removePincode(String pincode) {
    pincodes.remove(pincode);
  }

  // Inclusion management
  void addInclusion() {
    final inclusion = inclusionController.text.trim();
    if (inclusion.isNotEmpty && !inclusions.contains(inclusion)) {
      inclusions.add(inclusion);
      inclusionController.clear();
    }
  }

  void removeInclusion(String inclusion) {
    inclusions.remove(inclusion);
  }

  // Exclusion management
  void addExclusion() {
    final exclusion = exclusionController.text.trim();
    if (exclusion.isNotEmpty && !exclusions.contains(exclusion)) {
      exclusions.add(exclusion);
      exclusionController.clear();
    }
  }

  void removeExclusion(String exclusion) {
    exclusions.remove(exclusion);
  }

  // Custom amenities management
  void addCustomAmenity() {
    final amenity = customAmenityController.text.trim();
    if (amenity.isNotEmpty && !customAmenities.contains(amenity)) {
      if (customAmenities.length < 10) {
        customAmenities.add(amenity);
        customAmenityController.clear();
      }
    }
  }

  void removeCustomAmenity(String amenity) {
    customAmenities.remove(amenity);
  }


  // Method to get vendor coordinates for populating service listing location
  Future<Map<String, double?>> _getVendorCoordinates() async {
    try {
      final vendor = await _ref.read(vendorProvider.future);
      if (vendor?.location != null && vendor!.location is Map) {
        final location = vendor.location as Map;
        return {
          'latitude': location['latitude']?.toDouble(),
          'longitude': location['longitude']?.toDouble(),
        };
      }
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 Error getting vendor coordinates: $e');
    }
    return {'latitude': null, 'longitude': null};
  }

  // Media management
  Future<void> uploadImages() async {
    try {
      isUploadingMedia = true;
      final newPhotos = await _service.pickAndUploadImages(
        maxImages: 6,
        existingImages: photos,
      );
      photos = newPhotos;
      if (coverPhoto == null && photos.isNotEmpty) {
        coverPhoto = photos.first;
      }
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 AddServiceController: Error uploading images: $e');
      rethrow;
    } finally {
      isUploadingMedia = false;
    }
  }

  Future<void> uploadVideo() async {
    try {
      isUploadingMedia = true;
      final newVideoUrl = await _service.pickAndUploadVideo();
      if (newVideoUrl != null) {
        videoUrl = newVideoUrl;
      }
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 AddServiceController: Error uploading video: $e');
      rethrow;
    } finally {
      isUploadingMedia = false;
    }
  }

  void setCoverPhoto(String photoUrl) {
    coverPhoto = photoUrl;
    if (!photos.contains(photoUrl)) {
      photos.insert(0, photoUrl);
    } else {
      // Move to first position
      photos.remove(photoUrl);
      photos.insert(0, photoUrl);
    }
  }

  Future<void> removePhoto(String photoUrl) async {
    try {
      await _service.deleteMediaFile(photoUrl);
      photos.remove(photoUrl);
      if (coverPhoto == photoUrl) {
        coverPhoto = photos.isNotEmpty ? photos.first : null;
      }
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 AddServiceController: Error removing photo: $e');
      rethrow;
    }
  }

  Future<void> removeVideo() async {
    try {
      if (videoUrl != null) {
        await _service.deleteMediaFile(videoUrl!);
        videoUrl = null;
      }
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 AddServiceController: Error removing video: $e');
      rethrow;
    }
  }

  // Advanced validation debugging
  Map<String, dynamic> validateAllFields() {
    final validationReport = <String, dynamic>{};
    
    // Check each TextFormField individually
    try {
      // Title validation
      final titleError = validateTitle(titleController.text);
      validationReport['title'] = {
        'value': titleController.text,
        'error': titleError,
        'isValid': titleError == null,
        'controller': titleController.runtimeType.toString(),
      };
      
      // Price validations
      final originalPriceError = validatePrice(originalPriceController.text);
      validationReport['originalPrice'] = {
        'value': originalPriceController.text,
        'error': originalPriceError,
        'isValid': originalPriceError == null,
        'controller': originalPriceController.runtimeType.toString(),
      };
      
      final offerPriceError = validateOfferPrice(offerPriceController.text);
      validationReport['offerPrice'] = {
        'value': offerPriceController.text,
        'error': offerPriceError,
        'isValid': offerPriceError == null,
        'controller': offerPriceController.runtimeType.toString(),
      };
      
      // Category validation (dropdown)
      validationReport['category'] = {
        'value': selectedCategory,
        'isValid': selectedCategory != null && selectedCategory!.isNotEmpty,
        'availableOptions': categories.length,
      };
      
      // Service environment validation
      validationReport['serviceEnvironment'] = {
        'value': selectedServiceEnvironments,
        'count': selectedServiceEnvironments.length,
        'isValid': selectedServiceEnvironments.isNotEmpty,
      };
      
      // Setup time validation
      validationReport['setupTime'] = {
        'value': selectedSetupTime,
        'isValid': selectedSetupTime != null && selectedSetupTime!.isNotEmpty,
        'availableOptions': setupTimeOptions.length,
      };
      
      // Booking notice validation
      validationReport['bookingNotice'] = {
        'value': selectedBookingNotice,
        'isValid': selectedBookingNotice != null && selectedBookingNotice!.isNotEmpty,
        'availableOptions': bookingNoticeOptions.length,
      };
      
      // Pincodes validation
      validationReport['pincodes'] = {
        'value': pincodes,
        'count': pincodes.length,
        'isValid': pincodes.isNotEmpty,
      };
      
      // Inclusions validation
      validationReport['inclusions'] = {
        'value': inclusions,
        'count': inclusions.length,
        'isValid': inclusions.isNotEmpty,
      };
      
      // Form state validation
      validationReport['formState'] = {
        'formKeyExists': formKey.currentState != null,
        'formValidation': formKey.currentState?.validate(),
      };
      
    } catch (e, stackTrace) {
      validationReport['error'] = {
        'message': e.toString(),
        'stackTrace': stackTrace.toString(),
      };
    }
    
    return validationReport;
  }
  
  void printValidationReport() {
    final report = validateAllFields();
    
// TODO: Replace with proper logging - print('\n🔍 ===== ADVANCED VALIDATION REPORT =====');
    
    // Print each field's validation status
    report.forEach((fieldName, fieldData) {
      if (fieldName == 'error') {
// Error print removed
        return;
      }
      
      final isValid = fieldData['isValid'] ?? false;
      final status = isValid ? '✅' : '❌';
      
// TODO: Replace with proper logging - print('$status $fieldName:');
      if (fieldData['value'] != null) {
// TODO: Replace with proper logging - print('   Value: ${fieldData['value']}');
      }
      if (fieldData['error'] != null) {
// TODO: Replace with proper logging - print('   Error: ${fieldData['error']}');
      }
      if (fieldData['count'] != null) {
// TODO: Replace with proper logging - print('   Count: ${fieldData['count']}');
      }
      if (fieldData['availableOptions'] != null) {
// TODO: Replace with proper logging - print('   Available Options: ${fieldData['availableOptions']}');
      }
// TODO: Replace with proper logging - print('   Valid: $isValid');
// TODO: Replace with proper logging - print('');
    });
    
    // Calculate overall validity
    final failedFields = <String>[];
    report.forEach((fieldName, fieldData) {
      if (fieldName != 'error' && fieldName != 'formState') {
        final isValid = fieldData['isValid'] ?? false;
        if (!isValid) {
          failedFields.add(fieldName);
        }
      }
    });
    
// TODO: Replace with proper logging - print('📊 SUMMARY:');
// TODO: Replace with proper logging - print('   Total fields checked: ${report.length - 1}'); // -1 for formState
// TODO: Replace with proper logging - print('   Failed fields: ${failedFields.length}');
    if (failedFields.isNotEmpty) {
// TODO: Replace with proper logging - print('   Failed field names: ${failedFields.join(', ')}');
    }
// TODO: Replace with proper logging - print('   Form state valid: ${report['formState']?['formValidation'] ?? false}');
// TODO: Replace with proper logging - print('   Overall valid: ${failedFields.isEmpty && (report['formState']?['formValidation'] ?? false)}');
// TODO: Replace with proper logging - print('========================================\n');
  }

  // Form validation with fallback
  bool get isFormValid {
    // Generate detailed validation report
    printValidationReport();
    
    // Inspect form fields in detail
    inspectFormFields();
    
    // Check each field validation individually
    final titleValidation = validateTitle(titleController.text);
    final originalPriceValidation = validatePrice(originalPriceController.text);
    final offerPriceValidation = validateOfferPrice(offerPriceController.text);
    
    // Try form validation, but use fallback if form state is not available
    bool mainFormValidation = false;
    try {
      final formState = formKey.currentState;
      if (formState != null && formState.mounted) {
        mainFormValidation = formState.validate();
// TODO: Replace with proper logging - print('🟢 Form state validation successful: $mainFormValidation');
      } else {
// Warning print removed
        // Manual validation fallback for form fields
        mainFormValidation = titleValidation == null && selectedCategory != null;
// TODO: Replace with proper logging - print('🔧 Manual form validation result: $mainFormValidation');
      }
    } catch (e) {
// Error print removed
      // Fallback to manual validation
      mainFormValidation = titleValidation == null && selectedCategory != null;
// TODO: Replace with proper logging - print('🔧 Fallback validation result: $mainFormValidation');
    }
    
    // Check all required conditions through logic instead of form validation
    final hasCategory = selectedCategory != null;
    final hasServiceEnvironment = selectedServiceEnvironments.isNotEmpty;
    final hasSetupTime = selectedSetupTime != null;
    final hasBookingNotice = selectedBookingNotice != null;
    final hasPincodes = pincodes.isNotEmpty || serviceAllOverBangalore;
    final hasInclusions = inclusions.isNotEmpty;
    final hasValidPricing = originalPriceValidation == null && offerPriceValidation == null;
    
    final isValid = mainFormValidation &&
           hasValidPricing &&
           hasCategory &&
           hasServiceEnvironment &&
           hasSetupTime &&
           hasBookingNotice &&
           hasPincodes &&
           hasInclusions;
           
// TODO: Replace with proper logging - print('🎯 Final validation result: $isValid');
    return isValid;
  }

  // Create listing
  Future<bool> createListing() async {
    // Validate the form first
    if (!isFormValid) {
// TODO: Replace with proper logging - print('🔴 AddServiceController: Form is invalid. Aborting submission.');
      return false;
    }

    try {
      // Get the current vendor's main ID (which is the foreign key for service_listings)
      final vendor = await _ref.read(vendorProvider.future);
      if (vendor == null) {
        throw Exception('Could not get current vendor. Please login again.');
      }
      final vendorId = vendor.id; // Use the primary vendor ID

      // Get vendor coordinates to populate location
      final coordinates = await _getVendorCoordinates();

      // Construct the ServiceListing object from the form data
      final newListing = ServiceListing(
        // These will be generated by the DB, but are required by the model
        id: '',
        listingId: '', // Will be auto-generated by DB
        // Core fields
        vendorId: vendorId!,
        title: titleController.text.trim(),
        category: selectedCategory!,
        description: descriptionController.text.trim(),
        originalPrice: double.tryParse(originalPriceController.text) ?? 0.0,
        offerPrice: double.tryParse(offerPriceController.text) ?? 0.0,
        themeTags: selectedThemeTags,
        serviceEnvironment: selectedServiceEnvironments,
        setupTime: selectedSetupTime ?? 'Not specified',
        bookingNotice: selectedBookingNotice ?? 'Not specified',
        venueTypes: selectedVenueTypes,
        pincodes: pincodes,
        serviceAllOverBangalore: serviceAllOverBangalore,
        freeServiceKm: double.tryParse(freeServiceKmController.text.trim()),
        extraChargesPerKm: double.tryParse(extraChargesPerKmController.text.trim()),
        inclusions: inclusions,
        exclusions: exclusions,
        customAmenities: customAmenities,
        providesBanner: providesBanner,
        customizationAvailable: customizationAvailable,
        customizationNote: customizationAvailable ? customizationNoteController.text.trim() : null,
        promotionalTag: promotionalTagController.text.trim().isNotEmpty ? promotionalTagController.text.trim() : null,
        coverPhoto: coverPhoto,
        photos: photos,
        videoUrl: videoUrl,
        // Location from vendor data
        latitude: coordinates['latitude'],
        longitude: coordinates['longitude'],
      );

      // Call the service to create the listing
      final createdListing = await _service.createListing(newListing, vendorId);
      

      // Invalidate the provider to force a refresh on the listings screen
      _ref.invalidate(serviceListingsProvider);

// TODO: Replace with proper logging - print('🟢 AddServiceController: Listing created successfully!');
      return true;

    } catch (e) {
// TODO: Replace with proper logging - print('🔴 AddServiceController: Failed to create service listing: $e');
      // Optionally, show a user-friendly error message
      return false;
    }
  }

  // Reset form
  void resetForm() {
    titleController.clear();
    descriptionController.clear();
    originalPriceController.clear();
    offerPriceController.clear();
    promotionalTagController.clear();
    customizationNoteController.clear();
    pincodeController.clear();
    inclusionController.clear();
    exclusionController.clear();
    customAmenityController.clear();
    freeServiceKmController.clear();
    extraChargesPerKmController.clear();
    
    selectedCategory = null;
    selectedSetupTime = null;
    selectedBookingNotice = null;
    selectedThemeTags.clear();
    selectedServiceEnvironments.clear();
    selectedVenueTypes.clear();
    pincodes.clear();
    inclusions.clear();
    exclusions.clear();
    customAmenities.clear();
    photos.clear();
    coverPhoto = null;
    videoUrl = null;
    customizationAvailable = false;
    serviceAllOverBangalore = false;
    isUploadingMedia = false;
  }

  // Dispose controllers
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    originalPriceController.dispose();
    offerPriceController.dispose();
    promotionalTagController.dispose();
    customizationNoteController.dispose();
    pincodeController.dispose();
    inclusionController.dispose();
    exclusionController.dispose();
    customAmenityController.dispose();
    freeServiceKmController.dispose();
    extraChargesPerKmController.dispose();
  }

  // Form field inspector for debugging
  void inspectFormFields() {
// TODO: Replace with proper logging - print('\n🔬 ===== FORM FIELD INSPECTOR =====');
    
    // Check if form key is properly attached
    final formState = formKey.currentState;
// TODO: Replace with proper logging - print('📋 Form State Analysis:');
// TODO: Replace with proper logging - print('   Form key exists: ${formKey != null}');
// TODO: Replace with proper logging - print('   Form state exists: ${formState != null}');
    
    if (formState != null) {
      try {
// TODO: Replace with proper logging - print('   Form is mounted: ${formState.mounted}');
// TODO: Replace with proper logging - print('   Form context exists: ${formState.context != null}');
        
        // Try to validate and see what happens
// TODO: Replace with proper logging - print('\n🧪 Validation Test:');
        final validationResult = formState.validate();
// TODO: Replace with proper logging - print('   Validation result: $validationResult');
        
        // Check individual form fields if validation fails
        if (!validationResult) {
// TODO: Replace with proper logging - print('\n🕵️ Investigating Failed Validation...');
// TODO: Replace with proper logging - print('   Looking for TextFormField and DropdownButtonFormField widgets...');
          
          // This will show any validation errors that occur
          try {
            formState.save();
// TODO: Replace with proper logging - print('   Form save successful');
          } catch (e) {
// TODO: Replace with proper logging - print('   Form save error: $e');
          }
        }
        
      } catch (e) {
// TODO: Replace with proper logging - print('   ❌ Form inspection error: $e');
// TODO: Replace with proper logging - print('   Stack trace: $stackTrace');
      }
    }
    
    // Check controller states
// TODO: Replace with proper logging - print('\n📱 Controller States:');
// TODO: Replace with proper logging - print('   Title controller text: "${titleController.text}"');
// TODO: Replace with proper logging - print('   Title controller selection: ${titleController.selection}');
// TODO: Replace with proper logging - print('   Original price controller text: "${originalPriceController.text}"');
// TODO: Replace with proper logging - print('   Offer price controller text: "${offerPriceController.text}"');
    
    // Check dropdown values
// TODO: Replace with proper logging - print('\n📋 Dropdown Values:');
// TODO: Replace with proper logging - print('   Selected category: $selectedCategory');
// TODO: Replace with proper logging - print('   Available categories: $categories');
// TODO: Replace with proper logging - print('   Selected setup time: $selectedSetupTime');
// TODO: Replace with proper logging - print('   Available setup times: $setupTimeOptions');
// TODO: Replace with proper logging - print('   Selected booking notice: $selectedBookingNotice');
// TODO: Replace with proper logging - print('   Available booking notices: $bookingNoticeOptions');
    
// TODO: Replace with proper logging - print('==================================\n');
  }
} 