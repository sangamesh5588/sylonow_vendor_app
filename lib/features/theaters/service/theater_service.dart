import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:video_compress/video_compress.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/config/supabase_config.dart';
import '../models/private_theater.dart';
import '../models/theater_screen.dart';
import '../models/theater_time_slot.dart';

final theaterServiceProvider = Provider((ref) => TheaterService());

class TheaterService {
  final SupabaseClient _client = SupabaseConfig.client;
  final ImagePicker _picker = ImagePicker();

  // Get vendor's theaters
  Future<List<PrivateTheater>> getVendorTheaters(String ownerId) async {
    try {
// TODO: Replace with proper logging - print('🔵 TheaterService: Getting theaters for owner: $ownerId');
      
      final response = await _client
          .from('private_theaters')
          .select('*')
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);
      
// TODO: Replace with proper logging - print('🔵 TheaterService: Database response received');
// TODO: Replace with proper logging - print('🔵 TheaterService: Found ${response.length} theaters');
      
      return response.map((json) => PrivateTheater.fromJson(json)).toList();
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 TheaterService: Error getting theaters: $e');
      if (e is PostgrestException) {
// TODO: Replace with proper logging - print('🔴 TheaterService: Postgrest error details: ${e.details}');
// TODO: Replace with proper logging - print('🔴 TheaterService: Postgrest error message: ${e.message}');
      }
      rethrow;
    }
  }

  // Create a new theater
  Future<PrivateTheater> createTheater(PrivateTheater theater, String ownerId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User is not authenticated.');
      }
// TODO: Replace with proper logging - print('🔵 TheaterService: Creating new theater for owner ID: $ownerId');
      
      final theaterData = theater.toJson()
        ..['owner_id'] = ownerId;

      // Remove fields that should not be sent on creation
      theaterData.remove('id');
      theaterData.remove('created_at');
      theaterData.remove('updated_at');

// TODO: Replace with proper logging - print('🔵 TheaterService: Payload to be inserted: $theaterData');

      final response = await _client
          .from('private_theaters')
          .insert(theaterData)
          .select()
          .single();
      
