import 'package:travel_advisor_mobile/features/review/domain/repositories/review_repository.dart';
import 'package:travel_advisor_mobile/features/review/data/datasources/review_datasource.dart';

class GetPopupDataUseCase {
  final ReviewRepository repository;

  GetPopupDataUseCase(this.repository);

  Future<ItineraryReviewPopupData> call(String itineraryId) {
    return repository.getPopupData(itineraryId);
  }
}
