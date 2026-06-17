import 'itinerary_mock_data.dart';
import 'dart:async';
import 'dart:math' as math;
import 'itinerary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_summary.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/usecases/itinerary_usecases.dart';
import 'package:travel_advisor_mobile/core/config/app_config.dart';
import 'package:travel_advisor_mobile/features/itinerary/data/datasources/optimize_route_api.dart';

class ItineraryCubit extends Cubit<ItineraryState> {
  final GetItinerariesUseCase _getItineraries;
  final GetItinerarySummaryUseCase _getSummary;
  final DeleteItineraryUseCase _deleteItinerary;
  final GetItineraryDetailUseCase _getItineraryDetail;
  final UpdateItineraryActivitiesUseCase _updateActivities;
  final UpdateItineraryTitleUseCase _updateTitle;

  ItineraryStatus? _currentFilter;
  CompletedFilter _currentCompletedFilter = CompletedFilter.all;
  Timer? _searchDebounce;
  String _currentSearchQuery = '';
  int _loadGeneration = 0;

  ItineraryCubit({
    required GetItinerariesUseCase getItineraries,
    required GetItinerarySummaryUseCase getSummary,
    required DeleteItineraryUseCase deleteItinerary,
    required GetItineraryDetailUseCase getItineraryDetail,
    required UpdateItineraryActivitiesUseCase updateActivities,
    required UpdateItineraryTitleUseCase updateTitle,
  }) : _getItineraries = getItineraries,
       _getSummary = getSummary,
       _deleteItinerary = deleteItinerary,
       _getItineraryDetail = getItineraryDetail,
       _updateActivities = updateActivities,
       _updateTitle = updateTitle,
       super(const ItineraryInitial());

  static const bool kDemoMode = AppConfig.kUseMockData;

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  Future<void> loadData({bool keepCurrentList = false}) async {
    final generation = ++_loadGeneration;
    final previousSelected = state is ItineraryLoaded
        ? (state as ItineraryLoaded).selectedItinerary
        : null;
    final previousLoaded = state is ItineraryLoaded
        ? state as ItineraryLoaded
        : null;

    if (keepCurrentList && previousLoaded != null) {
      emit(
        previousLoaded.copyWith(
          searchQuery: _currentSearchQuery,
          isSearching: true,
        ),
      );
    } else {
      emit(const ItineraryLoading());
    }

    try {
      final hasSearch = _currentSearchQuery.isNotEmpty;
      final List<ItineraryEntity> itinerariesResult;
      final ItinerarySummary summaryResult;

      if (hasSearch && previousLoaded != null) {
        itinerariesResult = await _getItineraries(
          status: _currentFilter,
          query: _currentSearchQuery,
        );
        summaryResult = previousLoaded.summary;
      } else {
        final results = await Future.wait([
          _getItineraries(
            status: _currentFilter,
            query: hasSearch ? _currentSearchQuery : null,
          ),
          _getSummary(),
        ]);
        itinerariesResult = results[0] as List<ItineraryEntity>;
        summaryResult = results[1] as ItinerarySummary;
      }

      if (generation != _loadGeneration) return;

      var itineraries = itinerariesResult;

      if (_currentFilter == ItineraryStatus.completed) {
        if (_currentCompletedFilter == CompletedFilter.rated) {
          itineraries = itineraries.where((i) => i.rating != null).toList();
        } else if (_currentCompletedFilter == CompletedFilter.unrated) {
          itineraries = itineraries.where((i) => i.rating == null).toList();
        }
      }

      emit(
        ItineraryLoaded(
          itineraries: itineraries,
          summary: summaryResult,
          activeFilter: _currentFilter,
          activeCompletedFilter: _currentCompletedFilter,
          selectedItinerary: previousSelected,
          searchQuery: _currentSearchQuery,
          isSearching: false,
        ),
      );
    } catch (e) {
      if (kDemoMode) {
        final mockSummary = const ItinerarySummary(
          total: 5,
          draft: 2,
          upcoming: 1,
          completed: 1,
        );
        final mockItineraries = [
          ItineraryEntity(
            id: 'mock_saigon',
            title: 'Vi vu ở Sài Gòn',
            startDate: DateTime(2026, 5, 8),
            endDate: DateTime(2026, 5, 10),
            status: ItineraryStatus.upcoming,
            progress: 0.0,
            estimatedCost: 6800000,
            visitedLocations: 0,
            totalLocations: 27,
          ),
          ItineraryEntity(
            id: 'mock_completed',
            title: 'Khám phá Đà Nẵng 3 ngày 2 đêm',
            startDate: DateTime.now().subtract(const Duration(days: 10)),
            endDate: DateTime.now().subtract(const Duration(days: 5)),
            status: ItineraryStatus.completed,
            progress: 1.0,
            estimatedCost: 4500000,
            rating: null,
            visitedLocations: 8,
            totalLocations: 8,
          ),
          ItineraryEntity(
            id: 'mock_ongoing',
            title: 'Hè rực rỡ tại Phú Quốc',
            startDate: DateTime.now().subtract(const Duration(days: 1)),
            endDate: DateTime.now().add(const Duration(days: 3)),
            status: ItineraryStatus.ongoing,
            progress: 0.8,
            estimatedCost: 8500000,
            visitedLocations: 10,
            totalLocations: 12,
          ),
        ];
        emit(
          ItineraryLoaded(
            itineraries: mockItineraries,
            summary: mockSummary,
            activeFilter: _currentFilter,
            activeCompletedFilter: _currentCompletedFilter,
            selectedItinerary: (state is ItineraryLoaded)
                ? (state as ItineraryLoaded).selectedItinerary
                : null,
            searchQuery: _currentSearchQuery,
            isSearching: false,
          ),
        );
      } else {
        emit(ItineraryError(e.toString()));
      }
    }
  }

