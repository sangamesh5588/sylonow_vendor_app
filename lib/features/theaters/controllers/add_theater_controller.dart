import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/private_theater.dart';
import '../models/theater_screen.dart';
import '../models/theater_time_slot.dart';
import '../providers/theater_provider.dart';
import '../service/theater_service.dart';
import '../../onboarding/providers/vendor_provider.dart';

final addTheaterControllerProvider = ChangeNotifierProvider((ref) {
  return AddTheaterController(ref);
});

class AddTheaterController extends ChangeNotifier {
  final Ref _ref;
  final TheaterService _theaterService;

  AddTheaterController(this._ref) : _theaterService = _ref.read(theaterServiceProvider);

  // Location Section
  final locationFormKey = GlobalKey<FormState>();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final pinCodeController = TextEditingController();
  final stateController = TextEditingController();
  double? latitude;
  double? longitude;

  void updateLocation(double newLatitude, double newLongitude) {
    latitude = newLatitude;
    longitude = newLongitude;
    notifyListeners();
  }

  // Form Controllers
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final hourlyRateController = TextEditingController();
  final capacityController = TextEditingController();
  final bookingDurationController = TextEditingController();
  final advanceBookingDaysController = TextEditingController();
  final cancellationPolicyController = TextEditingController();

  // Form Keys
  final basicInfoFormKey = GlobalKey<FormState>();
  final settingsFormKey = GlobalKey<FormState>();

  // State Variables
  List<String> _selectedAmenities = [];
  List<String> _theaterImages = [];
  String? _theaterVideoUrl;
  bool _isLoading = false;
  bool _isVideoLoading = false;
  
  // Screens and Time Slots
  bool _useMultipleScreens = false;
  final List<TheaterScreen> _screens = [];
  List<TheaterTimeSlot> _timeSlots = [];
  final Map<String, List<TheaterTimeSlot>> _screenTimeSlots = {};

