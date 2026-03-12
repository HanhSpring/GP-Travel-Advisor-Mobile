import 'package:freezed_annotation/freezed_annotation.dart';

part 'location_review_entity.freezed.dart';

@freezed
class LocationReviewEntity with _$LocationReviewEntity {
  const factory LocationReviewEntity({
    required String id,
    required String name,
    required String imageUrl,
    required int day,
    double? rating,
    String? reviewText,
  }) = _LocationReviewEntity;
}
