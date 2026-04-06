import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/guest_auth_service.dart';

final guestAuthServiceProvider = Provider<GuestAuthService>((ref) {
  return GuestAuthService();
});

final isGuestUserProvider = FutureProvider<bool>((ref) async {
  final guestService = ref.watch(guestAuthServiceProvider);
  return await guestService.isGuestUser();
});

final guestBusinessTypeProvider = FutureProvider<String?>((ref) async {
  final guestService = ref.watch(guestAuthServiceProvider);
  return await guestService.getGuestBusinessType();
});

class GuestAuthNotifier extends StateNotifier<AsyncValue<bool>> {
  final GuestAuthService _guestService;

  GuestAuthNotifier(this._guestService) : super(const AsyncValue.loading()) {
    _checkGuestStatus();
  }

  Future<void> _checkGuestStatus() async {
    try {
      final isGuest = await _guestService.isGuestUser();
      state = AsyncValue.data(isGuest);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signInAsGuest(String businessType) async {
    try {
      state = const AsyncValue.loading();
      await _guestService.signInAsGuest(businessType: businessType);
      state = const AsyncValue.data(true);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOutGuest() async {
    try {
      await _guestService.signOutGuest();
      state = const AsyncValue.data(false);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void refresh() {
    _checkGuestStatus();
  }
}

final guestAuthNotifierProvider =
    StateNotifierProvider<GuestAuthNotifier, AsyncValue<bool>>((ref) {
  final guestService = ref.watch(guestAuthServiceProvider);
  return GuestAuthNotifier(guestService);
});
