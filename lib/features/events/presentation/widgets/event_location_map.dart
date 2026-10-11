import 'package:flutter/material.dart';

import '../../../../core/widgets/interactive_location_map.dart';
import '../../domain/entities/event.dart';

/// The venue map on an event's detail page.
///
/// Only physical events carry coordinates (an online or hand-typed-address
/// event has none), so anything without valid coordinates renders nothing.
class EventLocationMap extends StatelessWidget {
  const EventLocationMap({required this.event, super.key});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final lat = event.latitude, lng = event.longitude;
    if (!InteractiveLocationMap.validCoordinates(lat, lng)) {
      return const SizedBox.shrink();
    }
    final sub = [event.address, event.city]
        .where((s) => s != null && s.trim().isNotEmpty)
        .join(', ');
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InteractiveLocationMap(
        lat: lat!,
        lng: lng!,
        label: event.locationName,
        subtitle: sub.isEmpty ? event.locationName : sub,
        height: 190,
      ),
    );
  }
}
