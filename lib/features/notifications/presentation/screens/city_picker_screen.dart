import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;

import '../../../../core/constants/app_colors.dart';

/// Full-screen map city picker for event-alert subscriptions.
///
/// Native Google Maps on mobile (renders + gestures reliably; the OSM tile
/// renderer was gray/janky on some Android devices) and key-free flutter_map on
/// web (Google Maps needs a JS key we don't ship). Either way: search a city or
/// tap the map, then "Use this city" pops the resolved city name. A search never
/// returns empty (falls back to the typed query).
class CityPickerScreen extends StatefulWidget {
  const CityPickerScreen({super.key});

  @override
  State<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends State<CityPickerScreen> {
  // Web map controller.
  final MapController _fmap = MapController();
  // Mobile map controller.
  gmaps.GoogleMapController? _gmap;

  final TextEditingController _search = TextEditingController();

  double _lat = 20;
  double _lng = 0;
  bool _hasPin = false;
  String _city = '';
  String _country = '';
  bool _busy = false;

  @override
  void dispose() {
    _search.dispose();
    _gmap?.dispose();
    super.dispose();
  }

  String _firstNonEmpty(List<String?> v) =>
      v.map((e) => (e ?? '').trim()).firstWhere((s) => s.isNotEmpty,
          orElse: () => '');

  // ── Tap → reverse geocode ──────────────────────────────────────────────────
  Future<void> _onTap(double lat, double lng) async {
    setState(() {
      _lat = lat;
      _lng = lng;
      _hasPin = true;
      _busy = true;
    });
    try {
      if (kIsWeb) {
        final r = await _nominatimReverse(lat, lng);
        setState(() {
          _city = r.$1;
          _country = r.$2;
        });
      } else {
        final placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          setState(() {
            _city = _firstNonEmpty([
              p.locality,
              p.subAdministrativeArea,
              p.administrativeArea,
            ]);
            _country = p.country ?? '';
          });
        }
      }
    } catch (_) {
      // keep whatever we had
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Search → move map + resolve city ───────────────────────────────────────
  Future<void> _runSearch() async {
    final q = _search.text.trim();
    if (q.isEmpty || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      if (kIsWeb) {
        final r = await _nominatimSearch(q);
        if (r != null) {
          setState(() {
            _lat = r.$1;
            _lng = r.$2;
            _hasPin = true;
            _city = r.$3.isNotEmpty ? r.$3 : q;
            _country = r.$4;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              _fmap.move(ll.LatLng(_lat, _lng), 11);
            } catch (_) {}
          });
        } else {
          setState(() {
            _city = q;
            _hasPin = true;
          });
        }
      } else {
        final locs = await locationFromAddress(q);
        if (locs.isNotEmpty) {
          final loc = locs.first;
          _lat = loc.latitude;
          _lng = loc.longitude;
          _hasPin = true;
          await _gmap?.animateCamera(
            gmaps.CameraUpdate.newLatLngZoom(gmaps.LatLng(_lat, _lng), 11),
          );
          String city = q;
          String country = '';
          try {
            final placemarks = await placemarkFromCoordinates(_lat, _lng);
            if (placemarks.isNotEmpty) {
              final p = placemarks.first;
              final resolved = _firstNonEmpty([
                p.locality,
                p.subAdministrativeArea,
                p.administrativeArea,
              ]);
              if (resolved.isNotEmpty) city = resolved;
              country = p.country ?? '';
            }
          } catch (_) {}
          setState(() {
            _city = city;
            _country = country;
          });
        } else {
          setState(() {
            _city = q;
            _hasPin = true;
          });
        }
      }
    } catch (_) {
      setState(() {
        _city = q;
        _hasPin = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Nominatim (web only) ───────────────────────────────────────────────────
  Future<(String, String)> _nominatimReverse(double lat, double lng) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=jsonv2&lat=$lat&lon=$lng&zoom=10&addressdetails=1',
    );
    final resp = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 8));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final addr = (data['address'] as Map<String, dynamic>?) ?? {};
      return (_cityFromAddr(addr), (addr['country'] ?? '').toString());
    }
    return ('', '');
  }

