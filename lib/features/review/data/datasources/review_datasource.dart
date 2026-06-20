import 'dart:io';

import 'package:dio/dio.dart';
import 'package:travel_advisor_mobile/core/config/app_config.dart';
import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';
import 'package:travel_advisor_mobile/features/review/data/models/itinerary_review_model.dart';
import 'package:travel_advisor_mobile/features/review/data/models/location_review_model.dart';

class ItineraryReviewPopupData {
  final bool showPopup;
  final String reason;
  final String itineraryId;
  final String itineraryTitle;

  const ItineraryReviewPopupData({
    required this.showPopup,
    required this.reason,
    required this.itineraryId,
    required this.itineraryTitle,
  });
}

class ItineraryReviewSummary {
  final bool hasReview;
  final double? rating;
  final String? content;

  const ItineraryReviewSummary({
    required this.hasReview,
    this.rating,
    this.content,
  });
}

class SubmitPlaceReviewInput {
  final String itineraryDetailId;
  final int rating;
  final String? content;
  final List<String> tags;
  final List<SubmitReviewMediaInput> media;

  const SubmitPlaceReviewInput({
    required this.itineraryDetailId,
    required this.rating,
    this.content,
    this.tags = const [],
    this.media = const [],
  });
}

class SubmitReviewMediaInput {
  final String objectKey;
  final String mediaType;
  final int sortOrder;

  const SubmitReviewMediaInput({
    required this.objectKey,
    required this.mediaType,
    required this.sortOrder,
  });
}

class ReviewMediaUploadCandidate {
  final String fileName;
  final String contentType;
  final int size;
  final int sortOrder;

  const ReviewMediaUploadCandidate({
    required this.fileName,
    required this.contentType,
    required this.size,
    required this.sortOrder,
  });
}

class ReviewMediaPresignedUrl {
  final String uploadUrl;
  final String objectKey;
  final String publicUrl;
  final String mediaType;
  final int sortOrder;
  final int expiresInSeconds;

  const ReviewMediaPresignedUrl({
    required this.uploadUrl,
    required this.objectKey,
    required this.publicUrl,
    required this.mediaType,
    required this.sortOrder,
    required this.expiresInSeconds,
  });

  factory ReviewMediaPresignedUrl.fromJson(Map<String, dynamic> json) {
    return ReviewMediaPresignedUrl(
      uploadUrl: (json['upload_url'] ?? '').toString(),
      objectKey: (json['object_key'] ?? '').toString(),
      publicUrl: (json['public_url'] ?? '').toString(),
      mediaType: (json['media_type'] ?? '').toString(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      expiresInSeconds: (json['expires_in_seconds'] as num?)?.toInt() ?? 0,
    );
  }
}

abstract class ReviewDataSource {
  Future<ItineraryReviewModel> getItineraryForReview(String itineraryId);
  Future<ItineraryReviewSummary> getReviewSummary(String itineraryId);
  Future<ItineraryReviewPopupData> getPopupData(String itineraryId);
  Future<void> dismissPopup(String itineraryId);
  Future<void> submitItineraryReview({
    required String itineraryId,
    double? overallRating,
    String? overallContent,
    bool applyAllPlaces = false,
    List<SubmitPlaceReviewInput> placeReviews = const [],
    List<SubmitReviewMediaInput> media = const [],
  });
  Future<List<ReviewMediaPresignedUrl>> createReviewPresignedUrls({
    required String scope,
    required String itineraryId,
    String? itineraryDetailId,
    required List<ReviewMediaUploadCandidate> files,
  });
  Future<void> uploadReviewMediaToR2({
    required ReviewMediaPresignedUrl presignedUrl,
    required File file,
    required String contentType,
    required int contentLength,
    void Function(int sent, int total)? onSendProgress,
  });
}

class RemoteReviewDataSource implements ReviewDataSource {
  final DioClient _client;

  RemoteReviewDataSource(this._client);

  int _parseDayLabel(String label) {
    final normalized = label.toUpperCase().trim();
    final match = RegExp(r'(\d+)').firstMatch(normalized);
    return int.tryParse(match?.group(1) ?? '') ?? 1;
  }

  String _formatDateRange(String startDate, String endDate) {
    if (startDate.isEmpty && endDate.isEmpty) {
      return 'Không rõ thời gian';
    }
    if (startDate.isEmpty) {
      return endDate;
    }
    if (endDate.isEmpty) {
      return startDate;
    }
    return '$startDate - $endDate';
  }

