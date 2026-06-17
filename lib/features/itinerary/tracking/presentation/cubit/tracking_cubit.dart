import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

import 'package:travel_advisor_mobile/core/network/api_config.dart';
import 'package:travel_advisor_mobile/core/utils/auth_utils.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';

import '../../data/datasources/tracking_remote_datasource.dart';
import '../../data/models/tracking_models.dart';
import '../../domain/usecases/tracking_usecases.dart';
import '../../services/geofence_tracking_service.dart';
import '../../services/tracking_alarm_service.dart';
import '../../services/tracking_context.dart';
import '../../tracking_config.dart';
import 'tracking_state.dart';

class _FoodSpot {
  final String id;
  final String name;
  final double lat;
  final double lng;

  const _FoodSpot({required this.id, required this.name, required this.lat, required this.lng});

  Map<String, dynamic> toJson() => {'i': id, 'n': name, 'a': lat, 'o': lng};

  factory _FoodSpot.fromJson(Map<String, dynamic> j) => _FoodSpot(
        id: j['i'] as String? ?? '',
        name: j['n'] as String? ?? '',
        lat: (j['a'] as num).toDouble(),
        lng: (j['o'] as num).toDouble(),
      );
}

class TrackingCubit extends Cubit<TrackingState> with WidgetsBindingObserver {
  final StartTrackingUseCase _start;
  final GetTrackingStatusUseCase _status;
  final SendTrackingEventUseCase _sendEvent;
  final ManualCheckInUseCase _checkIn;
  final EndTrackingDayUseCase _endDay;
  final GeofenceTrackingService _geofenceSvc;
  final TrackingAlarmService _alarmSvc;

  static double get _foodProximityKm => TrackingConfig.foodProximityKm;

  static const _foodKeywords = [
    'nhà hàng', 'restaurant', 'cafe', 'cà phê', 'ăn uống',
    'quán ăn', 'buffet', 'fastfood', 'fast food', 'food', 'ẩm thực',
  ];

  static bool _isFoodCategory(String? category) {
    if (category == null || category.isEmpty) return false;
    final lower = category.toLowerCase();
    return _foodKeywords.any((k) => lower.contains(k));
  }

  static double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  TrackingCubit({
    required StartTrackingUseCase start,
    required GetTrackingStatusUseCase status,
    required SendTrackingEventUseCase sendEvent,
    required ManualCheckInUseCase checkIn,
    required EndTrackingDayUseCase endDay,
    required GeofenceTrackingService geofenceSvc,
    required TrackingAlarmService alarmSvc,
  })  : _start = start,
        _status = status,
        _sendEvent = sendEvent,
        _checkIn = checkIn,
        _endDay = endDay,
        _geofenceSvc = geofenceSvc,
        _alarmSvc = alarmSvc,
        super(const TrackingState()) {
    WidgetsBinding.instance.addObserver(this);
    _listenConnectivity();
  }

