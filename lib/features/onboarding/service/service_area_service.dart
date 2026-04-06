import '../../../core/config/supabase_config.dart';
import '../models/service_area.dart';

class ServiceAreaService {
  final _client = SupabaseConfig.client;

  /// Get primary service area for a vendor
  Future<ServiceArea?> getPrimaryServiceArea(String vendorId) async {
    try {
// TODO: Replace with proper logging - print('🔵 ServiceAreaService: Getting primary service area for vendor: ${vendorId.substring(0, 8)}...');
      
      final response = await _client
          .from('service_areas')
          .select('*')
          .eq('vendor_id', vendorId)
          .eq('is_primary', true)
          .maybeSingle();
      
      if (response == null) {
// TODO: Replace with proper logging - print('🟡 ServiceAreaService: No primary service area found, trying to get any service area...');
        
        // If no primary service area, get the first one
        final fallbackResponse = await _client
            .from('service_areas')
            .select('*')
            .eq('vendor_id', vendorId)
            .limit(1)
            .maybeSingle();
            
        if (fallbackResponse == null) {
// TODO: Replace with proper logging - print('🟡 ServiceAreaService: No service area found');
          return null;
        }
        
        final serviceArea = ServiceArea.fromJson(fallbackResponse);
// TODO: Replace with proper logging - print('🟢 ServiceAreaService: Found fallback service area: ${serviceArea.areaName}');
        return serviceArea;
      }
      
      final serviceArea = ServiceArea.fromJson(response);
// TODO: Replace with proper logging - print('🟢 ServiceAreaService: Found primary service area: ${serviceArea.areaName}');
      
      return serviceArea;
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ServiceAreaService: Error getting service area: $e');
      return null;
    }
  }

  /// Get all service areas for a vendor
  Future<List<ServiceArea>> getServiceAreas(String vendorId) async {
    try {
// TODO: Replace with proper logging - print('🔵 ServiceAreaService: Getting all service areas for vendor: ${vendorId.substring(0, 8)}...');
      
      final response = await _client
          .from('service_areas')
          .select('*')
          .eq('vendor_id', vendorId)
          .order('is_primary', ascending: false)
          .order('created_at', ascending: true);
      
      final serviceAreas = (response as List)
          .map((item) => ServiceArea.fromJson(item))
          .toList();
      
// TODO: Replace with proper logging - print('🟢 ServiceAreaService: Found ${serviceAreas.length} service areas');
      
      return serviceAreas;
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 ServiceAreaService: Error getting service areas: $e');
      return [];
    }
  }
} 