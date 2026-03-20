import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/itinerary_detail_entity.dart';
import 'itinerary_day_model.dart';

part 'itinerary_detail_model.g.dart';

@JsonSerializable()
class ItineraryDetailModel {
  final String id;
  final String title;
  final String destination;
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  @JsonKey(name: 'end_date')
  final DateTime endDate;
  final String status;
  @JsonKey(name: 'is_public')
  final bool isPublic;
  @JsonKey(name: 'duration_days')
  final int durationDays;
  @JsonKey(name: 'activities_count')
  final int activitiesCount;
  @JsonKey(name: 'hotels_count')
  final int hotelsCount;
  @JsonKey(name: 'transport_turns')
  final int transportTurns;
  @JsonKey(name: 'estimated_budget')
  final double estimatedBudget;
  @JsonKey(name: 'spent_budget')
  final double spentBudget;
  final String currency;
  final List<ItineraryDayModel> days;
  final List<String> notes;
  @JsonKey(name: 'center_coordinate')
  final List<double> centerCoordinate;

  const ItineraryDetailModel({
    required this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.isPublic = true,
    required this.durationDays,
    required this.activitiesCount,
    required this.hotelsCount,
    required this.transportTurns,
    required this.estimatedBudget,
    required this.spentBudget,
    this.currency = 'VNĐ',
    this.days = const [],
    this.notes = const [],
    this.centerCoordinate = const [],
  });

  factory ItineraryDetailModel.fromJson(Map<String, dynamic> json) =>
      _$ItineraryDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$ItineraryDetailModelToJson(this);

  ItineraryDetailEntity toEntity() {
    return ItineraryDetailEntity(
      id: id,
      title: title,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      status: status,
      isPublic: isPublic,
      durationDays: durationDays,
      activitiesCount: activitiesCount,
      hotelsCount: hotelsCount,
      transportTurns: transportTurns,
      estimatedBudget: estimatedBudget,
      spentBudget: spentBudget,
      currency: currency,
      days: days.map((e) => e.toEntity()).toList(),
      notes: notes,
      centerCoordinate: centerCoordinate,
    );
  }
}
