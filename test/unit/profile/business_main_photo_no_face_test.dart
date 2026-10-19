import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_event.dart';
import 'package:image_picker/image_picker.dart';

/// Owner, 2026-10-19: a business account's main photo may be a logo - no face
/// required, nudity / explicit checks still apply. The on-device check (ML
/// Kit) can't run in unit tests, so the wiring is checked in the source.
void main() {
  test('the upload event carries the business flag (default false)', () {
    final e = ProfilePhotoUploadRequested(userId: 'u', photo: XFile('x.jpg'), isMainPhoto: true);
    expect(e.isBusiness, isFalse);
    final b = ProfilePhotoUploadRequested(userId: 'u', photo: XFile('x.jpg'), isMainPhoto: true, isBusiness: true);
    expect(b.isBusiness, isTrue);
    expect(b == e, isFalse);
  });

  test('face is required only for a personal main photo; businesses keep the NSFW check', () {
    final src = File('lib/features/profile/presentation/bloc/profile_bloc.dart').readAsStringSync();
    // On-device: the face+NSFW branch is skipped for businesses ...
    expect(src.contains('if (!event.isPrivate && event.isMainPhoto && !event.isBusiness) {'), isTrue);
    // ... and they fall through to validatePublicPhoto (nudity check still runs).
    expect(src.contains('validationService.validatePublicPhoto(photoFile)'), isTrue);
    // Server (moderateUploadedImage) is told not to require a face for businesses.
    expect(src.contains('requireFace: !event.isPrivate && event.isMainPhoto && !event.isBusiness,'), isTrue);
  });

  test('the photo manager passes the account type', () {
    final src = File('lib/features/profile/presentation/screens/photo_management_screen.dart').readAsStringSync();
    expect(src.contains('isBusiness: widget.profile.isBusiness,'), isTrue);
  });
}
