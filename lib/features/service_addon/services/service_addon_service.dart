import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sylonow_vendor/features/orders/models/order_addon.dart';
import '../models/service_addon.dart';

class ServiceAddonService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'service_add_ons';

  /// Get booked addons for an order — single JOIN query that returns
  /// both order_add_ons (quantity, price_at_booking, customisation_input)
  /// and the nested service_add_ons catalog data.
  Future<List<OrderAddon>> getAddonsByOrderId(String orderId) async {
    try {
      final rows = await _supabase
          .from('order_add_ons')
          .select('id, order_id, quantity, price_at_booking, customisation_input, service_add_ons(*)')
          .eq('order_id', orderId);

      return (rows as List)
          .map((json) => OrderAddon.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch addons for order: $e');
    }
  }

  /// Get service addons by IDs
  Future<List<ServiceAddon>> getAddonsByIds(List<String> addonIds) async {
    if (addonIds.isEmpty) return [];
    
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .filter('id', 'in', addonIds);

      return (response as List)
          .map((json) => ServiceAddon.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch service addons by IDs: $e');
    }
  }

  /// Get all service addons for the current vendor
  Future<List<ServiceAddon>> getVendorAddons() async {
    try {
      final authUserId = _supabase.auth.currentUser?.id;
      if (authUserId == null) {
        throw Exception('User not authenticated');
      }

      // First get the vendor record to find the vendor.id
      final vendorResponse = await _supabase
          .from('vendors')
          .select('id')
          .eq('auth_user_id', authUserId)
          .single();

      final vendorId = vendorResponse['id'] as String;

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('vendor_id', vendorId)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ServiceAddon.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch service addons: $e');
    }
  }

  /// Create a new service addon
  Future<ServiceAddon> createAddon(ServiceAddon addon) async {
    try {
      final authUserId = _supabase.auth.currentUser?.id;
      if (authUserId == null) {
        throw Exception('User not authenticated');
      }

      // First get the vendor record to find the vendor.id
      final vendorResponse = await _supabase
          .from('vendors')
          .select('id')
          .eq('auth_user_id', authUserId)
          .single();

      final vendorId = vendorResponse['id'] as String;

      final addonData = addon.toJson();
      addonData['vendor_id'] = vendorId;
      addonData.remove('id'); // Let Supabase generate the ID
      addonData.remove('created_at');
      addonData.remove('updated_at');

      final response = await _supabase
          .from(_tableName)
          .insert(addonData)
          .select()
          .single();

      return ServiceAddon.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create service addon: $e');
    }
  }

  /// Update an existing service addon
  Future<ServiceAddon> updateAddon(ServiceAddon addon) async {
    try {
      final authUserId = _supabase.auth.currentUser?.id;
      if (authUserId == null) {
        throw Exception('User not authenticated');
      }

      // First get the vendor record to find the vendor.id
      final vendorResponse = await _supabase
          .from('vendors')
          .select('id')
          .eq('auth_user_id', authUserId)
          .single();

      final vendorId = vendorResponse['id'] as String;

      final addonData = addon.toJson();
      addonData['vendor_id'] = vendorId;
      addonData.remove('created_at');
      addonData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from(_tableName)
          .update(addonData)
          .eq('id', addon.id)
          .eq('vendor_id', vendorId)
          .select()
          .single();

      return ServiceAddon.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update service addon: $e');
    }
  }

  /// Delete a service addon
  Future<void> deleteAddon(String addonId) async {
    try {
      final authUserId = _supabase.auth.currentUser?.id;
      if (authUserId == null) {
        throw Exception('User not authenticated');
      }

      // First get the vendor record to find the vendor.id
      final vendorResponse = await _supabase
          .from('vendors')
          .select('id')
          .eq('auth_user_id', authUserId)
          .single();

      final vendorId = vendorResponse['id'] as String;

      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', addonId)
          .eq('vendor_id', vendorId);
    } catch (e) {
      throw Exception('Failed to delete service addon: $e');
    }
  }

  /// Toggle addon availability
  Future<ServiceAddon> toggleAvailability(String addonId, bool isAvailable) async {
    try {
      final authUserId = _supabase.auth.currentUser?.id;
      if (authUserId == null) {
        throw Exception('User not authenticated');
      }

      // First get the vendor record to find the vendor.id
      final vendorResponse = await _supabase
          .from('vendors')
          .select('id')
          .eq('auth_user_id', authUserId)
          .single();

      final vendorId = vendorResponse['id'] as String;

      final response = await _supabase
          .from(_tableName)
          .update({
            'is_available': isAvailable,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', addonId)
          .eq('vendor_id', vendorId)
          .select()
          .single();

      return ServiceAddon.fromJson(response);
    } catch (e) {
      throw Exception('Failed to toggle addon availability: $e');
    }
  }

  /// Update addon stock
  Future<ServiceAddon> updateStock(String addonId, int stock) async {
    try {
      final authUserId = _supabase.auth.currentUser?.id;
      if (authUserId == null) {
        throw Exception('User not authenticated');
      }

      // First get the vendor record to find the vendor.id
      final vendorResponse = await _supabase
          .from('vendors')
          .select('id')
          .eq('auth_user_id', authUserId)
          .single();

      final vendorId = vendorResponse['id'] as String;

      final response = await _supabase
          .from(_tableName)
          .update({
            'stock': stock,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', addonId)
          .eq('vendor_id', vendorId)
          .select()
          .single();

      return ServiceAddon.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update addon stock: $e');
    }
  }

  /// Reorder addons by updating sort_order
  Future<void> reorderAddons(List<String> addonIds) async {
    try {
      final authUserId = _supabase.auth.currentUser?.id;
      if (authUserId == null) {
        throw Exception('User not authenticated');
      }

      // First get the vendor record to find the vendor.id
      final vendorResponse = await _supabase
          .from('vendors')
          .select('id')
          .eq('auth_user_id', authUserId)
          .single();

      final vendorId = vendorResponse['id'] as String;

      for (int i = 0; i < addonIds.length; i++) {
        await _supabase
            .from(_tableName)
            .update({
              'sort_order': i,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', addonIds[i])
            .eq('vendor_id', vendorId);
      }
    } catch (e) {
      throw Exception('Failed to reorder addons: $e');
    }
  }
}