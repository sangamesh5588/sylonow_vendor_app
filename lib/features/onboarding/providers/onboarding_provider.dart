import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sylonow_vendor/features/onboarding/providers/supabase_provider.dart';
import '../models/vendor.dart';
import '../service/onboarding_service.dart';

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return OnboardingService(supabase);
});

final onboardingProvider =
    AsyncNotifierProvider<OnboardingNotifier, Option<Vendor>>(() {
  return OnboardingNotifier();
});

class OnboardingNotifier extends AsyncNotifier<Option<Vendor>> {
  @override
  Future<Option<Vendor>> build() async {
    return none();
  }

  /// Sends OTP via MSG91. Returns reqId on success (stored internally in
  /// OtpNotifier — use that provider for the full OTP flow).
  Future<Either<String, String>> signInWithMobile(String phoneNumber) async {
    final service = ref.read(onboardingServiceProvider);
    return service.signInWithMobile(phoneNumber);
  }

  /// Loads the vendor record for the authenticated user.
  /// The vendor row is seeded by the msg91-auth edge function on first login,
  /// so this should always find a row after OTP verification.
  Future<Either<String, Vendor>> loadVendor({
    required String phoneNumber,
  }) async {
    state = const AsyncLoading();
    final service = ref.read(onboardingServiceProvider);

    final result = await service.checkVendorExists(phoneNumber);

    return result.fold(
      (_) {
        // Should not happen after msg91-auth seeds the row, but handle gracefully
        state = const AsyncData(None());
        return left('Vendor profile not found. Please try logging in again.');
      },
      (vendor) {
        state = AsyncData(some(vendor));
        return right(vendor);
      },
    );
  }

  Future<Either<String, void>> updateVendorDetails(
    String vendorId,
    Map<String, dynamic> data,
  ) async {
    state = const AsyncLoading();
    final service = ref.read(onboardingServiceProvider);

    final result = await service.updateVendorDetails(
      vendorId: vendorId,
      data: data,
    );

    return result.fold(
      (error) => left(error),
      (vendor) {
        state = AsyncData(some(vendor));
        return right(null);
      },
    );
  }

  Future<Either<String, String>> uploadDocument({
    required String path,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final service = ref.read(onboardingServiceProvider);
    return service.uploadDocument(
      path: path,
      bytes: bytes,
      fileName: fileName,
    );
  }
}
