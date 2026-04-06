import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_version_service.dart';
import '../theme/app_theme.dart';

class AppUpdateDialog extends StatelessWidget {
  final AppVersionInfo info;

  const AppUpdateDialog({super.key, required this.info});

  static Future<void> showIfNeeded(
    BuildContext context,
    AppVersionInfo info,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (_) => AppUpdateDialog(info: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !info.forceUpdate,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              const Text(
                'Update Available',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Version badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'v${info.currentVersion}  →  v${info.latestVersion}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Message
              Text(
                info.message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              if (info.forceUpdate) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 15, color: AppTheme.errorColor),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'This update is required to continue using the app.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Update button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _openStore(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Update Now',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Later button (only for non-force updates)
              if (!info.forceUpdate) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Later',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openStore(BuildContext context) async {
    if (info.storeUrl.isEmpty) return;
    final uri = Uri.parse(info.storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
