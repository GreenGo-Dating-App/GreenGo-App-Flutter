import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';

/// Business Verification Admin Screen
///
/// Lets an admin review pending business verification requests and grant the
/// gold verified badge. Requests are written by the business account screen to
/// `business_verification_requests/{userId}` with:
///   { status: 'pending', businessName, note, submittedAt }
///
/// On approve the admin transactionally:
///   - sets `profiles/{userId}.businessVerified = true` (+ businessVerifiedAt,
///     businessVerifiedBy)
///   - updates the request to `status: 'approved'` (+ reviewedBy, reviewedAt)
///   - writes a `notifications` doc telling the owner they are verified.
/// On reject the request is set to `status: 'rejected'` (+ rejectionReason).
///
/// Access is gated to admins by reading `profiles/{adminId}.isAdmin`.
class BusinessVerificationAdminScreen extends StatefulWidget {
  const BusinessVerificationAdminScreen({
    required this.adminId,
    super.key,
  });

  final String adminId;

  @override
  State<BusinessVerificationAdminScreen> createState() =>
      _BusinessVerificationAdminScreenState();
}

/// Lightweight view model for a single pending request row.
class _BusinessRequest {
  const _BusinessRequest({
    required this.userId,
    required this.businessName,
    required this.note,
    required this.submittedAt,
    this.requesterName,
    this.requesterPhotoUrl,
  });

  final String userId;
  final String businessName;
  final String note;
  final DateTime? submittedAt;
  final String? requesterName;
  final String? requesterPhotoUrl;
}

