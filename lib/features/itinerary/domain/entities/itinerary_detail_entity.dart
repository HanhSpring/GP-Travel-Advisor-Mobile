import 'package:freezed_annotation/freezed_annotation.dart';
import 'itinerary_day_entity.dart';

part 'itinerary_detail_entity.freezed.dart';

@freezed
class ItineraryDetailEntity with _$ItineraryDetailEntity {
  const factory ItineraryDetailEntity({
    required String id,
    required String title,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    required String status, // e.g. "DANG DIEN RA"
    @Default(true) bool isPublic,
    
    // Stats for 2x2 grid
    required int durationDays,
    required int activitiesCount,
    required int hotelsCount,
    required int transportTurns,
    
    // Budget
    required double estimatedBudget,
    required double spentBudget,
    @Default('VNĐ') String currency,
    
    // Content
    @Default([]) List<ItineraryDayEntity> days,
    @Default([]) List<String> notes,
    
    // Coordinates for map context (simplified)
    @Default([]) List<double> centerCoordinate,
  }) = _ItineraryDetailEntity;
}
