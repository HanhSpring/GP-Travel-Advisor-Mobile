import 'dart:convert';
import 'dart:math' show sqrt, sin, cos, atan2, pi;
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../screens/activity_edit_screen.dart';

import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/constants/app_text_styles.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/utils/demo_review_store.dart';
import 'package:travel_advisor_mobile/features/food/presentation/screens/food_menu_screen.dart';
import 'package:travel_advisor_mobile/features/food/presentation/widgets/pre_order_popup.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_activity_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_day_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/cubit/tracking_state.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/data/models/tracking_models.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/presentation/widgets/tracking_section.dart';
import 'package:travel_advisor_mobile/features/itinerary/tracking/tracking_config.dart';
import 'package:travel_advisor_mobile/features/itinerary/domain/entities/itinerary_detail_entity.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_cubit.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/cubit/itinerary_state.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/day_selector_chip.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/itinerary_review_dialog.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/timeline_activity_card.dart';
import 'package:travel_advisor_mobile/features/place/presentation/cubit/place_detail_cubit.dart';
import 'package:travel_advisor_mobile/features/place/presentation/screens/place_detail_screen.dart';
import '../widgets/itinerary_map_view.dart';
import '../widgets/replace_place_sheet.dart';
import '../widgets/add_place_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:travel_advisor_mobile/core/utils/map_utils.dart';


class ItineraryDetailView extends StatelessWidget {
  final int selectedDay;
  final bool isPublic;
  final Function(int) onDayChanged;
  final Function(bool) onPublicChanged;
  final VoidCallback onAddPlaceTap;
  final MapboxMap? mapController;
  final Function(MapboxMap) onMapCreated;
  final ScrollController scrollController;
  final Map<String, GlobalKey> activityKeys;
  final Function(ItineraryActivityEntity) onActivityTap;
  final Function(ItineraryActivityEntity) onActivityLongPress;
  final Function(ItineraryActivityEntity) onEditActivity;
  final Function(ItineraryActivityEntity) onReplaceActivity;
  final Function(ItineraryActivityEntity) onDeleteActivity;
  final Function(ItineraryActivityEntity) onRateActivity;
  final Function(ItineraryActivityEntity, bool, bool) onEditTime;
  final Function(ItineraryActivityEntity, ItineraryActivityEntity)
  onDirectionTap;
  final VoidCallback onShareTap;
  final Function(String) onMarkerTap;
  final String? highlightedActivityId;
  final bool isEditMode;
  final VoidCallback onEditModeTap;
  final VoidCallback onDiscardTap;

