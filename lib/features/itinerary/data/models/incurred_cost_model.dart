import 'package:travel_advisor_mobile/features/itinerary/domain/entities/incurred_cost_entity.dart';

class IncurredCostModel {
  final String id;
  final String? placeId;
  final String? placeName;
  final String note;
  final double amount;
  final List<String> chargedTo;
  final String createdBy;
  final DateTime createdAt;

  const IncurredCostModel({
    required this.id,
    this.placeId,
    this.placeName,
    required this.note,
    required this.amount,
    this.chargedTo = const [],
    required this.createdBy,
    required this.createdAt,
  });

  factory IncurredCostModel.fromJson(Map<String, dynamic> json) {
    return IncurredCostModel(
      id: (json['id'] ?? '').toString(),
      placeId: json['place_id']?.toString() ?? json['placeId']?.toString(),
      placeName: json['place_name']?.toString() ?? json['placeName']?.toString(),
      note: (json['note'] ?? '').toString(),
      amount: (json['amount'] ?? 0).toDouble(),
      chargedTo:
          ((json['charged_to'] ?? json['chargedTo']) as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdBy:
          (json['created_by'] ?? json['createdBy'] ?? '').toString(),
      createdAt:
          DateTime.tryParse(
            (json['created_at'] ?? json['createdAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }

  IncurredCostEntity toEntity() => IncurredCostEntity(
    id: id,
    placeId: placeId,
    placeName: placeName,
    note: note,
    amount: amount,
    chargedTo: chargedTo,
    createdBy: createdBy,
    createdAt: createdAt,
  );
}

class EligiblePlaceModel {
  final String id;
  final String name;
  final String address;

  const EligiblePlaceModel({
    required this.id,
    required this.name,
    this.address = '',
  });

  factory EligiblePlaceModel.fromJson(Map<String, dynamic> json) {
    return EligiblePlaceModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
    );
  }

  EligiblePlaceEntity toEntity() =>
      EligiblePlaceEntity(id: id, name: name, address: address);
}

class MemberCostTotalModel {
  final String userId;
  final String fullName;
  final bool isOwner;
  final double total;

  const MemberCostTotalModel({
    required this.userId,
    required this.fullName,
    required this.isOwner,
    required this.total,
  });

  factory MemberCostTotalModel.fromJson(Map<String, dynamic> json) {
    return MemberCostTotalModel(
      userId: (json['userId'] ?? json['user_id'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['full_name'] ?? '').toString(),
      isOwner: json['isOwner'] == true || json['is_owner'] == true,
      total: (json['total'] ?? 0).toDouble(),
    );
  }

  MemberCostTotalEntity toEntity() => MemberCostTotalEntity(
    userId: userId,
    fullName: fullName,
    isOwner: isOwner,
    total: total,
  );
}

class CostBreakdownModel {
  final List<MemberCostTotalModel> memberTotals;
  final double totalCost;
  final double basePlanCost;
  final double incurredTotal;

  const CostBreakdownModel({
    this.memberTotals = const [],
    this.totalCost = 0,
    this.basePlanCost = 0,
    this.incurredTotal = 0,
  });

  factory CostBreakdownModel.fromJson(Map<String, dynamic> json) {
    return CostBreakdownModel(
      memberTotals:
          ((json['memberTotals'] ?? json['member_totals']) as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(MemberCostTotalModel.fromJson)
              .toList() ??
          const [],
      totalCost: (json['totalCost'] ?? json['total_cost'] ?? 0).toDouble(),
      basePlanCost:
          (json['basePlanCost'] ?? json['base_plan_cost'] ?? 0).toDouble(),
      incurredTotal:
          (json['incurredTotal'] ?? json['incurred_total'] ?? 0).toDouble(),
    );
  }

  CostBreakdownEntity toEntity() => CostBreakdownEntity(
    memberTotals: memberTotals.map((e) => e.toEntity()).toList(),
    totalCost: totalCost,
    basePlanCost: basePlanCost,
    incurredTotal: incurredTotal,
  );
}
