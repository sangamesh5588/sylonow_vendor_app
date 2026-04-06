import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/config/supabase_config.dart';
import '../models/theater_booking.dart';


part 'theater_booking_service.g.dart';

@riverpod
TheaterBookingService theaterBookingService(TheaterBookingServiceRef ref) {
  return TheaterBookingService();
}

class TheaterBookingService {
  final _client = SupabaseConfig.client;

  void _applySlotLinkedScreenData(
    Map<String, dynamic> source,
    Map<String, dynamic> flatData,
  ) {
    final slot = source['theater_time_slots'];
    if (slot is! Map<String, dynamic>) return;

    final basePrice = slot['base_price'];
    if (basePrice != null) {
      flatData['slot_base_price'] = (basePrice as num).toDouble();
    }

    final slotScreen = slot['theater_screens'];
    if (slotScreen is Map<String, dynamic>) {
      flatData['screen_name'] = slotScreen['screen_name'] ?? flatData['screen_name'];
      flatData['screen_number'] =
          slotScreen['screen_number'] ?? flatData['screen_number'];
      flatData['allowed_capacity'] =
          slotScreen['allowed_capacity'] ?? flatData['allowed_capacity'] ?? 0;
      flatData['charges_extra_per_person'] =
          (slotScreen['charges_extra_per_person'] as num?)?.toDouble() ??
              flatData['charges_extra_per_person'] ??
              0.0;
    }
  }

  // Helper method to get theater IDs for a vendor
  Future<List<String>> _getTheaterIdsForAuthUser(String authUserId) async {
    // Primary lookup: private_theaters.owner_id = authUserId
    final theaterResponse = await _client
        .from('private_theaters')
        .select('id')
        .eq('owner_id', authUserId);

    if (theaterResponse.isNotEmpty) {
      return theaterResponse.map<String>((t) => t['id'] as String).toList();
    }

    // Fallback: vendor_id column on private_theater_bookings
    // (handles vendors whose auth_user_id is stored as vendor_id in bookings)
    final bookingResponse = await _client
        .from('private_theater_bookings')
        .select('theater_id')
        .eq('vendor_id', authUserId);

    if (bookingResponse.isNotEmpty) {
      return (bookingResponse as List)
          .map<String>((b) => b['theater_id'] as String)
          .toSet()
          .toList();
    }

    return [];
  }


  // Get all bookings for a vendor's theaters
  Future<List<TheaterBooking>> getVendorBookings(String authUserId) async {
    try {
// TODO: Replace with proper logging - print('🔍 DEBUG: Fetching bookings for auth user: $authUserId');
      
      // Get theater IDs for this auth user
      final theaterIds = await _getTheaterIdsForAuthUser(authUserId);
      
      if (theaterIds.isEmpty) {
        return [];
      }
      
// TODO: Replace with proper logging - print('🔍 DEBUG: About to query bookings with theater IDs: $theaterIds');
      
      final response = await _client
          .from('private_theater_bookings')
          .select('''
            *,
            private_theater_booking_addons(
              id,
              addon_id,
              quantity,
              unit_price,
              total_price,
              add_ons(
                id,
                name,
                description,
                category,
                image_url
              )
            ),
            private_theaters!inner(
              name,
              theater_screens(
                screen_name,
                screen_number,
                allowed_capacity,
                charges_extra_per_person
              )
            ),
            theater_time_slots(
              base_price,
              screen_id,
              theater_screens(
                screen_name,
                screen_number,
                allowed_capacity,
                charges_extra_per_person
              )
            )
          ''')
          .inFilter('theater_id', theaterIds)
          .order('created_at', ascending: false);

// TODO: Replace with proper logging - print('🔍 DEBUG: Vendor bookings response: $response');
// TODO: Replace with proper logging - print('🔍 DEBUG: Response length: ${response.length}');
// TODO: Replace with proper logging - print('🔍 DEBUG: Response type: ${response.runtimeType}');
      
      if (response.isNotEmpty) {
// TODO: Replace with proper logging - print('🔍 DEBUG: First booking data: ${response[0]}');
      }

      if (response.isEmpty) {
// TODO: Replace with proper logging - print('🔍 DEBUG: Response is empty, returning empty list');
        return [];
      }

      // Collect user IDs that need profile lookup (where contact_name is "User")
      final userIdsToLookup = <String>[];
      for (final booking in response) {
        final contactName = booking['contact_name'] as String?;
        if (contactName == null || contactName == 'User' || contactName.isEmpty) {
          final userId = booking['user_id'] as String?;
          if (userId != null && !userIdsToLookup.contains(userId)) {
            userIdsToLookup.add(userId);
          }
        }
      }

      // Fetch user profiles for those users
      Map<String, String> userNames = {};
      if (userIdsToLookup.isNotEmpty) {
        final profilesResponse = await _client
            .from('user_profiles')
            .select('auth_user_id, full_name')
            .inFilter('auth_user_id', userIdsToLookup);

        for (final profile in profilesResponse) {
          final authUserId = profile['auth_user_id'] as String?;
          final fullName = profile['full_name'] as String?;
          if (authUserId != null && fullName != null && fullName.isNotEmpty) {
            userNames[authUserId] = fullName;
          }
        }
      }

      return response.map<TheaterBooking>((data) {
        // Process the booking data
        final flatData = Map<String, dynamic>.from(data);

        // Extract theater name and screen information
        if (data['private_theaters'] != null) {
          final theater = data['private_theaters'];
          flatData['theater_name'] = theater['name'];

          // Extract screen information from nested theater_screens
          if (theater['theater_screens'] != null && (theater['theater_screens'] as List).isNotEmpty) {
            final screen = (theater['theater_screens'] as List).first;
            flatData['screen_name'] = screen['screen_name'];
            flatData['screen_number'] = screen['screen_number'];
            flatData['allowed_capacity'] = screen['allowed_capacity'] ?? 0;
            flatData['charges_extra_per_person'] = (screen['charges_extra_per_person'] as num?)?.toDouble() ?? 0.0;
          }
        }

        // Override with exact booked screen/rates from selected slot
        _applySlotLinkedScreenData(data, flatData);

        // Use user profile name if contact_name is generic "User"
        final currentContactName = flatData['contact_name'] as String?;
        final userId = flatData['user_id'] as String?;
        if ((currentContactName == null || currentContactName == 'User' || currentContactName.isEmpty) &&
            userId != null && userNames.containsKey(userId)) {
          flatData['contact_name'] = userNames[userId];
        }

        // Process add-ons if they exist
        if (data['private_theater_booking_addons'] != null) {
          final addons = data['private_theater_booking_addons'] as List;
          flatData['selected_addons'] = addons.map((addon) => {
            'addon_id': addon['addon_id'],
            'addon_name': addon['add_ons']?['name'],
            'addon_description': addon['add_ons']?['description'],
            'addon_category': addon['add_ons']?['category'],
            'addon_image_url': addon['add_ons']?['image_url'],
            'quantity': addon['quantity'],
            'unit_price': addon['unit_price'],
            'total_price': addon['total_price'],
          }).toList();
        }

        // Remove nested objects
        flatData.remove('private_theater_booking_addons');
        flatData.remove('private_theaters');
        flatData.remove('theater_time_slots');

        return TheaterBooking.fromJson(flatData);
      }).toList();
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ERROR: Failed to fetch vendor bookings: $e');
      rethrow;
    }
  }

