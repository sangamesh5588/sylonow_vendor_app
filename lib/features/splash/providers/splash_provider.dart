import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to track whether the splash screen animation has completed
/// This prevents premature navigation from the splash screen
final splashAnimationCompletedProvider = StateProvider<bool>((ref) => false);
