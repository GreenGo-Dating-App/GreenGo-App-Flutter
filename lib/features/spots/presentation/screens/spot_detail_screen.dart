import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_state.dart';
import '../../domain/entities/spot.dart';
import '../../domain/entities/spot_review.dart';
import '../bloc/spots_bloc.dart';
import '../bloc/spots_event.dart';
import '../bloc/spots_state.dart';

/// Detail screen for a single cultural spot.
///
/// Shows:
/// - Photo gallery at top (horizontal scrollable)
/// - Name, category, rating, city/country
/// - Description
/// - Reviews list
/// - "Write a Review" button
/// - Dark theme using AppColors
class SpotDetailScreen extends StatefulWidget {
  final String spotId;

  const SpotDetailScreen({super.key, required this.spotId});

  @override
  State<SpotDetailScreen> createState() => _SpotDetailScreenState();
}

class _SpotDetailScreenState extends State<SpotDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SpotsBloc>().add(LoadSpotById(spotId: widget.spotId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: BlocConsumer<SpotsBloc, SpotsState>(
        listener: (context, state) {
          if (state is ReviewAdded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Review added!'),
                backgroundColor: AppColors.successGreen,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SpotsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.richGold),
            );
          }

          if (state is SpotDetailLoaded) {
            return _buildDetailContent(state.spot, state.reviews);
          }

          if (state is SpotsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.errorRed, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Could not load spot',
                    style:
                        TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context
                        .read<SpotsBloc>()
                        .add(LoadSpotById(spotId: widget.spotId)),
                    child: const Text('Try Again',
                        style: TextStyle(color: AppColors.richGold)),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildDetailContent(Spot spot, List<SpotReview> reviews) {
    return CustomScrollView(
      slivers: [
        // App bar with photo gallery
        SliverAppBar(
          backgroundColor: AppColors.backgroundDark,
          expandedHeight: spot.photos.isNotEmpty ? 280 : 180,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: spot.photos.isNotEmpty
                ? _buildPhotoGallery(spot.photos)
                : Container(
                    color: AppColors.backgroundInput,
                    child: const Center(
                      child: Icon(
                        Icons.place_outlined,
                        color: AppColors.textTertiary,
                        size: 64,
                      ),
                    ),
                  ),
          ),
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor: AppColors.deepBlack.withValues(alpha: 0.6),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge
                _buildCategoryBadge(spot.category),
                const SizedBox(height: 12),
                // Name
                Text(
                  spot.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Rating row
                Row(
                  children: [
                    ..._buildStars(spot.rating),
                    const SizedBox(width: 8),
                    Text(
                      spot.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.richGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${spot.reviewCount} ${spot.reviewCount == 1 ? 'review' : 'reviews'})',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Location
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.textTertiary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${spot.city}, ${spot.country}',
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Description
                if (spot.description.isNotEmpty) ...[
                  const Text(
                    'About',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    spot.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Created by
                Text(
                  'Added by ${spot.createdByName}',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 16),
                // Reviews section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reviews (${reviews.length})',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showReviewDialog(context, spot.id),
                      icon: const Icon(Icons.rate_review_outlined, size: 18),
                      label: const Text('Write a Review'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.richGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (reviews.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'No reviews yet. Be the first to write one!',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  ...reviews.map((review) => _buildReviewTile(review)),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGallery(List<String> photos) {
    if (photos.length == 1) {
      return Image.network(
        photos.first,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.backgroundInput,
          child: const Center(
            child: Icon(Icons.image_not_supported_outlined,
                color: AppColors.textTertiary, size: 48),
          ),
        ),
      );
    }

    return PageView.builder(
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              photos[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.backgroundInput,
                child: const Center(
                  child: Icon(Icons.image_not_supported_outlined,
                      color: AppColors.textTertiary, size: 48),
                ),
              ),
            ),
            // Photo counter
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.deepBlack.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${index + 1}/${photos.length}',
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryBadge(SpotCategory category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getCategoryColor(category).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getCategoryColor(category).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(category),
            color: _getCategoryColor(category),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            category.displayName,
            style: TextStyle(
              color: _getCategoryColor(category),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTile(SpotReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar, name, date, stars
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.backgroundInput,
                backgroundImage: review.userPhotoUrl != null
                    ? NetworkImage(review.userPhotoUrl!)
                    : null,
                child: review.userPhotoUrl == null
                    ? const Icon(Icons.person,
                        color: AppColors.textTertiary, size: 18)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Stars
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    color: i < review.rating
                        ? AppColors.richGold
                        : AppColors.textTertiary,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context, String spotId) {
    final textController = TextEditingController();
    int selectedRating = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Write a Review',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Star rating selector
                    const Text(
                      'Your Rating',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (i) {
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              selectedRating = i + 1;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              i < selectedRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: i < selectedRating
                                  ? AppColors.richGold
                                  : AppColors.textTertiary,
                              size: 36,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    // Review text
                    TextField(
                      controller: textController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Share your experience...',
                        hintStyle:
                            const TextStyle(color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.backgroundInput,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.richGold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final profileState =
                              this.context.read<ProfileBloc>().state;
                          if (profileState is! ProfileLoaded) return;

                          final profile = profileState.profile;

                          final review = SpotReview(
                            id: '',
                            spotId: spotId,
                            userId: profile.userId,
                            userName: profile.displayName,
                            userPhotoUrl: profile.photoUrls.isNotEmpty
                                ? profile.photoUrls.first
                                : null,
                            rating: selectedRating,
                            text: textController.text.trim(),
                            createdAt: DateTime.now(),
                          );

                          this.context.read<SpotsBloc>().add(
                                AddReview(review: review),
                              );

                          Navigator.of(sheetContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.richGold,
                          foregroundColor: AppColors.deepBlack,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Submit Review',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildStars(double rating) {
    final List<Widget> stars = [];
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;

    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(const Icon(Icons.star, color: AppColors.richGold, size: 20));
      } else if (i == fullStars && hasHalfStar) {
        stars.add(
            const Icon(Icons.star_half, color: AppColors.richGold, size: 20));
      } else {
        stars.add(const Icon(Icons.star_border,
            color: AppColors.textTertiary, size: 20));
      }
    }
    return stars;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
    return '${(diff.inDays / 365).floor()} years ago';
  }

  Color _getCategoryColor(SpotCategory category) {
    switch (category) {
      case SpotCategory.restaurant:
        return const Color(0xFFE65100);
      case SpotCategory.cafe:
        return const Color(0xFF6D4C41);
      case SpotCategory.culturalSite:
        return const Color(0xFF1565C0);
      case SpotCategory.market:
        return const Color(0xFF2E7D32);
      case SpotCategory.viewpoint:
        return const Color(0xFF7B1FA2);
    }
  }

  IconData _getCategoryIcon(SpotCategory category) {
    switch (category) {
      case SpotCategory.restaurant:
        return Icons.restaurant;
      case SpotCategory.cafe:
        return Icons.local_cafe;
      case SpotCategory.culturalSite:
        return Icons.account_balance;
      case SpotCategory.market:
        return Icons.storefront;
      case SpotCategory.viewpoint:
        return Icons.landscape;
    }
  }
}
