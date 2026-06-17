import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_summary.dart';
import 'package:travel_advisor_mobile/features/trip_planner/domain/usecases/create_itinerary_usecase.dart';

abstract class ItineraryRepository {
  Future<List<ItineraryEntity>> getItineraries({
    ItineraryStatus? status,
    String? query,
  });
  Future<ItinerarySummary> getSummary();
  Future<ItineraryDetailEntity> getItineraryDetail(String id);
  Future<void> deleteItinerary(String id);
  Future<void> toggleVisibility(String id, bool isPublic);
  Future<void> updateItineraryTitle(String id, String title);
  Future<void> updateActivity(
    String itineraryId,
    String activityId, {
    String? arrivalTime,
    String? departureTime,
    double? actualCost,
    String? userNotes,
    bool? isLocked,
  });
  Future<void> deleteActivity(String itineraryId, String activityId);

  Future<void> updateItineraryActivities(
    String id,
    List<ItineraryDayEntity> days,
  );

  Future<String> createItinerary(CreateItineraryParams params);
}
