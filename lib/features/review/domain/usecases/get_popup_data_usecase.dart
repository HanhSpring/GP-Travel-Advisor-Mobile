import 'package:travel_advisor_mobile/features/review/domain/repositories/review_repository.dart';
import 'package:travel_advisor_mobile/features/review/data/datasources/review_datasource.dart';

/// UseCase for fetching initial data required to populate a review popup/dialog.
class GetPopupDataUseCase {
  final ReviewRepository repository;

  GetPopupDataUseCase(this.repository);

  /// Executes the use case to load prerequisite popup data (e.g., initial rating parameters).
  ///
  /// [itineraryId] The unique identifier of the itinerary being reviewed.
  Future<ItineraryReviewPopupData> call(String itineraryId) {
    return repository.getPopupData(itineraryId);
  }
}
