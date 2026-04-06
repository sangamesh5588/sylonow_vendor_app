import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../../../core/config/supabase_config.dart';
import '../models/service_listing.dart';

final serviceListingServiceProvider = Provider((ref) => ServiceListingService());

class ServiceListingService {
  final SupabaseClient _client = SupabaseConfig.client;
  final ImagePicker _picker = ImagePicker();

  // Get a specific service listing by ID
  Future<ServiceListing?> getServiceListingById(String listingId) async {
    try {
// TODO: Replace with proper logging - print('🔵 ServiceListingService: Getting listing with ID: $listingId');
      
      final response = await _client
          .from('service_listings')
          .select('*')
          .eq('id', listingId)
          .single();
      
// TODO: Replace with proper logging - print('🔵 ServiceListingService: Found listing: ${response['title']}');
      
      // Handle null values that could cause type cast errors
      final Map<String, dynamic> safeJson = Map<String, dynamic>.from(response);
      
      // Ensure required string fields have fallback values
      safeJson['listing_id'] ??= safeJson['id'] ?? '';
      safeJson['vendor_id'] ??= '';
      safeJson['setup_time'] ??= '1 hr';
      safeJson['booking_notice'] ??= '1 day';
      
      // Ensure numeric fields have fallback values
      safeJson['original_price'] ??= 0.0;
      safeJson['offer_price'] ??= 0.0;
      
      // Ensure list fields are initialized
      safeJson['theme_tags'] ??= <String>[];
      safeJson['service_environment'] ??= <String>[];
      safeJson['photos'] ??= <String>[];
      safeJson['inclusions'] ??= <String>[];
      safeJson['pincodes'] ??= <String>[];
      safeJson['venue_types'] ??= <String>[];
      safeJson['exclusions'] ??= <String>[];
      safeJson['custom_amenities'] ??= <String>[];
      
      // Ensure boolean fields have fallback values
      safeJson['provides_banner'] ??= false;
      safeJson['customization_available'] ??= false;
      safeJson['service_all_over_bangalore'] ??= false;
      
      return ServiceListing.fromJson(safeJson);
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ServiceListingService: Error getting listing by ID: $e');
      return null;
    }
  }

  // Get vendor's service listings
  Future<List<ServiceListing>> getVendorListings(String vendorId) async {
    try {
// TODO: Replace with proper logging - print('🔵 ServiceListingService: Getting listings for vendor: $vendorId');
      
      final response = await _client
          .from('service_listings')
          .select('*')
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false);
      
// TODO: Replace with proper logging - print('🔵 ServiceListingService: Database response received');
// TODO: Replace with proper logging - print('🔵 ServiceListingService: Found ${response.length} listings');
      
      return response.map((json) {
        // Handle null values that could cause type cast errors
        final Map<String, dynamic> safeJson = Map<String, dynamic>.from(json);
        
        // Ensure required string fields have fallback values
        safeJson['listing_id'] ??= safeJson['id'] ?? '';
        safeJson['vendor_id'] ??= '';
        safeJson['setup_time'] ??= '1 hr';
        safeJson['booking_notice'] ??= '1 day';
        
        // Ensure numeric fields have fallback values
        safeJson['original_price'] ??= 0.0;
        safeJson['offer_price'] ??= 0.0;
        
        // Ensure list fields are initialized
        safeJson['theme_tags'] ??= <String>[];
        safeJson['service_environment'] ??= <String>[];
        safeJson['photos'] ??= <String>[];
        safeJson['inclusions'] ??= <String>[];
        safeJson['pincodes'] ??= <String>[];
        safeJson['venue_types'] ??= <String>[];
        
        // Ensure boolean fields have fallback values
        safeJson['is_active'] ??= true;
        safeJson['is_featured'] ??= false;
        safeJson['customization_available'] ??= false;
        
        return ServiceListing.fromJson(safeJson);
      }).toList();
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ServiceListingService: Error getting listings: $e');
      if (e is PostgrestException) {
// TODO: Replace with proper logging - print('🔴 ServiceListingService: Postgrest error details: ${e.details}');
// TODO: Replace with proper logging - print('🔴 ServiceListingService: Postgrest error message: ${e.message}');
      }
      rethrow;
    }
  }

  // Create a new service listing
  Future<ServiceListing> createListing(ServiceListing listing, String vendorId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User is not authenticated.');
      }
