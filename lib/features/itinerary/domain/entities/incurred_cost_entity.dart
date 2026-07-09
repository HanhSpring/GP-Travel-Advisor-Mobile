/// Một khoản chi phí phát sinh người dùng ghi nhận trong chuyến đi (mục 1.6),
/// gắn hoặc không gắn với 1 địa điểm cụ thể trong lịch trình.
class IncurredCostEntity {
  final String id;
  final String? placeId;
  final String? placeName;
  final String note;
  final double amount;
  // user_id phải gánh khoản này. Rỗng = chia đều cho cả nhóm.
  final List<String> chargedTo;
  final String createdBy;
  final DateTime createdAt;

  const IncurredCostEntity({
    required this.id,
    this.placeId,
    this.placeName,
    required this.note,
    required this.amount,
    this.chargedTo = const [],
    required this.createdBy,
    required this.createdAt,
  });
}

/// Địa điểm đã "đi" (visited), đủ điều kiện chọn trong combobox mục 1.6.
class EligiblePlaceEntity {
  final String id;
  final String name;
  final String address;

  const EligiblePlaceEntity({
    required this.id,
    required this.name,
    this.address = '',
  });
}

/// "Mỗi người phải trả tổng bao nhiêu" (mục 1.7) — không có khái niệm nợ/ứng
/// tiền trước, chỉ là tổng chi phí mỗi người gánh (kế hoạch gốc + phát sinh).
class MemberCostTotalEntity {
  final String userId;
  final String fullName;
  final bool isOwner;
  final double total;

  const MemberCostTotalEntity({
    required this.userId,
    required this.fullName,
    required this.isOwner,
    required this.total,
  });
}

class CostBreakdownEntity {
  final List<MemberCostTotalEntity> memberTotals;
  final double totalCost;
  final double basePlanCost;
  final double incurredTotal;

  const CostBreakdownEntity({
    this.memberTotals = const [],
    this.totalCost = 0,
    this.basePlanCost = 0,
    this.incurredTotal = 0,
  });
}
