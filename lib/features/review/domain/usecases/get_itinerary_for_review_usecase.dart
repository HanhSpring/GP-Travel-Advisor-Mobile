import 'package:travel_advisor_mobile/features/review/domain/entities/itinerary_review_entity.dart';
import 'package:travel_advisor_mobile/features/review/domain/repositories/review_repository.dart';

/// UseCase for fetching an itinerary specifically formatted for the review process.
class GetItineraryForReviewUseCase {
  final ReviewRepository repository;

  GetItineraryForReviewUseCase(this.repository);

  /// Executes the use case to retrieve the itinerary details needed for a review.
  ///
  /// [itineraryId] The unique identifier of the itinerary to review.
  Future<ItineraryReviewEntity> call(String itineraryId) {
    return repository.getItineraryForReview(itineraryId);
  }
}