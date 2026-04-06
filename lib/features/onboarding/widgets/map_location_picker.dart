import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_theme.dart';

class MapLocationResult {
  final double latitude;
  final double longitude;
  final String address;
  final String? pincode;
  final String? area;
  final String? city;
  final String? state;

  const MapLocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.pincode,
    this.area,
    this.city,
    this.state,
  });
}

class MapLocationPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const MapLocationPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  GoogleMapController? _mapController;

  // Default: Bangalore centre
  static const LatLng _defaultCenter = LatLng(12.9716, 77.5946);

  late LatLng _selectedPosition;
  bool _isLoadingAddress = false;
  bool _isLoadingGps = false;
  String _addressText = 'Move the map to select location';
  String? _pincode;
  String? _area;
  String? _city;
  String? _state;

  DateTime? _lastCameraMove;

  // Search
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Location> _searchResults = [];
  List<String> _searchLabels = [];
  bool _isSearching = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _selectedPosition = (widget.initialLatitude != null &&
            widget.initialLongitude != null)
        ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
        : _defaultCenter;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reverseGeocode(_selectedPosition);
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() {
      _isLoadingAddress = true;
      _addressText = 'Fetching address…';
    });

    try {
      final placemarks =
          await placemarkFromCoordinates(point.latitude, point.longitude);

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        final parts = <String>[
          if (p.name != null && p.name!.isNotEmpty && p.name != p.subLocality)
            p.name!,
          if (p.subLocality != null && p.subLocality!.isNotEmpty)
            p.subLocality!,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
          if (p.administrativeArea != null &&
              p.administrativeArea!.isNotEmpty)
            p.administrativeArea!,
        ];

        setState(() {
          _addressText =
              parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
          _pincode = p.postalCode?.isNotEmpty == true ? p.postalCode : null;
          _area = p.subLocality?.isNotEmpty == true ? p.subLocality : null;
          _city = p.locality?.isNotEmpty == true ? p.locality : null;
          _state = p.administrativeArea?.isNotEmpty == true
              ? p.administrativeArea
              : null;
        });
      } else {
        setState(() {
          _addressText =
              '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _addressText =
              '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _isLoadingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permission denied.';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final point = LatLng(position.latitude, position.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: point, zoom: 16),
        ),
      );
      setState(() => _selectedPosition = point);
      await _reverseGeocode(point);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  void _onCameraMove(CameraPosition position) {
    final newPoint = position.target;
    setState(() => _selectedPosition = newPoint);

    // Debounce reverse geocoding — fires 600 ms after camera stops
    _lastCameraMove = DateTime.now();
    final captured = _lastCameraMove;
    Future.delayed(const Duration(milliseconds: 600), () {
      if (_lastCameraMove == captured && mounted) {
        _reverseGeocode(newPoint);
      }
    });
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().length < 3) {
      setState(() {
        _searchResults = [];
        _searchLabels = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final locations = await locationFromAddress(query);
      if (!mounted) return;

      // Build human-readable labels via reverse geocoding for each result
      final labels = <String>[];
      for (final loc in locations.take(5)) {
        try {
          final marks = await placemarkFromCoordinates(
            loc.latitude,
            loc.longitude,
          );
          if (marks.isNotEmpty) {
            final p = marks.first;
            final parts = <String>[
              if (p.name != null &&
                  p.name!.isNotEmpty &&
                  p.name != p.subLocality)
                p.name!,
              if (p.subLocality != null && p.subLocality!.isNotEmpty)
                p.subLocality!,
              if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
              if (p.administrativeArea != null &&
                  p.administrativeArea!.isNotEmpty)
                p.administrativeArea!,
              if (p.country != null && p.country!.isNotEmpty) p.country!,
            ];
            labels.add(parts.isNotEmpty ? parts.join(', ') : query);
          } else {
            labels.add(
              '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
            );
          }
        } catch (_) {
          labels.add(
            '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _searchResults = locations.take(5).toList();
        _searchLabels = labels;
        _showSuggestions = _searchResults.isNotEmpty;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _searchLabels = [];
          _showSuggestions = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(int index) {
    final loc = _searchResults[index];
    final label = _searchLabels[index];
    final point = LatLng(loc.latitude, loc.longitude);

    _searchController.text = label;
    _searchFocusNode.unfocus();

    setState(() {
      _showSuggestions = false;
      _selectedPosition = point;
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: point, zoom: 16),
      ),
    );

    _reverseGeocode(point);
  }

  void _confirmLocation() {
    Navigator.of(context).pop(
      MapLocationResult(
        latitude: _selectedPosition.latitude,
        longitude: _selectedPosition.longitude,
        address: _addressText,
        pincode: _pincode,
        area: _area,
        city: _city,
        state: _state,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        title: const Text(
          'Pick Location on Map',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // ── Google Map ───────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: _onCameraMove,
            onTap: (_) {
              _searchFocusNode.unfocus();
              setState(() => _showSuggestions = false);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),

          // ── Fixed centre pin ─────────────────────────────────────────────
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_pin,
                  color: AppTheme.primaryColor,
                  size: 48,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                // Spacer so the pin tip aligns with exact map centre
                SizedBox(height: 48),
              ],
            ),
          ),

          // ── Search bar + suggestions ──────────────────────────────────────
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                // Search field
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: AppTheme.shadowColor,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search for a place…',
                      hintStyle: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.primaryColor,
                        size: 22,
                      ),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: AppTheme.textSecondaryColor,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _showSuggestions = false;
                                      _searchResults = [];
                                    });
                                  },
                                )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {}); // rebuild to show/hide clear button
                      _searchLocation(value);
                    },
                    onSubmitted: _searchLocation,
                  ),
                ),

                // Suggestions dropdown
                if (_showSuggestions && _searchLabels.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: AppTheme.shadowColor,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _searchLabels.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: AppTheme.dividerColor,
                        ),
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () => _selectSearchResult(index),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: AppTheme.primaryColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _searchLabels[index],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── My Location FAB ──────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton.small(
              heroTag: 'map_gps',
              backgroundColor: AppTheme.surfaceColor,
              elevation: 4,
              onPressed: _isLoadingGps ? null : _goToCurrentLocation,
              child: _isLoadingGps
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : const Icon(
                      Icons.my_location,
                      color: AppTheme.primaryColor,
                    ),
            ),
          ),

          // ── Bottom address card + confirm ────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: AppTheme.primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Location',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _isLoadingAddress
                                ? const SizedBox(
                                    height: 14,
                                    width: 160,
                                    child: LinearProgressIndicator(
                                      color: AppTheme.primaryColor,
                                      backgroundColor: AppTheme.dividerColor,
                                    ),
                                  )
                                : Text(
                                    _addressText,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                            if (_pincode != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Pincode: $_pincode',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingAddress ? null : _confirmLocation,
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: const Text(
                        'Use This Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
