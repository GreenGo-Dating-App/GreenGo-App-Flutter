import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/buddy_catalog.dart';

/// Look of one drawn Buddy avatar: palette + face features. 24 of them,
/// all different, drawn in code (no photos, no image assets, never a real
/// person).
class BuddyAvatarStyle {
  const BuddyAvatarStyle({
    required this.background,
    required this.face,
    required this.accent,
    required this.shape,
    required this.eyes,
    required this.mouth,
    required this.extra,
  });

  final Color background;
  final Color face;
  final Color accent;

  /// 0 round, 1 rounded square, 2 blob (wide), 3 tall oval.
  final int shape;

  /// 0 dots, 1 happy arcs, 2 big round eyes, 3 wink.
  final int eyes;

  /// 0 smile, 1 open smile, 2 small "o".
  final int mouth;

  /// 0 none, 1 antenna, 2 round ears, 3 leaf sprout, 4 glasses, 5 cheeks + tuft.
  final int extra;

  static const List<List<int>> _palettes = <List<int>>[
    // background, face, accent
    [0xFF1E3A5F, 0xFF7FD1FF, 0xFFFFD166],
    [0xFF2D1E4F, 0xFFC3A6FF, 0xFFFF8FAB],
    [0xFF123D2F, 0xFF7EE0B5, 0xFFFFE08A],
    [0xFF4A2511, 0xFFFFB37A, 0xFF7FDBFF],
    [0xFF3B1036, 0xFFFF9ECF, 0xFFB8F2E6],
    [0xFF0F3B3F, 0xFF66E3D6, 0xFFFFA36C],
    [0xFF3D3510, 0xFFFFE066, 0xFF8EA8FF],
    [0xFF1A2B4C, 0xFF9DB4FF, 0xFFFFC75F],
    [0xFF401818, 0xFFFF8A80, 0xFFFFF59D],
    [0xFF153A1A, 0xFFA5E887, 0xFFFF9F68],
    [0xFF2B2B2B, 0xFFE0E0E0, 0xFF64D2FF],
    [0xFF33204A, 0xFFFFC1E3, 0xFF9BF6FF],
    [0xFF0D2F44, 0xFFFFD6A5, 0xFF6EE7B7],
    [0xFF3F2A12, 0xFFD4A373, 0xFFFAEDCD],
    [0xFF183A37, 0xFFB5EAD7, 0xFFFF9AA2],
    [0xFF2A1B3D, 0xFFA0C4FF, 0xFFFDFFB6],
    [0xFF452A1F, 0xFFFFADAD, 0xFFCAFFBF],
    [0xFF1D3557, 0xFFF1FAEE, 0xFFE63946],
    [0xFF264653, 0xFFE9C46A, 0xFF2A9D8F],
    [0xFF3A0CA3, 0xFF4CC9F0, 0xFFF72585],
    [0xFF5F0F40, 0xFFFB8B24, 0xFFE9F5DB],
    [0xFF283618, 0xFFDDA15E, 0xFFFEFAE0],
    [0xFF22223B, 0xFFC9ADA7, 0xFFF2E9E4],
    [0xFF003049, 0xFFFCBF49, 0xFFEAE2B7],
  ];

  static final List<BuddyAvatarStyle> all = List<BuddyAvatarStyle>.unmodifiable(
    List<BuddyAvatarStyle>.generate(24, (i) {
      final p = _palettes[i];
      return BuddyAvatarStyle(
        background: Color(p[0]),
        face: Color(p[1]),
        accent: Color(p[2]),
        shape: i % 4,
        eyes: (i ~/ 2) % 4,
        mouth: (i ~/ 3) % 3,
        extra: (i * 5) % 6,
      );
    }),
  );

  static BuddyAvatarStyle of(String avatarId) => all[BuddyCatalog.avatarIndex(avatarId)];
}