  // Get bookings for a specific theater
  Future<List<TheaterBooking>> getTheaterBookings(String theaterId) async {
    try {
// TODO: Replace with proper logging - print('🔍 DEBUG: Fetching bookings for theater: $theaterId');
      
      final response = await _client
          .from('private_theater_bookings')
          .select('''
            *,
            private_theater_booking_addons(
              id,
              addon_id,
              quantity,
              unit_price,
              total_price,
              add_ons(
                id,
                name,
                description,
                category,
                image_url
              )
            )
          ''')
          .eq('theater_id', theaterId)
          .order('booking_date', ascending: false);

// TODO: Replace with proper logging - print('🔍 DEBUG: Theater bookings response: $response');

      if (response.isEmpty) {
        return [];
      }

      return response.map<TheaterBooking>((data) {
        // Process the booking data
        final flatData = Map<String, dynamic>.from(data);
        
        // Theater name and screen info will be fetched separately if needed
        // For now, we'll just use the theater_id to identify the theater
        
        // Process add-ons if they exist
        if (data['private_theater_booking_addons'] != null) {
          final addons = data['private_theater_booking_addons'] as List;
          flatData['selected_addons'] = addons.map((addon) => {
            'addon_id': addon['addon_id'],
            'addon_name': addon['add_ons']?['name'],
            'addon_description': addon['add_ons']?['description'],
            'addon_category': addon['add_ons']?['category'],
            'addon_image_url': addon['add_ons']?['image_url'],
            'quantity': addon['quantity'],
            'unit_price': addon['unit_price'],
            'total_price': addon['total_price'],
          }).toList();
        }

        // Remove nested objects
        flatData.remove('private_theater_booking_addons');
        
        return TheaterBooking.fromJson(flatData);
      }).toList();
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ERROR: Failed to fetch theater bookings: $e');
      rethrow;
    }
  }

