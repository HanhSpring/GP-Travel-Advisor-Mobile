import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_summary.dart';
import 'package:travel_advisor_mobile/features/trip_planner/domain/usecases/create_itinerary_usecase.dart';

/// Repository interface for itinerary-related data operations.
abstract class ItineraryRepository {
  Future<List<ItineraryEntity>> getItineraries({
    ItineraryStatus? status,
    String? query,
  });
  /// Retrieves summary statistics of the user's itineraries.
  Future<ItinerarySummary> getSummary();
  /// Retrieves detailed information about an itinerary, including its days and activities.
  Future<ItineraryDetailEntity> getItineraryDetail(String id);
  /// Deletes the itinerary identified by [id].
  Future<void> deleteItinerary(String id);
  /// Toggles the public/private visibility state of the itinerary.
  Future<void> toggleVisibility(String id, bool isPublic);
  /// Updates the title of the itinerary.
  Future<void> updateItineraryTitle(String id, String title);
  /// Updates an existing activity's details.
  Future<void> updateActivity(
    String itineraryId,
    String activityId, {
    String? arrivalTime,
    String? departureTime,
    double? actualCost,
    String? userNotes,
    bool? isLocked,
  });
  /// Deletes an activity [activityId] from the itinerary [itineraryId].
  Future<void> deleteActivity(String itineraryId, String activityId);

  Future<void> updateItineraryActivities(
    String id,
    List<ItineraryDayEntity> days,
  );

  Future<String> createItinerary(CreateItineraryParams params);
}