  Future<void> filterBy(ItineraryStatus? status) async {
    _currentFilter = status;
    _currentCompletedFilter = CompletedFilter.all;
    await loadData();
  }

  Future<void> filterByCompleted(CompletedFilter filter) async {
    _currentCompletedFilter = filter;
    await loadData();
  }

  void searchByTitle(String value) {
    final query = value.trim();
    if (query != _currentSearchQuery) {
      _loadGeneration++;
    }
    if (state is ItineraryLoaded) {
      final currentState = state as ItineraryLoaded;
      emit(currentState.copyWith(searchQuery: query));
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (query == _currentSearchQuery) return;
      _currentSearchQuery = query;
      loadData(keepCurrentList: true);
    });
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    if (_currentSearchQuery.isEmpty &&
        (state is! ItineraryLoaded ||
            (state as ItineraryLoaded).searchQuery.isEmpty)) {
      return;
    }
    _currentSearchQuery = '';
    if (state is ItineraryLoaded) {
      emit(
        (state as ItineraryLoaded).copyWith(searchQuery: '', isSearching: true),
      );
    }
    loadData(keepCurrentList: true);
  }

  Future<void> deleteItem(String id) async {
    try {
      await _deleteItinerary(id);
      await loadData();
    } catch (e) {
      emit(ItineraryError('Không thể xóa lịch trình: ${e.toString()}'));
    }
  }

  Future<void> updateItineraryTitle(String id, String title) async {
    if (state is! ItineraryLoaded) return;
    final previousState = state as ItineraryLoaded;

    if (previousState.selectedItinerary?.id == id) {
      final updatedItineraries = previousState.itineraries
          .map((e) => e.id == id ? e.copyWith(title: title) : e)
          .toList();
      emit(
        ItineraryLoaded(
          itineraries: updatedItineraries,
          summary: previousState.summary,
          activeFilter: previousState.activeFilter,
          activeCompletedFilter: previousState.activeCompletedFilter,
          selectedItinerary: previousState.selectedItinerary!.copyWith(
            title: title,
          ),
          searchQuery: previousState.searchQuery,
          isSearching: previousState.isSearching,
        ),
      );
    }

    try {
      if (!kDemoMode) {
        await _updateTitle(id, title);
      }
    } catch (e) {
      emit(
        ItineraryError('Không thể cập nhật tên lịch trình: ${e.toString()}'),
      );
      emit(previousState);
    }
  }

  Future<void> selectItinerary(String id) async {
    final currentState = state;
    if (currentState is ItineraryLoaded) {
      emit(currentState.copyWithSelected(null));
      try {
        final detail = await _getItineraryDetail(id);
        final materializedDetail = ItineraryMockData.materializeMockDays(detail);
        emit((state as ItineraryLoaded).copyWithSelected(materializedDetail));
      } catch (e) {
        if (kDemoMode) {
          final ItineraryDetailEntity mockDetail;
          if (id == 'mock_saigon') {
            mockDetail = ItineraryMockData.buildSaigonDetail(id);
          } else {
            mockDetail = ItineraryDetailEntity(
              id: id,
              title: 'Đà Nẵng - Thành phố đáng sống',
              destination: 'Đà Nẵng',
              startDate: DateTime.now(),
              endDate: DateTime.now().add(const Duration(days: 3)),
              status: 'ONGOING',
              durationDays: 3,
              activitiesCount: 5,
              visitedLocations: 2,
              totalLocations: 5,
              hotelsCount: 1,
              transportTurns: 3,
              estimatedBudget: 4500000,
              spentBudget: 1200000,
              currency: 'VNĐ',
              days: [],
              notes: [],
              visitedRestaurants: [],
              centerCoordinate: [16.0611, 108.2274],
            );
          }
          emit(
            (state as ItineraryLoaded).copyWithSelected(
              ItineraryMockData.materializeMockDays(mockDetail),
            ),
          );
        } else {
          emit(
            currentState.copyWith(
              detailError: 'Không thể tải chi tiết: ${e.toString()}',
            ),
          );
        }
      }
    }
  }

  Future<void> ensureItinerarySelected(String id) async {
    if (state is! ItineraryLoaded) {
      await loadData();
    }

    final currentState = state;
    if (currentState is ItineraryLoaded &&
        currentState.selectedItinerary?.id != id) {
      await selectItinerary(id);
    }
  }



  void toggleItineraryStatus(String id, bool isOngoing) {
    if (state is ItineraryLoaded) {
      final currentState = state as ItineraryLoaded;
      final updatedList = currentState.itineraries.map((itinerary) {
        if (itinerary.id == id) {
          return itinerary.copyWith(
            status: isOngoing ? ItineraryStatus.ongoing : ItineraryStatus.upcoming,
            trackingActive: isOngoing,
          );
        }
        return itinerary;
      }).toList();

      emit(
        ItineraryLoaded(
          itineraries: updatedList,
          summary: currentState.summary,
          activeFilter: currentState.activeFilter,
          activeCompletedFilter: currentState.activeCompletedFilter,
          selectedItinerary: currentState.selectedItinerary,
          searchQuery: currentState.searchQuery,
          isSearching: currentState.isSearching,
        ),
      );
    }
  }

  void updateActivityTimeSingle(
    String activityId, {
    String? startTime,
    String? endTime,
  }) {
    if (state is ItineraryLoaded) {
      final currentState = state as ItineraryLoaded;
      final itin = currentState.selectedItinerary;
      if (itin == null) return;

      final updatedDays = itin.days.map((day) {
        final updatedActivities = day.activities.map((activity) {
          if (activity.id == activityId) {
            return activity.copyWith(
              startTime: startTime ?? activity.startTime,
              endTime: endTime ?? activity.endTime,
            );
          }
          return activity;
        }).toList();
        return day.copyWith(activities: updatedActivities);
      }).toList();

      emit(currentState.copyWithSelected(itin.copyWith(days: updatedDays)));
    }
  }

  void updateActivityTimesWithShift({
    required String activityId,
    required int deltaMinutes,
    bool shiftStartTimeOnly =
        true,
  }) {
    if (state is ItineraryLoaded) {
      final currentState = state as ItineraryLoaded;
      final itin = currentState.selectedItinerary;
      if (itin == null) return;

      final updatedDays = itin.days.map((day) {
        final hasActivity = day.activities.any((a) => a.id == activityId);
        if (!hasActivity) return day;

        bool foundActivity = false;
        final updatedActivities = day.activities.map((activity) {
          if (activity.id == activityId) {
            foundActivity = true;
            if (shiftStartTimeOnly) {
              return activity.copyWith(
                startTime: _shiftTimeStr(activity.startTime, deltaMinutes),
                endTime: _shiftTimeStr(activity.endTime, deltaMinutes),
              );
            } else {
              return activity.copyWith(
                endTime: _shiftTimeStr(activity.endTime, deltaMinutes),
              );
            }
          }
          if (foundActivity) {
            return activity.copyWith(
              startTime: _shiftTimeStr(activity.startTime, deltaMinutes),
              endTime: _shiftTimeStr(activity.endTime, deltaMinutes),
            );
          }
          return activity;
        }).toList();

        return day.copyWith(activities: updatedActivities);
      }).toList();

      emit(currentState.copyWithSelected(itin.copyWith(days: updatedDays)));
    }
  }

  String _shiftTimeStr(String timeStr, int deltaMinutes) {
    try {
      final parts = timeStr.split(':');
      final currentMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      var targetMin = currentMin + deltaMinutes;
      if (targetMin < 0) targetMin = 0;
      if (targetMin >= 24 * 60) targetMin = (24 * 60) - 1;

      final hour = targetMin ~/ 60;
      final minute = targetMin % 60;
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timeStr;
    }
  }

  void discardChanges(ItineraryDetailEntity snapshot) {
    if (state is ItineraryLoaded) {
      emit((state as ItineraryLoaded).copyWithSelected(snapshot));
    }
  }

  Future<void> confirmUpdateItinerary(String id) async {
    if (state is! ItineraryLoaded) return;
    final currentState = state as ItineraryLoaded;
    final itin = currentState.selectedItinerary;
    if (itin == null) return;

    emit(currentState.copyWithSelected(itin));

    try {
      if (!kDemoMode) {
        await _updateActivities(id, itin.days);
      }
    } catch (e) {
      emit(ItineraryError('Không thể cập nhật lịch trình: ${e.toString()}'));
      emit(currentState);
    }
  }

  void rateActivity(String activityId, double rating) {
    if (state is ItineraryLoaded) {
      final currentState = state as ItineraryLoaded;
      final itin = currentState.selectedItinerary;
      if (itin == null) return;

      final updatedDays = itin.days.map((day) {
        final updatedActivities = day.activities.map((activity) {
          if (activity.id == activityId) {
            return activity.copyWith(rating: rating);
          }
          return activity;
        }).toList();
        return day.copyWith(activities: updatedActivities);
      }).toList();

      emit(currentState.copyWithSelected(itin.copyWith(days: updatedDays)));
    }
  }

  Future<void> replaceActivity(
    String oldActivityId,
    String newPlaceId,
    String newPlaceName, {
    double? newLat,
    double? newLng,
    String? newImageUrl,
    double? newRating,
    int? newReviewCount,
    String? newAddress,
    String? newCategory,
  }) async {
    if (state is! ItineraryLoaded) return;
    final currentState = state as ItineraryLoaded;
    final itin = currentState.selectedItinerary;
    if (itin == null) return;

    emit(const ItineraryLoading());

    var updatedDays = itin.days.map((day) {
      if (!day.activities.any((a) => a.id == oldActivityId)) return day;
      final updatedActivities = day.activities.map((a) {
        if (a.id != oldActivityId) return a;
        return a.copyWith(
          id: newPlaceId,
          title: newPlaceName,
          locationName: newPlaceName,
          latitude: newLat ?? a.latitude,
          longitude: newLng ?? a.longitude,
          imageUrl: newImageUrl ?? a.imageUrl,
          rating: newRating ?? a.rating,
          reviewCount: newReviewCount ?? a.reviewCount,
          address: newAddress ?? a.address,
          category: newCategory ?? a.category,
        );
      }).toList();
      return day.copyWith(activities: updatedActivities);
    }).toList();

    int? dayNum;
    ItineraryDayEntity? originalDay;
    for (final d in itin.days) {
      if (d.activities.any((a) => a.id == oldActivityId)) {
        dayNum = d.dayNumber;
        originalDay = d;
        break;
      }
    }

    List<ItineraryDayEntity>? optimizedDays;
    if (dayNum != null) {
      optimizedDays = await _optimizeSpecificDay(updatedDays, dayNum);
    }

    List<ItineraryDayEntity>? suggestion;
    int? suggestionDayNum;
    if (originalDay != null && optimizedDays != null && dayNum != null) {
      final currentDay = updatedDays.firstWhere((d) => d.dayNumber == dayNum);
      final optimizedDay = optimizedDays.firstWhere(
        (d) => d.dayNumber == dayNum,
      );
      final distBefore = _totalRouteDistanceKm(currentDay.activities);
      final distAfter = _totalRouteDistanceKm(optimizedDay.activities);

      if (distBefore > 0.5 && distAfter < distBefore * 0.85) {
        suggestion = optimizedDays;
        suggestionDayNum = dayNum;
      }
    }

    final finalDays = suggestion == null
        ? (optimizedDays ?? updatedDays)
        : updatedDays;
    final newState = ItineraryLoaded(
      itineraries: currentState.itineraries,
      summary: currentState.summary,
      activeFilter: currentState.activeFilter,
      activeCompletedFilter: currentState.activeCompletedFilter,
      selectedItinerary: itin.copyWith(days: finalDays),
      searchQuery: currentState.searchQuery,
      isSearching: currentState.isSearching,
      suggestedDays: suggestion,
      suggestedDayNumber: suggestionDayNum,
    );
    emit(newState);
  }

  Future<void> addActivityToDay(
    int dayNumber,
    String placeId,
    String placeName, {
    double? lat,
    double? lng,
    String? imageUrl,
    String? address,
    String? category,
  }) async {
    if (state is! ItineraryLoaded) return;
    final currentState = state as ItineraryLoaded;
    final itin = currentState.selectedItinerary;
    if (itin == null) return;

    emit(const ItineraryLoading());

    var updatedDays = itin.days.map((day) {
      if (day.dayNumber != dayNumber) return day;

      String startTime = '08:00';
      if (day.activities.isNotEmpty) startTime = day.activities.last.endTime;
      final endTime = _shiftTimeStr(startTime, 60);

      final newActivity = ItineraryActivityEntity(
        id: placeId,
        title: placeName,
        locationName: placeName,
        address: address ?? '',
        imageUrl: imageUrl ?? 'https://placehold.co/1080x720?text=New+Place',
        startTime: startTime,
        endTime: endTime,
        latitude: lat,
        longitude: lng,
        category: category,
      );

      return day.copyWith(activities: [...day.activities, newActivity]);
    }).toList();

    updatedDays = await _optimizeSpecificDay(updatedDays, dayNumber);

    emit(currentState.copyWithSelected(itin.copyWith(days: updatedDays)));
  }

  double _totalRouteDistanceKm(List<ItineraryActivityEntity> activities) {
    double total = 0;
    for (int i = 0; i < activities.length - 1; i++) {
      final a = activities[i];
      final b = activities[i + 1];
      if (a.latitude != null &&
          a.longitude != null &&
          b.latitude != null &&
          b.longitude != null) {
        total += _haversineKm(
          a.latitude!,
          a.longitude!,
          b.latitude!,
          b.longitude!,
        );
      }
    }
    return total;
  }

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final sinDLat = math.sin(dLat / 2);
    final sinDLng = math.sin(dLng / 2);
    final a =
        sinDLat * sinDLat +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            sinDLng *
            sinDLng;
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  void applySuggestedReorder() {
    if (state is! ItineraryLoaded) return;
    final s = state as ItineraryLoaded;
    if (s.suggestedDays == null || s.selectedItinerary == null) return;
    emit(
      ItineraryLoaded(
        itineraries: s.itineraries,
        summary: s.summary,
        activeFilter: s.activeFilter,
        activeCompletedFilter: s.activeCompletedFilter,
        selectedItinerary: s.selectedItinerary!.copyWith(
          days: s.suggestedDays!,
        ),
        searchQuery: s.searchQuery,
        isSearching: s.isSearching,
      ),
    );
  }

  void dismissReorderSuggestion() {
    if (state is! ItineraryLoaded) return;
    final s = state as ItineraryLoaded;
    emit(s.copyWith(clearSuggestion: true));
  }

  Future<void> deleteActivity(String activityId) async {
    if (state is ItineraryLoaded) {
      final currentState = state as ItineraryLoaded;
      final itin = currentState.selectedItinerary;
      if (itin == null) return;

      emit(const ItineraryLoading());

      int? updatedDayNum;
      var updatedDays = itin.days.map((day) {
        final hasActivity = day.activities.any((a) => a.id == activityId);
        if (!hasActivity) return day;

        updatedDayNum = day.dayNumber;
        final updatedActivities = day.activities
            .where((a) => a.id != activityId)
            .toList();
        return day.copyWith(activities: updatedActivities);
      }).toList();

      if (updatedDayNum != null) {
        updatedDays = await _optimizeSpecificDay(updatedDays, updatedDayNum!);
      }

      emit(currentState.copyWithSelected(itin.copyWith(days: updatedDays)));
    }
  }

  Future<List<ItineraryDayEntity>> _optimizeSpecificDay(
    List<ItineraryDayEntity> days,
    int dayNumber,
  ) async {
    final List<ItineraryDayEntity> newDays = [];
    for (final d in days) {
      if (d.dayNumber == dayNumber) {
        final optimized = await OptimizeRouteApi.optimizeDay(d.activities);
        newDays.add(d.copyWith(activities: optimized));
      } else {
        newDays.add(d);
      }
    }
    return newDays;
  }
}

