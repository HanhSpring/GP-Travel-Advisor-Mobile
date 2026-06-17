import 'package:dio/dio.dart';
import 'package:travel_advisor_mobile/core/network/dio_client.dart';

import '../models/tracking_models.dart';
import '../../tracking_config.dart';

class TrackingRemoteDataSource {
  final DioClient _client;
  TrackingRemoteDataSource(this._client);

  Dio get _dio => _client.dio;
  static const _base = '/itinerary/tracking';

  /// `yyyy-MM-dd` cho field `date`/`track_date`.
  static String fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<TrackingStartResult> start({
    required String itineraryId,
    required String touristId,
    required DateTime date,
    int radiusM = TrackingConfig.radiusM,
  }) async {
    final res = await _dio.post('$_base/start', data: {
      'itineraryId': itineraryId,
      'touristId': touristId,
      'date': fmtDate(date),
      'radiusM': radiusM,
    });
    return TrackingStartResult.fromAny(res.data);
  }

  Future<List<TrackingGeofence>> geofences({
    required String itineraryId,
    required DateTime date,
    int radiusM = TrackingConfig.radiusM,
  }) async {
    final res = await _dio.get('$_base/geofences', queryParameters: {
      'itineraryId': itineraryId,
      'date': fmtDate(date),
      'radiusM': radiusM,
    });
    return TrackingStartResult.fromAny(res.data).geofences;
  }

  Future<GeofenceEventResult> sendEvent({
    required String itineraryDetailId,
    required String touristId,
    required String eventType, // ENTER | DWELL | EXIT
    DateTime? occurredAt,
    int? dwellSeconds,
  }) async {
    final res = await _dio.post('$_base/event', data: {
      'itineraryDetailId': itineraryDetailId,
      'touristId': touristId,
      'eventType': eventType,
      'occurredAt': (occurredAt ?? DateTime.now()).toIso8601String(),
      'dwellSeconds': ?dwellSeconds,
    });
    return GeofenceEventResult.fromAny(res.data);
  }

  Future<GeofenceEventResult> checkIn({
    required String itineraryDetailId,
    required String touristId,
  }) async {
    final res = await _dio.post('$_base/check-in', data: {
      'itineraryDetailId': itineraryDetailId,
      'touristId': touristId,
    });
    return GeofenceEventResult.fromAny(res.data);
  }

  Future<TrackingStatusResult> status({
    required String itineraryId,
    required DateTime date,
  }) async {
    final res = await _dio.get('$_base/status', queryParameters: {
      'itineraryId': itineraryId,
      'date': fmtDate(date),
    });
    return TrackingStatusResult.fromAny(res.data);
  }

  Future<EndDayResult> endDay({
    required String itineraryId,
    required DateTime date,
    bool markPendingAsSkipped = true,
  }) async {
    final res = await _dio.post('$_base/end-day', data: {
      'itineraryId': itineraryId,
      'date': fmtDate(date),
      'markPendingAsSkipped': markPendingAsSkipped,
    });
    return EndDayResult.fromAny(res.data);
  }
}
