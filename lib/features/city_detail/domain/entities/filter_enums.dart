import 'package:freezed_annotation/freezed_annotation.dart';

part 'filter_enums.freezed.dart';

// ============================================================
// ============================================================

enum ActivityCategory {
  culturalHistory('Văn hóa/Lịch sử'),
  nature('Thiên nhiên'),
  entertainment('Giải trí'),
  restaurant('Nhà hàng'),
  attractions('Điểm tham quan'),
  cafe('Quán cà phê'),
  photoSpot('Điểm chụp ảnh'),
  museum('Bảo tàng');

  final String label;
  const ActivityCategory(this.label);
}

enum ActivityPriceType {
  all('Tất cả'),
  free('Miễn phí'),
  paid('Trả phí');

  final String label;
  const ActivityPriceType(this.label);
}

enum RestaurantCuisine {
  vietnamese('Món Việt'),
  foreign('Món ngoại'),
  vegetarian('Đồ chay');

  final String label;
  const RestaurantCuisine(this.label);
}

enum RestaurantPriceLevel {
  all('Tất cả'),
  budget('Bình dân'),
  midRange('Trung cấp'),
  premium('Sang trọng');

  final String label;
  const RestaurantPriceLevel(this.label);
}

enum RestaurantAmenity {
  parking('Có chỗ đậu xe'),
  airCon('Có điều hòa'),
  kidFriendly('Phù hợp cho trẻ em');

  final String label;
  const RestaurantAmenity(this.label);
}

enum AccommodationType {
  hotel('Khách sạn'),
  homestay('Homestay'),
  resort('Resort'),
  apartment('Căn hộ'),
  guesthouse('Nhà nghỉ');

  final String label;
  const AccommodationType(this.label);
}

enum HotelAmenity {
  pool('Hồ bơi'),
  freeWifi('Wifi miễn phí'),
  breakfast('Có bữa sáng'),
  gym('Phòng gym');

  final String label;
  const HotelAmenity(this.label);
}

enum SortOption {
  none('Mặc định'),
  mostPopular('Phổ biến nhất'),
  highestRated('Đánh giá cao nhất'),
  cheapest('Giá rẻ nhất');

  final String label;
  const SortOption(this.label);
}

// ============================================================
// ============================================================

@freezed
class ActivityFilter with _$ActivityFilter {
  const factory ActivityFilter({
    @Default({}) Set<ActivityCategory> categories,

    @Default(ActivityPriceType.all) ActivityPriceType priceType,

    @Default(null) String? district,

    @Default(SortOption.none) SortOption sortOption,
  }) = _ActivityFilter;
}

@freezed
class RestaurantFilter with _$RestaurantFilter {
  const factory RestaurantFilter({
    @Default({}) Set<RestaurantCuisine> cuisines,

    @Default(RestaurantPriceLevel.all) RestaurantPriceLevel priceLevel,

    @Default({}) Set<RestaurantAmenity> amenities,

    @Default(SortOption.none) SortOption sortOption,
  }) = _RestaurantFilter;
}

@freezed
class HotelFilter with _$HotelFilter {
  const factory HotelFilter({
    @Default(0) double minPrice,

    @Default(0) double maxPrice,

    @Default({}) Set<AccommodationType> accommodationTypes,

    @Default({}) Set<HotelAmenity> amenities,

    @Default(SortOption.none) SortOption sortOption,
  }) = _HotelFilter;
}
