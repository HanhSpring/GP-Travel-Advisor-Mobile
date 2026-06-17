import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/features/city_detail/domain/entities/filter_enums.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/usecases/get_city_overview_usecase.dart';
import 'package:travel_advisor_mobile/features/city_detail/presentation/cubit/city_detail_state.dart';

class CityDetailCubit extends Cubit<CityDetailState> {
  final GetCityOverviewUseCase _getCityOverview;
  String currentCityName = "";

  CityDetailCubit(this._getCityOverview)
    : super(const CityDetailState.initial());

Future<void> loadCityDetail(String cityId, String cityName) async {
  emit(const CityDetailState.loading());
  try {
    currentCityName = cityName;
    final overview = await _getCityOverview(cityId);
    emit(
      CityDetailState.loaded(
        overview,
        0,
        filteredActivities: overview.activities,
        filteredRestaurants: overview.restaurants,
        filteredHotels: overview.hotels,
        itineraries: overview.itineraries,
      ),
    );
  } catch (e) {
    emit(CityDetailState.error(e.toString()));
  }
}

  void changeTab(int index) {
    state.mapOrNull(loaded: (s) => emit(s.copyWith(activeTab: index)));
  }

  // ============================================================
  // ============================================================

  void updateActivityFilter(ActivityFilter filter) {
    state.mapOrNull(
      loaded: (s) {
        var result = s.overview.activities.toList();

        if (filter.categories.isNotEmpty) {
          result = result.where((a) {
            return filter.categories.any((c) => c.name == a.category);
          }).toList();
        }

        if (filter.priceType != ActivityPriceType.all) {
          result = result
              .where((a) => a.priceType == filter.priceType.name)
              .toList();
        }

        if (filter.district != null && filter.district!.isNotEmpty) {
          result = result.where((a) => a.district == filter.district).toList();
        }

        switch (filter.sortOption) {
          case SortOption.mostPopular:
            result.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
            break;
          case SortOption.highestRated:
            result.sort((a, b) => b.rating.compareTo(a.rating));
            break;
          default:
            break;
        }

        emit(s.copyWith(activityFilter: filter, filteredActivities: result));
      },
    );
  }

  void resetActivityFilter() {
    updateActivityFilter(const ActivityFilter());
  }

  // ============================================================
  // ============================================================

  void updateRestaurantFilter(RestaurantFilter filter) {
    state.mapOrNull(
      loaded: (s) {
        var result = s.overview.restaurants.toList();

        if (filter.cuisines.isNotEmpty) {
          result = result.where((r) {
            return filter.cuisines.any((c) => c.name == r.cuisine);
          }).toList();
        }

        if (filter.priceLevel != RestaurantPriceLevel.all) {
          final priceLevelStr =
              filter.priceLevel == RestaurantPriceLevel.midRange
              ? 'mid_range'
              : filter.priceLevel.name;
          result = result.where((r) => r.priceLevel == priceLevelStr).toList();
        }

        if (filter.amenities.isNotEmpty) {
          result = result.where((r) {
            return filter.amenities.every(
              (amenity) => r.amenities.contains(amenity.name),
            );
          }).toList();
        }

        switch (filter.sortOption) {
          case SortOption.highestRated:
            result.sort((a, b) => b.rating.compareTo(a.rating));
            break;
          case SortOption.cheapest:
            result.sort(
              (a, b) => _priceLevelOrder(
                a.priceLevel,
              ).compareTo(_priceLevelOrder(b.priceLevel)),
            );
            break;
          default:
            break;
        }

        emit(s.copyWith(restaurantFilter: filter, filteredRestaurants: result));
      },
    );
  }

  void resetRestaurantFilter() {
    updateRestaurantFilter(const RestaurantFilter());
  }

  int _priceLevelOrder(String priceLevel) {
    switch (priceLevel) {
      case 'budget':
        return 0;
      case 'mid_range':
        return 1;
      case 'premium':
        return 2;
      default:
        return 1;
    }
  }

  // ============================================================
  // ============================================================

  void updateHotelFilter(HotelFilter filter) {
    state.mapOrNull(
      loaded: (s) {
        var result = s.overview.hotels.toList();

        if (filter.minPrice > 0 || filter.maxPrice > 0) {
          result = result.where((h) {
            final aboveMin = h.priceValue >= filter.minPrice;
            final belowMax =
                filter.maxPrice <= 0 || h.priceValue <= filter.maxPrice;
            return aboveMin && belowMax;
          }).toList();
        }

        if (filter.accommodationTypes.isNotEmpty) {
          result = result.where((h) {
            return filter.accommodationTypes.any(
              (t) => t.name == h.accommodationType,
            );
          }).toList();
        }

        if (filter.amenities.isNotEmpty) {
          result = result.where((h) {
            return filter.amenities.every(
              (amenity) => h.amenities.contains(amenity.name),
            );
          }).toList();
        }

        switch (filter.sortOption) {
          case SortOption.highestRated:
            result.sort((a, b) => b.rating.compareTo(a.rating));
            break;
          case SortOption.cheapest:
            result.sort((a, b) => a.priceValue.compareTo(b.priceValue));
            break;
          default:
            break;
        }

        emit(s.copyWith(hotelFilter: filter, filteredHotels: result));
      },
    );
  }

  void resetHotelFilter() {
    updateHotelFilter(const HotelFilter());
  }
}
