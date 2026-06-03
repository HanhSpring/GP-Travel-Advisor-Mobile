import 'package:travel_advisor_mobile/core/network/dio_client.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';

class OptimizeRouteApi {
  static Future<List<ItineraryActivityEntity>> optimizeDay(List<ItineraryActivityEntity> activities) async {
    if (activities.length <= 2) return activities;
    
    try {
      final client = sl<DioClient>();
      
      final payload = {
        'activities': activities.map((a) => {
          'id': a.id,
          'title': a.title,
          'startTime': a.startTime,
          'endTime': a.endTime,
          'latitude': a.latitude,
          'longitude': a.longitude,
          'locationName': a.locationName,
          'address': a.address,
          'imageUrl': a.imageUrl,
          'category': a.category,
        }).toList(),
      };

      final response = await client.dio.post('/itinerary/optimize-day', data: payload);
      
      final data = response.data['optimized'] as List;
      if (data.isEmpty) return activities;

      return data.map((json) {
        return ItineraryActivityEntity(
          id: json['id'] ?? '',
          title: json['title'] ?? '',
          startTime: json['startTime'] ?? '',
          endTime: json['endTime'] ?? '',
          latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
          longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
          locationName: json['locationName'] ?? '',
          address: json['address'] ?? '',
          imageUrl: json['imageUrl'] ?? '',
          category: json['category'],
        );
      }).toList();
    } catch (e) {
      print('Error optimizing route: $e');
      return activities;
    }
  }
}
