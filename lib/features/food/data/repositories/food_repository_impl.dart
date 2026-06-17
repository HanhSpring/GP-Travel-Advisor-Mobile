import 'package:travel_advisor_mobile/features/food/data/datasources/food_remote_data_source.dart';
import 'package:travel_advisor_mobile/features/food/domain/repositories/food_repository.dart';

class FoodRepositoryImpl implements FoodRepository {
  final FoodRemoteDataSource remoteDataSource;

  FoodRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<OrderEligiblePlace>> getItineraryOrderPlaces({required String itineraryId}) {
    return remoteDataSource.getItineraryOrderPlaces(itineraryId: itineraryId);
  }

  @override
  Future<OrderPopupData> getOrderPopup(String placeId) {
    return remoteDataSource.getOrderPopup(placeId);
  }
}
