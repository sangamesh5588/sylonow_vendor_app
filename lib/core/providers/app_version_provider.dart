import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sylonow_vendor/core/services/app_version_service.dart';

final appVersionServiceProvider = Provider((_) => AppVersionService());

final appVersionCheckProvider = FutureProvider<AppVersionInfo?>((ref) async {
  return ref.read(appVersionServiceProvider).checkForUpdate();
});