  @override
  Future<ItineraryReviewModel> getItineraryForReview(String itineraryId) async {
    final touristId = await AuthUtils.requireCurrentUserId();
    final response = await _client.dio.get(
      '/itinerary-reviews/$itineraryId/detail',
      queryParameters: {'tourist_id': touristId},
    );

    final data = response.data as Map<String, dynamic>;
    final itinerary =
        (data['itinerary'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final places = (data['places'] as List?) ?? const [];
    return ItineraryReviewModel(
      id: (itinerary['id'] ?? itineraryId).toString(),
      title: (itinerary['title'] ?? 'Lịch trình của bạn').toString(),
      imageUrl: (itinerary['cover_image'] ?? '').toString(),
      dateRange: _formatDateRange(
        (itinerary['start_date'] ?? '').toString(),
        (itinerary['end_date'] ?? '').toString(),
      ),
      status: ((itinerary['status'] ?? 'completed').toString()).toUpperCase(),
      locations: places
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => LocationReviewModel(
              id: (item['itinerary_detail_id'] ?? '').toString(),
              name: (item['place_name'] ?? 'Địa điểm').toString(),
              imageUrl: (item['place_image_url'] ?? '').toString(),
              day: _parseDayLabel((item['day_label'] ?? '').toString()),
              rating: (item['rating'] as num?)?.toDouble(),
              reviewText: item['content']?.toString(),
            ),
          )
          .where((item) => item.id.isNotEmpty)
          .toList(),
    );
  }

  @override
  Future<ItineraryReviewSummary> getReviewSummary(String itineraryId) async {
    final touristId = await AuthUtils.requireCurrentUserId();
    final response = await _client.dio.get(
      '/itinerary-reviews/$itineraryId/summary',
      queryParameters: {'tourist_id': touristId},
    );
    final data = response.data as Map<String, dynamic>;
    return ItineraryReviewSummary(
      hasReview: data['has_review'] == true,
      rating: (data['rating'] as num?)?.toDouble(),
      content: data['content']?.toString(),
    );
  }

  @override
  Future<ItineraryReviewPopupData> getPopupData(String itineraryId) async {
    final touristId = await AuthUtils.requireCurrentUserId();
    final response = await _client.dio.get(
      '/itinerary-reviews/popup',
      queryParameters: {'tourist_id': touristId, 'itinerary_id': itineraryId},
    );

    final data = response.data as Map<String, dynamic>;
    final itinerary =
        (data['itinerary'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};

    return ItineraryReviewPopupData(
      showPopup: data['show_popup'] == true,
      reason: (data['reason'] ?? '').toString(),
      itineraryId: (itinerary['id'] ?? itineraryId).toString(),
      itineraryTitle: (itinerary['title'] ?? 'Lịch trình của bạn').toString(),
    );
  }

  @override
  Future<void> dismissPopup(String itineraryId) async {
    final touristId = await AuthUtils.requireCurrentUserId();
    await _client.dio.post(
      '/itinerary-reviews/popup/dismiss',
      data: {'tourist_id': touristId, 'itinerary_id': itineraryId},
    );
  }

  @override
  Future<void> submitItineraryReview({
    required String itineraryId,
    double? overallRating,
    String? overallContent,
    bool applyAllPlaces = false,
    List<SubmitPlaceReviewInput> placeReviews = const [],
    List<SubmitReviewMediaInput> media = const [],
  }) async {
    final touristId = await AuthUtils.requireCurrentUserId();

    // Để pass qua @IsUUID('4') của NestJS trong chế độ Demo
    final isDemo = AppConfig.kUseMockData;
    final validItineraryId = isDemo
        ? '11111111-1111-4111-a111-111111111111'
        : itineraryId;
    final validTouristId = isDemo
        ? '22222222-2222-4222-a222-222222222222'
        : touristId;

    await _client.dio.post(
      '/itinerary-reviews/$validItineraryId/submit',
      data: {
        'tourist_id': validTouristId,
        if (overallRating != null) 'overall_rating': overallRating.round(),
        if (overallContent != null && overallContent.trim().isNotEmpty)
          'overall_content': overallContent,
        'apply_all_places': applyAllPlaces,
        if (placeReviews.isNotEmpty)
          'place_reviews': placeReviews
              .map(
                (item) => {
                  'itinerary_detail_id': isDemo
                      ? '33333333-3333-4333-a333-333333333333'
                      : item.itineraryDetailId,
                  'rating': item.rating,
                  if (item.content != null && item.content!.trim().isNotEmpty)
                    'content': item.content,
                  if (item.tags.isNotEmpty) 'tags': item.tags,
                  if (item.media.isNotEmpty)
                    'media': item.media
                        .map(
                          (mediaItem) => {
                            'object_key': mediaItem.objectKey,
                            'media_type': mediaItem.mediaType,
                            'sort_order': mediaItem.sortOrder,
                          },
                        )
                        .toList(),
                },
              )
              .toList(),
        if (media.isNotEmpty)
          'media': media
              .map(
                (item) => {
                  'object_key': item.objectKey,
                  'media_type': item.mediaType,
                  'sort_order': item.sortOrder,
                },
              )
              .toList(),
      },
    );
  }

  @override
  Future<List<ReviewMediaPresignedUrl>> createReviewPresignedUrls({
    required String scope,
    required String itineraryId,
    String? itineraryDetailId,
    required List<ReviewMediaUploadCandidate> files,
  }) async {
    if (files.isEmpty) {
      return const [];
    }

    final isDemo = AppConfig.kUseMockData;
    final validItineraryId = isDemo
        ? '11111111-1111-4111-a111-111111111111'
        : itineraryId;

    final response = await _client.dio.post(
      '/upload/reviews/presigned-urls',
      data: {
        'scope': scope,
        'itinerary_id': validItineraryId,
        if (itineraryDetailId != null)
          'itinerary_detail_id': isDemo
              ? '33333333-3333-4333-a333-333333333333'
              : itineraryDetailId,
        'files': files
            .map(
              (file) => {
                'file_name': file.fileName,
                'content_type': file.contentType,
                'size': file.size,
                'sort_order': file.sortOrder,
              },
            )
            .toList(),
      },
    );

    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ReviewMediaPresignedUrl.fromJson)
        .where((item) => item.uploadUrl.isNotEmpty && item.objectKey.isNotEmpty)
        .toList();
  }

  @override
  Future<void> uploadReviewMediaToR2({
    required ReviewMediaPresignedUrl presignedUrl,
    required File file,
    required String contentType,
    required int contentLength,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final uploadDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(minutes: 2),
      ),
    );

    await uploadDio.put(
      presignedUrl.uploadUrl,
      data: file.openRead(),
      onSendProgress: onSendProgress,
      options: Options(
        headers: {
          Headers.contentTypeHeader: contentType,
          Headers.contentLengthHeader: contentLength,
        },
      ),
    );
  }
}
