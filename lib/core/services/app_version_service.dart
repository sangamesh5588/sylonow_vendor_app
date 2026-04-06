import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sylonow_vendor/core/config/supabase_config.dart';

class AppVersionInfo {
  final bool needsUpdate;
  final bool forceUpdate;
  final String currentVersion;
  final String latestVersion;
  final String message;
  final String storeUrl;

  const AppVersionInfo({
    required this.needsUpdate,
    required this.forceUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.message,
    required this.storeUrl,
  });
}

class AppVersionService {
  Future<AppVersionInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "2.1.1"

      final platform = Platform.isAndroid ? 'android' : 'ios';

      final response = await SupabaseConfig.client
          .from('app_versions')
          .select()
          .eq('platform', platform)
          .eq('app_type', 'vendor')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      final latestVersion = response['version'] as String;
      final forceUpdate = response['force_update'] as bool? ?? false;
      final message = response['update_message'] as String? ??
          'A new version is available. Please update for the best experience.';
      final storeUrl = response['store_url'] as String? ?? '';

      final needsUpdate = _isNewerVersion(latestVersion, currentVersion);

      if (kDebugMode) {
        print('🔵 AppVersionService: current=$currentVersion latest=$latestVersion needsUpdate=$needsUpdate');
      }

      if (!needsUpdate) return null;

      return AppVersionInfo(
        needsUpdate: true,
        forceUpdate: forceUpdate,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        message: message,
        storeUrl: storeUrl,
      );
    } catch (e) {
      if (kDebugMode) {
        print('🔴 AppVersionService: Error checking version: $e');
      }
      return null;
    }
  }

  /// Returns true if [latest] is strictly greater than [current].
  /// Compares semantic versions: major.minor.patch
  bool _isNewerVersion(String latest, String current) {
    try {
      final l = _parse(latest);
      final c = _parse(current);
      for (int i = 0; i < 3; i++) {
        if (l[i] > c[i]) return true;
        if (l[i] < c[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  List<int> _parse(String version) {
    final parts = version.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    while (parts.length < 3) parts.add(0);
    return parts;
  }
}