  // Get booking by ID
  Future<TheaterBooking?> getBookingById(String bookingId) async {
    try {
// TODO: Replace with proper logging - print('🔍 DEBUG: Fetching booking by ID: $bookingId');
      
      final response = await _client
          .from('private_theater_bookings')
          .select('''
            *,
            private_theater_booking_addons(
              id,
              addon_id,
              quantity,
              unit_price,
              total_price,
              add_ons(
                id,
                name,
                description,
                category,
                image_url
              )
            ),
            private_theaters!inner(
              name,
              theater_screens(
                images,
                screen_name,
                screen_number,
                allowed_capacity,
                charges_extra_per_person
              )
            ),
            theater_time_slots(
              base_price,
              screen_id,
              theater_screens(
                images,
                screen_name,
                screen_number,
                allowed_capacity,
                charges_extra_per_person
              )
            )
          ''')
          .eq('id', bookingId)
          .maybeSingle();

// TODO: Replace with proper logging - print('🔍 DEBUG: Booking by ID response: $response');

      if (response == null) {
        return null;
      }

      // Process the booking data
      final flatData = Map<String, dynamic>.from(response);
      
      // Process theater information
      if (response['private_theaters'] != null) {
        final theater = response['private_theaters'];
        flatData['theater_name'] = theater['name'];

        // Fallback from theater-level screens (will be overridden by slot-linked screen below)
        if (theater['theater_screens'] != null && (theater['theater_screens'] as List).isNotEmpty) {
          final screen = (theater['theater_screens'] as List).first;
          flatData['screen_name'] = screen['screen_name'];
          flatData['screen_number'] = screen['screen_number'];
          flatData['screen_images'] = screen['images'] ?? [];
          flatData['allowed_capacity'] = screen['allowed_capacity'] ?? 0;
          flatData['charges_extra_per_person'] = (screen['charges_extra_per_person'] as num?)?.toDouble() ?? 0.0;
        }
      }
      
      // Process add-ons if they exist
      if (response['private_theater_booking_addons'] != null) {
        final addons = response['private_theater_booking_addons'] as List;
        flatData['selected_addons'] = addons.map((addon) => {
          'addon_id': addon['addon_id'],
          'addon_name': addon['add_ons']?['name'],
          'addon_description': addon['add_ons']?['description'],
          'addon_category': addon['add_ons']?['category'],
            'addon_image_url': addon['add_ons']?['image_url'],
            'quantity': addon['quantity'],
          'unit_price': addon['unit_price'],
          'total_price': addon['total_price'],
        }).toList();
      }

      // Extract slot base price + exact booked screen (via time_slot -> screen_id)
      if (response['theater_time_slots'] != null) {
        final slot = response['theater_time_slots'];
        final basePrice = slot['base_price'];
        if (basePrice != null) {
          flatData['slot_base_price'] = (basePrice as num).toDouble();
        }

        final slotScreen = slot['theater_screens'];
        if (slotScreen != null) {
          flatData['screen_name'] = slotScreen['screen_name'] ?? flatData['screen_name'];
          flatData['screen_number'] = slotScreen['screen_number'] ?? flatData['screen_number'];
          flatData['screen_images'] = slotScreen['images'] ?? flatData['screen_images'] ?? [];
          flatData['allowed_capacity'] =
              slotScreen['allowed_capacity'] ?? flatData['allowed_capacity'] ?? 0;
          flatData['charges_extra_per_person'] =
              (slotScreen['charges_extra_per_person'] as num?)?.toDouble() ??
                  flatData['charges_extra_per_person'] ??
                  0.0;
        }
      }

      // Remove nested objects
      flatData.remove('private_theater_booking_addons');
      flatData.remove('private_theaters');
      flatData.remove('theater_time_slots');

      return TheaterBooking.fromJson(flatData);
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ERROR: Failed to fetch booking by ID: $e');
      rethrow;
    }
  }