extension on ItineraryLoaded {
  ItineraryLoaded copyWithSelected(dynamic selected) {
    return ItineraryLoaded(
      itineraries: itineraries,
      summary: summary,
      activeFilter: activeFilter,
      activeCompletedFilter: activeCompletedFilter,
      selectedItinerary: selected,
      detailError: null,
      searchQuery: searchQuery,
      isSearching: isSearching,
      suggestedDays: null,
      suggestedDayNumber: null,
    );
  }

  ItineraryLoaded copyWith({
    List<ItineraryEntity>? itineraries,
    ItinerarySummary? summary,
    ItineraryStatus? activeFilter,
    CompletedFilter? activeCompletedFilter,
    ItineraryDetailEntity? selectedItinerary,
    String? detailError,
    String? searchQuery,
    bool? isSearching,
    List<ItineraryDayEntity>? suggestedDays,
    int? suggestedDayNumber,
    bool clearSuggestion = false,
  }) {
    return ItineraryLoaded(
      itineraries: itineraries ?? this.itineraries,
      summary: summary ?? this.summary,
      activeFilter: activeFilter ?? this.activeFilter,
      activeCompletedFilter:
          activeCompletedFilter ?? this.activeCompletedFilter,
      selectedItinerary: selectedItinerary ?? this.selectedItinerary,
      detailError: detailError,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      suggestedDays: clearSuggestion
          ? null
          : (suggestedDays ?? this.suggestedDays),
      suggestedDayNumber: clearSuggestion
          ? null
          : (suggestedDayNumber ?? this.suggestedDayNumber),
    );
  }
}
