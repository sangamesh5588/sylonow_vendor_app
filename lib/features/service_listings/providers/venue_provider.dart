import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/venue.dart';
import '../service/venue_service.dart';

part 'venue_provider.g.dart';

@riverpod
class Venues extends _$Venues {
  @override
  Future<List<Venue>> build() async {
    return _fetchVenues();
  }

  Future<List<Venue>> _fetchVenues() async {
    final venueService = ref.read(venueServiceProvider);
    return await venueService.getActiveVenues();
  }

  /// Refresh venues list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchVenues());
  }
}

/// Provider to get venue names as a list of strings (for backward compatibility)
@riverpod
Future<List<String>> venueNames(VenueNamesRef ref) async {
  final venues = await ref.watch(venuesProvider.future);
  return venues.map((venue) => venue.name).toList();
}

/// Provider to get a venue by name
@riverpod
Future<Venue?> venueByName(VenueByNameRef ref, String venueName) async {
  final venues = await ref.watch(venuesProvider.future);
  try {
    return venues.firstWhere((venue) => venue.name == venueName);
  } catch (e) {
    return null;
  }
}
