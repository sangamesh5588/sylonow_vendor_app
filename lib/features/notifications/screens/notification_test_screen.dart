import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/providers/firebase_notification_provider.dart';
import '../../../core/theme/app_theme.dart';

class NotificationTestScreen extends ConsumerWidget {
  const NotificationTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationProvider =
        ref.watch(firebaseNotificationNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Tests'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Full-Screen Notification Tests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Test the full-screen notification with sound and View Order button. Make sure to grant permissions.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: notificationProvider.when(
                        data: (initialized) => initialized
                            ? () => _testFullScreenNotification(ref, context)
                            : null,
                        loading: () => null,
                        error: (_, __) => null,
                      ),
                      icon: const HeroIcon(
                        HeroIcons.megaphone,
                        style: HeroIconStyle.solid,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Test Full-Screen Notification',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _checkPermissions(context),
                      icon: const HeroIcon(
                        HeroIcons.shieldCheck,
                        style: HeroIconStyle.outline,
                      ),
                      label: const Text('Check Permissions'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Regular Notification Tests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: notificationProvider.when(
                        data: (initialized) => initialized
                            ? () => _testRegularNotification(ref, context)
                            : null,
                        loading: () => null,
                        error: (_, __) => null,
                      ),
                      icon: const HeroIcon(
                        HeroIcons.bell,
                        style: HeroIconStyle.outline,
                      ),
                      label: const Text('Test Regular Notification'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: notificationProvider.when(
                        data: (initialized) => initialized
                            ? () => _testUpdateNotification(ref, context)
                            : null,
                        loading: () => null,
                        error: (_, __) => null,
                      ),
                      icon: const HeroIcon(
                        HeroIcons.informationCircle,
                        style: HeroIconStyle.outline,
                      ),
                      label: const Text('Test Update Notification'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notification Controls',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _stopNotificationSound(ref, context),
                            icon: const HeroIcon(
                              HeroIcons.speakerXMark,
                              style: HeroIconStyle.outline,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Stop Sound',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _clearAllNotifications(ref, context),
                            icon: const HeroIcon(
                              HeroIcons.trash,
                              style: HeroIconStyle.outline,
                              color: Colors.orange,
                            ),
                            label: const Text(
                              'Clear All',
                              style: TextStyle(color: Colors.orange),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade50,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            notificationProvider.when(
              data: (initialized) => Card(
                color: initialized ? Colors.green.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      HeroIcon(
                        initialized ? HeroIcons.checkCircle : HeroIcons.xCircle,
                        style: HeroIconStyle.solid,
                        color: initialized ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        initialized
                            ? 'Notification service initialized'
                            : 'Notification service failed to initialize',
                        style: TextStyle(
                          color: initialized
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Initializing notification service...'),
                    ],
                  ),
                ),
              ),
              error: (error, stack) => Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const HeroIcon(
                        HeroIcons.exclamationTriangle,
                        style: HeroIconStyle.solid,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Error: $error',
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkPermissions(BuildContext context) async {
    try {
      final notificationStatus = await Permission.notification.status;
      final systemAlertStatus = await Permission.systemAlertWindow.status;
      final phoneStatus = await Permission.phone.status;

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissions Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPermissionRow('Notifications', notificationStatus),
                _buildPermissionRow('System Alert Window', systemAlertStatus),
                _buildPermissionRow('Phone', phoneStatus),
                const SizedBox(height: 16),
                const Text(
                  'Note: System Alert Window permission is required for full-screen notifications to work properly.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              if (systemAlertStatus.isDenied || notificationStatus.isDenied)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking permissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPermissionRow(String name, PermissionStatus status) {
    Color color;
    IconData icon;
    String statusText;

    switch (status) {
      case PermissionStatus.granted:
        color = Colors.green;
        icon = Icons.check_circle;
        statusText = 'Granted';
        break;
      case PermissionStatus.denied:
        color = Colors.red;
        icon = Icons.cancel;
        statusText = 'Denied';
        break;
      case PermissionStatus.permanentlyDenied:
        color = Colors.red;
        icon = Icons.block;
        statusText = 'Permanently Denied';
        break;
      default:
        color = Colors.orange;
        icon = Icons.warning;
        statusText = 'Unknown';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text('$name: '),
          Text(statusText, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _testFullScreenNotification(
      WidgetRef ref, BuildContext context) async {
    try {
      // Check permissions first
      final notificationStatus = await Permission.notification.status;
      final systemAlertStatus = await Permission.systemAlertWindow.status;

      if (!notificationStatus.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permission is required! Please grant permission first.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final notifier = ref.read(firebaseNotificationNotifierProvider.notifier);
      await notifier.showFullScreenOrderNotification(
        orderId: 'test_order_${DateTime.now().millisecondsSinceEpoch}',
        customerName: 'John Doe',
        serviceTitle: 'Event Photography',
        amount: 5000.0,
        bookingDate: DateTime.now().toString(),
        additionalData: {
          'service_type': 'photography',
          'duration': '4 hours',
          'location': 'Wedding Venue',
        },
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Full-screen notification sent! 🔔'),
                const SizedBox(height: 4),
                Text(
                  systemAlertStatus.isGranted 
                    ? 'Check notification panel or lock screen.' 
                    : 'Note: For full-screen display, enable "Display over other apps" permission.',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testRegularNotification(
      WidgetRef ref, BuildContext context) async {
    try {
      final notifier = ref.read(firebaseNotificationNotifierProvider.notifier);
      await notifier.showNewBookingNotification(
        bookingId: 'test_booking_${DateTime.now().millisecondsSinceEpoch}',
        customerName: 'Jane Smith',
        serviceName: 'Wedding Photography',
        amount: 7500.0,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Regular notification sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testUpdateNotification(
      WidgetRef ref, BuildContext context) async {
    try {
      final notifier = ref.read(firebaseNotificationNotifierProvider.notifier);
      await notifier.showBookingUpdateNotification(
        bookingId:
            'test_booking_update_${DateTime.now().millisecondsSinceEpoch}',
        status: 'confirmed',
        customerName: 'Mike Johnson',
        serviceName: 'Corporate Event',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update notification sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopNotificationSound(
      WidgetRef ref, BuildContext context) async {
    try {
      final notifier = ref.read(firebaseNotificationNotifierProvider.notifier);
      await notifier.stopNotificationSound();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification sound stopped.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllNotifications(
      WidgetRef ref, BuildContext context) async {
    try {
      final notifier = ref.read(firebaseNotificationNotifierProvider.notifier);
      await notifier.cancelAllFullScreenNotifications();
      await notifier.clearAllNotifications();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications cleared.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
