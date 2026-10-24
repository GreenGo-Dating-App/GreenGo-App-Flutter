import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/buddy_catalog.dart';
import '../../domain/entities/buddy_avatar_option.dart';
import '../../domain/repositories/buddies_repository.dart';

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

/// The avatar pictures (`buddy_avatars`) for the widgets below it, read
/// once through [BuddiesRepository.avatarOptions] (cached there, so every
/// screen that adds a scope shares one read). [BuddyAvatar] resolves a
/// Buddy's avatar id to its picture here.
class BuddyAvatarScope extends StatefulWidget {
  const BuddyAvatarScope({required this.repository, required this.child, super.key});

  final BuddiesRepository repository;
  final Widget child;

  /// The nearest pictures, or null outside a scope.
  static BuddyAvatarCatalog? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_BuddyAvatarInherited>()?.catalog;

  @override
  State<BuddyAvatarScope> createState() => _BuddyAvatarScopeState();
}

/// What a [BuddyAvatarScope] knows about the pictures.
class BuddyAvatarCatalog {
  BuddyAvatarCatalog({
    required this.options,
    required this.loading,
    required this.failed,
    required this.retry,
  }) : _byId = {for (final o in options) o.id: o};

  final List<BuddyAvatarOption> options;
  final bool loading;
  final bool failed;
  final VoidCallback retry;
  final Map<String, BuddyAvatarOption> _byId;

  BuddyAvatarOption? byId(String id) => _byId[id];
}

