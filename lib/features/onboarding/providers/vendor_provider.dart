import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sylonow_vendor/core/providers/auth_provider.dart';
import 'package:sylonow_vendor/features/onboarding/models/vendor.dart';
import 'package:sylonow_vendor/features/onboarding/service/vendor_service.dart';

final vendorServiceProvider = Provider((ref) => VendorService());

final vendorProvider = AsyncNotifierProvider<VendorNotifier, Vendor?>(
  () => VendorNotifier(),
);

class VendorNotifier extends AsyncNotifier<Vendor?> {
  @override
  Future<Vendor?> build() async {
    try {
      final authState = ref.watch(authStateProvider);
      final user = authState.valueOrNull?.session?.user;
      
      if (user == null) {
        print('🔵 VendorNotifier: No user found, returning null');
        return null;
      }

      print('🔵 VendorNotifier: Loading vendor data for user: ${user.id.substring(0, 8)}...');

      final vendorService = ref.read(vendorServiceProvider);
      final vendor = await vendorService.getVendorByUserId(user.id);

      if (vendor != null) {
        print('🟢 VendorNotifier: Vendor loaded - Onboarding: ${vendor.isOnboardingComplete}, Verified: ${vendor.isVerified}');
      } else {
        print('🟡 VendorNotifier: No vendor data found for user');
      }

      return vendor;
    } catch (e) {
      print('🔴 VendorNotifier: Error loading vendor data: $e');
      return null;
    }
  }

  Future<void> refreshVendor() async {
// TODO: Replace with proper logging - print('🔵 VendorNotifier: Manual refresh requested');
    
    // Don't set state to loading during refresh to avoid router triggers
    // Instead, fetch data in background and only update state with new data
    try {
      final authState = ref.watch(authStateProvider);
      final user = authState.valueOrNull?.session?.user;
      
      if (user == null) {
// TODO: Replace with proper logging - print('🟡 VendorNotifier: No authenticated user found during refresh');
        return;
      }

// TODO: Replace with proper logging - print('🔵 VendorNotifier: Refreshing vendor data for user: ${user.id.substring(0, 8)}...');
      
      final vendorService = ref.read(vendorServiceProvider);
      
      // Add a small delay to ensure auth state is fully propagated
      await Future.delayed(const Duration(milliseconds: 100));
      
      final vendor = await vendorService.getVendorByUserId(user.id);
      
      if (vendor != null) {
// TODO: Replace with proper logging - print('🟢 VendorNotifier: Vendor refreshed - ID: ${vendor.id?.substring(0, 8) ?? 'null'}, Onboarding: ${vendor.isOnboardingComplete}, Verified: ${vendor.isVerified}');
        // Update state with fresh data
        state = AsyncData(vendor);
      } else {
// TODO: Replace with proper logging - print('🟡 VendorNotifier: No vendor data found during refresh - checking by email fallback');
        
        // Try checking by email as fallback for edge cases
        final userEmail = user.email;
        if (userEmail != null) {
          final vendorByEmail = await vendorService.checkVendorStatus(user.id);
          if (vendorByEmail['exists'] == true && vendorByEmail['can_link'] == true) {
// TODO: Replace with proper logging - print('🔄 VendorNotifier: Found vendor by email, will need linking');
          }
        }
        
        // Only update to null if we currently have data (don't overwrite loading states)
        if (state.hasValue) {
          state = const AsyncData(null);
        }
      }
    } catch (e) {
// TODO: Replace with proper logging - print('🔴 VendorNotifier: Manual refresh failed: $e');
      // Don't set error state during refresh, keep existing data
      // Only log the error for debugging
    }
  }

  void clearVendorData() {
// TODO: Replace with proper logging - print('🔵 VendorNotifier: Clearing vendor data');
    state = const AsyncData(null);
  }

  /// Alternative refresh method using Riverpod's built-in invalidation
  /// This is safer as it uses the normal provider lifecycle
  Future<void> invalidateAndRefresh() async {
// TODO: Replace with proper logging - print('🔵 VendorNotifier: Invalidating and refreshing...');
    ref.invalidateSelf();
  }

  /// Update online status locally without full refresh
  void updateOnlineStatus(bool isOnline) {
    final currentVendor = state.valueOrNull;
    if (currentVendor != null) {
      final updatedVendor = currentVendor.copyWith(isOnline: isOnline);
      state = AsyncValue.data(updatedVendor);
// TODO: Replace with proper logging - print('🟢 VendorNotifier: Online status updated to $isOnline');
    }
  }
}