/// A round, drawn Buddy avatar with an optional "AI" badge.
class BuddyAvatar extends StatelessWidget {
  const BuddyAvatar({
    required this.avatarId,
    this.size = 48,
    this.showAiBadge = false,
    this.greyed = false,
    super.key,
  });

  final String avatarId;
  final double size;
  final bool showAiBadge;

  /// Locked Buddies are shown desaturated.
  final bool greyed;

  static const ColorFilter _grey = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 0.6, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final style = BuddyAvatarStyle.of(avatarId);
    Widget face = CustomPaint(
      size: Size.square(size),
      painter: BuddyAvatarPainter(style),
    );
    if (greyed) face = ColorFiltered(colorFilter: _grey, child: face);
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n?.buddyAvatarLabel(BuddyCatalog.avatarIndex(avatarId) + 1),
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            face,
            if (showAiBadge && l10n != null)
              Positioned(
                right: -2,
                bottom: -2,
                child: BuddyAiBadge(compact: size < 44),
              ),
          ],
        ),
      ),
    );
  }
}

/// The small "AI" pill (localized: KI / IA ...).
class BuddyAiBadge extends StatelessWidget {
  const BuddyAiBadge({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: const ValueKey('buddy-ai-badge'),
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.richGold,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.backgroundDark, width: 1.5),
      ),
      child: Text(
        l10n.buddyAiBadge,
        style: TextStyle(
          color: AppColors.deepBlack,
          fontSize: compact ? 8 : 10,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Paints one friendly illustrated face.
class BuddyAvatarPainter extends CustomPainter {
  BuddyAvatarPainter(this.style);

  final BuddyAvatarStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s / 2);
    final bg = Paint()..color = style.background;
    canvas.drawCircle(c, s / 2, bg);
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: s / 2)));

    final face = Paint()..color = style.face;
    final accent = Paint()..color = style.accent;
    final ink = Paint()
      ..color = const Color(0xFF1B1B1F)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.045;
    final inkFill = Paint()..color = const Color(0xFF1B1B1F);

    final faceCenter = Offset(s / 2, s * 0.56);
    Rect faceRect;
    switch (style.shape) {
      case 0:
        faceRect = Rect.fromCenter(center: faceCenter, width: s * 0.66, height: s * 0.66);
        break;
      case 1:
        faceRect = Rect.fromCenter(center: faceCenter, width: s * 0.64, height: s * 0.6);
        break;
      case 2:
        faceRect = Rect.fromCenter(center: faceCenter, width: s * 0.76, height: s * 0.58);
        break;
      default:
        faceRect = Rect.fromCenter(center: faceCenter, width: s * 0.58, height: s * 0.7);
    }

    // Extras behind the face.
    switch (style.extra) {
      case 1: // antenna
        canvas.drawLine(Offset(s / 2, faceRect.top), Offset(s / 2, faceRect.top - s * 0.12),
            ink..color = style.accent);
        canvas.drawCircle(Offset(s / 2, faceRect.top - s * 0.13), s * 0.05, accent);
        ink.color = const Color(0xFF1B1B1F);
        break;
      case 2: // round ears
        canvas.drawCircle(Offset(faceRect.left + s * 0.06, faceRect.top + s * 0.06), s * 0.1, face);
        canvas.drawCircle(Offset(faceRect.right - s * 0.06, faceRect.top + s * 0.06), s * 0.1, face);
        canvas.drawCircle(Offset(faceRect.left + s * 0.06, faceRect.top + s * 0.06), s * 0.05, accent);
        canvas.drawCircle(Offset(faceRect.right - s * 0.06, faceRect.top + s * 0.06), s * 0.05, accent);
        break;
      case 3: // leaf sprout
        final stem = Offset(s / 2, faceRect.top + s * 0.02);
        final leaf = Path()
          ..moveTo(stem.dx, stem.dy)
          ..quadraticBezierTo(stem.dx + s * 0.16, stem.dy - s * 0.14, stem.dx + s * 0.02, stem.dy - s * 0.2)
          ..quadraticBezierTo(stem.dx - s * 0.06, stem.dy - s * 0.1, stem.dx, stem.dy);
        canvas.drawPath(leaf, accent);
        break;
    }

    // Face.
    if (style.shape == 1) {
      canvas.drawRRect(RRect.fromRectAndRadius(faceRect, Radius.circular(s * 0.16)), face);
    } else {
      canvas.drawOval(faceRect, face);
    }

    // Eyes.
    final eyeY = faceRect.top + faceRect.height * 0.42;
    final dx = faceRect.width * 0.2;
    final le = Offset(s / 2 - dx, eyeY), re = Offset(s / 2 + dx, eyeY);
    switch (style.eyes) {
      case 0:
        canvas.drawCircle(le, s * 0.04, inkFill);
        canvas.drawCircle(re, s * 0.04, inkFill);
        break;
      case 1:
        for (final e in [le, re]) {
          canvas.drawArc(Rect.fromCenter(center: e.translate(0, s * 0.02), width: s * 0.1, height: s * 0.08),
              math.pi, math.pi, false, ink);
        }
        break;
      case 2:
        final white = Paint()..color = Colors.white;
        for (final e in [le, re]) {
          canvas.drawCircle(e, s * 0.07, white);
          canvas.drawCircle(e.translate(s * 0.01, s * 0.01), s * 0.035, inkFill);
        }
        break;
      default:
        canvas.drawCircle(le, s * 0.04, inkFill);
        canvas.drawLine(re.translate(-s * 0.045, 0), re.translate(s * 0.045, 0), ink);
    }

    // Glasses over the eyes.
    if (style.extra == 4) {
      final frame = Paint()
        ..color = style.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.03;
      canvas.drawCircle(le, s * 0.09, frame);
      canvas.drawCircle(re, s * 0.09, frame);
      canvas.drawLine(le.translate(s * 0.09, 0), re.translate(-s * 0.09, 0), frame);
    }

    // Cheeks + tuft.
    if (style.extra == 5) {
      final blush = Paint()..color = style.accent.withValues(alpha: 0.7);
      canvas.drawOval(
          Rect.fromCenter(center: le.translate(-s * 0.03, s * 0.1), width: s * 0.1, height: s * 0.06), blush);
      canvas.drawOval(
          Rect.fromCenter(center: re.translate(s * 0.03, s * 0.1), width: s * 0.1, height: s * 0.06), blush);
      final tuft = Paint()
        ..color = style.background
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = s * 0.04;
      final top = Offset(s / 2, faceRect.top + s * 0.02);
      canvas.drawLine(top, top.translate(-s * 0.05, -s * 0.08), tuft);
      canvas.drawLine(top, top.translate(s * 0.04, -s * 0.09), tuft);
    }

    // Mouth.
    final mouthC = Offset(s / 2, faceRect.top + faceRect.height * 0.7);
    switch (style.mouth) {
      case 0:
        canvas.drawArc(Rect.fromCenter(center: mouthC.translate(0, -s * 0.03), width: s * 0.2, height: s * 0.12),
            0.15 * math.pi, 0.7 * math.pi, false, ink);
        break;
      case 1:
        final p = Path()
          ..moveTo(mouthC.dx - s * 0.1, mouthC.dy - s * 0.02)
          ..quadraticBezierTo(mouthC.dx, mouthC.dy + s * 0.14, mouthC.dx + s * 0.1, mouthC.dy - s * 0.02)
          ..close();
        canvas.drawPath(p, inkFill);
        canvas.drawCircle(mouthC.translate(0, s * 0.035), s * 0.025, accent);
        break;
      default:
        canvas.drawOval(Rect.fromCenter(center: mouthC, width: s * 0.07, height: s * 0.08), inkFill);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BuddyAvatarPainter oldDelegate) => oldDelegate.style != style;
}
