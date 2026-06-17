import 'package:equatable/equatable.dart';

class UserLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String? ward;
  final String? province;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.ward,
    this.province,
  });

  String get displayText {
    final parts = [ward, province]
        .where((e) => e != null && e.trim().isNotEmpty)
        .map((e) => e!.trim())
        .toList();
    if (parts.isEmpty) return 'KHÔNG XÁC ĐỊNH VỊ TRÍ';
    return parts.join(', ').toUpperCase();
  }

  @override
  List<Object?> get props => [latitude, longitude, ward, province];
}