  void _listenConnectivity() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline && _wasOffline && state.isActive) {
        refreshStatus();
        _evaluateGeofences();
      }
      _wasOffline = !isOnline;
    });
  }

  String _touristId = '';
  Timer? _refreshTimer;
  Timer? _geofenceTimer;
  StreamSubscription<Position>? _locationSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  List<_FoodSpot> _foodSpots = [];
  bool _wasOffline = false;
  final _connectivity = Connectivity();

  List<TrackingGeofence> _geofences = [];
  Position? _lastPosition;
  final Set<String> _insideIds = {};
  final Map<String, DateTime> _enteredAt = {};
  final Set<String> _dwellSentIds = {};
  final Set<String> _visitedIds = {};

  bool _highAccuracyMode = false;

  static const double _highAccuracyRangeM = 500;

  static int _foregroundDwell(int threshold) => threshold.clamp(15, 120);

  void _resetDetectionState() {
    _geofences = [];
    _lastPosition = null;
    _highAccuracyMode = false;
    _insideIds.clear();
    _enteredAt.clear();
    _dwellSentIds.clear();
    _visitedIds.clear();
  }


  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _geofenceTimer?.cancel();
    _locationSub?.cancel();
    _connectivitySub?.cancel();
    return super.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed && state.isActive) {
      refreshStatus();
      _evaluateGeofences();
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => refreshStatus());
  }

  void _startFoodProximityWatch(List<ItineraryActivityEntity> activities) {
    _foodSpots = activities
        .where((a) => _isFoodCategory(a.category) && a.latitude != null && a.longitude != null)
        .map((a) => _FoodSpot(
              id: a.id,
              name: a.locationName.isNotEmpty ? a.locationName : a.title,
              lat: a.latitude!,
              lng: a.longitude!,
            ))
        .toList();
    _persistFoodSpots();
    _subscribeLocationStream();
  }

  Future<void> _persistFoodSpots() async {
    if (_foodSpots.isEmpty) {
      await TrackingContextStore.clearFoodSpots();
    } else {
      await TrackingContextStore.saveFoodSpots(
        jsonEncode(_foodSpots.map((s) => s.toJson()).toList()),
      );
    }
  }

  Future<void> _restoreFoodProximityWatch() async {
    final raw = await TrackingContextStore.loadFoodSpots();
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List;
      _foodSpots = list
          .map((j) => _FoodSpot.fromJson(Map<String, dynamic>.from(j as Map)))
          .where((s) => s.id.isNotEmpty)
          .toList();
    } catch (_) {
      _foodSpots = [];
    }
    _subscribeLocationStream();
  }

  void _subscribeLocationStream({bool highAccuracy = false}) {
    _locationSub?.cancel();
    if (!state.isActive) return;
    _highAccuracyMode = highAccuracy;
    try {
      _locationSub = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy:
              highAccuracy ? LocationAccuracy.high : LocationAccuracy.medium,
          distanceFilter: highAccuracy ? 10 : 100,
        ),
      ).listen(_onPosition, onError: (_) {});
    } catch (_) {}
  }

  void _onPosition(Position pos) {
    if (isClosed) return;
    _lastPosition = pos;
    _evaluateGeofences();
    _checkFoodProximity(pos);
    _maybeSwitchAccuracy(pos);
  }

  void _maybeSwitchAccuracy(Position pos) {
    if (_geofences.isEmpty) return;
    double? nearest;
    for (final g in _geofences) {
      if (_visitedIds.contains(g.itineraryDetailId)) continue;
      final m =
          _haversineKm(pos.latitude, pos.longitude, g.latitude, g.longitude) *
              1000;
      if (nearest == null || m < nearest) nearest = m;
    }
    if (nearest == null) return;
    final shouldHigh = nearest <= _highAccuracyRangeM;
    if (shouldHigh != _highAccuracyMode) {
      _subscribeLocationStream(highAccuracy: shouldHigh);
    }
  }

  void _ensureDwellTimer() {
    _geofenceTimer ??=
        Timer.periodic(const Duration(seconds: 5), (_) => _evaluateGeofences());
  }

  void _stopDwellTimerIfIdle() {
    if (_insideIds.isEmpty) {
      _geofenceTimer?.cancel();
      _geofenceTimer = null;
    }
  }

  void _checkFoodProximity(Position pos) {
    if (isClosed || _foodSpots.isEmpty) return;
    for (final s in _foodSpots) {
      final km = _haversineKm(pos.latitude, pos.longitude, s.lat, s.lng);
      if (km <= _foodProximityKm) {
        if (state.nearbyRestaurantDetailId != s.id) {
          emit(state.copyWith(
            nearbyRestaurantDetailId: s.id,
            nearbyRestaurantName: s.name,
          ));
        }
        return;
      }
    }
    if (state.nearbyRestaurantDetailId != null) {
      emit(state.copyWith(clearNearbyRestaurant: true));
    }
  }

  void _evaluateGeofences() {
    if (isClosed || !state.isActive) return;
    final pos = _lastPosition;
    if (pos == null || _geofences.isEmpty) return;
    final now = DateTime.now();

    for (final g in _geofences) {
      final id = g.itineraryDetailId;
      if (id.isEmpty || _visitedIds.contains(id)) continue;

      final meters =
          _haversineKm(pos.latitude, pos.longitude, g.latitude, g.longitude) *
              1000;
      final inside = meters <= g.radiusM;

      if (inside) {
        if (!_insideIds.contains(id)) {
          _insideIds.add(id);
          _enteredAt[id] = now;
          _ensureDwellTimer();
          _sendGeofenceEvent(id, 'ENTER');
        } else if (!_dwellSentIds.contains(id)) {
          final entered = _enteredAt[id] ?? now;
          final elapsed = now.difference(entered).inSeconds;
          if (elapsed >= _foregroundDwell(g.dwellThresholdSeconds)) {
            _dwellSentIds.add(id);
            _sendGeofenceEvent(
              id,
              'DWELL',
              dwellSeconds: g.dwellThresholdSeconds,
              placeName: g.name,
            ).then((ok) {
              if (!ok) _dwellSentIds.remove(id);
            });
          }
        }
      } else if (_insideIds.remove(id)) {
        _enteredAt.remove(id);
        _dwellSentIds.remove(id);
        _sendGeofenceEvent(id, 'EXIT');
      }
    }
    _stopDwellTimerIfIdle();
  }

  Future<bool> _sendGeofenceEvent(
    String detailId,
    String eventType, {
    int? dwellSeconds,
    String? placeName,
  }) async {
    if (_touristId.isEmpty) _touristId = await _resolveTouristId();
    if (_touristId.isEmpty) return false;
    try {
      final res = await _sendEvent(
        itineraryDetailId: detailId,
        touristId: _touristId,
        eventType: eventType,
        occurredAt: DateTime.now(),
        dwellSeconds: dwellSeconds,
      );
      if (eventType == 'DWELL' && res.status == VisitStatus.visited) {
        _visitedIds.add(detailId);
        await refreshStatus();
        await _showArrivalNotification(
          detailId: detailId,
          placeName: res.name ?? placeName ?? 'địa điểm',
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _showArrivalNotification({
    required String detailId,
    required String placeName,
  }) async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await plugin.initialize(settings: initSettings);
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'itinerary_tracking_channel',
          'Theo dõi lịch trình',
          channelDescription:
              'Thông báo khi bạn đến một địa điểm trong lịch trình',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
      await plugin.show(
        id: detailId.hashCode & 0x7fffffff,
        title: 'Đã đến nơi 🎉',
        body: 'Bạn đã đến $placeName',
        notificationDetails: details,
        payload: 'tracking:$detailId',
      );
    } catch (_) {}
  }

  Future<void> _rebuildGeofencesFromStatus(TrackingStatusResult status) async {
    final ctx = await TrackingContextStore.load();
    final radius = ctx?.radiusM ?? TrackingConfig.radiusM;
    final list = <TrackingGeofence>[];
    for (final p in status.places) {
      if (p.status == VisitStatus.visited || p.status == VisitStatus.skipped) {
        _visitedIds.add(p.itineraryDetailId);
        continue;
      }
      if (p.latitude == null || p.longitude == null) continue;
      list.add(TrackingGeofence(
        itineraryDetailId: p.itineraryDetailId,
        latitude: p.latitude!,
        longitude: p.longitude!,
        name: p.name,
        radiusM: radius,
        dwellThresholdSeconds:
            ctx?.metaFor(p.itineraryDetailId)?.dwellSeconds ??
                TrackingConfig.dwellSeconds,
      ));
    }
    _geofences = list;
  }

  void updateActivities(List<ItineraryActivityEntity> activities) {
    if (!state.isActive) return;
    _startFoodProximityWatch(activities);
  }

  void dismissNearbyRestaurant() {
    emit(state.copyWith(clearNearbyRestaurant: true));
  }

  Future<String> _resolveTouristId() async {
    final fromAuth = await AuthUtils.getCurrentUserId();
    return (fromAuth != null && fromAuth.isNotEmpty)
        ? fromAuth
        : (dotenv.env['EXPLORE_TOURIST_ID']?.trim() ?? '');
  }

  Future<void> restoreIfActive() async {
    if (state.isActive) return;

    final ctx = await TrackingContextStore.load();
    if (ctx == null || ctx.itineraryId.isEmpty || ctx.date.isEmpty) return;

    DateTime? date;
    try {
      final p = ctx.date.split('-');
      if (p.length == 3) date = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    } catch (_) {}
    if (date == null) return;

    _touristId = ctx.touristId;
    _resetDetectionState();

    emit(state.copyWith(
      phase: TrackingPhase.active,
      itineraryId: ctx.itineraryId,
      date: date,
    ));

    try {
      final status = await _status(itineraryId: ctx.itineraryId, date: date);
      emit(state.copyWith(places: status.places));
      await _rebuildGeofencesFromStatus(status);
    } catch (_) {}

    _startRefreshTimer();
    await _restoreFoodProximityWatch();
    _subscribeLocationStream();
  }

  Future<void> start({
    required String itineraryId,
    required DateTime date,
    int radiusM = TrackingConfig.radiusM,
    List<ItineraryActivityEntity> activities = const [],
  }) async {
    emit(state.copyWith(
      phase: TrackingPhase.starting,
      itineraryId: itineraryId,
      date: date,
      clearMessage: true,
    ));
    try {
      _touristId = await _resolveTouristId();
      if (_touristId.isEmpty) {
        emit(state.copyWith(
          phase: TrackingPhase.error,
          message: 'Không xác định được tài khoản. Vui lòng đăng nhập lại.',
        ));
        return;
      }

      final result = await _start(
        itineraryId: itineraryId,
        touristId: _touristId,
        date: date,
        radiusM: radiusM,
      );
      final geofences = result.geofences.where((g) => g.hasValidLocation).toList();
      if (geofences.isEmpty) {
        emit(state.copyWith(
          phase: TrackingPhase.error,
          message: 'Ngày này chưa có địa điểm để theo dõi.',
        ));
        return;
      }

      await TrackingContextStore.save(TrackingContextStore.build(
        baseUrl: ApiConfig.baseUrl,
        touristId: _touristId,
        itineraryId: itineraryId,
        date: TrackingRemoteDataSource.fmtDate(date),
        radiusM: radiusM,
        geofences: geofences,
      ));

      await _geofenceSvc.removeAll();

      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59);
      final ttl = endOfDay.difference(DateTime.now());
      final registered = await _geofenceSvc.registerAll(
        geofences,
        expiration: ttl.isNegative ? null : ttl,
      );

      final dayEndAt = DateTime(date.year, date.month, date.day, 23, 0);
      if (dayEndAt.isAfter(DateTime.now())) {
        await _alarmSvc.scheduleEndOfDay(dayEndAt);
      }

      final status = await _status(itineraryId: itineraryId, date: date);

      if (registered == 0) {
        emit(state.copyWith(
          phase: TrackingPhase.error,
          message: 'Không đăng ký được geofence. '
              'Kiểm tra quyền vị trí "Luôn cho phép" (Always Allow) '
              'trong Cài đặt → Ứng dụng → Quyền → Vị trí.',
        ));
        return;
      }

      emit(state.copyWith(
        phase: TrackingPhase.active,
        registeredCount: registered,
        places: status.places,
      ));

      _resetDetectionState();
      _geofences = geofences;
      for (final p in status.places) {
        if (p.status == VisitStatus.visited || p.status == VisitStatus.skipped) {
          _visitedIds.add(p.itineraryDetailId);
        }
      }

      _startRefreshTimer();
      _startFoodProximityWatch(activities);
    } catch (e) {
      emit(state.copyWith(
        phase: TrackingPhase.error,
        message: 'Không bắt đầu được theo dõi: $e',
      ));
    }
  }

  Future<void> refreshStatus() async {
    final id = state.itineraryId;
    final d = state.date;
    if (id == null || d == null) return;
    try {
      final status = await _status(itineraryId: id, date: d);
      emit(state.copyWith(places: status.places));
      for (final p in status.places) {
        if (p.status == VisitStatus.visited || p.status == VisitStatus.skipped) {
          _visitedIds.add(p.itineraryDetailId);
        }
      }
    } catch (_) {/* giữ trạng thái cũ */}
  }

  Future<void> manualCheckIn(String itineraryDetailId) async {
    if (_touristId.isEmpty) _touristId = await _resolveTouristId();
    emit(state.copyWith(checkingInDetailId: itineraryDetailId));
    try {
      await _checkIn(
        itineraryDetailId: itineraryDetailId,
        touristId: _touristId,
      );
      await refreshStatus();
      emit(state.copyWith(clearCheckingIn: true, message: 'Đã check-in'));
    } catch (e) {
      emit(state.copyWith(
        clearCheckingIn: true,
        message: 'Check-in thất bại: $e',
      ));
    }
  }

  Future<void> notifyDbState(String itineraryId, bool dbActive) async {
    if (state.itineraryId != itineraryId) return;
    if (!state.isActive) return;
    if (!dbActive) await clearStaleCache();
  }

  Future<void> clearStaleCache() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _geofenceTimer?.cancel();
    _geofenceTimer = null;
    _locationSub?.cancel();
    _locationSub = null;
    _foodSpots = [];
    _resetDetectionState();
    await _geofenceSvc.removeAll();
    await _alarmSvc.cancelAll();
    await TrackingContextStore.clear();
    await TrackingContextStore.clearFoodSpots();
    emit(const TrackingState());
  }

  Future<void> stop() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _geofenceTimer?.cancel();
    _geofenceTimer = null;
    _locationSub?.cancel();
    _locationSub = null;
    _foodSpots = [];
    _resetDetectionState();
    try {
      final id = state.itineraryId;
      final d = state.date;
      if (id != null && d != null) {
        await _endDay(itineraryId: id, date: d, markPendingAsSkipped: false);
      }
    } catch (_) {}
    await _geofenceSvc.removeAll();
    await _alarmSvc.cancelAll();
    await TrackingContextStore.clear();
    await TrackingContextStore.clearNextDate();
    await TrackingContextStore.clearFoodSpots();
    emit(const TrackingState());
  }
}
