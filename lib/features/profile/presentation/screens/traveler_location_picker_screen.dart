import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/location.dart' as profile_entity;

/// Full-screen location picker for Traveler mode.
/// Uses geocoding for forward/reverse address lookup, GPS for current location,
/// and Google Maps for interactive map selection and preview.
class TravelerLocationPickerScreen extends StatefulWidget {
  const TravelerLocationPickerScreen({super.key});

  @override
  State<TravelerLocationPickerScreen> createState() =>
      _TravelerLocationPickerScreenState();
}

class _TravelerLocationPickerScreenState
    extends State<TravelerLocationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  profile_entity.Location? _selectedLocation;
  List<_SearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingGps = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final locations = await locationFromAddress(query);
      final results = <_SearchResult>[];

      for (final loc in locations.take(5)) {
        try {
          final placemarks =
              await placemarkFromCoordinates(loc.latitude, loc.longitude);
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            final city = place.locality ??
                place.subLocality ??
                place.subAdministrativeArea ??
                place.administrativeArea ??
                place.name ??
                query;
            final country = place.country ?? '';
            final region = place.administrativeArea ?? '';
            results.add(_SearchResult(
              latitude: loc.latitude,
              longitude: loc.longitude,
              city: city,
              country: country,
              region: region,
              displayAddress:
                  [city, region, country].where((s) => s.isNotEmpty).join(', '),
            ));
          }
        } catch (_) {
          results.add(_SearchResult(
            latitude: loc.latitude,
            longitude: loc.longitude,
            city: query,
            country: '',
            region: '',
            displayAddress:
                '$query (${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)})',
          ));
        }
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No results found for "$query"'),
            backgroundColor: AppColors.warningAmber,
          ),
        );
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final city = place.locality ??
            place.subLocality ??
            place.subAdministrativeArea ??
            place.administrativeArea ??
            'Unknown';
        final country = place.country ?? 'Unknown';

        setState(() {
          _selectedLocation = profile_entity.Location(
            latitude: position.latitude,
            longitude: position.longitude,
            city: city,
            country: country,
            displayAddress: '$city, $country',
          );
          _searchResults = [];
          _searchController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  void _selectResult(_SearchResult result) {
    setState(() {
      _selectedLocation = profile_entity.Location(
        latitude: result.latitude,
        longitude: result.longitude,
        city: result.city,
        country: result.country,
        displayAddress: result.displayAddress,
      );
      _searchResults = [];
      _searchController.text = result.displayAddress;
      _searchFocus.unfocus();
    });
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.of(context).pop(_selectedLocation);
    }
  }

  /// Open full-screen map picker
  Future<void> _openMapPicker() async {
    final result = await Navigator.of(context).push<profile_entity.Location>(
      MaterialPageRoute(
        builder: (_) => _MapPickerScreen(
          initialLocation: _selectedLocation,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLocation = result;
        _searchResults = [];
        _searchController.text = result.displayAddress;
        _searchFocus.unfocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.flight, color: Color(0xFF1E88E5), size: 22),
            SizedBox(width: 8),
            Text(
              'Select Travel Location',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search city, address, or place...',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textTertiary),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.richGold,
                          ),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: AppColors.textTertiary),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchResults = []);
                            },
                          )
                        : null,
                filled: true,
                fillColor: AppColors.backgroundCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  borderSide:
                      const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
                ),
              ),
            ),
          ),

          // GPS button + Map picker button row
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM),
            child: Row(
              children: [
                // GPS button
                Expanded(
                  child: InkWell(
                    onTap: _isLoadingGps ? null : _useCurrentLocation,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusM),
                      ),
                      child: Row(
                        children: [
                          _isLoadingGps
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF1E88E5),
                                  ),
                                )
                              : const Icon(Icons.my_location,
                                  color: Color(0xFF1E88E5), size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isLoadingGps
                                  ? 'Getting location...'
                                  : 'Use GPS',
                              style: const TextStyle(
                                color: Color(0xFF1E88E5),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Map picker button
                InkWell(
                  onTap: _openMapPicker,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.map, color: Color(0xFF1E88E5), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Pick on Map',
                          style: TextStyle(
                            color: Color(0xFF1E88E5),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Search results list
          if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return _SearchResultTile(
                    result: result,
                    onTap: () => _selectResult(result),
                  );
                },
              ),
            )
          else
            Expanded(
              child: _selectedLocation != null
                  ? _SelectedLocationCard(
                      location: _selectedLocation!,
                      onClear: () =>
                          setState(() => _selectedLocation = null),
                    )
                  : const _EmptyState(),
            ),
        ],
      ),
      bottomNavigationBar: _selectedLocation != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: ElevatedButton(
                  onPressed: _confirmLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusL),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flight_takeoff, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Confirm Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