  const ItineraryDetailView({
    required this.selectedDay,
    required this.isPublic,
    required this.onDayChanged,
    required this.onPublicChanged,
    required this.onAddPlaceTap,
    this.mapController,
    required this.onMapCreated,
    required this.scrollController,
    required this.activityKeys,
    required this.onActivityTap,
    required this.onActivityLongPress,
    required this.onEditActivity,
    required this.onReplaceActivity,
    required this.onDeleteActivity,
    required this.onRateActivity,
    required this.onEditTime,
    required this.onDirectionTap,
    required this.onShareTap,
    required this.onMarkerTap,
    this.highlightedActivityId,
    required this.isEditMode,
    required this.onEditModeTap,
    required this.onDiscardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<ItineraryCubit, ItineraryState>(
        builder: (context, state) {
          if (state is ItineraryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ItineraryError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.s24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: AppSizes.s48,
                      color: AppColorsExt.error,
                    ),
                    const SizedBox(height: AppSizes.s16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: AppSizes.s16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<ItineraryCubit>().loadData(),
                      child: Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is ItineraryLoaded && state.selectedItinerary != null) {
            final itin = state.selectedItinerary!;
            final currentDayData = itin.days.firstWhere(
              (d) => d.dayNumber == selectedDay,
              orElse: () => itin.days.first,
            );

            return Stack(
              children: [
                Positioned.fill(
                  child: ItineraryMapView(
                    activities: currentDayData.activities,
                    allDays: itin.days,
                    selectedDay: selectedDay,
                    onMarkerTap: onMarkerTap,
                    onMapCreated: onMapCreated,
                  ),
                ),

                DraggableScrollableSheet(
                  initialChildSize: 0.45,
                  minChildSize: 0.12,
                  maxChildSize: 0.85,
                  snap: true,
                  snapSizes: const [0.12, 0.45, 0.85],
                  builder: (context, sheetScrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 8),
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              controller: sheetScrollController,
                              padding: EdgeInsets.zero,
                              children: [
                                _buildContentCard(
                                  context,
                                  itin,
                                  currentDayData,
                                  itin.days,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                Positioned(
                  top: MediaQuery.of(context).padding.top + AppSizes.s12,
                  left: AppSizes.s20,
                  right: AppSizes.s20,
                  child: Row(
                    children: [
                      _floatingCircleButton(
                        Icons.arrow_back_ios_new,
                        () => Navigator.pop(context),
                      ),
                      if (itin.status == 'COMPLETED' ||
                          itin.status == 'ONGOING' ||
                          itin.endDate.isBefore(DateTime.now()))
                        Padding(
                          padding: const EdgeInsets.only(left: AppSizes.s12),
                          child: _floatingCircleButton(
                            Icons.star_outline_rounded,
                            () {
                              showDialog(
                                context: context,
                                builder: (_) => ItineraryReviewDialog(
                                  itineraryId: itin.id,
                                  itineraryTitle: itin.title,
                                  totalLocations: itin.totalLocations,
                                  visitedLocations: itin.visitedLocations,
                                ),
                              );
                            },
                          ),
                        ),
                      const Spacer(),
                      if (isEditMode) ...[
                        _floatingCircleButton(
                          Icons.close_rounded,
                          onDiscardTap,
                          iconColor: const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: AppSizes.s12),
                      ],
                      _floatingCircleButton(
                        isEditMode ? Icons.check_rounded : Icons.edit_outlined,
                        onEditModeTap,
                        active: isEditMode,
                      ),
                      if (!isEditMode) ...[
                        const SizedBox(width: AppSizes.s12),
                        _floatingCircleButton(Icons.share_outlined, onShareTap),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContentCard(
    BuildContext context,
    ItineraryDetailEntity itin,
    ItineraryDayEntity currentDayData,
    List<ItineraryDayEntity> displayDays,
  ) {
    final visibleActivities = _timelineActivities(currentDayData);
    final destinationCount = _visitActivities(currentDayData).length;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r32)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s20,
        vertical: AppSizes.s12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.s12),
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: displayDays
                    .map<Widget>(
                      (day) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: DaySelectorChip(
                          dayNumber: day.dayNumber,
                          locationCount: day.locationsCount,
                          dateLabel: _formatShortDate(
                            itin.startDate.add(
                              Duration(days: day.dayNumber - 1),
                            ),
                          ),
                          isSelected: selectedDay == day.dayNumber,
                          onTap: () => onDayChanged(day.dayNumber),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.s12),
          Row(
            children: [
              Text(
                '$destinationCount điểm trong ngày',
                style: AppTextStylesExt.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onAddPlaceTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Thêm địa điểm',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s16),
          TrackingSection(
            itineraryId: itin.id,
            date: currentDayData.date,
            itineraryStatus: itin.status,
            activities: currentDayData.activities,
            showStartButton: false,
            dbTrackingActive: itin.trackingActive,
            onStopped: () =>
                context.read<ItineraryCubit>().toggleItineraryStatus(itin.id, false),
          ),
          Builder(builder: (context) {
            final tracking = context.watch<TrackingCubit>().state;
            final activities = visibleActivities;
            return Column(
              children: activities.asMap().entries.map((entry) {
                final index = entry.key;
                final activity = entry.value;
                final key = activityKeys.putIfAbsent(activity.id, () => GlobalKey());
                final nextActivity =
                    index < activities.length - 1 ? activities[index + 1] : null;
                final nextTransport = nextActivity == null
                    ? null
                    : (activities[index].transportInfo?.isNotEmpty == true
                        ? activities[index].transportInfo
                        : _estimateTransit(
                            activity.latitude, activity.longitude,
                            nextActivity.latitude, nextActivity.longitude,
                          ));
                final TrackingPlaceStatus? trackingStatus =
                    tracking.isActive ? tracking.byDetailId(activity.id) : null;
                return TimelineActivityCard(
                  key: key,
                  activity: activity,
                  day: selectedDay,
                  isFirst: index == 0,
                  isLast: index == activities.length - 1,
                  nextTransportInfo: nextTransport,
                  onAddTap: onAddPlaceTap,
                  onEditTap: () => onEditActivity(activity),
                  onReplaceTap: () => onReplaceActivity(activity),
                  onDeleteTap: () => onDeleteActivity(activity),
                  onRateTap: () => onRateActivity(activity),
                  onCardTap: () => onActivityTap(activity),
                  onCardLongPress: () => onActivityLongPress(activity),
                  isHighlighted: highlightedActivityId == activity.id,
                  onStartTimeTap: () =>
                      onEditTime(activity, true, index == activities.length - 1),
                  onEndTimeTap: () =>
                      onEditTime(activity, false, index == activities.length - 1),
                  isEditMode: isEditMode,
                  onDirectionTap: nextActivity != null
                      ? () => onDirectionTap(activity, nextActivity)
                      : null,
                  trackingStatus: trackingStatus,
                  onCheckIn: trackingStatus != null
                      ? () =>
                          context.read<TrackingCubit>().manualCheckIn(activity.id)
                      : null,
                  isCheckingIn: tracking.checkingInDetailId == activity.id,
                );
              }).toList(),
            );
          }),
          const SizedBox(height: AppSizes.s40),
        ],
      ),
    );
  }

  List<ItineraryActivityEntity> _visitActivities(ItineraryDayEntity day) {
    return day.activities
        .where((activity) => !_isHotelStart(activity))
        .toList();
  }

  List<ItineraryActivityEntity> _timelineActivities(ItineraryDayEntity day) {
    if (day.dayNumber == 1) return _visitActivities(day);

    final hotels = day.activities.where(_isHotelStart).toList();
    final visits = _visitActivities(day);
    return [...hotels, ...visits];
  }

  bool _isHotelStart(ItineraryActivityEntity activity) {
    final category = (activity.category ?? '').toLowerCase();
    final title = activity.title.toLowerCase();
    final sameTime = activity.startTime == activity.endTime;
    return sameTime &&
        (category.contains('lưu trú') ||
            category.contains('luu tru') ||
            category.contains('khách sạn') ||
            category.contains('khach san') ||
            category.contains('hotel') ||
            title.contains('hotel') ||
            title.contains('khách sạn') ||
            title.contains('khach san'));
  }

  String _formatShortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  static String _estimateTransit(
    double? lat1,
    double? lng1,
    double? lat2,
    double? lng2,
  ) {
    if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) {
      return 'Di chuyển đến điểm tiếp theo';
    }
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final km = r * 2 * atan2(sqrt(a), sqrt(1 - a));
    final mins = (km / 25 * 60).ceil().clamp(1, 999);
    if (mins < 60) return '~$mins phút di chuyển';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '~$h giờ di chuyển' : '~$h giờ $m phút di chuyển';
  }

  Widget _floatingCircleButton(
    IconData icon,
    VoidCallback onTap, {
    bool active = false,
    Color? iconColor,
  }) {
    return Material(
      color: active
          ? AppColors.primary.withAlpha(220)
          : Colors.black.withAlpha(120),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: iconColor ?? Colors.white),
        ),
      ),
    );
  }
}
