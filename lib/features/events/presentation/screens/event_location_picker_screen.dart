import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/data/models/profile_model.dart'
    show normalizeCountryName;
import '../../../profile/domain/entities/location.dart';

/// Event location picker — shows a map to drop a pin, or search/type an address.
/// Returns a [Location] (lat/lng + city/country + display address) via pop.
class EventLocationPickerScreen extends StatefulWidget {
  const EventLocationPickerScreen({super.key, this.initial});

  final LatLng? initial;

  static Route<Location> route({LatLng? initial}) =>
      MaterialPageRoute(builder: (_) => EventLocationPickerScreen(initial: initial));

  @override
  State<EventLocationPickerScreen> createState() =>
      _EventLocationPickerScreenState();
}

class _EventLocationPickerScreenState extends State<EventLocationPickerScreen> {
  GoogleMapController? _controller;
  final _searchController = TextEditingController();
  late LatLng _picked = widget.initial ?? const LatLng(41.9028, 12.4964); // Rome
  String _city = '';
  String _country = '';
  String _address = '';
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _resolve(_picked);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _resolve(LatLng p) async {
    setState(() => _resolving = true);
    try {
      final placemarks =
          await placemarkFromCoordinates(p.latitude, p.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final pl = placemarks.first;
        final city = pl.locality ?? pl.subAdministrativeArea ?? '';
        final country = normalizeCountryName(pl.country ?? '');
        setState(() {
          _city = city;
          _country = country;
          _address = [
            if ((pl.street ?? '').isNotEmpty) pl.street!,
            city,
            country,
          ].where((s) => s.isNotEmpty).join(', ');
        });
      }
    } catch (_) {
      // ignore — user can still confirm raw coordinates
    }
    if (mounted) setState(() => _resolving = false);
  }

  Future<void> _onMapTap(LatLng p) async {
    setState(() => _picked = p);
    await _resolve(p);
  }

  Future<void> _search() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    try {
      final locs = await locationFromAddress(q);
      if (locs.isNotEmpty) {
        final p = LatLng(locs.first.latitude, locs.first.longitude);
        setState(() => _picked = p);
        await _controller?.animateCamera(CameraUpdate.newLatLngZoom(p, 13));
        await _resolve(p);
        return;
      }
    } catch (_) {
      // Forward-geocode failed — fall back to the typed text as the address.
    }
    if (mounted) setState(() => _address = q);
  }

  void _confirm() {
    Navigator.pop(
      context,
      Location(
        latitude: _picked.latitude,
        longitude: _picked.longitude,
        city: _city,
        country: _country,
        displayAddress: _address.isNotEmpty
            ? _address
            : '${_picked.latitude.toStringAsFixed(4)}, ${_picked.longitude.toStringAsFixed(4)}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Text(l10n.eventsPickLocation,
            style: const TextStyle(color: AppColors.textPrimary)),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _picked, zoom: 12),
            onMapCreated: (c) => _controller = c,
            onTap: _onMapTap,
            markers: {
              Marker(
                markerId: const MarkerId('picked'),
                position: _picked,
              ),
            },
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
          ),
          // Search / manual address
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
                  hintText: l10n.eventsSearchAddress,
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
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
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.richGold,
                        foregroundColor: AppColors.deepBlack,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(l10n.eventsUseThisLocation),
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
