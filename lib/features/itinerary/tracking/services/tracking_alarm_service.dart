import 'dart:io';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';

import '../data/models/tracking_models.dart';
import 'geofence_tracking_service.dart';
import 'tracking_context.dart';
import 'tracking_http.dart';

class TrackingAlarmService {
  static const int endOfDayAlarmId = 990001;
  static const int nextDayAlarmId = 990002;

  Future<void> scheduleEndOfDay(DateTime at) async {
    if (!Platform.isAndroid) return;
    await AndroidAlarmManager.oneShotAt(
      at, endOfDayAlarmId, onTrackingDayEnd,
      exact: true, wakeup: true,
      rescheduleOnReboot: true, allowWhileIdle: true,
    );
  }

  Future<void> scheduleNextDay(DateTime at) async {
    if (!Platform.isAndroid) return;
    await AndroidAlarmManager.oneShotAt(
      at, nextDayAlarmId, onTrackingNextDay,
      exact: true, wakeup: true,
      rescheduleOnReboot: true, allowWhileIdle: true,
    );
  }

  Future<void> cancelAll() async {
    if (!Platform.isAndroid) return;
    await AndroidAlarmManager.cancel(endOfDayAlarmId);
    await AndroidAlarmManager.cancel(nextDayAlarmId);
  }
}

@pragma('vm:entry-point')
Future<void> onTrackingDayEnd() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final ctx = await TrackingContextStore.load();
  if (ctx == null || ctx.baseUrl.isEmpty) return;

  try {
    final dio = await buildTrackingDio(ctx.baseUrl);
    final res = await dio.post('/itinerary/tracking/end-day', data: {
      'itineraryId': ctx.itineraryId,
      'date': ctx.date,
      'markPendingAsSkipped': true,
    });
    final end = EndDayResult.fromAny(res.data);

    final ids = end.removedItineraryDetailIds.isNotEmpty
        ? end.removedItineraryDetailIds
        : ctx.places.keys.toList();
    await GeofenceTrackingService().removeByIds(ids);

    final hasNext =
        end.itineraryStatus != 'completed' && end.nextDayDate != null;
    if (hasNext) {
      final next = end.nextDayDate!;
      await TrackingContextStore.saveNextDate(
        '${next.year.toString().padLeft(4, '0')}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}',
      );
      final alarmAt = end.nextDayAlarmAt ??
          DateTime(next.year, next.month, next.day, 7);
      await TrackingAlarmService().scheduleNextDay(alarmAt);
    } else {
      await TrackingContextStore.clear();
      await TrackingContextStore.clearNextDate();
    }
  } catch (_) {
  }
}

@pragma('vm:entry-point')
Future<void> onTrackingNextDay() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final ctx = await TrackingContextStore.load();
  final nextDate = await TrackingContextStore.loadNextDate();
  if (ctx == null || ctx.baseUrl.isEmpty || nextDate == null) return;

  try {
    final dio = await buildTrackingDio(ctx.baseUrl);
    final res = await dio.get('/itinerary/tracking/geofences', queryParameters: {
      'itineraryId': ctx.itineraryId,
      'date': nextDate,
      'radiusM': ctx.radiusM,
    });
    final geofences = TrackingStartResult.fromAny(res.data).geofences;
    if (geofences.isEmpty) return;

    await GeofenceTrackingService().registerAll(geofences);

    final newCtx = TrackingContextStore.build(
      baseUrl: ctx.baseUrl,
      touristId: ctx.touristId,
      itineraryId: ctx.itineraryId,
      date: nextDate,
      radiusM: ctx.radiusM,
      geofences: geofences,
    );
    await TrackingContextStore.save(newCtx);
    await TrackingContextStore.clearNextDate();

    final p = nextDate.split('-');
    if (p.length == 3) {
      final endAt = DateTime(
          int.parse(p[0]), int.parse(p[1]), int.parse(p[2]), 23, 0);
      await TrackingAlarmService().scheduleEndOfDay(endAt);
    }
  } catch (_) {}
}
