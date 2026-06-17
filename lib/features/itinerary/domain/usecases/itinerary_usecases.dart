import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_summary.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/repositories/itinerary_repository.dart';

/// UseCase for retrieving a list of itineraries with optional filters.
class GetItinerariesUseCase {
  final ItineraryRepository _repository;
  GetItinerariesUseCase(this._repository);

  /// Executes the use case to fetch itineraries.
  ///
  /// [status] Optional filter for itinerary status (e.g., draft, active, completed).
  /// [query] Optional search text to filter itineraries by title.
  Future<List<ItineraryEntity>> call({ItineraryStatus? status, String? query}) {
    return _repository.getItineraries(status: status, query: query);
  }
}

/// UseCase for fetching summary statistics of the user's itineraries.
class GetItinerarySummaryUseCase {
  final ItineraryRepository _repository;
  GetItinerarySummaryUseCase(this._repository);

  /// Executes the use case to fetch the summary data.
  Future<ItinerarySummary> call() {
    return _repository.getSummary();
  }
}

/// UseCase for deleting an entire itinerary.
class DeleteItineraryUseCase {
  final ItineraryRepository _repository;
  DeleteItineraryUseCase(this._repository);

  /// Executes the use case to delete the itinerary.
  ///
  /// [id] The unique identifier of the itinerary to delete.
  Future<void> call(String id) {
    return _repository.deleteItinerary(id);
  }
}

/// UseCase for retrieving the full details of a specific itinerary.
class GetItineraryDetailUseCase {
  final ItineraryRepository _repository;
  GetItineraryDetailUseCase(this._repository);

  /// Executes the use case to fetch itinerary details including activities.
  ///
  /// [id] The unique identifier of the itinerary.
  Future<ItineraryDetailEntity> call(String id) {
    return _repository.getItineraryDetail(id);
  }
}

/// UseCase for updating the activities within an itinerary (e.g., after drag-and-drop reordering).
class UpdateItineraryActivitiesUseCase {
  final ItineraryRepository _repository;
  UpdateItineraryActivitiesUseCase(this._repository);

  /// Executes the use case to save the updated list of days and activities.
  ///
  /// [id] The unique identifier of the itinerary.
  /// [days] The newly ordered/modified list of days and their activities.
  Future<void> call(String id, List<ItineraryDayEntity> days) {
    return _repository.updateItineraryActivities(id, days);
  }
}

/// UseCase for toggling the public visibility of an itinerary.
class ToggleVisibilityUseCase {
  final ItineraryRepository _repository;
  ToggleVisibilityUseCase(this._repository);

  /// Executes the use case to change the visibility status.
  ///
  /// [id] The unique identifier of the itinerary.
  /// [isPublic] Set to true to make the itinerary public, false for private.
  Future<void> call(String id, bool isPublic) {
    return _repository.toggleVisibility(id, isPublic);
  }
}

/// UseCase for renaming an itinerary.
class UpdateItineraryTitleUseCase {
  final ItineraryRepository _repository;
  UpdateItineraryTitleUseCase(this._repository);

  /// Executes the use case to update the itinerary title.
  ///
  /// [id] The unique identifier of the itinerary.
  /// [title] The new title.
  Future<void> call(String id, String title) {
    return _repository.updateItineraryTitle(id, title);
  }
}

/// UseCase for partially updating an individual activity's details.
class UpdateActivityUseCase {
  final ItineraryRepository _repository;
  UpdateActivityUseCase(this._repository);

  /// Executes the use case to update specific fields of an activity.
  ///
  /// [itineraryId] The ID of the parent itinerary.
  /// [activityId] The ID of the activity to update.
  /// Returns a Future that completes when the update is successful.
  Future<void> call(
    String itineraryId,
    String activityId, {
    String? arrivalTime,
    String? departureTime,
    double? actualCost,
    String? userNotes,
    bool? isLocked,
  }) {
    return _repository.updateActivity(
      itineraryId,
      activityId,
      arrivalTime: arrivalTime,
      departureTime: departureTime,
      actualCost: actualCost,
      userNotes: userNotes,
      isLocked: isLocked,
    );
  }
}

/// UseCase for removing an activity from an itinerary.
class DeleteActivityUseCase {
  final ItineraryRepository _repository;
  DeleteActivityUseCase(this._repository);

  /// Executes the use case to delete the specified activity.
  ///
  /// [itineraryId] The ID of the parent itinerary.
  /// [activityId] The ID of the activity to delete.
  Future<void> call(String itineraryId, String activityId) {
    return _repository.deleteActivity(itineraryId, activityId);
  }
}
