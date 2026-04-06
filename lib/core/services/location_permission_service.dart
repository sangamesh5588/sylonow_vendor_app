import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/onboarding/models/vendor.dart';
import '../theme/app_theme.dart';

/// Service to handle mandatory location permission for vendors
/// Only shows prompt to vendors who don't have location coordinates in database
class LocationPermissionService {
  static const String _hasShownPromptKey =
      'has_shown_mandatory_location_prompt';

  /// Check if vendor needs location permission and show mandatory prompt
  /// Returns true if permission was granted, false otherwise
  static Future<bool> checkAndRequestMandatoryLocation({
    required BuildContext context,
    required Vendor? vendor,
    required Function(double lat, double lng) onLocationGranted,
  }) async {
    try {
      // Don't show if vendor is null
      if (vendor == null) {
        if (kDebugMode) {
          print('⚠️ Vendor is null, skipping location check');
        }
        return false;
      }

      // Check if vendor already has location coordinates
      final hasLocation = vendor.latitude != null && vendor.longitude != null;

      if (hasLocation) {
        if (kDebugMode) {
          print(
              '✅ Vendor already has location: (${vendor.latitude}, ${vendor.longitude})');
        }
        return true;
      }

      if (kDebugMode) {
        print(
            '⚠️ Vendor missing location coordinates - showing mandatory prompt');
      }

      // Check current permission status
      final permission = await Geolocator.checkPermission();

      // If permission denied or not determined, show mandatory dialog
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          final granted = await _showMandatoryLocationDialog(context);

          if (granted) {
            // Request permission
            return await _requestAndSaveLocation(context, onLocationGranted);
          } else {
            // User declined - show them why it's important
            _showLocationImportanceSnackbar(context);
            return false;
          }
        }
      } else if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // Permission already granted but no coordinates saved - get location
        return await _requestAndSaveLocation(context, onLocationGranted);
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in checkAndRequestMandatoryLocation: $e');
      }
      return false;
    }
  }

  /// Show mandatory location permission dialog with clear explanation
  static Future<bool> _showMandatoryLocationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Make it mandatory
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button dismiss
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Location Required',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your location is essential to provide services on our platform.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Why we need your location:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildReasonItem(
                          icon: Icons.person_search,
                          text: 'Help nearby customers find your services',
                        ),
                        const SizedBox(height: 8),
                        _buildReasonItem(
                          icon: Icons.radar,
                          text:
                              'Show you to customers within your service radius',
                        ),
                        const SizedBox(height: 8),
                        _buildReasonItem(
                          icon: Icons.map,
                          text: 'Calculate accurate distances for bookings',
                        ),
                        const SizedBox(height: 8),
                        _buildReasonItem(
                          icon: Icons.trending_up,
                          text: 'Increase your visibility and bookings',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.warningColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: AppTheme.warningColor,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your privacy is protected. We only access location when the app is in use.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text(
                  'Not Now',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 2,
                ),
                child: const Text(
                  'Allow Location',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    return result ?? false;
  }

  static Widget _buildReasonItem(
      {required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryColor,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  /// Request location permission and get coordinates
  static Future<bool> _requestAndSaveLocation(
    BuildContext context,
    Function(double lat, double lng) onLocationGranted,
  ) async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          _showLocationServicesDisabledDialog(context);
        }
        return false;
      }

      // Check current permission
      LocationPermission permission = await Geolocator.checkPermission();

      // Request permission if denied
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Handle permission results
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          _showPermissionDeniedSnackbar(
              context, permission == LocationPermission.deniedForever);
        }
        return false;
      }

      // Get current position
      if (context.mounted) {
        _showLoadingSnackbar(context);
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (kDebugMode) {
        print(
            '✅ Location obtained: (${position.latitude}, ${position.longitude})');
      }

      // Call the callback with coordinates
      await onLocationGranted(position.latitude, position.longitude);

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Location saved! Customers can now find you easily.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting location: $e');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to get location: ${e.toString()}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      return false;
    }
  }

  static void _showLoadingSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Getting your location...'),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        duration: Duration(seconds: 30),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _showLocationServicesDisabledDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_off, color: AppTheme.errorColor),
            SizedBox(width: 12),
            Text('Location Services Disabled'),
          ],
        ),
        content: const Text(
          'Please enable location services in your device settings to continue.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  static void _showPermissionDeniedSnackbar(
      BuildContext context, bool isPermanent) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPermanent
              ? 'Location permission permanently denied. Please enable it in app settings.'
              : 'Location permission denied. You can enable it later in settings.',
        ),
        backgroundColor: AppTheme.errorColor,
        duration: Duration(seconds: isPermanent ? 5 : 4),
        behavior: SnackBarBehavior.floating,
        action: isPermanent
            ? SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => Geolocator.openAppSettings(),
              )
            : null,
      ),
    );
  }

  static void _showLocationImportanceSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Location is required to show your services to nearby customers. You can enable it anytime from Profile settings.',
        ),
        backgroundColor: AppTheme.warningColor,
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Reset the shown prompt flag (for testing purposes)
  static Future<void> resetPromptFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasShownPromptKey);
  }
}
