import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/models/profile_model.dart' show normalizeCountryName;
import '../../domain/entities/location.dart' as profile_entity;

/// Interactive map location picker used ONLY on the web build.
///
/// The mobile build resolves the current location through GPS + the
/// `geocoding` plugin, neither of which work on Flutter web. This screen gives
/// web users a real, key-free map (OpenStreetMap / Carto tiles via
/// `flutter_map`) to drop a pin, plus forward/reverse geocoding through the
/// public Nominatim service — mirroring the traveler location picker.
class WebLocationPickerScreen extends StatefulWidget {
  const WebLocationPickerScreen({super.key, this.initial});

  final profile_entity.Location? initial;

  static Route<profile_entity.Location> route({
    profile_entity.Location? initial,
  }) =>
      MaterialPageRoute(
        builder: (_) => WebLocationPickerScreen(initial: initial),
      );

  @override
  State<WebLocationPickerScreen> createState() =>
      _WebLocationPickerScreenState();
}

class _WebLocationPickerScreenState extends State<WebLocationPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  late LatLng _picked;
  String _city = '';
  String _country = '';
  String _address = '';
  bool _resolving = false;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _picked = (init != null && (init.latitude != 0 || init.longitude != 0))
        ? LatLng(init.latitude, init.longitude)
        : const LatLng(20, 0); // world view when unknown
    if (init != null) {
      _city = init.city;
      _country = init.country;
      _address = init.displayAddress;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasPin => _picked.latitude != 20 || _picked.longitude != 0;

  Future<void> _onTap(LatLng point) async {
    setState(() => _picked = point);
    await _reverse(point);
  }

  /// Reverse-geocode via Nominatim; degrade gracefully to coordinates.
  Future<void> _reverse(LatLng p) async {
    setState(() => _resolving = true);
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
        final city = _firstNonEmpty([
          addr['city'],
          addr['town'],
          addr['village'],
          addr['municipality'],
          addr['county'],
          addr['state'],
        ]);
        final country = normalizeCountryName((addr['country'] ?? '').toString());
        setState(() {
          _city = city;
          _country = country;
          _address = [city, country].where((s) => s.isNotEmpty).join(', ');
        });
        return;
      }
    } catch (_) {
      // fall through to coordinate-only display
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
    setState(() {
      if (_address.isEmpty) {
        _address =
            '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}';
      }
    });
  }

  /// Forward-geocode a typed query via Nominatim.
  Future<void> _search() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
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
          if (lat != null && lon != null) {
            final p = LatLng(lat, lon);
            setState(() => _picked = p);
            _mapController.move(p, 11);
            await _reverse(p);
          }
        }
      }
    } catch (_) {
      // ignore — user can still tap the map
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _confirm() {
    Navigator.pop(
      context,
      profile_entity.Location(
        latitude: _picked.latitude,
        longitude: _picked.longitude,
        city: _city,
        country: _country,
        displayAddress: _address.isNotEmpty
            ? _address
            : '${_picked.latitude.toStringAsFixed(4)}, '
                '${_picked.longitude.toStringAsFixed(4)}',
      ),
    );
  }

  static String _firstNonEmpty(List<dynamic> vals) => vals
      .map((v) => (v ?? '').toString().trim())
      .firstWhere((s) => s.isNotEmpty, orElse: () => '');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Text(l10n.webLocationPickerTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _picked,
              initialZoom: _hasPin ? 11 : 2,
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
                      point: _picked,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_on,
                          color: AppColors.richGold, size: 44),
                    ),
                  ],
                ),
            ],
          ),
          // Search bar
          Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: Material(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.backgroundCard,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textPrimary),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: l10n.webLocationSearchHint,
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _searching
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
                          onPressed: _search,
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          // Tap hint
          if (!_hasPin)
            Positioned(
              top: 72,
              left: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.webLocationTapHint,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ),
          // Confirm bar
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
                    _resolving ? '…' : (_address.isEmpty ? '—' : _address),
                    style: const TextStyle(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasPin ? _confirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.richGold,
                        foregroundColor: AppColors.deepBlack,
                        disabledBackgroundColor: AppColors.backgroundDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(l10n.webLocationConfirm),
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
