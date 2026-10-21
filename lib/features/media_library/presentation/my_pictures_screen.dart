import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../generated/app_localizations.dart';
import '../data/media_library_repository.dart';
import '../domain/media_library_item.dart';

/// Profile > My pictures: every picture the user uploaded, newest first,
/// paged. Approved pictures can be removed from the library; held ones are
/// shown as "Not visible" (no image, only the owner sees the entry) with
/// "Ask for a review".
///
/// With [pickMode] the same grid lists only approved pictures and returns the
/// tapped [MediaLibraryItem] (the "Choose from My pictures" picker).
class MyPicturesScreen extends StatefulWidget {
  const MyPicturesScreen({
    super.key,
    this.repository,
    this.pickMode = false,
    this.pageSize = 30,
  });

  final MediaLibraryRepository? repository;
  final bool pickMode;
  final int pageSize;

  /// Opens the picker; resolves to the chosen approved picture or null.
  static Future<MediaLibraryItem?> pick(
    BuildContext context, {
    MediaLibraryRepository? repository,
  }) {
    return Navigator.of(context).push<MediaLibraryItem>(
      MaterialPageRoute(
        builder: (_) => MyPicturesScreen(repository: repository, pickMode: true),
      ),
    );
  }

  @override
  State<MyPicturesScreen> createState() => _MyPicturesScreenState();
}

class _MyPicturesScreenState extends State<MyPicturesScreen> {
  late final MediaLibraryRepository _repo =
      widget.repository ?? FirestoreMediaLibraryRepository();
  final _scroll = ScrollController();
  final List<MediaLibraryItem> _items = [];
  Object? _cursor;
  bool _hasMore = true;
  bool _loading = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter < 600) _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final page = await _repo.fetchPage(
        approvedOnly: widget.pickMode,
        cursor: _cursor,
        limit: widget.pageSize,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _cursor = page.cursor;
        _hasMore = page.hasMore;
      });
    } catch (_) {
      // Stop auto-paging; pull to refresh retries.
      if (mounted) {
        setState(() {
          _error = true;
          _hasMore = false;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _cursor = null;
      _hasMore = true;
    });
    await _loadMore();
  }

  Future<void> _remove(MediaLibraryItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(l10n.myPicturesRemoveTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.myPicturesRemoveBody,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('my_pictures_remove_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.myPicturesRemove,
                style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _repo.remove(item.id);
      if (mounted) setState(() => _items.removeWhere((i) => i.id == item.id));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.myPicturesReviewFailed)));
      }
    }
  }

  Future<void> _askForReview(MediaLibraryItem item) async {
    final l10n = AppLocalizations.of(context)!;
    // The dialog owns its text controller (disposed after its exit
    // animation); it returns the note, or null when cancelled.
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _ReviewRequestDialog(),
    );
    if (text == null || !mounted) return;
    String message;
    try {
      await _repo.requestReview(item.id, note: text);
      message = l10n.myPicturesReviewSent;
      final i = _items.indexWhere((e) => e.id == item.id);
      if (i >= 0 && mounted) {
        setState(() => _items[i] = MediaLibraryItem(
              id: item.id,
              path: item.path,
              status: item.status,
              reasons: item.reasons,
              reviewable: item.reviewable,
              reviewStatus: 'pending',
              createdAt: item.createdAt,
            ));
      }
    } on ReviewRequestException catch (e) {
      message = switch (e.error) {
        ReviewRequestError.rateLimited => l10n.myPicturesReviewRateLimited,
        ReviewRequestError.alreadyRequested => l10n.myPicturesReviewAlready,
        _ => l10n.myPicturesReviewFailed,
      };
    } catch (_) {
      message = l10n.myPicturesReviewFailed;
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          widget.pickMode ? l10n.myPicturesChoose : l10n.myPicturesTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _body(l10n),
      ),
    );
  }

  Widget _body(AppLocalizations l10n) {
    if (_items.isEmpty && _loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.richGold));
    }
    if (_items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.photo_library_outlined,
              size: 56, color: AppColors.textTertiary.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error
                  ? l10n.myPicturesReviewFailed
                  : (widget.pickMode ? l10n.myPicturesPickerEmpty : l10n.myPicturesEmpty),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }
    return GridView.builder(
      key: const Key('my_pictures_grid'),
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.78,
      ),
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i >= _items.length) {
          // Last cell: keeps loading when the grid is shorter than the screen.
          WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
          return const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.richGold),
            ),
          );
        }
        return _tile(_items[i], l10n);
      },
    );
  }

  Widget _tile(MediaLibraryItem item, AppLocalizations l10n) {
    final visible = item.isApproved;
    final badge = item.isReviewPending
        ? l10n.myPicturesNotVisibleReview
        : (item.status == 'rejected'
            ? l10n.myPicturesNotVisibleRejected
            : l10n.myPicturesNotVisibleHeld);
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: visible
          ? Image.network(
              item.displayUrl!,
              fit: BoxFit.cover,
              cacheWidth: 320,
              errorBuilder: (_, __, ___) => _placeholder(Icons.broken_image_outlined),
            )
          : _placeholder(Icons.visibility_off_outlined),
    );
    return Column(
      key: Key('my_pictures_tile_${item.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.pickMode)
                InkWell(
                  onTap: () => Navigator.of(context).pop(item),
                  child: image,
                )
              else
                image,
              if (!widget.pickMode && visible)
                Positioned(
                  top: 2,
                  right: 2,
                  child: IconButton(
                    key: Key('my_pictures_remove_${item.id}'),
                    tooltip: l10n.myPicturesRemove,
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.textPrimary, size: 20),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.black45),
                    onPressed: () => _remove(item),
                  ),
                ),
            ],
          ),
        ),
        if (!visible) ...[
          const SizedBox(height: 4),
          Text(
            badge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: AppColors.warningAmber,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
          if (item.canAskForReview)
            TextButton(
              key: Key('my_pictures_ask_review_${item.id}'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => _askForReview(item),
              child: Text(l10n.myPicturesAskReview,
                  style: const TextStyle(
                      color: AppColors.richGold, fontSize: 12)),
            )
          else
            Text(
              l10n.myPicturesHiddenNote,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 10),
            ),
        ],
      ],
    );
  }

  Widget _placeholder(IconData icon) => Container(
        color: AppColors.backgroundInput,
        alignment: Alignment.center,
        child: Icon(icon, color: AppColors.textTertiary),
      );
}

class _ReviewRequestDialog extends StatefulWidget {
  const _ReviewRequestDialog();

  @override
  State<_ReviewRequestDialog> createState() => _ReviewRequestDialogState();
}

class _ReviewRequestDialogState extends State<_ReviewRequestDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppColors.backgroundCard,
      title: Text(l10n.myPicturesAskReview,
          style: const TextStyle(color: AppColors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.myPicturesReviewSla,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          TextField(
            key: const Key('my_pictures_review_note'),
            controller: _note,
            maxLength: 500,
            maxLines: 3,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: l10n.myPicturesReviewNoteHint),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          key: const Key('my_pictures_review_send'),
          onPressed: () => Navigator.of(context).pop(_note.text),
          child: Text(l10n.myPicturesReviewSend),
        ),
      ],
    );
  }
}