  // Getters
  List<String> get selectedAmenities => _selectedAmenities;
  List<String> get theaterImages => _theaterImages;
  String? get theaterVideoUrl => _theaterVideoUrl;
  bool get isLoading => _isLoading;
  bool get isVideoLoading => _isVideoLoading;
  bool get useMultipleScreens => _useMultipleScreens;
  List<TheaterScreen> get screens => _screens;
  List<TheaterTimeSlot> get timeSlots => _timeSlots;
  bool get hasTimeSlots => _timeSlots.isNotEmpty || _screenTimeSlots.values.any((slots) => slots.isNotEmpty);

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    hourlyRateController.dispose();
    capacityController.dispose();
    bookingDurationController.dispose();
    advanceBookingDaysController.dispose();
    cancellationPolicyController.dispose();
    super.dispose();
  }

  // Update selected amenities
  void updateAmenities(List<String> amenities) {
    _selectedAmenities = amenities;
    notifyListeners();
  }

  // Add amenity
  void addAmenity(String amenity) {
    if (!_selectedAmenities.contains(amenity)) {
      _selectedAmenities.add(amenity);
      notifyListeners();
    }
  }

  // Remove amenity
  void removeAmenity(String amenity) {
    _selectedAmenities.remove(amenity);
    notifyListeners();
  }

  // Update theater images
  void updateImages(List<String> images) {
    _theaterImages = images;
    notifyListeners();
  }

  // Add image
  void addImage(String imageUrl) {
    _theaterImages.add(imageUrl);
    notifyListeners();
  }

  // Remove image
  void removeImage(String imageUrl) {
    _theaterImages.remove(imageUrl);
    notifyListeners();
  }


  // Pick and upload images
  Future<void> pickAndUploadImages() async {
    try {
      _isLoading = true;
      notifyListeners();

      final newImages = await _theaterService.pickAndUploadTheaterImages(
        maxImages: 10,
        existingImages: _theaterImages,
      );

      _theaterImages = newImages;
      notifyListeners();
    } catch (e) {
// TODO: Replace with proper logging - print('Error picking images: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Pick and upload video
  Future<void> pickAndUploadVideo() async {
    try {
      _isVideoLoading = true;
      notifyListeners();

      final videoUrl = await _theaterService.pickAndUploadTheaterVideo();
      
      if (videoUrl != null) {
        _theaterVideoUrl = videoUrl;
        notifyListeners();
      }
    } catch (e) {
// TODO: Replace with proper logging - print('Error picking video: $e');
      rethrow;
    } finally {
      _isVideoLoading = false;
      notifyListeners();
    }
  }

  // Remove video
  void removeVideo() {
    _theaterVideoUrl = null;
    notifyListeners();
  }

  // Validation methods
  bool validateBasicInfo() {
// TODO: Replace with proper logging - print('🔍 DEBUG: validateBasicInfo() called');
// TODO: Replace with proper logging - print('🔍 DEBUG: basicInfoFormKey.currentState?.validate() = ${basicInfoFormKey.currentState?.validate()}');
    
    if (basicInfoFormKey.currentState?.validate() != true) {
// TODO: Replace with proper logging - print('🔴 DEBUG: Form validation failed');
      return false;
    }
    
// TODO: Replace with proper logging - print('🔍 DEBUG: nameController.text = "${nameController.text.trim()}"');
    if (nameController.text.trim().isEmpty) {
// TODO: Replace with proper logging - print('🔴 DEBUG: Name is empty');
      return false;
    }
    
// TODO: Replace with proper logging - print('🔍 DEBUG: hourlyRateController.text = "${hourlyRateController.text.trim()}"');
    if (hourlyRateController.text.trim().isEmpty || 
        double.tryParse(hourlyRateController.text) == null ||
        double.parse(hourlyRateController.text) <= 0) {
// TODO: Replace with proper logging - print('🔴 DEBUG: Hourly rate validation failed');
      return false;
    }
    
// TODO: Replace with proper logging - print('🟢 DEBUG: validateBasicInfo() passed');
    return true;
  }


  bool validateSettings() {
// TODO: Replace with proper logging - print('🔍 DEBUG: validateSettings() called');
// TODO: Replace with proper logging - print('🔍 DEBUG: settingsFormKey.currentState?.validate() = ${settingsFormKey.currentState?.validate()}');
    
    if (settingsFormKey.currentState?.validate() != true) {
// TODO: Replace with proper logging - print('🔴 DEBUG: Settings form validation failed');
      return false;
    }
    
// TODO: Replace with proper logging - print('🔍 DEBUG: bookingDurationController.text = "${bookingDurationController.text.trim()}"');
    if (bookingDurationController.text.trim().isEmpty ||
        int.tryParse(bookingDurationController.text) == null ||
        int.parse(bookingDurationController.text) <= 0) {
// TODO: Replace with proper logging - print('🔴 DEBUG: Booking duration validation failed');
      return false;
    }
    
// TODO: Replace with proper logging - print('🔍 DEBUG: advanceBookingDaysController.text = "${advanceBookingDaysController.text.trim()}"');
    if (advanceBookingDaysController.text.trim().isEmpty ||
        int.tryParse(advanceBookingDaysController.text) == null ||
        int.parse(advanceBookingDaysController.text) <= 0) {
// TODO: Replace with proper logging - print('🔴 DEBUG: Advance booking days validation failed');
      return false;
    }
    
// TODO: Replace with proper logging - print('🟢 DEBUG: validateSettings() passed');
    return true;
  }

  // Create theater
  Future<void> createTheater() async {
    if (!validateAll()) {
      throw Exception('Validation failed');
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Auto-retrieve location data from vendor profile
      final vendorAsync = _ref.read(vendorProvider);
      Map<String, dynamic>? vendorLocation;
      
      if (vendorAsync.hasValue && vendorAsync.value?.location != null) {
        vendorLocation = vendorAsync.value!.location;
// TODO: Replace with proper logging - print('🔍 DEBUG: Using vendor location: $vendorLocation');
      }

      // Extract location data from vendor profile
      final String address = vendorLocation?['address']?.toString() ?? 'Theater Address';
      final String city = vendorLocation?['city']?.toString() ?? 'City';
      final String state = vendorLocation?['state']?.toString() ?? 'State';
      final String pinCode = vendorLocation?['pinCode']?.toString() ?? '000000';
      final double? latitude = vendorLocation?['latitude']?.toDouble();
      final double? longitude = vendorLocation?['longitude']?.toDouble();

// TODO: Replace with proper logging - print('🔍 DEBUG: Theater location - Address: $address, City: $city, State: $state, PinCode: $pinCode');

      final theater = PrivateTheater(
        id: '', // Will be generated by database
        name: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty 
            ? null 
            : descriptionController.text.trim(),
        address: address,
        city: city,
        state: state,
        pinCode: pinCode,
        latitude: latitude,
        longitude: longitude,
        capacity: 50, // Default capacity since max capacity field was removed
        amenities: _selectedAmenities,
        images: _theaterImages,
        videoUrl: _theaterVideoUrl,
        hourlyRate: double.parse(hourlyRateController.text.trim()),
        bookingDurationHours: bookingDurationController.text.trim().isEmpty 
            ? 2 
            : int.parse(bookingDurationController.text.trim()),
        advanceBookingDays: advanceBookingDaysController.text.trim().isEmpty 
            ? 30 
            : int.parse(advanceBookingDaysController.text.trim()),
        cancellationPolicy: cancellationPolicyController.text.trim().isEmpty 
            ? 'Free cancellation up to 24 hours before the booking'
            : cancellationPolicyController.text.trim(),
      );

      await _ref.read(theatersProvider.notifier).createTheater(theater);
      
      // Reset form after successful creation
      _resetForm();
    } catch (e) {
// TODO: Replace with proper logging - print('Error creating theater: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  // Screen Management Methods
  void setMultipleScreens(bool useMultiple) {
    _useMultipleScreens = useMultiple;
    if (!useMultiple) {
      // Clear screens if switching to single theater mode
      _screens.clear();
      _screenTimeSlots.clear();
    } else {
      // Clear main theater time slots if switching to multiple screens
      _timeSlots.clear();
    }
    notifyListeners();
  }

  void addScreen(TheaterScreen screen) {
    final newScreen = screen.copyWith(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
    );
    _screens.add(newScreen);
    notifyListeners();
  }

  void updateScreen(TheaterScreen updatedScreen) {
    final index = _screens.indexWhere((s) => s.id == updatedScreen.id);
    if (index != -1) {
      _screens[index] = updatedScreen;
      notifyListeners();
    }
  }

  void deleteScreen(String screenId) {
    final index = _screens.indexWhere((s) => s.id == screenId);
    if (index != -1) {
      _screens.removeAt(index);
      _screenTimeSlots.remove(screenId);
      notifyListeners();
    }
  }

  // Time Slots Management Methods
  void updateTimeSlots(List<TheaterTimeSlot> slots) {
    _timeSlots = slots;
    notifyListeners();
  }

  void updateScreenTimeSlots(String screenId, List<TheaterTimeSlot> slots) {
    _screenTimeSlots[screenId] = slots;
    notifyListeners();
  }

  List<TheaterTimeSlot> getScreenTimeSlots(String screenId) {
    return _screenTimeSlots[screenId] ?? [];
  }

  // Validation Methods for Screens
  bool validateScreensAndTimeSlots() {
// TODO: Replace with proper logging - print('🔍 DEBUG: validateScreensAndTimeSlots() called');
// TODO: Replace with proper logging - print('🔍 DEBUG: useMultipleScreens = $_useMultipleScreens');
    
    if (_useMultipleScreens) {
// TODO: Replace with proper logging - print('🔍 DEBUG: Multiple screens mode - screens count: ${_screens.length}');
      
      if (_screens.isEmpty) {
// TODO: Replace with proper logging - print('🔴 DEBUG: No screens configured for multiple screens mode');
        return false;
      }
      
      // Check if at least one screen has time slots
      bool hasAnyTimeSlots = _screenTimeSlots.values.any((slots) => slots.isNotEmpty);
// TODO: Replace with proper logging - print('🔍 DEBUG: Has any screen time slots: $hasAnyTimeSlots');
      
      if (!hasAnyTimeSlots) {
// TODO: Replace with proper logging - print('🔴 DEBUG: No time slots configured for any screen');
        return false;
      }
    } else {
// TODO: Replace with proper logging - print('🔍 DEBUG: Single theater mode - time slots count: ${_timeSlots.length}');
      
      if (_timeSlots.isEmpty) {
// TODO: Replace with proper logging - print('🔴 DEBUG: No time slots configured for single theater');
        return false;
      }
    }
    
// TODO: Replace with proper logging - print('🟢 DEBUG: validateScreensAndTimeSlots() passed');
    return true;
  }

  // Updated validation method - location auto-retrieved from vendor profile
  bool validateAll() {
// TODO: Replace with proper logging - print('🔍 DEBUG: validateAll() called');
    final basicValid = validateBasicInfo();
    final settingsValid = validateSettings();
    final screensValid = validateScreensAndTimeSlots();
    
// TODO: Replace with proper logging - print('🔍 DEBUG: Basic Info Valid: $basicValid');
// TODO: Replace with proper logging - print('🔍 DEBUG: Settings Valid: $settingsValid');
// TODO: Replace with proper logging - print('🔍 DEBUG: Screens & Time Slots Valid: $screensValid');
    
    final allValid = basicValid && settingsValid && screensValid;
// TODO: Replace with proper logging - print('🔍 DEBUG: Overall validation result: $allValid');
    
    return allValid;
  }

  // Reset form
  void _resetForm() {
    nameController.clear();
    descriptionController.clear();
    hourlyRateController.clear();
    bookingDurationController.clear();
    advanceBookingDaysController.clear();
    cancellationPolicyController.clear();

    _selectedAmenities.clear();
    _theaterImages.clear();
    _theaterVideoUrl = null;
    
    // Clear screens and time slots
    _useMultipleScreens = false;
    _screens.clear();
    _timeSlots.clear();
    _screenTimeSlots.clear();
    
    notifyListeners();
  }

  // Initialize with default values
  void initializeDefaults() {
    bookingDurationController.text = '2';
    advanceBookingDaysController.text = '30';
    cancellationPolicyController.text = 'Free cancellation up to 24 hours before the booking';
    notifyListeners();
  }
}