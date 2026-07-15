import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/safe_navigation.dart';
import '../../../../generated/app_localizations.dart';
import '../../../discovery/presentation/screens/profile_detail_screen.dart';
import '../../../profile/domain/repositories/profile_repository.dart';

/// Business Leads / enquiries list.
///
/// Shows the people who have interacted with the business (opened a chat →
/// "contact", or saved/RSVP'd one of the business's events → "saved_event").
///
/// Reads are deliberately cheap and index-free so this scales to millions:
///   * A single-collection read of `business_leads/{businessId}/leads`
///     `.limit(100)` (no `.orderBy` → no single-field index needed at all),
///     then sorted CLIENT side by `updatedAt` newest-first.
///   * The acting user's minimal profile (name + avatar) is loaded best-effort
///     in parallel via `profiles/{uid}` `get()`; a failed/missing profile just
///     falls back to a neutral placeholder so one bad doc never breaks the list.
class BusinessLeadsScreen extends StatefulWidget {
  const BusinessLeadsScreen({required this.businessId, super.key});

  /// The business's own uid — the `business_leads/{businessId}` document owner.
  final String businessId;

  @override
  State<BusinessLeadsScreen> createState() => _BusinessLeadsScreenState();
}

class _BusinessLeadsScreenState extends State<BusinessLeadsScreen> {
  late Future<List<_Lead>> _leadsFuture;

  @override
  void initState() {
    super.initState();
    _leadsFuture = _loadLeads();
  }

  Future<List<_Lead>> _loadLeads() async {
    // Single-collection read, no orderBy → no index required. Bounded to 100.
    final snap = await FirebaseFirestore.instance
        .collection('business_leads')
        .doc(widget.businessId)
        .collection('leads')
        .limit(100)
        .get();

    final leads = snap.docs
        .map((d) => _Lead.fromDoc(d.id, d.data()))
        .toList()
      // Newest interaction first (client-side sort → no composite index).
      ..sort((a, b) {
        final at = a.updatedAt;
        final bt = b.updatedAt;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });

    // Name + avatar hydration via the shared ProfileRepository (the same,
    // reliable path the rest of the app uses) — more robust than a raw doc read.
    await Future.wait(leads.map((lead) async {
      try {
        final result = await di.sl<ProfileRepository>().getProfile(lead.uid);
        final profile = result.fold((f) {
          debugPrint('[Leads] profile load failed for ${lead.uid}: ${f.message}');
          return null;
        }, (p) => p);
        if (profile != null) {
          final name = profile.displayName.trim();
          lead.displayName = name.isNotEmpty ? name : null;
          if (profile.photoUrls.isNotEmpty) {
            lead.avatarUrl = profile.photoUrls.first;
          }
        }
      } catch (e) {
        debugPrint('[Leads] hydration error for ${lead.uid}: $e');
      }
    }));

    return leads;
  }

  Future<void> _refresh() async {
    final future = _loadLeads();
    setState(() => _leadsFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => SafeNavigation.pop(context),
        ),
        title: Text(
          l10n.businessLeadsTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: FutureBuilder<List<_Lead>>(
        future: _leadsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _loading();
          }
          if (snap.hasError) {
            return _errorState();
          }
          final leads = snap.data ?? const <_Lead>[];
          if (leads.isEmpty) {
            return _emptyState(l10n.businessLeadsEmpty);
          }
          return RefreshIndicator(
            color: AppColors.richGold,
            backgroundColor: AppColors.backgroundCard,
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              itemCount: leads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _leadTile(leads[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _leadTile(_Lead lead) {
    final l10n = AppLocalizations.of(context)!;
    final isContact = lead.type != 'saved_event';
    final typeLabel =
        isContact ? l10n.businessLeadContact : l10n.businessLeadSavedEvent;
    // Never show the raw uid — fall back to a neutral label if the name is
    // unavailable (e.g. a deleted profile or a transient load failure).
    final name = (lead.displayName?.isNotEmpty ?? false)
        ? lead.displayName!
        : l10n.chatUnknown;

    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      onTap: () => _openLeadProfile(lead.uid),
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.richGold.withOpacity(0.12),
              image: lead.avatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(lead.avatarUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: lead.avatarUrl == null
                ? const Icon(Icons.person, color: AppColors.richGold)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isContact ? Icons.chat_bubble_outline : Icons.event,
                      size: 13,
                      color: AppColors.richGold,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      typeLabel,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (!isContact && (lead.eventId?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 2),
                  Text(
                    lead.eventId!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (lead.updatedAt != null) ...[
            const SizedBox(width: 10),
            Text(
              _fmtDate(lead.updatedAt!),
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  /// Open the lead user's profile (loads it by uid, then ProfileDetailScreen).
  Future<void> _openLeadProfile(String uid) async {
    final navigator = Navigator.of(context);
    final result = await di.sl<ProfileRepository>().getProfile(uid);
    final profile = result.fold((_) => null, (p) => p);
    if (profile == null) return;
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileDetailScreen(
          profile: profile,
          currentUserId: widget.businessId,
        ),
      ),
    );
  }

  Widget _loading() => const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.richGold,
          ),
        ),
      );

  Widget _emptyState(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_outlined,
                  size: 56, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _errorState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _refresh,
                child: Text(
                  AppLocalizations.of(context)!.retry,
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

/// Lightweight mutable view model for a lead row (name/avatar are hydrated
/// best-effort after the initial list read).
class _Lead {
  _Lead({
    required this.uid,
    required this.type,
    this.eventId,
    this.updatedAt,
  });

  final String uid;
  final String type;
  final String? eventId;
  final DateTime? updatedAt;

  String? displayName;
  String? avatarUrl;

  factory _Lead.fromDoc(String id, Map<String, dynamic> d) {
    DateTime? ts(dynamic v) => v is Timestamp ? v.toDate() : null;
    return _Lead(
      uid: (d['uid'] as String?) ?? id,
      type: (d['lastType'] as String?) ?? (d['type'] as String?) ?? 'contact',
      eventId: d['eventId'] as String?,
      updatedAt: ts(d['updatedAt']) ?? ts(d['createdAt']),
    );
  }
}
