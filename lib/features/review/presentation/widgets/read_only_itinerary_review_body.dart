import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/widgets/net_image.dart';
import 'package:travel_advisor_mobile/features/review/presentation/cubit/review_cubit.dart';
import 'package:travel_advisor_mobile/features/review/presentation/cubit/review_state.dart';
import 'package:travel_advisor_mobile/features/review/presentation/screens/place_review_screen.dart';
import 'package:travel_advisor_mobile/features/review/presentation/widgets/review_media_list.dart';
import 'package:travel_advisor_mobile/features/review/presentation/widgets/star_rating_input.dart';

class ReadOnlyItineraryReviewBody extends StatelessWidget {
  final ReviewLoaded state;

  const ReadOnlyItineraryReviewBody({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 104),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReadOnlyItineraryHeader(state: state),
              const SizedBox(height: 20),
              _ReadOnlyOverallReview(state: state),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Đánh giá địa điểm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blobLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${state.itinerary.locations.length} địa điểm',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...state.itinerary.locations.map(
                (location) => _ReadOnlyLocationReviewCard(
                  locationId: location.id,
                  state: state,
                  onOpen: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlaceReviewScreen(
                          locationId: location.id,
                          reviewCubit: context.read<ReviewCubit>(),
                          isReadOnly: true,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                minimumSize: const Size(double.infinity, 48),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Quay lại',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyItineraryHeader extends StatelessWidget {
  final ReviewLoaded state;

  const _ReadOnlyItineraryHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 164,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NetImage(
            url: state.itinerary.imageUrl,
            placeholderColor: AppColors.blobMedium.toARGB32(),
          ),
          Container(color: Colors.black.withValues(alpha: 0.42)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    state.itinerary.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  state.itinerary.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.itinerary.dateRange,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyOverallReview extends StatelessWidget {
  final ReviewLoaded state;

  const _ReadOnlyOverallReview({required this.state});

  @override
  Widget build(BuildContext context) {
    final hasComment = state.generalComment.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đánh giá tổng quan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 12),
          StarRatingInput(
            rating: state.generalRating,
            onRatingChanged: (_) {},
            enabled: false,
            mainAxisAlignment: MainAxisAlignment.start,
          ),
          if (hasComment) ...[
            const SizedBox(height: 12),
            Text(
              state.generalComment,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
          ReviewMediaList(
            mediaItems: state.itineraryMedia,
            onAddImages: () {},
            onAddVideo: () {},
            onRemoveMedia: (_) {},
            onClearAllMedia: () {},
            isReadOnly: true,
            imageSize: 112,
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyLocationReviewCard extends StatelessWidget {
  final String locationId;
  final ReviewLoaded state;
  final VoidCallback onOpen;

  const _ReadOnlyLocationReviewCard({
    required this.locationId,
    required this.state,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final location = state.itinerary.locations.firstWhere(
      (item) => item.id == locationId,
    );
    final mediaItems = state.locationMediaByDetailId[location.id] ?? const [];
    final hasComment = location.reviewText?.trim().isNotEmpty == true;
    final hasTags = location.reviewTags?.isNotEmpty == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 72,
                child: NetImage(
                  url: location.imageUrl,
                  placeholderColor: AppColors.blobLight.toARGB32(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blobLight.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'NGÀY ${location.day}',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(location.rating ?? 0).toStringAsFixed(0)}/5',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFB020),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    location.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  StarRatingInput(
                    rating: location.rating ?? 0,
                    onRatingChanged: (_) {},
                    enabled: false,
                    size: 18,
                  ),
                  if (hasComment) ...[
                    const SizedBox(height: 6),
                    Text(
                      location.reviewText!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                  if (hasTags) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: location.reviewTags!
                          .take(3)
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF0D9488),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (mediaItems.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ReviewMediaList(
                      mediaItems: mediaItems,
                      onAddImages: () {},
                      onAddVideo: () {},
                      onRemoveMedia: (_) {},
                      onClearAllMedia: () {},
                      isReadOnly: true,
                      imageSize: 64,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Xem chi tiết',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
