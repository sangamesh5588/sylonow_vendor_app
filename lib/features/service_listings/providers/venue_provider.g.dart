// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$venueNamesHash() => r'463e96199ace349dc427e5c8942059ce0ddded01';

/// Provider to get venue names as a list of strings (for backward compatibility)
///
/// Copied from [venueNames].
@ProviderFor(venueNames)
final venueNamesProvider = AutoDisposeFutureProvider<List<String>>.internal(
  venueNames,
  name: r'venueNamesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$venueNamesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef VenueNamesRef = AutoDisposeFutureProviderRef<List<String>>;
String _$venueByNameHash() => r'abd1a11d14d3c451383c27e6df6a121a76196787';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provider to get a venue by name
///
/// Copied from [venueByName].
@ProviderFor(venueByName)
const venueByNameProvider = VenueByNameFamily();

/// Provider to get a venue by name
///
/// Copied from [venueByName].
class VenueByNameFamily extends Family<AsyncValue<Venue?>> {
  /// Provider to get a venue by name
  ///
  /// Copied from [venueByName].
  const VenueByNameFamily();

  /// Provider to get a venue by name
  ///
  /// Copied from [venueByName].
  VenueByNameProvider call(
    String venueName,
  ) {
    return VenueByNameProvider(
      venueName,
    );
  }

  @override
  VenueByNameProvider getProviderOverride(
    covariant VenueByNameProvider provider,
  ) {
    return call(
      provider.venueName,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'venueByNameProvider';
}

/// Provider to get a venue by name
///
/// Copied from [venueByName].
class VenueByNameProvider extends AutoDisposeFutureProvider<Venue?> {
  /// Provider to get a venue by name
  ///
  /// Copied from [venueByName].
  VenueByNameProvider(
    String venueName,
  ) : this._internal(
          (ref) => venueByName(
            ref as VenueByNameRef,
            venueName,
          ),
          from: venueByNameProvider,
          name: r'venueByNameProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$venueByNameHash,
          dependencies: VenueByNameFamily._dependencies,
          allTransitiveDependencies:
              VenueByNameFamily._allTransitiveDependencies,
          venueName: venueName,
        );

  VenueByNameProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.venueName,
  }) : super.internal();

  final String venueName;

  @override
  Override overrideWith(
    FutureOr<Venue?> Function(VenueByNameRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: VenueByNameProvider._internal(
        (ref) => create(ref as VenueByNameRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        venueName: venueName,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Venue?> createElement() {
    return _VenueByNameProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VenueByNameProvider && other.venueName == venueName;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, venueName.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin VenueByNameRef on AutoDisposeFutureProviderRef<Venue?> {
  /// The parameter `venueName` of this provider.
  String get venueName;
}

class _VenueByNameProviderElement
    extends AutoDisposeFutureProviderElement<Venue?> with VenueByNameRef {
  _VenueByNameProviderElement(super.provider);

  @override
  String get venueName => (origin as VenueByNameProvider).venueName;
}

String _$venuesHash() => r'b17efa62351b0877086a56585728eeaa5cf2cd93';

/// See also [Venues].
@ProviderFor(Venues)
final venuesProvider =
    AutoDisposeAsyncNotifierProvider<Venues, List<Venue>>.internal(
  Venues.new,
  name: r'venuesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$venuesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Venues = AutoDisposeAsyncNotifier<List<Venue>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
