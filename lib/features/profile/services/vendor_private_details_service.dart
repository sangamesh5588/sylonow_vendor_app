import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vendor_private_details.dart';

class VendorPrivateDetailsService {
  static final VendorPrivateDetailsService _instance = VendorPrivateDetailsService._internal();
  factory VendorPrivateDetailsService() => _instance;
  VendorPrivateDetailsService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// Get vendor private details by vendor ID
  Future<VendorPrivateDetails?> getVendorPrivateDetails(String vendorId) async {
    try {
// TODO: Replace with proper logging - print('🔍 VendorPrivateDetailsService: Fetching private details for vendor: $vendorId');

      final response = await _client
          .from('vendor_private_details')
          .select()
          .eq('vendor_id', vendorId)
          .maybeSingle();

      if (response != null) {
        final details = VendorPrivateDetails.fromJson(response);
// Success print removed
// TODO: Replace with proper logging - print('🏦 Has bank details: ${details.hasBankDetails}');
// TODO: Replace with proper logging - print('📄 Has GST: ${details.hasGstDetails}');
        return details;
      } else {
// Warning print removed
        return null;
      }
    } catch (e) {
// Error print removed
      rethrow;
    }
  }

  /// Create new vendor private details
  Future<VendorPrivateDetails> createVendorPrivateDetails(
    String vendorId,
    Map<String, dynamic> details,
  ) async {
    try {
// TODO: Replace with proper logging - print('🔍 VendorPrivateDetailsService: Creating private details for vendor: $vendorId');

      final data = {
        'vendor_id': vendorId,
        ...details,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('vendor_private_details')
          .insert(data)
          .select()
          .single();

      final privateDetails = VendorPrivateDetails.fromJson(response);
// Success print removed
      return privateDetails;
    } catch (e) {
// Error print removed
      rethrow;
    }
  }

  /// Update vendor private details
  Future<VendorPrivateDetails> updateVendorPrivateDetails(
    String vendorId,
    Map<String, dynamic> updates,
  ) async {
    try {
// TODO: Replace with proper logging - print('🔍 VendorPrivateDetailsService: Updating private details for vendor: $vendorId');

      final data = {
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('vendor_private_details')
          .update(data)
          .eq('vendor_id', vendorId)
          .select()
          .single();

      final privateDetails = VendorPrivateDetails.fromJson(response);
// Success print removed
      return privateDetails;
    } catch (e) {
// Error print removed
      rethrow;
    }
  }

  /// Update or create vendor private details (upsert)
  Future<VendorPrivateDetails> upsertVendorPrivateDetails(
    String vendorId,
    Map<String, dynamic> details,
  ) async {
    try {
// TODO: Replace with proper logging - print('🔍 VendorPrivateDetailsService: Upserting private details for vendor: $vendorId');

      // Check if details exist
      final existing = await getVendorPrivateDetails(vendorId);

      if (existing != null) {
        // Update existing details
        return await updateVendorPrivateDetails(vendorId, details);
      } else {
        // Create new details
        return await createVendorPrivateDetails(vendorId, details);
      }
    } catch (e) {
// Error print removed
      rethrow;
    }
  }

  /// Update bank details specifically
  Future<VendorPrivateDetails> updateBankDetails(
    String vendorId, {
    required String accountNumber,
    required String ifscCode,
  }) async {
    final bankData = {
      'bank_account_number': accountNumber,
      'bank_ifsc_code': ifscCode.toUpperCase(),
    };

    return await upsertVendorPrivateDetails(vendorId, bankData);
  }

  /// Update GST details specifically
  Future<VendorPrivateDetails> updateGstDetails(
    String vendorId, {
    required String gstNumber,
  }) async {
    final gstData = {
      'gst_number': gstNumber.toUpperCase(),
    };

    return await upsertVendorPrivateDetails(vendorId, gstData);
  }

  /// Update Aadhaar details specifically
  Future<VendorPrivateDetails> updateAadhaarDetails(
    String vendorId, {
    required String aadhaarNumber,
  }) async {
    final aadhaarData = {
      'aadhaar_number': aadhaarNumber,
    };

    return await upsertVendorPrivateDetails(vendorId, aadhaarData);
  }

  /// Delete vendor private details
  Future<void> deleteVendorPrivateDetails(String vendorId) async {
    try {
// TODO: Replace with proper logging - print('🔍 VendorPrivateDetailsService: Deleting private details for vendor: $vendorId');

      await _client
          .from('vendor_private_details')
          .delete()
          .eq('vendor_id', vendorId);

// Success print removed
    } catch (e) {
// Error print removed
      rethrow;
    }
  }

  /// Validate IFSC code format
  bool isValidIfscCode(String ifsc) {
    if (ifsc.length != 11) return false;
    final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
    return ifscRegex.hasMatch(ifsc.toUpperCase());
  }

  /// Validate bank account number format
  bool isValidAccountNumber(String accountNumber) {
    if (accountNumber.length < 8 || accountNumber.length > 18) return false;
    final accountRegex = RegExp(r'^[0-9]+$');
    return accountRegex.hasMatch(accountNumber);
  }

  /// Get bank details summary for display
  Map<String, String> getBankDetailsSummary(VendorPrivateDetails details) {
    return {
      'account': details.formattedBankAccount,
      'ifsc': details.bankIfscCode ?? 'Not provided',
    };
  }
}