// TODO: Replace with proper logging - print('🟢 TheaterService: Theater created successfully. Response: $response');
      return PrivateTheater.fromJson(response);
    } on PostgrestException {
// TODO: Replace with proper logging - print('🔴 TheaterService: Postgrest error creating theater:');
// TODO: Replace with proper logging - print('   - Message: ${e.message}');
// TODO: Replace with proper logging - print('   - Code: ${e.code}');
// TODO: Replace with proper logging - print('   - Details: ${e.details}');
      rethrow;
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 TheaterService: A generic error occurred creating theater: $e');
// TODO: Replace with proper logging - print('   - Error Type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Update an existing theater
  Future<PrivateTheater> updateTheater(PrivateTheater theater) async {
    try {
// TODO: Replace with proper logging - print('🔵 TheaterService: Updating theater: ${theater.id}');
      
      final theaterData = theater.toJson();
      // Remove fields that shouldn't be updated
      theaterData.remove('id');
      theaterData.remove('owner_id');
      theaterData.remove('created_at');
      theaterData.remove('updated_at');
      
      final response = await _client
          .from('private_theaters')
          .update(theaterData)
          .eq('id', theater.id)
          .select()
          .single();
      
// TODO: Replace with proper logging - print('🟢 TheaterService: Theater updated successfully');
      return PrivateTheater.fromJson(response);
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 TheaterService: Error updating theater: $e');
      rethrow;
    }
  }

  // Delete a theater
  Future<void> deleteTheater(String theaterId) async {
    try {
// TODO: Replace with proper logging - print('🔵 TheaterService: Deleting theater: $theaterId');
      
      await _client
          .from('private_theaters')
          .delete()
          .eq('id', theaterId);
      
// TODO: Replace with proper logging - print('🟢 TheaterService: Theater deleted successfully');
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 TheaterService: Error deleting theater: $e');
      rethrow;
    }
  }

  // Toggle theater active status
  Future<PrivateTheater> toggleTheaterStatus(String theaterId, bool isActive) async {
    try {
// TODO: Replace with proper logging - print('🔵 TheaterService: Toggling theater status: $theaterId to $isActive');
      
      final response = await _client
          .from('private_theaters')
          .update({'is_active': isActive})
          .eq('id', theaterId)
          .select()
          .single();
      
// TODO: Replace with proper logging - print('🟢 TheaterService: Theater status updated successfully');
      return PrivateTheater.fromJson(response);
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 TheaterService: Error toggling theater status: $e');
      rethrow;
    }
  }

  // Get screens for a theater
  Future<List<TheaterScreen>> getTheaterScreens(String theaterId) async {
    try {
// TODO: Replace with proper logging - print('🔵 TheaterService: Getting screens for theater: $theaterId');
      
      final response = await _client
          .from('theater_screens')
          .select('*')
          .eq('theater_id', theaterId)
          .order('screen_number', ascending: true);
      
// TODO: Replace with proper logging - print('🔵 TheaterService: Found ${response.length} screens');
      
      return response.map((json) => TheaterScreen.fromJson(json)).toList();
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 TheaterService: Error getting screens: $e');
      rethrow;
    }
  }

  // Create a new theater screen
  Future<TheaterScreen> createScreen(TheaterScreen screen) async {
    try {
// TODO: Replace with proper logging - print('🔵 TheaterService: Creating new screen for theater: ${screen.theaterId}');
      
      final screenData = screen.toJson();
      // Remove fields that should not be sent on creation
      screenData.remove('id');
      screenData.remove('created_at');
      screenData.remove('updated_at');

      final response = await _client
          .from('theater_screens')
          .insert(screenData)
          .select()
          .single();
      
// TODO: Replace with proper logging - print('🟢 TheaterService: Screen created successfully');
      return TheaterScreen.fromJson(response);
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 TheaterService: Error creating screen: $e');
      rethrow;
    }
  }

  // Update a theater screen
  Future<TheaterScreen> updateScreen(TheaterScreen screen) async {
    try {
// TODO: Replace with proper logging - print('🔵 TheaterService: Updating screen: ${screen.id}');
      
      final screenData = screen.toJson();
      screenData.remove('id');
      screenData.remove('theater_id');
      screenData.remove('created_at');
      screenData.remove('updated_at');
      
      final response = await _client
          .from('theater_screens')
          .update(screenData)
          .eq('id', screen.id)
          .select()
          .single();
      
// TODO: Replace with proper logging - print('🟢 TheaterService: Screen updated successfully');
      return TheaterScreen.fromJson(response);
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 TheaterService: Error updating screen: $e');
      rethrow;
    }
  }

  // Delete a theater screen
  Future<void> deleteScreen(String screenId) async {
    try {
// TODO: Replace with proper logging - print('🔵 TheaterService: Deleting screen: $screenId');
      
      await _client
          .from('theater_screens')
          .delete()
          .eq('id', screenId);
      
// TODO: Replace with proper logging - print('🟢 TheaterService: Screen deleted successfully');
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 TheaterService: Error deleting screen: $e');
      rethrow;
    }
  }

  // Get time slots for a theater
  Future<List<TheaterTimeSlot>> getTheaterTimeSlots(String theaterId, {String? screenId}) async {
    try {
// TODO: Replace with proper logging - print('🔵 TheaterService: Getting time slots for theater: $theaterId');
      
      var query = _client
          .from('theater_time_slots')
          .select('*')
          .eq('theater_id', theaterId);
      
      if (screenId != null) {
        query = query.eq('screen_id', screenId);
      }
      
      final response = await query.order('start_time', ascending: true);
      
// TODO: Replace with proper logging - print('🔵 TheaterService: Found ${response.length} time slots');
      
      return response.map((json) => TheaterTimeSlot.fromJson(json)).toList();
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 TheaterService: Error getting time slots: $e');
      rethrow;
    }
  }

  // Create theater time slots
  Future<List<TheaterTimeSlot>> createTimeSlots(List<TheaterTimeSlot> timeSlots) async {
    try {
// TODO: Replace with proper logging - print('🔵 TheaterService: Creating ${timeSlots.length} time slots');
      
      final slotsData = timeSlots.map((slot) {
        final data = slot.toJson();
        data.remove('id');
        data.remove('created_at');
        data.remove('updated_at');
        return data;
      }).toList();

      final response = await _client
          .from('theater_time_slots')
          .insert(slotsData)
          .select();
      
// TODO: Replace with proper logging - print('🟢 TheaterService: Time slots created successfully');
      return response.map((json) => TheaterTimeSlot.fromJson(json)).toList();
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 TheaterService: Error creating time slots: $e');
      rethrow;
    }
  }

  // Update a time slot
  Future<TheaterTimeSlot> updateTimeSlot(TheaterTimeSlot timeSlot) async {
    try {
// TODO: Replace with proper logging - print('🔵 TheaterService: Updating time slot: ${timeSlot.id}');
      
      final slotData = timeSlot.toJson();
      slotData.remove('id');
      slotData.remove('theater_id');
      slotData.remove('created_at');
      slotData.remove('updated_at');
      
      final response = await _client
          .from('theater_time_slots')
          .update(slotData)
          .eq('id', timeSlot.id)
          .select()
          .single();
      
// TODO: Replace with proper logging - print('🟢 TheaterService: Time slot updated successfully');
      return TheaterTimeSlot.fromJson(response);
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 TheaterService: Error updating time slot: $e');
      rethrow;
    }
  }

  // Delete time slots
  Future<void> deleteTimeSlots(List<String> slotIds) async {
    try {
// TODO: Replace with proper logging - print('🔵 TheaterService: Deleting ${slotIds.length} time slots');
      
      await _client
          .from('theater_time_slots')
          .delete()
          .inFilter('id', slotIds);
      
// TODO: Replace with proper logging - print('🟢 TheaterService: Time slots deleted successfully');
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 TheaterService: Error deleting time slots: $e');
      rethrow;
    }
  }

  // Convert image to JPEG format with optimization
  Future<Uint8List> _convertToJpeg(File imageFile, {int quality = 85}) async {
    try {
// TODO: Replace with proper logging - print('🔵 TheaterService: Converting image to JPEG format');
      
      // Read and decode the image
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Resize image if it's too large while maintaining aspect ratio
      img.Image resizedImage = originalImage;
      const int maxWidth = 1920;
      const int maxHeight = 1080;
      
      if (originalImage.width > maxWidth || originalImage.height > maxHeight) {
        // Calculate new dimensions maintaining aspect ratio
        double aspectRatio = originalImage.width / originalImage.height;
        int newWidth, newHeight;
        
        if (aspectRatio > 1) {
          // Landscape orientation
          newWidth = maxWidth;
          newHeight = (maxWidth / aspectRatio).round();
        } else {
          // Portrait orientation
          newHeight = maxHeight;
          newWidth = (maxHeight * aspectRatio).round();
        }
        
        resizedImage = img.copyResize(originalImage, width: newWidth, height: newHeight);
// TODO: Replace with proper logging - print('🔵 TheaterService: Resized image from ${originalImage.width}x${originalImage.height} to ${newWidth}x$newHeight');
      }

      // Convert to JPEG format with specified quality
      // Note: WebP encoding might not be available in this version of the image package
      // Using JPEG as fallback for now
      final jpegBytes = img.encodeJpg(resizedImage, quality: quality);
// TODO: Replace with proper logging - print('🟢 TheaterService: Image converted to JPEG successfully (WebP not available)');
      
      return Uint8List.fromList(jpegBytes);
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 TheaterService: Error converting image to JPEG: $e');
      rethrow;
    }
  }

  // Pick and upload images for theater
  Future<List<String>> pickAndUploadTheaterImages({
    required int maxImages,
    List<String> existingImages = const [],
  }) async {
    try {
// TODO: Replace with proper logging - print('🔵 TheaterService: Picking images (max: $maxImages)');
      
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
        imageQuality: 85,
      );

      if (images.isEmpty) return existingImages;

      final imagesToProcess = images.take(availableSlots).toList();
      final uploadedUrls = <String>[];

      for (int i = 0; i < imagesToProcess.length; i++) {
        final image = imagesToProcess[i];
        final imageFile = File(image.path);
        
        // Validate original file size (max 10MB)
        final fileSize = await imageFile.length();
        if (fileSize > 10 * 1024 * 1024) {
// TODO: Replace with proper logging - print('🔴 TheaterService: Image ${i + 1} too large: $fileSize bytes');
          continue;
        }

        try {
          // Convert image to optimized JPEG format
          final jpegBytes = await _convertToJpeg(imageFile, quality: 85);
          
          // Generate unique filename with JPEG extension
          final fileName = 'theater_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final filePath = '${user.id}/theater-media/$fileName';
          
// TODO: Replace with proper logging - print('🔵 TheaterService: Uploading JPEG image ${i + 1}: $filePath (${jpegBytes.length} bytes)');

          await _client.storage.from('theater-media').uploadBinary(
            filePath,
            jpegBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: 'image/jpeg',
            ),
          );

          final imageUrl = _client.storage
              .from('theater-media')
              .getPublicUrl(filePath);

          uploadedUrls.add(imageUrl);
// TODO: Replace with proper logging - print('🟢 TheaterService: JPEG image uploaded successfully: $imageUrl');
        } catch (e) {
// TODO: Replace with proper logging - print('🔴 TheaterService: Error processing/uploading image ${i + 1}: $e');
          // Continue to next image instead of failing completely
          continue;
        }
      }

      return [...existingImages, ...uploadedUrls];
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 TheaterService: Error picking/uploading images: $e');
      rethrow;
    }
  }

  // Pick and upload theater video (max 30 seconds)
  Future<String?> pickAndUploadTheaterVideo() async {
    try {
// TODO: Replace with proper logging - print('🔵 TheaterService: Picking video for theater');
      
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Pick video file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = File(result.files.single.path!);
      
      // Validate file size (max 100MB before compression)
      final fileSize = await file.length();
      if (fileSize > 100 * 1024 * 1024) {
        throw Exception('Video file too large. Maximum size is 100MB');
      }

// TODO: Replace with proper logging - print('🔵 TheaterService: Video picked, starting compression');

      // Compress video
      final compressedVideo = await _compressVideo(file);
      
      if (compressedVideo == null) {
        throw Exception('Failed to compress video');
      }

      // Validate compressed video duration (max 30 seconds)
      final mediaInfo = await VideoCompress.getMediaInfo(compressedVideo.path);
      final duration = mediaInfo.duration;
      
      if (duration != null && duration > 30000) { // 30 seconds in milliseconds
        await compressedVideo.delete(); // Clean up
        throw Exception('Video duration exceeds 30 seconds limit');
      }

// TODO: Replace with proper logging - print('🔵 TheaterService: Video compressed successfully');

      // Generate unique filename
      final fileName = 'theater_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final filePath = '${user.id}/theater-media/$fileName';
      
// TODO: Replace with proper logging - print('🔵 TheaterService: Uploading compressed video: $filePath');

      // Upload to Supabase storage
      final videoBytes = await compressedVideo.readAsBytes();
      await _client.storage.from('theater-media').uploadBinary(
        filePath,
        videoBytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
          contentType: 'video/mp4',
        ),
      );

      // Get public URL
      final videoUrl = _client.storage
          .from('theater-media')
          .getPublicUrl(filePath);

      // Clean up temporary file
      await compressedVideo.delete();

// TODO: Replace with proper logging - print('🟢 TheaterService: Video uploaded successfully: $videoUrl');
      return videoUrl;
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 TheaterService: Error picking/uploading video: $e');
      rethrow;
    }
  }

  // Compress video to reduce size and ensure quality
  Future<File?> _compressVideo(File videoFile) async {
    try {
// TODO: Replace with proper logging - print('🔵 TheaterService: Compressing video');
      
      final info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false, // Keep original file
        includeAudio: true,
      );
      
      if (info == null) {
        return null;
      }
      
      final compressedFile = File(info.path!);
      final compressedSize = await compressedFile.length();
      
// TODO: Replace with proper logging - print('🔵 TheaterService: Video compressed from ${await videoFile.length()} to $compressedSize bytes');
      
      return compressedFile;
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 TheaterService: Error compressing video: $e');
      return null;
    }
  }

  // Delete media file from storage
  Future<void> deleteMediaFile(String fileUrl) async {
    try {
// TODO: Replace with proper logging - print('🔵 TheaterService: Deleting media file: $fileUrl');
      
      // Extract file path from URL
      final uri = Uri.parse(fileUrl);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf('theater-media');
      
      if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) {
        throw Exception('Invalid file URL format');
      }
      
      final filePath = segments.sublist(bucketIndex + 1).join('/');
      
      await _client.storage
          .from('theater-media')
          .remove([filePath]);
      
// TODO: Replace with proper logging - print('🟢 TheaterService: Media file deleted successfully');
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 TheaterService: Error deleting media file: $e');
      rethrow;
    }
  }

  // Get amenities options
  List<String> getAmenities() {
    return [
      'AC',
      'WiFi',
      'Parking',
      'Sound System',
      'Projector',
      'Screen',
      'Microphone',
      'Stage Lighting',
      'Comfortable Seating',
      'Washroom',
      'Cafeteria',
      'Green Room',
      'Power Backup',
      'Security',
      'Elevator Access',
    ];
  }

  // Get time slot options
  List<String> getTimeSlotOptions() {
    return [
      '09:00',
      '10:00',
      '11:00',
      '12:00',
      '13:00',
      '14:00',
      '15:00',
      '16:00',
      '17:00',
      '18:00',
      '19:00',
      '20:00',
      '21:00',
      '22:00',
    ];
  }

  // Helper method to generate recurring time slots
  List<TheaterTimeSlot> generateTimeSlots({
    required String theaterId,
    String? screenId,
    required List<String> timeSlots,
    double basePrice = 0.0,
    double pricePerHour = 0.0,
  }) {
    final slots = <TheaterTimeSlot>[];
    
    for (int i = 0; i < timeSlots.length - 1; i++) {
      final startTime = timeSlots[i];
      final endTime = timeSlots[i + 1];
      
      slots.add(TheaterTimeSlot(
        id: '', // Will be generated by database
        theaterId: theaterId,
        screenId: screenId,
        startTime: startTime,
        endTime: endTime,
        basePrice: basePrice,
        pricePerHour: pricePerHour,
      ));
    }
    
    return slots;
  }
}