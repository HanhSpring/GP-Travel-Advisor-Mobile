import 'package:travel_advisor_mobile/features/place/domain/entities/place_detail_entity.dart';

/// Repository interface defining the contract for place-related operations.
abstract class PlaceRepository {
  /// Retrieves the detailed information of a specific place.
  ///
  /// [id] The unique identifier of the place.
  Future<PlaceDetailEntity> getPlaceDetail(String id);
}