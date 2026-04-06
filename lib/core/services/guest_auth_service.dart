import 'package:shared_preferences/shared_preferences.dart';

class GuestAuthService {
  static const String _isGuestKey = 'is_guest_user';
  static const String _guestBusinessTypeKey = 'guest_business_type';

  // Check if current user is a guest
  Future<bool> isGuestUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isGuestKey) ?? false;
  }

  // Get guest business type
  Future<String?> getGuestBusinessType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_guestBusinessTypeKey);
  }

  // Set guest user with business type
  Future<void> setGuestUser({required String businessType}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGuestKey, true);
    await prefs.setString(_guestBusinessTypeKey, businessType);
  }

  // Clear guest status (when user signs in)
  Future<void> clearGuestStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isGuestKey);
    await prefs.remove(_guestBusinessTypeKey);
  }

  // Sign in as guest
  Future<void> signInAsGuest({required String businessType}) async {
    await setGuestUser(businessType: businessType);
  }

  // Sign out guest
  Future<void> signOutGuest() async {
    await clearGuestStatus();
  }
}
