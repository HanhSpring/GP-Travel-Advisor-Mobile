import 'package:equatable/equatable.dart';

import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_summary.dart';

///
abstract class ItineraryState extends Equatable {
  const ItineraryState();

  @override
  List<Object?> get props => [];
}

enum CompletedFilter { all, rated, unrated }

class ItineraryInitial extends ItineraryState {
  const ItineraryInitial();
}

class ItineraryLoading extends ItineraryState {
  const ItineraryLoading();
}

class ItineraryLoaded extends ItineraryState {
  final List<ItineraryEntity> itineraries;

  final ItinerarySummary summary;

  final ItineraryStatus? activeFilter;

  final ItineraryDetailEntity? selectedItinerary;

  final CompletedFilter activeCompletedFilter;

  final String? detailError;

  /// Current search text shown in the list screen.
  /// This is separate from [activeFilter] so search and status tabs can merge safely.
  final String searchQuery;

  /// True while a debounced search request is in flight.
  /// The UI keeps the current list visible and only shows a small search spinner.
  final bool isSearching;

  final List<ItineraryDayEntity>? suggestedDays;
  final int? suggestedDayNumber;

  const ItineraryLoaded({
    required this.itineraries,
    required this.summary,
    this.activeFilter,
    this.selectedItinerary,
    this.activeCompletedFilter = CompletedFilter.all,
    this.detailError,
    this.searchQuery = '',
    this.isSearching = false,
    this.suggestedDays,
    this.suggestedDayNumber,
  });

  @override
  List<Object?> get props => [
    itineraries,
    summary,
    activeFilter,
    selectedItinerary,
    activeCompletedFilter,
    detailError,
    searchQuery,
    isSearching,
    suggestedDays,
    suggestedDayNumber,
  ];
}

class ItineraryError extends ItineraryState {
  final String message;
  const ItineraryError(this.message);

  @override
  List<Object?> get props => [message];
}