class _BuddyAvatarScopeState extends State<BuddyAvatarScope> {
  late List<BuddyAvatarOption> _options;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final cached = widget.repository.cachedAvatarOptions;
    _options = cached ?? const <BuddyAvatarOption>[];
    if (cached == null) {
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    if (mounted && !_loading) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    try {
      final list = await widget.repository.avatarOptions();
      if (!mounted) return;
      setState(() {
        _options = list;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) => _BuddyAvatarInherited(
        catalog: BuddyAvatarCatalog(
          options: _options,
          loading: _loading,
          failed: _failed,
          retry: () {
            if (!_loading) _load();
          },
        ),
        child: widget.child,
      );
}

class _BuddyAvatarInherited extends InheritedWidget {
  const _BuddyAvatarInherited({required this.catalog, required super.child});

  final BuddyAvatarCatalog catalog;

  @override
  bool updateShouldNotify(_BuddyAvatarInherited old) =>
      old.catalog.loading != catalog.loading ||
      old.catalog.failed != catalog.failed ||
      !identical(old.catalog.options, catalog.options);
}

/// A round Buddy avatar with an optional "AI" badge. A `buddy_avatars`
/// picture id shows that picture (cached network image); a legacy id
/// (`buddy_01..24`) or an id the [BuddyAvatarScope] does not know shows the
/// drawn avatar. Not tappable: Buddies have no profile.
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
    final l10n = AppLocalizations.of(context);
    final picture = BuddyCatalog.isLegacyAvatar(avatarId)
        ? null
        : BuddyAvatarScope.maybeOf(context)?.byId(avatarId);
    Widget face = picture != null
        ? BuddyAvatarImage(url: picture.url, size: size)
        : CustomPaint(
            key: const ValueKey('buddy-avatar-drawn'),
            size: Size.square(size),
            painter: BuddyAvatarPainter(BuddyAvatarStyle.of(avatarId)),
          );
    if (greyed) face = ColorFiltered(colorFilter: _grey, child: face);
    final label = picture != null
        ? (picture.label.isNotEmpty ? picture.label : null)
        : l10n?.buddyAvatarLabel(BuddyCatalog.avatarIndex(avatarId) + 1);
    return Semantics(
      label: label,
      image: true,
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

/// A circular avatar picture: the app's cached network image, decoded at
/// the shown size, with a neutral placeholder while loading and on error.
class BuddyAvatarImage extends StatelessWidget {
  const BuddyAvatarImage({required this.url, required this.size, super.key});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipOval(
      child: CachedNetworkImage(
        key: ValueKey('buddy-avatar-image-$url'),
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: px,
        memCacheHeight: px,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, __) => BuddyAvatarPlaceholder(size: size),
        errorWidget: (_, __, ___) => BuddyAvatarPlaceholder(size: size, failed: true),
      ),
    );
  }
}

/// Neutral circle shown while a picture loads or when it failed.
class BuddyAvatarPlaceholder extends StatelessWidget {
  const BuddyAvatarPlaceholder({required this.size, this.failed = false, super.key});

  final double size;
  final bool failed;

  @override
  Widget build(BuildContext context) => Container(
        key: ValueKey(failed ? 'buddy-avatar-error' : 'buddy-avatar-placeholder'),
        width: size,
        height: size,
        decoration: const BoxDecoration(color: AppColors.backgroundCard, shape: BoxShape.circle),
        child: Icon(
          failed ? Icons.broken_image_outlined : Icons.smart_toy_outlined,
          size: size * 0.45,
          color: AppColors.textTertiary,
        ),
      );
}

/// Grid of the avatar pictures of the nearest [BuddyAvatarScope]; the
/// selected one has a gold ring. Shows a spinner while loading and a retry
/// line when the read failed.
class BuddyAvatarGrid extends StatelessWidget {
  const BuddyAvatarGrid({required this.selected, required this.onSelected, super.key});

  final String? selected;
  final ValueChanged<String> onSelected;

  static const double _picture = 52;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final catalog = BuddyAvatarScope.maybeOf(context);
    final options = catalog?.options ?? const <BuddyAvatarOption>[];
    if (options.isEmpty) {
      if (catalog == null || catalog.loading) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(
                key: ValueKey('buddy-avatars-loading'), color: AppColors.richGold),
          ),
        );
      }
      return Padding(
        key: const ValueKey('buddy-avatars-failed'),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(l10n.buddyAvatarsLoadFailed,
                  style: const TextStyle(color: AppColors.textTertiary)),
            ),
            TextButton(
              key: const ValueKey('buddy-avatars-retry'),
              onPressed: catalog.retry,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          Semantics(
            selected: selected == o.id,
            button: true,
            label: o.label.isNotEmpty ? o.label : null,
            child: InkWell(
              key: ValueKey('buddy-avatar-${o.id}'),
              customBorder: const CircleBorder(),
              onTap: () => onSelected(o.id),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected == o.id ? AppColors.richGold : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: BuddyAvatarImage(url: o.url, size: _picture),
              ),
            ),
          ),
      ],
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
        canvas.drawCircle(
            Offset(faceRect.right - s * 0.06, faceRect.top + s * 0.06), s * 0.1, face);
        canvas.drawCircle(
            Offset(faceRect.left + s * 0.06, faceRect.top + s * 0.06), s * 0.05, accent);
        canvas.drawCircle(
            Offset(faceRect.right - s * 0.06, faceRect.top + s * 0.06), s * 0.05, accent);
        break;
      case 3: // leaf sprout
        final stem = Offset(s / 2, faceRect.top + s * 0.02);
        final leaf = Path()
          ..moveTo(stem.dx, stem.dy)
          ..quadraticBezierTo(
              stem.dx + s * 0.16, stem.dy - s * 0.14, stem.dx + s * 0.02, stem.dy - s * 0.2)
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
          canvas.drawArc(
              Rect.fromCenter(center: e.translate(0, s * 0.02), width: s * 0.1, height: s * 0.08),
              math.pi,
              math.pi,
              false,
              ink);
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
          Rect.fromCenter(
              center: le.translate(-s * 0.03, s * 0.1), width: s * 0.1, height: s * 0.06),
          blush);
      canvas.drawOval(
          Rect.fromCenter(
              center: re.translate(s * 0.03, s * 0.1), width: s * 0.1, height: s * 0.06),
          blush);
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
        canvas.drawArc(
            Rect.fromCenter(
                center: mouthC.translate(0, -s * 0.03), width: s * 0.2, height: s * 0.12),
            0.15 * math.pi,
            0.7 * math.pi,
            false,
            ink);
        break;
      case 1:
        final p = Path()
          ..moveTo(mouthC.dx - s * 0.1, mouthC.dy - s * 0.02)
          ..quadraticBezierTo(
              mouthC.dx, mouthC.dy + s * 0.14, mouthC.dx + s * 0.1, mouthC.dy - s * 0.02)
          ..close();
        canvas.drawPath(p, inkFill);
        canvas.drawCircle(mouthC.translate(0, s * 0.035), s * 0.025, accent);
        break;
      default:
        canvas.drawOval(
            Rect.fromCenter(center: mouthC, width: s * 0.07, height: s * 0.08), inkFill);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BuddyAvatarPainter oldDelegate) => oldDelegate.style != style;
}