  // Update booking status
  Future<TheaterBooking> updateBookingStatus(String bookingId, String status) async {
    try {
// TODO: Replace with proper logging - print('🔍 DEBUG: Updating booking status for $bookingId to $status');
      
      final response = await _client
          .from('private_theater_bookings')
          .update({'booking_status': status, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', bookingId)
          .select('''
            *,
            private_theater_booking_addons(
              id,
              addon_id,
              quantity,
              unit_price,
              total_price,
              add_ons(
                id,
                name,
                description,
                category,
                image_url
              )
            )
          ''')
          .single();

// TODO: Replace with proper logging - print('🔍 DEBUG: Updated booking response: $response');

      // Process the booking data
      final flatData = Map<String, dynamic>.from(response);
      
      // Process add-ons if they exist
      if (response['private_theater_booking_addons'] != null) {
        final addons = response['private_theater_booking_addons'] as List;
        flatData['selected_addons'] = addons.map((addon) => {
          'addon_id': addon['addon_id'],
          'addon_name': addon['add_ons']?['name'],
          'addon_description': addon['add_ons']?['description'],
          'addon_category': addon['add_ons']?['category'],
            'addon_image_url': addon['add_ons']?['image_url'],
            'quantity': addon['quantity'],
          'unit_price': addon['unit_price'],
          'total_price': addon['total_price'],
        }).toList();
      }

      // Remove nested objects
      flatData.remove('private_theater_booking_addons');
      
      return TheaterBooking.fromJson(flatData);
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ERROR: Failed to update booking status: $e');
      rethrow;
    }
  }

  // Update payment status
  Future<TheaterBooking> updatePaymentStatus(String bookingId, String paymentStatus) async {
    try {
// TODO: Replace with proper logging - print('🔍 DEBUG: Updating payment status for $bookingId to $paymentStatus');
      
      final response = await _client
          .from('private_theater_bookings')
          .update({'payment_status': paymentStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', bookingId)
          .select('''
            *,
            private_theater_booking_addons(
              id,
              addon_id,
              quantity,
              unit_price,
              total_price,
              add_ons(
                id,
                name,
                description,
                category,
                image_url
              )
            )
          ''')
          .single();

// TODO: Replace with proper logging - print('🔍 DEBUG: Updated payment response: $response');

      // Process the booking data
      final flatData = Map<String, dynamic>.from(response);
      
      // Process add-ons if they exist
      if (response['private_theater_booking_addons'] != null) {
        final addons = response['private_theater_booking_addons'] as List;
        flatData['selected_addons'] = addons.map((addon) => {
          'addon_id': addon['addon_id'],
          'addon_name': addon['add_ons']?['name'],
          'addon_description': addon['add_ons']?['description'],
          'addon_category': addon['add_ons']?['category'],
            'addon_image_url': addon['add_ons']?['image_url'],
            'quantity': addon['quantity'],
          'unit_price': addon['unit_price'],
          'total_price': addon['total_price'],
        }).toList();
      }

      // Remove nested objects
      flatData.remove('private_theater_booking_addons');
      
      return TheaterBooking.fromJson(flatData);
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ERROR: Failed to update payment status: $e');
      rethrow;
    }
  }

  // Get booking statistics for vendor using the new view
  Future<Map<String, dynamic>> getBookingStats(String authUserId) async {
    try {
// TODO: Replace with proper logging - print('🔍 DEBUG: Fetching booking stats for auth user: $authUserId');

      // theater_booking_stats uses auth_user_id in vendor_id and can return multiple rows (per theater)
      final response = await _client
          .from('theater_booking_stats')
          .select('*')
          .eq('vendor_id', authUserId);

      if (response.isEmpty) {
// TODO: Replace with proper logging - print('🔍 DEBUG: No stats found for vendor, returning zero stats with theater count');
        return await _getEmptyStatsWithTheaterCount(authUserId);
      }

      // Get actual theater count and screen count from database
      final theaterCountResponse = await _client
          .from('private_theaters')
          .select('id')
          .eq('owner_id', authUserId);
      final theaterCount = theaterCountResponse.length;
      
      // Count screens across all theaters for this auth user
      int screenCount = 0;
      if (theaterCountResponse.isNotEmpty) {
        for (final theater in theaterCountResponse) {
          final theaterId = theater['id'] as String;
          final screenResponse = await _client
              .from('theater_screens')
              .select('id')
              .eq('theater_id', theaterId);
          screenCount += screenResponse.length;
        }
      }
      
      if (kDebugMode) {
        print('🟢 TheaterBookingService: Found $screenCount screens for auth_user_id: $authUserId');
      }

      int totalBookings = 0;
      int confirmedBookings = 0;
      int cancelledBookings = 0;
      int completedBookings = 0;
      double totalRevenue = 0.0;
      double pendingRevenue = 0.0;
      double grossSales = 0.0;
      int paidBookings = 0;
      int pendingPayments = 0;
      int failedPayments = 0;
      int todayBookings = 0;
      int thisMonthBookings = 0;
      double thisMonthRevenue = 0.0;
      int upcomingBookings = 0;
      int totalCustomers = 0;

      for (final row in response) {
        totalBookings += (row['total_bookings'] as num?)?.toInt() ?? 0;
        confirmedBookings += (row['confirmed_bookings'] as num?)?.toInt() ?? 0;
        cancelledBookings += (row['cancelled_bookings'] as num?)?.toInt() ?? 0;
        completedBookings += (row['completed_bookings'] as num?)?.toInt() ?? 0;
        totalRevenue += (row['total_revenue'] as num?)?.toDouble() ?? 0.0;
        pendingRevenue += (row['pending_revenue'] as num?)?.toDouble() ?? 0.0;
        grossSales += (row['gross_sales'] as num?)?.toDouble() ?? 0.0;
        paidBookings += (row['paid_bookings'] as num?)?.toInt() ?? 0;
        pendingPayments += (row['pending_payments'] as num?)?.toInt() ?? 0;
        failedPayments += (row['failed_payments'] as num?)?.toInt() ?? 0;
        todayBookings += (row['today_bookings'] as num?)?.toInt() ?? 0;
        thisMonthBookings += (row['this_month_bookings'] as num?)?.toInt() ?? 0;
        thisMonthRevenue += (row['this_month_revenue'] as num?)?.toDouble() ?? 0.0;
        upcomingBookings += (row['upcoming_bookings'] as num?)?.toInt() ?? 0;
        totalCustomers += (row['unique_customers'] as num?)?.toInt() ?? 0;
      }

      final stats = {
        'total_bookings': totalBookings,
        'confirmed_bookings': confirmedBookings,
        'cancelled_bookings': cancelledBookings,
        'completed_bookings': completedBookings,
        'total_revenue': totalRevenue,
        'pending_revenue': pendingRevenue,
        'gross_sales': grossSales,
        'paid_bookings': paidBookings,
        'pending_payments': pendingPayments,
        'failed_payments': failedPayments,
        'today_bookings': todayBookings,
        'upcoming_bookings': upcomingBookings,
        'this_month_bookings': thisMonthBookings,
        'this_month_revenue': thisMonthRevenue,
        'avg_booking_value': totalBookings > 0 ? grossSales / totalBookings : 0.0,
        'total_customers': totalCustomers,
        'total_theaters': theaterCount,
        'total_screens': screenCount,
      };
      
// TODO: Replace with proper logging - print('🔍 DEBUG: Processed stats with $theaterCount theaters: $stats');
      return stats;
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ERROR: Failed to fetch booking stats: $e');
      // Return default stats with theater count on error
      return await _getEmptyStatsWithTheaterCount(authUserId);
    }
  }

  // Helper method to get empty stats with actual theater and screen count
  Future<Map<String, dynamic>> _getEmptyStatsWithTheaterCount(String authUserId) async {
    try {
      final theaterCountResponse = await _client
          .from('private_theaters')
          .select('id')
          .eq('owner_id', authUserId);
      final theaterCount = theaterCountResponse.length;
      
      // Count screens across all theaters for this auth user
      int screenCount = 0;
      if (theaterCountResponse.isNotEmpty) {
        for (final theater in theaterCountResponse) {
          final theaterId = theater['id'] as String;
          final screenResponse = await _client
              .from('theater_screens')
              .select('id')
              .eq('theater_id', theaterId);
          screenCount += screenResponse.length;
        }
      }
      
      return {
        'total_bookings': 0,
        'confirmed_bookings': 0,
        'cancelled_bookings': 0,
        'completed_bookings': 0,
        'total_revenue': 0.0,
        'gross_sales': 0.0,
        'pending_payments': 0,
        'today_bookings': 0,
        'upcoming_bookings': 0,
        'this_month_bookings': 0,
        'this_month_revenue': 0.0,
        'avg_booking_value': 0.0,
        'total_customers': 0,
        'total_theaters': theaterCount,
        'total_screens': screenCount,
      };
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ERROR: Failed to get theater count: $e');
      return {
        'total_bookings': 0,
        'confirmed_bookings': 0,
        'cancelled_bookings': 0,
        'completed_bookings': 0,
        'total_revenue': 0.0,
        'gross_sales': 0.0,
        'pending_payments': 0,
        'today_bookings': 0,
        'upcoming_bookings': 0,
        'this_month_bookings': 0,
        'this_month_revenue': 0.0,
        'avg_booking_value': 0.0,
        'total_customers': 0,
        'total_theaters': 0,
        'total_screens': 0,
      };
    }
  }

  // Helper method to calculate booking statistics
  Map<String, dynamic> _calculateBookingStats(List<dynamic> bookings) {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    var totalBookings = 0;
    var confirmedBookings = 0;
    var cancelledBookings = 0;
    var completedBookings = 0;
    var totalRevenue = 0.0;
    var pendingPayments = 0;
    var todayBookings = 0;
    var upcomingBookings = 0;
    
    for (final booking in bookings) {
      totalBookings++;
      
      final status = booking['booking_status']?.toString().toLowerCase() ?? '';
      final paymentStatus = booking['payment_status']?.toString().toLowerCase() ?? '';
      final amount = booking['total_amount']?.toDouble() ?? 0.0;
      final bookingDate = booking['booking_date']?.toString() ?? '';
      
      // Count by booking status
      switch (status) {
        case 'confirmed':
          confirmedBookings++;
          break;
        case 'cancelled':
          cancelledBookings++;
          break;
        case 'completed':
          completedBookings++;
          break;
      }
      
      // Count revenue and pending payments
      if (paymentStatus == 'paid') {
        totalRevenue += amount;
      } else if (paymentStatus == 'pending') {
        pendingPayments++;
      }
      
      // Count today's bookings
      if (bookingDate.startsWith(todayStr)) {
        todayBookings++;
      }
      
      // Count upcoming bookings (confirmed bookings after today)
      if (status == 'confirmed' && bookingDate.compareTo(todayStr) >= 0) {
        upcomingBookings++;
      }
    }
    
    return {
      'total_bookings': totalBookings,
      'confirmed_bookings': confirmedBookings,
      'cancelled_bookings': cancelledBookings,
      'completed_bookings': completedBookings,
      'total_revenue': totalRevenue,
      'pending_payments': pendingPayments,
      'today_bookings': todayBookings,
      'upcoming_bookings': upcomingBookings,
    };
  }

  // Get today's bookings
  Future<List<TheaterBooking>> getTodayBookings(String authUserId) async {
    try {
// TODO: Replace with proper logging - print('🔍 DEBUG: Fetching today bookings for auth user: $authUserId');
      
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Get theater IDs for this auth user
      final theaterIds = await _getTheaterIdsForAuthUser(authUserId);
      
      if (theaterIds.isEmpty) {
        return [];
      }
      
      final response = await _client
          .from('private_theater_bookings')
          .select('''
            *,
            private_theater_booking_addons(
              id,
              addon_id,
              quantity,
              unit_price,
              total_price,
              add_ons(
                id,
                name,
                description,
                category,
                image_url
              )
            ),
            private_theaters!inner(
              theater_screens(
                allowed_capacity,
                charges_extra_per_person
              )
            ),
            theater_time_slots(
              base_price,
              screen_id,
              theater_screens(
                screen_name,
                screen_number,
                allowed_capacity,
                charges_extra_per_person
              )
            )
          ''')
          .inFilter('theater_id', theaterIds)
          .eq('booking_date', today)
          .order('start_time', ascending: true);

// TODO: Replace with proper logging - print('🔍 DEBUG: Today bookings response: $response');

      if (response.isEmpty) {
        return [];
      }

      return response.map<TheaterBooking>((data) {
        final flatData = Map<String, dynamic>.from(data);

        // Extract capacity pricing from joined theater_screens
        if (data['private_theaters'] != null) {
          final theater = data['private_theaters'];
          final screens = theater['theater_screens'] as List?;
          if (screens != null && screens.isNotEmpty) {
            final screen = screens.first;
            flatData['allowed_capacity'] = screen['allowed_capacity'] ?? 0;
            flatData['charges_extra_per_person'] = (screen['charges_extra_per_person'] as num?)?.toDouble() ?? 0.0;
          }
        }

        // Override with exact booked screen/rates from selected slot
        _applySlotLinkedScreenData(data, flatData);

        // Process add-ons if they exist
        if (data['private_theater_booking_addons'] != null) {
          final addons = data['private_theater_booking_addons'] as List;
          flatData['selected_addons'] = addons.map((addon) => {
            'addon_id': addon['addon_id'],
            'addon_name': addon['add_ons']?['name'],
            'addon_description': addon['add_ons']?['description'],
            'addon_category': addon['add_ons']?['category'],
            'addon_image_url': addon['add_ons']?['image_url'],
            'quantity': addon['quantity'],
            'unit_price': addon['unit_price'],
            'total_price': addon['total_price'],
          }).toList();
        }

        flatData.remove('private_theater_booking_addons');
        flatData.remove('private_theaters');
        flatData.remove('theater_time_slots');

        return TheaterBooking.fromJson(flatData);
      }).toList();
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ERROR: Failed to fetch today bookings: $e');
      rethrow;
    }
  }

  // Get upcoming bookings
  Future<List<TheaterBooking>> getUpcomingBookings(String authUserId) async {
    try {
// TODO: Replace with proper logging - print('🔍 DEBUG: Fetching upcoming bookings for auth user: $authUserId');
      
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Get theater IDs for this auth user
      final theaterIds = await _getTheaterIdsForAuthUser(authUserId);
      
      if (theaterIds.isEmpty) {
        return [];
      }
      
      final response = await _client
          .from('private_theater_bookings')
          .select('''
            *,
            private_theater_booking_addons(
              id,
              addon_id,
              quantity,
              unit_price,
              total_price,
              add_ons(
                id,
                name,
                description,
                category,
                image_url
              )
            ),
            private_theaters!inner(
              theater_screens(
                allowed_capacity,
                charges_extra_per_person
              )
            ),
            theater_time_slots(
              base_price,
              screen_id,
              theater_screens(
                screen_name,
                screen_number,
                allowed_capacity,
                charges_extra_per_person
              )
            )
          ''')
          .inFilter('theater_id', theaterIds)
          .gte('booking_date', today)
          .eq('booking_status', 'confirmed')
          .order('booking_date', ascending: true)
          .limit(10);

// TODO: Replace with proper logging - print('🔍 DEBUG: Upcoming bookings response: $response');

      if (response.isEmpty) {
        return [];
      }

      return response.map<TheaterBooking>((data) {
        final flatData = Map<String, dynamic>.from(data);

        if (data['private_theaters'] != null) {
          final screens = (data['private_theaters']['theater_screens'] as List?);
          if (screens != null && screens.isNotEmpty) {
            flatData['allowed_capacity'] = screens.first['allowed_capacity'] ?? 0;
            flatData['charges_extra_per_person'] = (screens.first['charges_extra_per_person'] as num?)?.toDouble() ?? 0.0;
          }
        }
        _applySlotLinkedScreenData(data, flatData);

        if (data['private_theater_booking_addons'] != null) {
          final addons = data['private_theater_booking_addons'] as List;
          flatData['selected_addons'] = addons.map((addon) => {
            'addon_id': addon['addon_id'],
            'addon_name': addon['add_ons']?['name'],
            'addon_description': addon['add_ons']?['description'],
            'addon_category': addon['add_ons']?['category'],
            'addon_image_url': addon['add_ons']?['image_url'],
            'quantity': addon['quantity'],
            'unit_price': addon['unit_price'],
            'total_price': addon['total_price'],
          }).toList();
        }

        flatData.remove('private_theater_booking_addons');
        flatData.remove('private_theaters');
        flatData.remove('theater_time_slots');

        return TheaterBooking.fromJson(flatData);
      }).toList();
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ERROR: Failed to fetch upcoming bookings: $e');
      rethrow;
    }
  }

  // Filter bookings by status
  Future<List<TheaterBooking>> getBookingsByStatus(String authUserId, String status) async {
    try {
// TODO: Replace with proper logging - print('🔍 DEBUG: Fetching bookings by status for auth user: $authUserId, status: $status');
      
      // Get theater IDs for this auth user
      final theaterIds = await _getTheaterIdsForAuthUser(authUserId);
      
      if (theaterIds.isEmpty) {
// TODO: Replace with proper logging - print('🔍 DEBUG: No theaters found for auth user, returning empty list');
        return [];
      }
      
// TODO: Replace with proper logging - print('🔍 DEBUG: Querying bookings for theater IDs: $theaterIds with status: $status');
      
      final response = await _client
          .from('private_theater_bookings')
          .select('''
            *,
            private_theater_booking_addons(
              id,
              addon_id,
              quantity,
              unit_price,
              total_price,
              add_ons(
                id,
                name,
                description,
                category,
                image_url
              )
            ),
            private_theaters!inner(
              theater_screens(
                allowed_capacity,
                charges_extra_per_person
              )
            ),
            theater_time_slots(
              base_price,
              screen_id,
              theater_screens(
                screen_name,
                screen_number,
                allowed_capacity,
                charges_extra_per_person
              )
            )
          ''')
          .inFilter('theater_id', theaterIds)
          .eq('booking_status', status)
          .order('created_at', ascending: false);

// TODO: Replace with proper logging - print('🔍 DEBUG: Bookings by status response for status "$status": ${response.length} bookings found');
// TODO: Replace with proper logging - print('🔍 DEBUG: Raw response: $response');

      if (response.isEmpty) {
        return [];
      }

      return response.map<TheaterBooking>((data) {
        final flatData = Map<String, dynamic>.from(data);

        if (data['private_theaters'] != null) {
          final screens = (data['private_theaters']['theater_screens'] as List?);
          if (screens != null && screens.isNotEmpty) {
            flatData['allowed_capacity'] = screens.first['allowed_capacity'] ?? 0;
            flatData['charges_extra_per_person'] = (screens.first['charges_extra_per_person'] as num?)?.toDouble() ?? 0.0;
          }
        }
        _applySlotLinkedScreenData(data, flatData);

        if (data['private_theater_booking_addons'] != null) {
          final addons = data['private_theater_booking_addons'] as List;
          flatData['selected_addons'] = addons.map((addon) => {
            'addon_id': addon['addon_id'],
            'addon_name': addon['add_ons']?['name'],
            'addon_description': addon['add_ons']?['description'],
            'addon_category': addon['add_ons']?['category'],
            'addon_image_url': addon['add_ons']?['image_url'],
            'quantity': addon['quantity'],
            'unit_price': addon['unit_price'],
            'total_price': addon['total_price'],
          }).toList();
        }

        flatData.remove('private_theater_booking_addons');
        flatData.remove('private_theaters');
        flatData.remove('theater_time_slots');

        return TheaterBooking.fromJson(flatData);
      }).toList();
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ERROR: Failed to fetch bookings by status: $e');
      rethrow;
    }
  }

  // Search bookings
  Future<List<TheaterBooking>> searchBookings(String authUserId, String query) async {
    try {
// TODO: Replace with proper logging - print('🔍 DEBUG: Searching bookings for auth user: $authUserId, query: $query');
      
      // Get theater IDs for this auth user
      final theaterIds = await _getTheaterIdsForAuthUser(authUserId);
      
      if (theaterIds.isEmpty) {
        return [];
      }
      
      final response = await _client
          .from('private_theater_bookings')
          .select('''
            *,
            private_theater_booking_addons(
              id,
              addon_id,
              quantity,
              unit_price,
              total_price,
              add_ons(
                id,
                name,
                description,
                category,
                image_url
              )
            ),
            private_theaters!inner(
              theater_screens(
                allowed_capacity,
                charges_extra_per_person
              )
            ),
            theater_time_slots(
              base_price,
              screen_id,
              theater_screens(
                screen_name,
                screen_number,
                allowed_capacity,
                charges_extra_per_person
              )
            )
          ''')
          .inFilter('theater_id', theaterIds)
          .or('contact_name.ilike.%$query%,contact_phone.ilike.%$query%,celebration_name.ilike.%$query%')
          .order('created_at', ascending: false);

// TODO: Replace with proper logging - print('🔍 DEBUG: Search bookings response: $response');

      if (response.isEmpty) {
        return [];
      }

      return response.map<TheaterBooking>((data) {
        final flatData = Map<String, dynamic>.from(data);

        // Extract capacity fields from theater_screens via private_theaters join
        if (data['private_theaters'] != null) {
          final theater = data['private_theaters'] as Map<String, dynamic>;
          if (theater['theater_screens'] != null) {
            final screenList = theater['theater_screens'] as List;
            if (screenList.isNotEmpty) {
              final screen = screenList.first as Map<String, dynamic>;
              flatData['allowed_capacity'] = screen['allowed_capacity'] ?? 0;
              flatData['charges_extra_per_person'] =
                  (screen['charges_extra_per_person'] as num?)?.toDouble() ?? 0.0;
            }
          }
        }
        flatData.remove('private_theaters');

        // Override with exact booked screen/rates from selected slot
        _applySlotLinkedScreenData(data, flatData);
        flatData.remove('theater_time_slots');

        // Process add-ons
        if (data['private_theater_booking_addons'] != null) {
          final addons = data['private_theater_booking_addons'] as List;
          flatData['selected_addons'] = addons.map((addon) => {
            'addon_id': addon['addon_id'],
            'addon_name': addon['add_ons']?['name'],
            'addon_description': addon['add_ons']?['description'],
            'addon_category': addon['add_ons']?['category'],
            'addon_image_url': addon['add_ons']?['image_url'],
            'quantity': addon['quantity'],
            'unit_price': addon['unit_price'],
            'total_price': addon['total_price'],
          }).toList();
        }
        flatData.remove('private_theater_booking_addons');

        return TheaterBooking.fromJson(flatData);
      }).toList();
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ERROR: Failed to search bookings: $e');
      rethrow;
    }
  }

  // Get screen images for a theater
  Future<List<String>> getScreenImages(
    String theaterId, {
    String? screenName,
    String? timeSlotId,
  }) async {
    try {
// TODO: Replace with proper logging - print('🔍 DEBUG: Fetching screen images for theater: $theaterId');

      // Highest priority: exact booked screen via time_slot_id -> theater_time_slots.screen_id
      if (timeSlotId != null && timeSlotId.trim().isNotEmpty) {
        final slotRows = await _client
            .from('theater_time_slots')
            .select('screen_id')
            .eq('id', timeSlotId.trim())
            .limit(1);

        if (slotRows is List && slotRows.isNotEmpty) {
          final slotRow = slotRows.first as Map<String, dynamic>;
          final screenId = slotRow['screen_id'] as String?;
          if (screenId != null && screenId.isNotEmpty) {
            final screenRows = await _client
                .from('theater_screens')
                .select('images')
                .eq('id', screenId)
                .eq('theater_id', theaterId)
                .limit(1);

            if (screenRows is List && screenRows.isNotEmpty) {
              final first = screenRows.first as Map<String, dynamic>;
              final images = (first['images'] as List<dynamic>?)
                      ?.map<String>((img) => img.toString())
                      .where((img) => img.isNotEmpty)
                      .toList() ??
                  const <String>[];
              if (images.isNotEmpty) return images;
            }
          }
        }
      }

      if (screenName != null && screenName.trim().isNotEmpty) {
        final selectedScreenResponse = await _client
            .from('theater_screens')
            .select('images')
            .eq('theater_id', theaterId)
            .eq('screen_name', screenName.trim())
            .limit(1);

        if (selectedScreenResponse is List && selectedScreenResponse.isNotEmpty) {
          final first = selectedScreenResponse.first as Map<String, dynamic>;
          final selectedImages = (first['images'] as List<dynamic>?)
                  ?.map<String>((img) => img.toString())
                  .where((img) => img.isNotEmpty)
                  .toList() ??
              const <String>[];
          if (selectedImages.isNotEmpty) return selectedImages;
        }
      }

      final response = await _client
          .from('theater_screens')
          .select('images')
          .eq('theater_id', theaterId);

      if (response is! List || response.isEmpty) {
        return [];
      }

      final allImages = <String>[];
      for (final row in response) {
        final rowMap = row as Map<String, dynamic>;
        final images = (rowMap['images'] as List<dynamic>?)
                ?.map<String>((img) => img.toString())
                .where((img) => img.isNotEmpty)
                .toList() ??
            const <String>[];
        allImages.addAll(images);
      }

      return allImages;
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ERROR: Failed to fetch screen images: $e');
      return [];
    }
  }
}