// TODO: Replace with proper logging - print('🔵 ServiceListingService: Creating new listing for vendor ID: $vendorId and auth user id ${currentUser.id}');
      
      final listingData = listing.toJson()
        ..['vendor_id'] = vendorId; // Use the passed vendor ID, not auth user ID

      // Remove fields that should not be sent on creation
      listingData.remove('id');
      listingData.remove('created_at');
      listingData.remove('updated_at');

// TODO: Replace with proper logging - print('🔵 ServiceListingService: Payload to be inserted: $listingData');

      final response = await _client
          .from('service_listings')
          .insert(listingData)
          .select()
          .single();
      
// TODO: Replace with proper logging - print('🟢 ServiceListingService: Listing created successfully. Response: $response');
      return ServiceListing.fromJson(response);
    } on PostgrestException {
// TODO: Replace with proper logging - print('🔴 ServiceListingService: Postgrest error creating listing:');
// TODO: Replace with proper logging - print('   - Message: ${e.message}');
// TODO: Replace with proper logging - print('   - Code: ${e.code}');
// TODO: Replace with proper logging - print('   - Details: ${e.details}');
      rethrow;
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ServiceListingService: A generic error occurred creating listing: $e');
// TODO: Replace with proper logging - print('   - Error Type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Update an existing service listing
  Future<ServiceListing> updateListing(ServiceListing listing) async {
    try {
// TODO: Replace with proper logging - print('🔵 ServiceListingService: Updating listing: ${listing.id}');
      
      final listingData = listing.toJson();
      // Remove fields that shouldn't be updated
      listingData.remove('id');
      listingData.remove('listing_id');
      listingData.remove('vendor_id');
      listingData.remove('created_at');
      listingData.remove('updated_at');
      
      final response = await _client
          .from('service_listings')
          .update(listingData)
          .eq('id', listing.id)
          .select()
          .single();
      
// TODO: Replace with proper logging - print('🟢 ServiceListingService: Listing updated successfully');
      return ServiceListing.fromJson(response);
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ServiceListingService: Error updating listing: $e');
      rethrow;
    }
  }

  // Delete a service listing
  Future<void> deleteListing(String listingId) async {
    try {
// TODO: Replace with proper logging - print('🔵 ServiceListingService: Deleting listing: $listingId');
      
      await _client
          .from('service_listings')
          .delete()
          .eq('id', listingId);
      
// TODO: Replace with proper logging - print('🟢 ServiceListingService: Listing deleted successfully');
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ServiceListingService: Error deleting listing: $e');
      rethrow;
    }
  }

  // Toggle listing active status
  Future<ServiceListing> toggleListingStatus(String listingId, bool isActive) async {
    try {
// TODO: Replace with proper logging - print('🔵 ServiceListingService: Toggling listing status: $listingId to $isActive');
      
      final response = await _client
          .from('service_listings')
          .update({'is_active': isActive})
          .eq('id', listingId)
          .select()
          .single();
      
// TODO: Replace with proper logging - print('🟢 ServiceListingService: Listing status updated successfully');
      return ServiceListing.fromJson(response);
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ServiceListingService: Error toggling listing status: $e');
      rethrow;
    }
  }

  // Request activation for a listing
  Future<ServiceListing> requestActivation(String listingId) async {
    try {
      final response = await _client
          .from('service_listings')
          .update({
            'activation_requested': true,
            'activation_requested_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', listingId)
          .select()
          .single();

      return ServiceListing.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Request deactivation for a listing
  Future<ServiceListing> requestDeactivation(String listingId) async {
    try {
      final response = await _client
          .from('service_listings')
          .update({
            'deactivation_requested': true,
            'deactivation_requested_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', listingId)
          .select()
          .single();

      return ServiceListing.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Pick and upload images for service listing
  Future<List<String>> pickAndUploadImages({
    required int maxImages,
    List<String> existingImages = const [],
  }) async {
    try {
// TODO: Replace with proper logging - print('🔵 ServiceListingService: Picking images (max: $maxImages)');
      
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final availableSlots = maxImages - existingImages.length;
      if (availableSlots <= 0) {
        throw Exception('Maximum images already selected');
      }

      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (images.isEmpty) return existingImages;

      final imagesToProcess = images.take(availableSlots).toList();
      final uploadedUrls = <String>[];

      for (int i = 0; i < imagesToProcess.length; i++) {
        final image = imagesToProcess[i];
        final imageFile = File(image.path);
        
        // Validate file size (max 10MB)
        final fileSize = await imageFile.length();
        if (fileSize > 10 * 1024 * 1024) {
// TODO: Replace with proper logging - print('🔴 ServiceListingService: Image ${i + 1} too large: $fileSize bytes');
          continue;
        }

        // Generate unique filename
        final extension = path.extension(image.path).toLowerCase();
        final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}_$i$extension';
        final filePath = '${user.id}/service-media/$fileName';
        
// TODO: Replace with proper logging - print('🔵 ServiceListingService: Uploading image ${i + 1}: $filePath');

        try {
          await _client.storage.from('service-listing-media').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

          final imageUrl = _client.storage
              .from('service-listing-media')
              .getPublicUrl(filePath);

          uploadedUrls.add(imageUrl);
// TODO: Replace with proper logging - print('🟢 ServiceListingService: Image uploaded successfully: $imageUrl');
        } catch (e) {
// TODO: Replace with proper logging - print('🔴 ServiceListingService: Error uploading image ${i + 1}: $e');
        }
      }

      return [...existingImages, ...uploadedUrls];
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ServiceListingService: Error picking/uploading images: $e');
      rethrow;
    }
  }

  // Pick and upload video for service listing
  Future<String?> pickAndUploadVideo() async {
    try {
// TODO: Replace with proper logging - print('🔵 ServiceListingService: Picking video');
      
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );

      if (video == null) return null;

      final videoFile = File(video.path);
      
      // Validate file size (max 50MB)
      final fileSize = await videoFile.length();
      if (fileSize > 50 * 1024 * 1024) {
        throw Exception('Video file too large. Maximum size is 50MB.');
      }

      // Generate unique filename
      final extension = path.extension(video.path).toLowerCase();
      final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}$extension';
      final filePath = '${user.id}/service-media/$fileName';
      
// TODO: Replace with proper logging - print('🔵 ServiceListingService: Uploading video: $filePath');

      await _client.storage.from('service-listing-media').upload(
        filePath,
        videoFile,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );

      final videoUrl = _client.storage
          .from('service-listing-media')
          .getPublicUrl(filePath);

// TODO: Replace with proper logging - print('🟢 ServiceListingService: Video uploaded successfully: $videoUrl');
      return videoUrl;
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ServiceListingService: Error picking/uploading video: $e');
      rethrow;
    }
  }

  // Delete media file from storage
  Future<void> deleteMediaFile(String fileUrl) async {
    try {
// TODO: Replace with proper logging - print('🔵 ServiceListingService: Deleting media file: $fileUrl');
      
      // Extract file path from URL
      final uri = Uri.parse(fileUrl);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf('service-listing-media');
      
      if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) {
        throw Exception('Invalid file URL format');
      }
      
      final filePath = segments.sublist(bucketIndex + 1).join('/');
      
      await _client.storage
          .from('service-listing-media')
          .remove([filePath]);
      
// TODO: Replace with proper logging - print('🟢 ServiceListingService: Media file deleted successfully');
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ServiceListingService: Error deleting media file: $e');
      rethrow;
    }
  }

  // Get active categories from database
  Future<List<String>> fetchActiveCategories() async {
    final response = await _client
        .from('categories')
        .select('name')
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return (response as List)
        .map((row) => row['name'] as String)
        .toList();
  }

  // Get theme tags for selection
  List<String> getThemeTags() {
    return [
      'Romantic',
      'Silver',
      'Gold',
      'Kids',
      'Vintage',
      'Modern',
      'Traditional',
      'Colorful',
      'Elegant',
      'Fun',
      'Luxury',
      'Simple',
      'Floral',
      'Balloon',
      'LED',
    ];
  }

  // Get service environment options
  List<String> getServiceEnvironments() {
    return [
      'indoor',
      'outdoor',
    ];
  }

  // Get setup time options
  List<String> getSetupTimeOptions() {
    return [
      '2 hours',
      '4 hours',
      '6 hours',
      '8 hours',
      '12 hours',
    ];
  }

  // Get booking notice options
  List<String> getBookingNoticeOptions() {
    return [
      '4 hours',
      '6 hours',
      '8 hours',
      '12 hours',
      '1 Day',
      '2 Days',
      '3 Days',
    ];
  }

  // Get venue types
  List<String> getVenueTypes() {
    return [
      'Home',
      'Apartment',
      'Café',
      'Restaurant',
      'Rooftop',
      'Garden',
      'Hall',
      'Hotel',
      'Office',
      'Outdoor',
      'Beach',
      'Farmhouse',
    ];
  }
} 