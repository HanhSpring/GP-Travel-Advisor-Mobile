import '../../data/models/tracking_models.dart';
import '../../tracking_config.dart';
import '../repositories/tracking_repository.dart';

class StartTrackingUseCase {
  final TrackingRepository repo;
  StartTrackingUseCase(this.repo);

  Future<TrackingStartResult> call({
    required String itineraryId,
    required String touristId,
    required DateTime date,
    int radiusM = TrackingConfig.radiusM,
  }) =>
      repo.start(
        itineraryId: itineraryId,
        touristId: touristId,
        date: date,
        radiusM: radiusM,
      );
}

class GetGeofencesUseCase {
  final TrackingRepository repo;
  GetGeofencesUseCase(this.repo);

  Future<List<TrackingGeofence>> call({
    required String itineraryId,
    required DateTime date,
    int radiusM = TrackingConfig.radiusM,
  }) =>
      repo.geofences(itineraryId: itineraryId, date: date, radiusM: radiusM);
}

class SendTrackingEventUseCase {
  final TrackingRepository repo;
  SendTrackingEventUseCase(this.repo);

  Future<GeofenceEventResult> call({
    required String itineraryDetailId,
    required String touristId,
    required String eventType,
    DateTime? occurredAt,
    int? dwellSeconds,
  }) =>
      repo.sendEvent(
        itineraryDetailId: itineraryDetailId,
        touristId: touristId,
        eventType: eventType,
        occurredAt: occurredAt,
        dwellSeconds: dwellSeconds,
      );
}

class ManualCheckInUseCase {
  final TrackingRepository repo;
  ManualCheckInUseCase(this.repo);

  Future<GeofenceEventResult> call({
    required String itineraryDetailId,
    required String touristId,
  }) =>
      repo.checkIn(itineraryDetailId: itineraryDetailId, touristId: touristId);
}

class GetTrackingStatusUseCase {
  final TrackingRepository repo;
  GetTrackingStatusUseCase(this.repo);

  Future<TrackingStatusResult> call({
    required String itineraryId,
    required DateTime date,
  }) =>
      repo.status(itineraryId: itineraryId, date: date);
}

class EndTrackingDayUseCase {
  final TrackingRepository repo;
  EndTrackingDayUseCase(this.repo);

  Future<EndDayResult> call({
    required String itineraryId,
    required DateTime date,
    bool markPendingAsSkipped = true,
  }) =>
      repo.endDay(
        itineraryId: itineraryId,
        date: date,
        markPendingAsSkipped: markPendingAsSkipped,
      );
}
