import 'package:native_geofence/native_geofence.dart';

import '../data/models/tracking_models.dart';
import 'geofence_callback.dart';

///
class GeofenceTrackingService {
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await NativeGeofenceManager.instance.initialize();
    _initialized = true;
  }

  Future<int> registerAll(
    List<TrackingGeofence> geofences, {
    Duration? expiration,
  }) async {
    await _ensureInit();
    var ok = 0;
    for (final g in geofences) {
      if (g.itineraryDetailId.isEmpty || !g.hasValidLocation) continue;
      try {
        final geofence = Geofence(
          id: g.itineraryDetailId,
          location: Location(latitude: g.latitude, longitude: g.longitude),
          radiusMeters: g.radiusM.toDouble(),
          triggers: const {
            GeofenceEvent.enter,
            GeofenceEvent.dwell,
            GeofenceEvent.exit,
          },
          iosSettings: const IosGeofenceSettings(initialTrigger: true),
          androidSettings: AndroidGeofenceSettings(
            initialTriggers: const {GeofenceEvent.enter},
            loiteringDelay: Duration(seconds: g.dwellThresholdSeconds.clamp(30, 120)),
            notificationResponsiveness: const Duration(seconds: 10),
            expiration: expiration,
          ),
        );
        await NativeGeofenceManager.instance
            .createGeofence(geofence, geofenceTriggered);
        ok++;
      } catch (_) {
      }
    }
    return ok;
  }

  Future<void> removeByIds(List<String> ids) async {
    await _ensureInit();
    for (final id in ids) {
      if (id.isEmpty) continue;
      try {
        await NativeGeofenceManager.instance.removeGeofenceById(id);
      } catch (_) {}
    }
  }

  Future<void> removeAll() async {
    await _ensureInit();
    try {
      await NativeGeofenceManager.instance.removeAllGeofences();
    } catch (_) {}
  }

  Future<List<String>> registeredIds() async {
    await _ensureInit();
    try {
      return await NativeGeofenceManager.instance.getRegisteredGeofenceIds();
    } catch (_) {
      return const [];
    }
  }
}
