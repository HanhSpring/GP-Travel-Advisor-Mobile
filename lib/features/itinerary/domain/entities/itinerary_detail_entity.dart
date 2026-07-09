import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';

class VisitedDish {
  final String name;
  final double price;
  final int quantity;

  const VisitedDish({
    required this.name,
    required this.price,
    this.quantity = 1,
  });
}

class VisitedRestaurant {
  final String name;
  final List<VisitedDish> dishes;
  final String imageUrl;

  const VisitedRestaurant({
    required this.name,
    required this.dishes,
    required this.imageUrl,
  });
}

/// A "quality layer" banner note for one day of the itinerary — layer 2
/// (lunch time shifted), layer 3 (restaurant dropped) or layer 4 (greedy
/// fallback used). Layer 1 (perfect solve) never gets a note.
class DayQualityNoteEntity {
  final int day;
  final String date;
  final int layer;
  final String message;

  const DayQualityNoteEntity({
    required this.day,
    required this.date,
    required this.layer,
    required this.message,
  });
}

class ItineraryMemberEntity {
  final String id;
  final String fullName;
  final String avatarUrl;
  final bool isOwner;

  const ItineraryMemberEntity({
    required this.id,
    required this.fullName,
    this.avatarUrl = '',
    this.isOwner = false,
  });
}

class ItineraryDetailEntity {
  final String id;
  final String title;
  final String destination;
  final String? tripIntent;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final bool isPublic;
  final bool isFavorite;
  final String? creatorId;
  final bool isOwner;
  final List<ItineraryMemberEntity> members;
  final int durationDays;
  final int activitiesCount;
  final int totalLocations;
  final int visitedLocations;
  final int hotelsCount;
  final int transportTurns;

  final double estimatedBudget;
  // User's original input budget ceiling (trip_budget_total), 0 when unknown
  // (e.g. itineraries created before this field existed). Kept separate from
  // estimatedBudget so the UI can show both and warn when the calculated
  // cost exceeds 90% of it.
  final double userBudget;
  final int participantCount;
  final double spentBudget;
  final double placeCost;
  final double hotelCost;
  final double transportCost;
  final double rideHailingTransportCost;
  final String currency;

  final List<ItineraryDayEntity> days;
  final List<String> notes;
  final List<VisitedRestaurant> visitedRestaurants;
  final List<DayQualityNoteEntity> dayQuality;

  final List<double> centerCoordinate;
  final bool trackingActive;

  final String? dailyStartTime;
  final String? dailyEndTime;

  const ItineraryDetailEntity({
    required this.id,
    required this.title,
    required this.destination,
    this.tripIntent,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.isPublic = true,
    this.isFavorite = false,
    this.creatorId,
    this.isOwner = true,
    this.members = const [],
    required this.durationDays,
    required this.activitiesCount,
    this.totalLocations = 0,
    this.visitedLocations = 0,
    required this.hotelsCount,
    required this.transportTurns,
    required this.estimatedBudget,
    this.userBudget = 0,
    this.participantCount = 1,
    required this.spentBudget,
    this.placeCost = 0,
    this.hotelCost = 0,
    this.transportCost = 0,
    this.rideHailingTransportCost = 0,
    this.currency = 'VNĐ',
    this.days = const [],
    this.notes = const [],
    this.visitedRestaurants = const [],
    this.dayQuality = const [],
    this.centerCoordinate = const [],
    this.trackingActive = false,
    this.dailyStartTime,
    this.dailyEndTime,
  });

  ItineraryDetailEntity copyWith({
    String? id,
    String? title,
    String? destination,
    String? tripIntent,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    bool? isPublic,
    bool? isFavorite,
    String? creatorId,
    bool? isOwner,
    List<ItineraryMemberEntity>? members,
    int? durationDays,
    int? activitiesCount,
    int? totalLocations,
    int? visitedLocations,
    int? hotelsCount,
    int? transportTurns,
    double? estimatedBudget,
    double? userBudget,
    int? participantCount,
    double? spentBudget,
    double? placeCost,
    double? hotelCost,
    double? transportCost,
    double? rideHailingTransportCost,
    String? currency,
    List<ItineraryDayEntity>? days,
    List<String>? notes,
    List<VisitedRestaurant>? visitedRestaurants,
    List<DayQualityNoteEntity>? dayQuality,
    List<double>? centerCoordinate,
    bool? trackingActive,
    String? dailyStartTime,
    String? dailyEndTime,
  }) {
    return ItineraryDetailEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      tripIntent: tripIntent ?? this.tripIntent,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      isPublic: isPublic ?? this.isPublic,
      isFavorite: isFavorite ?? this.isFavorite,
      creatorId: creatorId ?? this.creatorId,
      isOwner: isOwner ?? this.isOwner,
      members: members ?? this.members,
      durationDays: durationDays ?? this.durationDays,
      activitiesCount: activitiesCount ?? this.activitiesCount,
      totalLocations: totalLocations ?? this.totalLocations,
      visitedLocations: visitedLocations ?? this.visitedLocations,
      hotelsCount: hotelsCount ?? this.hotelsCount,
      transportTurns: transportTurns ?? this.transportTurns,
      estimatedBudget: estimatedBudget ?? this.estimatedBudget,
      userBudget: userBudget ?? this.userBudget,
      participantCount: participantCount ?? this.participantCount,
      spentBudget: spentBudget ?? this.spentBudget,
      placeCost: placeCost ?? this.placeCost,
      hotelCost: hotelCost ?? this.hotelCost,
      transportCost: transportCost ?? this.transportCost,
      rideHailingTransportCost:
          rideHailingTransportCost ?? this.rideHailingTransportCost,
      currency: currency ?? this.currency,
      days: days ?? this.days,
      notes: notes ?? this.notes,
      visitedRestaurants: visitedRestaurants ?? this.visitedRestaurants,
      dayQuality: dayQuality ?? this.dayQuality,
      centerCoordinate: centerCoordinate ?? this.centerCoordinate,
      trackingActive: trackingActive ?? this.trackingActive,
      dailyStartTime: dailyStartTime ?? this.dailyStartTime,
      dailyEndTime: dailyEndTime ?? this.dailyEndTime,
    );
  }
}
