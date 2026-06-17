import 'package:freezed_annotation/freezed_annotation.dart';

part 'itinerary_entity.freezed.dart';

enum ItineraryStatus { upcoming, ongoing, completed, draft }

///
@freezed
class ItineraryEntity with _$ItineraryEntity {
  const factory ItineraryEntity({
    required String id,

    required String title,

    String? imageUrl,

    DateTime? startDate,

    DateTime? endDate,

    @Default(0) double estimatedCost,

    @Default('VNĐ') String currency,

    @Default(1) int durationDays,

    @Default(0.0) double progress,

    @Default(ItineraryStatus.draft) ItineraryStatus status,

    double? rating,

    @Default(0) int visitedLocations,

    @Default(0) int totalLocations,

    @Default(0xFF90CAF9) int placeholderColor,

    @Default(false) bool trackingActive,

    @Default([]) List<String> placeImages,
  }) = _ItineraryEntity;
}