  Future<(double, double, String, String)?> _nominatimSearch(String q) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?format=jsonv2&q=${Uri.encodeQueryComponent(q)}&limit=1&addressdetails=1',
    );
    final resp = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 8));
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List<dynamic>;
      if (list.isNotEmpty) {
        final first = list.first as Map<String, dynamic>;
        final lat = double.tryParse('${first['lat']}');
        final lon = double.tryParse('${first['lon']}');
        final addr = (first['address'] as Map<String, dynamic>?) ?? {};
        if (lat != null && lon != null) {
          return (lat, lon, _cityFromAddr(addr), (addr['country'] ?? '').toString());
        }
      }
    }
    return null;
  }

  String _cityFromAddr(Map<String, dynamic> addr) => _firstNonEmpty([
        addr['city']?.toString(),
        addr['town']?.toString(),
        addr['village']?.toString(),
        addr['municipality']?.toString(),
        addr['county']?.toString(),
        addr['state']?.toString(),
      ]);

  String get _label => _city.isEmpty
      ? ''
      : [_city, _country].where((s) => s.isNotEmpty).join(', ');

  @override
  Widget build(BuildContext context) {
    final canUse = _hasPin && _city.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text('Pick a city',
            style: TextStyle(color: AppColors.textPrimary)),
      ),
      // Column + Expanded gives the map a definite height (the working pattern);
      // a Stack/Positioned.fill left the native map view with bad constraints
      // and gesture conflicts (gray, "whole block" panning).
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Material(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.backgroundCard,
              child: TextField(
                controller: _search,
                style: const TextStyle(color: AppColors.textPrimary),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _runSearch(),
                decoration: InputDecoration(
                  hintText: 'Search a city…',
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _busy
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.richGold),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.arrow_forward,
                              color: AppColors.richGold),
                          onPressed: _runSearch,
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Map fills the remaining space.
          Expanded(child: _buildMap()),

          // Confirm bar.
          Container(
            width: double.infinity,
            color: AppColors.backgroundCard,
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _busy
                      ? '…'
                      : (_label.isEmpty
                          ? 'Search a city or tap the map'
                          : _label),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        canUse ? () => Navigator.of(context).pop(_city) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.deepBlack,
                      disabledBackgroundColor: AppColors.backgroundDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Use this city',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (kIsWeb) {
      return FlutterMap(
        mapController: _fmap,
        options: MapOptions(
          initialCenter: ll.LatLng(_lat, _lng),
          initialZoom: 2,
          minZoom: 2,
          maxZoom: 18,
          interactionOptions:
              const InteractionOptions(flags: InteractiveFlag.all),
          onTap: (_, point) => _onTap(point.latitude, point.longitude),
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.greengochat.greengochatapp',
            maxZoom: 19,
            retinaMode: true,
          ),
          if (_hasPin)
            MarkerLayer(
              markers: [
                Marker(
                  point: ll.LatLng(_lat, _lng),
                  width: 46,
                  height: 46,
                  alignment: Alignment.topCenter,
                  child: const Icon(Icons.location_on,
                      color: AppColors.richGold, size: 46),
                ),
              ],
            ),
        ],
      );
    }
    // Mobile: native Google Maps.
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(_lat, _lng),
        zoom: 2,
      ),
      onMapCreated: (c) => _gmap = c,
      onTap: (pos) => _onTap(pos.latitude, pos.longitude),
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      markers: _hasPin
          ? {
              gmaps.Marker(
                markerId: const gmaps.MarkerId('picked'),
                position: gmaps.LatLng(_lat, _lng),
              ),
            }
          : const {},
    );
  }
}
