import 'package:freezed_annotation/freezed_annotation.dart';

part 'itinerary_summary.freezed.dart';

@freezed
class ItinerarySummary with _$ItinerarySummary {
  const factory ItinerarySummary({
    @Default(0) int total,

    @Default(0) int completed,

    @Default(0) int upcoming,

    @Default(0) int draft,
  }) = _ItinerarySummary;
}