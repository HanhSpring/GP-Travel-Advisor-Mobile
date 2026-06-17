import 'package:travel_advisor_mobile/features/food/data/datasources/food_remote_data_source.dart';

abstract class FoodRepository {
  Future<List<OrderEligiblePlace>> getItineraryOrderPlaces({required String itineraryId});
  Future<OrderPopupData> getOrderPopup(String placeId);
}
