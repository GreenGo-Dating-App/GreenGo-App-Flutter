import 'package:flutter/material.dart';

import '../../../../core/widgets/interactive_location_map.dart';
import '../../domain/entities/user_experience.dart';

/// The meeting-point map on an experience's detail page.
///
/// Experiences publish their meeting point openly (the text is shown to every
/// viewer and there is no "revealed after booking" rule), so the exact pin is
/// shown. Nothing renders without valid coordinates.
class ExperienceLocationMap extends StatelessWidget {
  const ExperienceLocationMap({required this.experience, super.key});

  final UserExperience experience;

  @override
  Widget build(BuildContext context) {
    final e = experience;
    if (!InteractiveLocationMap.validCoordinates(e.lat, e.lng)) {
      return const SizedBox.shrink();
    }
    final mp = (e.meetingPoint ?? '').trim();
    final place = [e.city, e.country]
        .where((s) => s != null && s.trim().isNotEmpty)
        .join(', ');
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InteractiveLocationMap(
        lat: e.lat!,
        lng: e.lng!,
        label: mp.isNotEmpty ? mp : e.locationName,
        subtitle: [e.locationName, if (place.isNotEmpty) place].join(' · '),
        height: 190,
      ),
    );
  }
}
