import 'package:flutter/material.dart';

import '../../../../core/widgets/interactive_location_map.dart';

/// A small, static map preview inside a location chat bubble.
///
/// No gestures (it lives inside a scrolling chat list), light CARTO basemap
/// with a gold pin. Tapping opens the full-screen interactive
/// [LocationMapScreen] with zoom, recenter and directions; [onTap] overrides
/// that.
class LocationMessageMap extends StatelessWidget {
  const LocationMessageMap({
    required this.lat,
    required this.lng,
    super.key,
    this.onTap,
    this.label,
    this.width = 220,
    this.height = 130,
  });

  final double lat;
  final double lng;
  final VoidCallback? onTap;
  final String? label;
  final double width;
  final double height;

  void _open(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => LocationMapScreen(lat: lat, lng: lng, label: label),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('chat-location-map'),
      onTap: onTap ?? () => _open(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: width,
          height: height,
          child: AbsorbPointer(
            child: LocationMapView(
              lat: lat,
              lng: lng,
              interactive: false,
              initialZoom: 15,
            ),
          ),
        ),
      ),
    );
  }
}
