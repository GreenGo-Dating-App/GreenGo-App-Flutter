import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection_container.dart' as di;
import '../../../core/services/effective_tier.dart';
import '../../../core/widgets/limit_reached_dialog.dart';
import '../../../generated/app_localizations.dart';
import '../../coins/presentation/bloc/coin_bloc.dart';
import '../../coins/presentation/bloc/coin_event.dart';
import '../../coins/presentation/screens/coin_shop_screen.dart';
import '../../membership/domain/entities/membership.dart';
import '../domain/experience_limits.dart';
import '../domain/repositories/user_experiences_repository.dart';

/// Result of checking whether a host may create another experience.
class ExperienceAllowance {
  const ExperienceAllowance({
    required this.tier,
    required this.count,
    required this.limit,
  });
  final MembershipTier tier;
  final int count;

  /// null = unlimited.
  final int? limit;

  bool get allowed => limit == null || count < limit!;
}

/// Client-side tier gate for creating experiences (FREE 0 / SILVER 1 /
/// GOLD 5 / PLATINUM ∞ / TEST ∞ / admin ∞, on the EFFECTIVE tier). The
/// server enforces the same limit in `createUserExperience`; this only saves
/// the user from filling in a form they can't submit.
class ExperienceCreationGate {
  ExperienceCreationGate({
    required UserExperiencesRepository repository,
    FirebaseFirestore? firestore,
  })  : _repo = repository,
        _db = firestore ?? FirebaseFirestore.instance;

  final UserExperiencesRepository _repo;
  final FirebaseFirestore _db;

  Future<ExperienceAllowance> check(String uid) async {
    var tier = MembershipTier.free;
    var isAdmin = false;
    try {
      final doc = await _db
          .collection('profiles')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 6));
      tier = effectiveTierFromDoc(doc.data());
      isAdmin = doc.data()?['isAdmin'] == true;
    } catch (_) {/* free fallback; the server decides anyway */}
    final limit = experienceLimitFor(tier, isAdmin: isAdmin);
    // Unlimited: no need to count.
    if (limit == null) {
      return ExperienceAllowance(tier: tier, count: 0, limit: null);
    }
    final count =
        (await _repo.countHostExperiences(uid)).fold((_) => 0, (c) => c);
    return ExperienceAllowance(tier: tier, count: count, limit: limit);
  }

  /// True when [uid] may create another experience; otherwise shows the
  /// upgrade prompt (→ Shop, Membership tab) and returns false.
  Future<bool> ensureCanCreate(BuildContext context, String uid) async {
    final a = await check(uid);
    if (a.allowed) return true;
    if (!context.mounted) return false;
    await showLimitDialog(context, uid, a);
    return false;
  }

  static Future<void> showLimitDialog(
    BuildContext context,
    String uid,
    ExperienceAllowance a,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final needed =
        tierNeededForExperiences(a.count) ?? MembershipTier.platinum;
    final r = await FeatureNotAvailableDialog.show(
      context: context,
      featureName: (a.limit ?? 0) == 0
          ? l10n.uexpLimitFeature
          : l10n.uexpUpgradeToCreateMore,
      description: (a.limit ?? 0) == 0
          ? l10n.uexpLimitFreeBody
          : l10n.uexpLimitReachedBody(a.limit!),
      currentTier: a.tier,
      requiredTier: needed,
      userId: uid,
      icon: Icons.travel_explore,
    );
    if (r?.action == LimitDialogAction.upgrade && context.mounted) {
      openMembershipShop(context, uid);
    }
  }

  /// The Shop opened on its Membership tab (index 1), like other tier gates.
  static void openMembershipShop(BuildContext context, String uid) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<CoinBloc>(
          create: (_) => di.sl<CoinBloc>()
            ..add(LoadCoinBalance(uid))
            ..add(const LoadAvailablePackages()),
          child: CoinShopScreen(userId: uid, initialTab: 1),
        ),
      ),
    );
  }
}
