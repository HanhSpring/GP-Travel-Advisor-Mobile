import 'package:travel_advisor_mobile/features/review/domain/entities/itinerary_review_entity.dart';
import 'package:travel_advisor_mobile/features/review/data/datasources/review_datasource.dart';

/// Repository interface defining the contract for handling itinerary reviews.
abstract class ReviewRepository {
  /// Fetches an itinerary along with its places/activities specifically tailored for the review process.
  Future<ItineraryReviewEntity> getItineraryForReview(String itineraryId);
  /// Retrieves the necessary initial data structures needed to show the rating popup.
  Future<ItineraryReviewPopupData> getPopupData(String itineraryId);
  Future<void> dismissPopup(String itineraryId);
  Future<void> submitItineraryReview({
    required String itineraryId,
    double? overallRating,
    String? overallContent,
    bool applyAllPlaces = false,
    List<SubmitPlaceReviewInput> placeReviews = const [],
    List<String> mediaUrls = const [],
  });
}