class _BusinessVerificationAdminScreenState
    extends State<BusinessVerificationAdminScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _checkingAccess = true;
  bool _isAdmin = false;

  bool _isLoading = true;
  String? _loadError;
  List<_BusinessRequest> _requests = [];
  final Set<String> _busyUserIds = {};

  @override
  void initState() {
    super.initState();
    _verifyAccess();
  }

  Future<void> _verifyAccess() async {
    try {
      final doc =
          await _firestore.collection('profiles').doc(widget.adminId).get();
      final isAdmin = (doc.data()?['isAdmin'] as bool?) ?? false;
      if (!mounted) return;
      setState(() {
        _isAdmin = isAdmin;
        _checkingAccess = false;
      });
      if (isAdmin) {
        await _loadRequests();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
        _checkingAccess = false;
      });
    }
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      // Bounded read of pending requests; sorted client-side to avoid needing
      // a composite index.
      final snapshot = await _firestore
          .collection('business_verification_requests')
          .where('status', isEqualTo: 'pending')
          .limit(100)
          .get();

      final requests = <_BusinessRequest>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        // Load a minimal profile for the requester (best effort).
        String? requesterName;
        String? requesterPhotoUrl;
        try {
          final profileDoc =
              await _firestore.collection('profiles').doc(doc.id).get();
          final profileData = profileDoc.data();
          if (profileData != null) {
            requesterName = profileData['displayName'] as String?;
            final photos = profileData['photoUrls'];
            if (photos is List && photos.isNotEmpty) {
              requesterPhotoUrl = photos.first as String?;
            }
          }
        } catch (_) {
          // Ignore profile load failures; row still renders.
        }

        requests.add(
          _BusinessRequest(
            userId: doc.id,
            businessName: (data['businessName'] as String?) ?? '',
            note: (data['note'] as String?) ?? '',
            submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
            requesterName: requesterName,
            requesterPhotoUrl: requesterPhotoUrl,
          ),
        );
      }

      // Newest first.
      requests.sort((a, b) {
        final aDate = a.submittedAt;
        final bDate = b.submittedAt;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      if (!mounted) return;
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _approve(_BusinessRequest request) async {
    setState(() => _busyUserIds.add(request.userId));
    try {
      final batch = _firestore.batch();

      final profileRef =
          _firestore.collection('profiles').doc(request.userId);
      batch.set(
        profileRef,
        <String, dynamic>{
          'businessVerified': true,
          'businessVerifiedAt': FieldValue.serverTimestamp(),
          'businessVerifiedBy': widget.adminId,
        },
        SetOptions(merge: true),
      );

      final requestRef = _firestore
          .collection('business_verification_requests')
          .doc(request.userId);
      batch.set(
        requestRef,
        <String, dynamic>{
          'status': 'approved',
          'reviewedBy': widget.adminId,
          'reviewedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Best-effort notification to the business owner.
      final notificationRef = _firestore.collection('notifications').doc();
      final l10n = AppLocalizations.of(context)!;
      batch.set(notificationRef, <String, dynamic>{
        'userId': request.userId,
        'type': 'system',
        'title': l10n.adminBusinessVerifiedNotificationTitle,
        'message': l10n.adminBusinessVerifiedNotificationBody,
        'data': <String, dynamic>{'businessVerified': true},
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'actionUrl': null,
        'imageUrl': null,
      });

      await batch.commit();

      if (!mounted) return;
      setState(() {
        _requests.removeWhere((r) => r.userId == request.userId);
        _busyUserIds.remove(request.userId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.adminBusinessApproved),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busyUserIds.remove(request.userId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _reject(_BusinessRequest request) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(
          l10n.adminRejectBusinessVerification,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: l10n.adminBusinessRejectReasonHint,
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _busyUserIds.add(request.userId));
    try {
      await _firestore
          .collection('business_verification_requests')
          .doc(request.userId)
          .set(
        <String, dynamic>{
          'status': 'rejected',
          'rejectionReason': controller.text.trim(),
          'reviewedBy': widget.adminId,
          'reviewedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      setState(() {
        _requests.removeWhere((r) => r.userId == request.userId);
        _busyUserIds.remove(request.userId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.adminBusinessRejected),
          backgroundColor: AppColors.charcoal,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busyUserIds.remove(request.userId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          l10n.adminBusinessVerifications,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          if (!_checkingAccess && _isAdmin)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
              onPressed: _loadRequests,
            ),
        ],
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_checkingAccess) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.richGold),
      );
    }

    if (!_isAdmin) {
      return _EmptyState(
        icon: Icons.lock_outline,
        iconColor: AppColors.errorRed,
        message: l10n.adminAccessDenied,
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.richGold),
      );
    }

    if (_loadError != null) {
      return _EmptyState(
        icon: Icons.error_outline,
        iconColor: AppColors.errorRed,
        message: l10n.adminErrorLoadingData(_loadError!),
      );
    }

    if (_requests.isEmpty) {
      return _EmptyState(
        icon: Icons.verified_outlined,
        iconColor: AppColors.successGreen,
        message: l10n.adminNoPendingBusinessVerifications,
      );
    }

    return RefreshIndicator(
      color: AppColors.richGold,
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (context, index) =>
            _buildRequestCard(l10n, _requests[index]),
      ),
    );
  }

  Widget _buildRequestCard(AppLocalizations l10n, _BusinessRequest request) {
    final isBusy = _busyUserIds.contains(request.userId);

    return Card(
      color: AppColors.backgroundCard,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.richGold.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.richGold.withValues(alpha: 0.2),
                  backgroundImage: (request.requesterPhotoUrl != null &&
                          request.requesterPhotoUrl!.isNotEmpty)
                      ? NetworkImage(request.requesterPhotoUrl!)
                      : null,
                  child: (request.requesterPhotoUrl == null ||
                          request.requesterPhotoUrl!.isEmpty)
                      ? const Icon(Icons.storefront, color: AppColors.richGold)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              request.businessName.isNotEmpty
                                  ? request.businessName
                                  : l10n.adminUnknown,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.verified,
                            size: 18,
                            color: AppColors.richGold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.requesterName ??
                            '${request.userId.substring(0, request.userId.length < 8 ? request.userId.length : 8)}…',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request.note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  request.note,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              request.submittedAt != null
                  ? l10n.adminSubmittedLabel(_formatDate(request.submittedAt!))
                  : l10n.adminSubmittedLabel('—'),
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            if (isBusy)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(color: AppColors.richGold),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approve(request),
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(l10n.adminApproveBusinessVerification),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _reject(request),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.errorRed,
                      foregroundColor: Colors.white,
                    ),
                    tooltip: l10n.adminRejectBusinessVerification,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.iconColor,
    required this.message,
  });

  final IconData icon;
  final Color iconColor;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: iconColor),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
