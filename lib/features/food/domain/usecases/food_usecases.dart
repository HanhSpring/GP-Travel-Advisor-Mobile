import 'package:travel_advisor_mobile/features/food/data/datasources/food_remote_data_source.dart';
import 'package:travel_advisor_mobile/features/food/domain/repositories/food_repository.dart';

class GetItineraryOrderPlacesUseCase {
  final FoodRepository repository;

  GetItineraryOrderPlacesUseCase(this.repository);

  Future<List<OrderEligiblePlace>> call(String itineraryId) {
    return repository.getItineraryOrderPlaces(itineraryId: itineraryId);
  }
}

class GetOrderPopupUseCase {
  final FoodRepository repository;

  GetOrderPopupUseCase(this.repository);

  Future<OrderPopupData> call(String placeId) {
    return repository.getOrderPopup(placeId);
  }
}
