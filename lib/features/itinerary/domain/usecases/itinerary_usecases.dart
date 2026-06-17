import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_summary.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/repositories/itinerary_repository.dart';

class GetItinerariesUseCase {
  final ItineraryRepository _repository;
  GetItinerariesUseCase(this._repository);

  Future<List<ItineraryEntity>> call({ItineraryStatus? status, String? query}) {
    return _repository.getItineraries(status: status, query: query);
  }
}

class GetItinerarySummaryUseCase {
  final ItineraryRepository _repository;
  GetItinerarySummaryUseCase(this._repository);

  Future<ItinerarySummary> call() {
    return _repository.getSummary();
  }
}

class DeleteItineraryUseCase {
  final ItineraryRepository _repository;
  DeleteItineraryUseCase(this._repository);

  Future<void> call(String id) {
    return _repository.deleteItinerary(id);
  }
}

class GetItineraryDetailUseCase {
  final ItineraryRepository _repository;
  GetItineraryDetailUseCase(this._repository);

  Future<ItineraryDetailEntity> call(String id) {
    return _repository.getItineraryDetail(id);
  }
}

class UpdateItineraryActivitiesUseCase {
  final ItineraryRepository _repository;
  UpdateItineraryActivitiesUseCase(this._repository);

  Future<void> call(String id, List<ItineraryDayEntity> days) {
    return _repository.updateItineraryActivities(id, days);
  }
}

class ToggleVisibilityUseCase {
  final ItineraryRepository _repository;
  ToggleVisibilityUseCase(this._repository);

  Future<void> call(String id, bool isPublic) {
    return _repository.toggleVisibility(id, isPublic);
  }
}

class UpdateItineraryTitleUseCase {
  final ItineraryRepository _repository;
  UpdateItineraryTitleUseCase(this._repository);

  Future<void> call(String id, String title) {
    return _repository.updateItineraryTitle(id, title);
  }
}

class UpdateActivityUseCase {
  final ItineraryRepository _repository;
  UpdateActivityUseCase(this._repository);

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

class DeleteActivityUseCase {
  final ItineraryRepository _repository;
  DeleteActivityUseCase(this._repository);

  Future<void> call(String itineraryId, String activityId) {
    return _repository.deleteActivity(itineraryId, activityId);
  }
}
