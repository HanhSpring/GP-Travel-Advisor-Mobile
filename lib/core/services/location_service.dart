import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import 'package:travel_advisor_mobile/features/home/domain/entities/user_location.dart';

class LocationFailure implements Exception {
  final String message;
  final bool permissionDenied;
  const LocationFailure(this.message, {this.permissionDenied = false});

  @override
  String toString() => message;
}

///
class LocationService {
  final Dio _dio;

  LocationService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  static const _nominatimUrl = 'https://nominatim.openstreetmap.org/reverse';

  Future<UserLocation> getCurrentLocation() async {
    final position = await _resolvePosition();
    final geo = await _reverseGeocode(position.latitude, position.longitude);
    return UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      ward: geo.$1,
      province: geo.$2,
    );
  }

  ///
  Stream<Position> positionStream({int distanceFilter = 100}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: distanceFilter,
      ),
    );
  }

  Future<UserLocation> reverseGeocode(double lat, double lng) async {
    final geo = await _reverseGeocode(lat, lng);
    return UserLocation(
      latitude: lat,
      longitude: lng,
      ward: geo.$1,
      province: geo.$2,
    );
  }

  Future<Position> _resolvePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationFailure(
        'Dịch vụ vị trí đang tắt. Vui lòng bật GPS để xác định vị trí.',
        permissionDenied: true,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        'Bạn đã từ chối quyền truy cập vị trí.',
        permissionDenied: true,
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        'Quyền vị trí bị từ chối vĩnh viễn. Hãy cấp quyền trong Cài đặt.',
        permissionDenied: true,
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<(String?, String?)> _reverseGeocode(double lat, double lng) async {
    try {
      final res = await _dio.get(
        _nominatimUrl,
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'jsonv2',
          'accept-language': 'vi',
          'addressdetails': 1,
          'zoom': 18,
        },
        options: Options(
          headers: {'User-Agent': 'GPTravelAdvisor/1.0 (thesis app)'},
        ),
      );

      final data = res.data;
      final address = (data is Map ? data['address'] : null) as Map?;
      if (address == null) return (null, null);

      String? pick(List<String> keys) {
        for (final k in keys) {
          final v = address[k];
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
        return null;
      }

      final ward = pick([
        'quarter',
        'ward',
        'suburb',
        'neighbourhood',
        'village',
        'hamlet',
        'town',
      ]);
      final province = pick(['state', 'city', 'region', 'county']);

      return (ward, province);
    } on DioException {
      return (null, null);
    }
  }
}