/// Full-screen Google Maps picker
class _MapPickerScreen extends StatefulWidget {
  final profile_entity.Location? initialLocation;

  const _MapPickerScreen({this.initialLocation});

  @override
  State<_MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<_MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLatLng = const LatLng(40.7128, -74.0060); // Default: NYC
  String _addressText = 'Tap on the map to select a location';
  bool _isLoadingAddress = false;
  String _city = '';
  String _country = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLatLng = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _addressText = widget.initialLocation!.displayAddress;
      _city = widget.initialLocation!.city;
      _country = widget.initialLocation!.country;
    } else {
      // Try to get current position for initial map center
      _initCurrentPosition();
    }
  }

  Future<void> _initCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      if (mounted) {
        setState(() {
          _selectedLatLng = LatLng(position.latitude, position.longitude);
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_selectedLatLng),
        );
      }
    } catch (_) {
      // Use default position
    }
  }

  Future<void> _onMapTapped(LatLng latLng) async {
    setState(() {
      _selectedLatLng = latLng;
      _isLoadingAddress = true;
      _addressText = 'Loading address...';
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final city = place.locality ??
            place.subLocality ??
            place.subAdministrativeArea ??
            place.administrativeArea ??
            'Unknown';
        final country = place.country ?? 'Unknown';
        final region = place.administrativeArea ?? '';

        setState(() {
          _city = city;
          _country = country;
          _addressText =
              [city, region, country].where((s) => s.isNotEmpty).join(', ');
          _isLoadingAddress = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _city = 'Unknown';
          _country = 'Unknown';
          _addressText =
              '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
          _isLoadingAddress = false;
        });
      }
    }
  }

  void _confirmMapSelection() {
    if (_city.isEmpty && _country.isEmpty) return;

    Navigator.of(context).pop(profile_entity.Location(
      latitude: _selectedLatLng.latitude,
      longitude: _selectedLatLng.longitude,
      city: _city,
      country: _country,
      displayAddress: _addressText,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Select on Map',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _selectedLatLng,
                  zoom: 10,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                onTap: _onMapTapped,
                markers: {
                  Marker(
                    markerId: const MarkerId('selected'),
                    position: _selectedLatLng,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                  ),
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
              ),
            ),
          ),

          // Address bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.backgroundCard,
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Color(0xFF1E88E5), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _isLoadingAddress
                          ? Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF1E88E5),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _addressText,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              _addressText,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_selectedLatLng.latitude.toStringAsFixed(6)}, ${_selectedLatLng.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: ElevatedButton(
            onPressed:
                (_city.isNotEmpty || _country.isNotEmpty) && !_isLoadingAddress
                    ? _confirmMapSelection
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.divider,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
            ),
            child: const Text(
              'Select This Location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResult {
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final String region;
  final String displayAddress;

  _SearchResult({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    required this.region,
    required this.displayAddress,
  });
}

class _SearchResultTile extends StatelessWidget {
  final _SearchResult result;
  final VoidCallback onTap;

  const _SearchResultTile({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.richGold, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.displayAddress,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${result.latitude.toStringAsFixed(6)}, ${result.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SelectedLocationCard extends StatelessWidget {
  final profile_entity.Location location;
  final VoidCallback onClear;

  const _SelectedLocationCard({
    required this.location,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        children: [
          // Map preview
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border: Border.all(
                  color: const Color(0xFF1E88E5).withOpacity(0.3)),
            ),
            clipBehavior: Clip.antiAlias,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(location.latitude, location.longitude),
                zoom: 12,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('selected'),
                  position: LatLng(location.latitude, location.longitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                ),
              },
              liteModeEnabled: true,
              zoomControlsEnabled: false,
              scrollGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              zoomGesturesEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
          const SizedBox(height: 16),
          // Location info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border: Border.all(
                  color: const Color(0xFF1E88E5).withOpacity(0.5)),
            ),
            child: Column(
              children: [
                const Icon(Icons.flight,
                    color: Color(0xFF1E88E5), size: 48),
                const SizedBox(height: 16),
                Text(
                  location.displayAddress,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                      color: Color(0xFF1E88E5),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  location.city != location.country
                      ? '${location.city}, ${location.country}'
                      : location.city,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.refresh,
                      color: AppColors.textTertiary, size: 18),
                  label: const Text(
                    'Change location',
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'You will appear in discovery results for this location for 24 hours.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.travel_explore,
              size: 64,
              color: AppColors.textTertiary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Search for a city or use GPS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your profile will appear in that location\'s discovery feed for 24 hours with a Traveler badge.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
