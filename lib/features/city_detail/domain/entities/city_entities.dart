import 'package:freezed_annotation/freezed_annotation.dart';

part 'city_entities.freezed.dart';

@freezed
class CityItinerary with _$CityItinerary {
  const factory CityItinerary({
    required String id,
    required String title,
    required String authorName,
    required String authorAvatar,
    required String imageUrl,
    required String duration,
    required String views,
    required String likes,
    @Default('') String location,
  }) = _CityItinerary;
}

@freezed
class CityActivity with _$CityActivity {
  const factory CityActivity({
    required String id,
    required String name,
    required String imageUrl,
    @Default(0.0) double rating,
    @Default(0) int reviewCount,
    @Default('') String address,
    @Default('') String status,
    @Default(false) bool isFavorite,
    // === Filter fields ===
    @Default('') String category,   // 'cultural_history', 'nature', 'entertainment'
    @Default('') String priceType,  // 'free', 'paid'
    @Default('') String district,
  }) = _CityActivity;
}

@freezed
class CityRestaurant with _$CityRestaurant {
  const factory CityRestaurant({
    required String id,
    required String name,
    required String imageUrl,
    required double rating,
    required int reviewCount,
    @Default('') String address,
    @Default('') String status,
    @Default(false) bool isFavorite,
    // === Filter fields ===
    @Default('') String cuisine,          // 'vietnamese', 'foreign', 'vegetarian'
    @Default('') String priceLevel,       // 'budget', 'mid_range', 'premium'
    @Default([]) List<String> amenities,  // ['parking', 'air_con', 'kid_friendly']
  }) = _CityRestaurant;
}

@freezed
class CityHotel with _$CityHotel {
  const factory CityHotel({
    required String id,
    required String name,
    required String imageUrl,
    required double rating,
    required int reviewCount,
    required String price,
    @Default('') String address,
    @Default(false) bool isFavorite,
    // === Filter fields ===
    @Default(0) int starRating,               // 1-5
    @Default(0) double priceValue,
    @Default('') String accommodationType,    // 'hotel','homestay','resort','apartment','guesthouse'
    @Default([]) List<String> amenities,      // ['pool','wifi','breakfast','gym']
  }) = _CityHotel;
}

@freezed
class CityOverview with _$CityOverview {
  const factory CityOverview({
    required List<CityItinerary> itineraries,
    required List<CityActivity> activities,
    required List<CityRestaurant> restaurants,
    required List<CityHotel> hotels,
  }) = _CityOverview;
}