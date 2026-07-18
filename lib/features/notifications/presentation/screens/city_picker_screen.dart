import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';

/// Full-screen map city picker for event-alert subscriptions.
///
/// Search a place (map flies there) OR tap the map to drop a pin. Either way we
/// resolve a city via Nominatim; "Use this city" pops the resolved city name.
/// Robust: a search always yields a city (falls back to the typed query), so
/// the caller always gets a non-empty value to add.
class CityPickerScreen extends StatefulWidget {
  const CityPickerScreen({super.key});

  @override
  State<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends State<CityPickerScreen> {
  final MapController _map = MapController();
  final TextEditingController _search = TextEditingController();

  LatLng _center = const LatLng(20, 0);
  bool _hasPin = false;
  String _city = '';
  String _country = '';
  bool _busy = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _firstNonEmpty(List<dynamic> v) => v
      .map((e) => (e ?? '').toString().trim())
      .firstWhere((s) => s.isNotEmpty, orElse: () => '');

  String _cityFrom(Map<String, dynamic> addr) => _firstNonEmpty([
        addr['city'],
        addr['town'],
        addr['village'],
        addr['municipality'],
        addr['county'],
        addr['state_district'],
        addr['state'],
      ]);

  void _moveMap(LatLng p, double zoom) {
    // Move after the current frame so the map is laid out and the animation
    // actually takes (calling move mid-build can be a silent no-op).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _map.move(p, zoom);
      } catch (_) {}
    });
  }

  /// Forward-geocode the typed query, fly the map there, and set the city
  /// straight from the search result's address details.
  Future<void> _runSearch() async {
    final q = _search.text.trim();
    if (q.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=jsonv2&q=${Uri.encodeQueryComponent(q)}'
        '&limit=1&addressdetails=1',
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
          final city = _cityFrom(addr);
          setState(() {
            if (lat != null && lon != null) {
              _center = LatLng(lat, lon);
              _hasPin = true;
              _moveMap(_center, 11);
            }
            // Fall back to the typed query so "Use this city" is never empty.
            _city = city.isNotEmpty ? city : q;
            _country = (addr['country'] ?? '').toString();
          });
        }
      }
    } catch (_) {
      // Keep the typed query as the city so the user isn't blocked.
      setState(() {
        _city = q;
        _hasPin = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Reverse-geocode a tapped point to a city.
  Future<void> _onTap(LatLng p) async {
    setState(() {
      _center = p;
      _hasPin = true;
      _busy = true;
    });
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=jsonv2&lat=${p.latitude}&lon=${p.longitude}'
        '&zoom=10&addressdetails=1',
      );
      final resp = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final addr = (data['address'] as Map<String, dynamic>?) ?? {};
        setState(() {
          _city = _cityFrom(addr);
          _country = (addr['country'] ?? '').toString();
        });
      }
    } catch (_) {
      // leave whatever we had
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _label {
    if (_city.isEmpty) return '';
    return [_city, _country].where((s) => s.isNotEmpty).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final canUse = _hasPin && _city.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Full-screen map.
          Positioned.fill(
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 2,
                onTap: (_, point) => _onTap(point),
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
                        point: _center,
                        width: 46,
                        height: 46,
                        alignment: Alignment.topCenter,
                        child: const Icon(Icons.location_on,
                            color: AppColors.richGold, size: 46),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Back button + search bar.
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                Material(
                  color: AppColors.backgroundCard,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
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
                        hintStyle:
                            const TextStyle(color: AppColors.textTertiary),
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.textSecondary),
                        suffixIcon: _busy
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.richGold),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.arrow_forward,
                                    color: AppColors.richGold),
                                onPressed: _runSearch,
                              ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (!_hasPin)
            Positioned(
              top: MediaQuery.of(context).padding.top + 64,
              left: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Search a city or tap anywhere on the map',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ),

          // Confirm bar.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: AppColors.backgroundCard,
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _busy ? '…' : (_label.isEmpty ? '—' : _label),
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
          ),
        ],
      ),
    );
  }
}
