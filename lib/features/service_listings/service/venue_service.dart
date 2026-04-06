import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/venue.dart';

final venueServiceProvider = Provider<VenueService>((ref) {
  return VenueService(Supabase.instance.client);
});

class VenueService {
  final SupabaseClient _supabase;

  VenueService(this._supabase);

  /// Fetch all active venues ordered by display_order
  Future<List<Venue>> getActiveVenues() async {
    try {
      final response = await _supabase
          .from('venues')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      return (response as List)
          .map((json) => Venue.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch venues: $e');
    }
  }

  /// Fetch all venues (including inactive) - for admin use
  Future<List<Venue>> getAllVenues() async {
    try {
      final response = await _supabase
          .from('venues')
          .select()
          .order('display_order', ascending: true);

      return (response as List)
          .map((json) => Venue.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch all venues: $e');
    }
  }

  /// Get a single venue by ID
  Future<Venue?> getVenueById(String id) async {
    try {
      final response =
          await _supabase.from('venues').select().eq('id', id).maybeSingle();

      if (response == null) return null;

      return Venue.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch venue: $e');
    }
  }
}
