import 'dart:math' show sqrt, sin, cos, atan2, pi;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'activity_edit_screen.dart';

import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/constants/app_text_styles.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
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
import 'package:travel_advisor_mobile/features/review/presentation/widgets/itinerary_rating_popup.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/timeline_activity_card.dart';
import 'package:travel_advisor_mobile/features/itinerary/presentation/widgets/public_visibility_switch.dart';
import 'package:travel_advisor_mobile/features/place/presentation/cubit/place_detail_cubit.dart';
import 'package:travel_advisor_mobile/features/place/presentation/screens/place_detail_screen.dart';
import 'package:travel_advisor_mobile/features/saved/data/datasources/favorite_remote_datasource.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/location_review_entity.dart';
import 'package:travel_advisor_mobile/features/review/presentation/cubit/review_cubit.dart';
import 'package:travel_advisor_mobile/features/review/presentation/cubit/review_state.dart';
import 'package:travel_advisor_mobile/features/review/presentation/screens/place_review_screen.dart';
import '../widgets/itinerary_map_view.dart';
import '../widgets/replace_place_sheet.dart';
import '../widgets/add_place_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:travel_advisor_mobile/core/utils/map_utils.dart';

class ItineraryDetailScreen extends StatefulWidget {
  final String itineraryId;
  final ItineraryDetailEntity? initialDetail;
  final int initialDay;

  const ItineraryDetailScreen({
    super.key,
    required this.itineraryId,
    this.initialDetail,
    this.initialDay = 1,
  });

  @override
  State<ItineraryDetailScreen> createState() => _ItineraryDetailScreenState();
}

class _ItineraryDetailScreenState extends State<ItineraryDetailScreen> {
  late int _selectedDay = widget.initialDay;
  bool _isPublic = true;
  bool _isEditMode = false;
  bool _isMapLoaded = false;
  ItineraryDetailEntity? _editSnapshot;
  MapboxMap? _mapController;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _activityKeys = {};
  final Set<String> _openingReviewActivityIds = <String>{};
  String? _highlightedActivityId;

  DateTime? _visitDateForDay(int dayNumber) {
    final state = context.read<ItineraryCubit>().state;
    if (state is! ItineraryLoaded || state.selectedItinerary == null) {
      return null;
    }
    try {
      return state.selectedItinerary!.days
          .firstWhere((day) => day.dayNumber == dayNumber)
          .date;
    } catch (_) {
      return null;
    }
  }

  (String, String)? _parseOpenSlot(String raw, DateTime visitDate) {
    final matches = RegExp(
      r'(\d{1,2}:\d{2})\s*[-Ã¢â‚¬â€œ]\s*(\d{1,2}:\d{2})',
    ).allMatches(raw).toList();
    if (matches.isEmpty) return null;
    final match = matches.first;
    return (match.group(1)!, match.group(2)!);
  }

  void _onEditModeTap() {
    final state = context.read<ItineraryCubit>().state;
    if (_isEditMode) {
      final itin = state is ItineraryLoaded ? state.selectedItinerary : null;
      if (itin != null) {
        context.read<ItineraryCubit>().confirmUpdateItinerary(itin.id);
      }
      setState(() {
        _isEditMode = false;
        _editSnapshot = null;
      });
      return;
    }

    setState(() {
      _isEditMode = true;
      _editSnapshot = state is ItineraryLoaded ? state.selectedItinerary : null;
    });
  }

  void _onDiscardChanges() {
    final snapshot = _editSnapshot;
    if (snapshot != null) {
      context.read<ItineraryCubit>().discardChanges(snapshot);
    }
    setState(() {
      _isEditMode = false;
      _editSnapshot = null;
    });
  }

  void _showAddPlaceScreen() {
    final state = context.read<ItineraryCubit>().state;
    double? refLat;
    double? refLng;
    String? proposedVisitTime;
    List<String> existingIds = [];

    if (state is ItineraryLoaded && state.selectedItinerary != null) {
      final itin = state.selectedItinerary!;
      for (final day in itin.days) {
        for (final act in day.activities) {
          existingIds.add(act.id);
        }
      }
      try {
        final dayData = itin.days.firstWhere(
          (d) => d.dayNumber == _selectedDay,
        );
        if (dayData.activities.isNotEmpty) {
          final lastActivity = dayData.activities.last;
          refLat = lastActivity.latitude;
          refLng = lastActivity.longitude;
          proposedVisitTime = lastActivity.endTime;
        }
      } catch (_) {}
    }

    // LÃ¡ÂºÂ¥y ngÃƒÂ y tham quan Ã„â€˜Ã¡Â»Æ’ validate opening hours Ã„â€˜ÃƒÂºng thÃ¡Â»Â© trong tuÃ¡ÂºÂ§n
    DateTime? visitDate;
    if ((context.read<ItineraryCubit>().state as ItineraryLoaded?)
            ?.selectedItinerary !=
        null) {
      try {
        final dayData =
            (context.read<ItineraryCubit>().state as ItineraryLoaded)
                .selectedItinerary!
                .days
                .firstWhere((d) => d.dayNumber == _selectedDay);
        visitDate = dayData.date;
      } catch (_) {}
    }

    AddPlaceSheet.show(
      context,
      referenceLat: refLat,
      referenceLng: refLng,
      existingIds: existingIds,
      visitDate: visitDate,
      proposedVisitTime: proposedVisitTime,
      onAdd: (place) {
        context.read<ItineraryCubit>().addActivityToDay(
          _selectedDay,
          place.id,
          place.name,
          lat: place.latitude,
          lng: place.longitude,
          imageUrl: place.imageUrl,
          address: place.address,
          category: place.category,
        );
      },
    );
  }

  void _onDayChanged(int day) {
    setState(() => _selectedDay = day);
  }

  void _scrollToActivity(String activityId) {
    setState(() => _highlightedActivityId = activityId);

    // TÃƒÂ¬m activity Ã„â€˜Ã¡Â»Æ’ lÃ¡ÂºÂ¥y tÃ¡Â»Âa Ã„â€˜Ã¡Â»â„¢ vÃƒÂ  zoom nhÃ¡ÂºÂ¹
    final itin = (context.read<ItineraryCubit>().state as ItineraryLoaded)
        .selectedItinerary;
    final activity = itin?.days
        .expand((d) => d.activities)
        .firstWhere((a) => a.id == activityId);
    if (activity != null &&
        activity.latitude != null &&
        activity.longitude != null) {
      _mapController?.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(activity.longitude!, activity.latitude!),
          ),
          zoom: 15,
        ),
      );
      // Mapbox v0.4.4 doesn't have showMarkerInfoWindow, we'd need a custom popup
    }

    final key = _activityKeys[activityId];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        alignment: 0.1,
      );
    }

    // Reset highlight after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _highlightedActivityId = null);
      }
    });
  }

  void _zoomToActivity(ItineraryActivityEntity activity) {
    if (activity.latitude != null && activity.longitude != null) {
      _mapController?.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(activity.longitude!, activity.latitude!),
          ),
          zoom: 17,
        ),
        MapAnimationOptions(duration: 1000),
      );
    }
  }

  Future<void> _launchDirections(
    ItineraryActivityEntity from,
    ItineraryActivityEntity to,
  ) async {
    if (from.latitude == null ||
        from.longitude == null ||
        to.latitude == null ||
        to.longitude == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KhÃƒÂ´ng cÃƒÂ³ tÃ¡Â»Âa Ã„â€˜Ã¡Â»â„¢ Ã„â€˜Ã¡Â»Æ’ chÃ¡Â»â€° Ã„â€˜Ã†Â°Ã¡Â»Âng')),
        );
      }
      return;
    }
    final url = Uri.parse(
      MapUtils.getDirectionsUrl(
        from.latitude!,
        from.longitude!,
        to.latitude!,
        to.longitude!,
      ),
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('_launchDirections failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KhÃƒÂ´ng thÃ¡Â»Æ’ mÃ¡Â»Å¸ Google Maps')),
        );
      }
    }
  }

  void _navigateToPlaceDetail(ItineraryActivityEntity activity) {
    final placeId = activity.placeId ?? activity.id;
    if (placeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KhÃ´ng tÃ¬m tháº¥y thÃ´ng tin Ä‘á»‹a Ä‘iá»ƒm')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<PlaceDetailCubit>(),
          child: PlaceDetailScreen(
            placeId: placeId,
            showRelatedPlaces: false,
          ),
        ),
      ),
    );
  }

  void _onEditActivity(ItineraryActivityEntity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ActivityEditScreen(activity: activity)),
    );
  }

  Future<void> _toggleItineraryFavorite() async {
    final state = context.read<ItineraryCubit>().state;
    if (state is! ItineraryLoaded || state.selectedItinerary == null) {
      return;
    }

    final itinerary = state.selectedItinerary!;
    if (!itinerary.isPublic) {
      return;
    }

    final nextFavorite = !itinerary.isFavorite;
    context.read<ItineraryCubit>().setSelectedItineraryFavorite(nextFavorite);

    try {
      await sl<FavoriteRemoteDataSource>().setItineraryFavorite(
        itinerary.id,
        nextFavorite,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextFavorite
                ? 'Ã„ÂÃƒÂ£ lÃ†Â°u vÃƒÂ o danh mÃ¡Â»Â¥c yÃƒÂªu thÃƒÂ­ch'
                : 'Ã„ÂÃƒÂ£ bÃ¡Â»Â khÃ¡Â»Âi danh mÃ¡Â»Â¥c yÃƒÂªu thÃƒÂ­ch',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      context.read<ItineraryCubit>().setSelectedItineraryFavorite(
        itinerary.isFavorite,
      );
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ChÃ†Â°a thÃ¡Â»Æ’ cÃ¡ÂºÂ­p nhÃ¡ÂºÂ­t yÃƒÂªu thÃƒÂ­ch, vui lÃƒÂ²ng thÃ¡Â»Â­ lÃ¡ÂºÂ¡i'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onEditTime(
    ItineraryActivityEntity activity,
    bool isStart,
    bool isLastInDay,
  ) async {
    final initialTimeStr = isStart ? activity.startTime : activity.endTime;
    final parts = initialTimeStr.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColorsExt.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null && mounted) {
      final newTime =
          '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
      final currentTime = isStart ? activity.startTime : activity.endTime;

      // Ã¢â€â‚¬Ã¢â€â‚¬ Validation: kiÃ¡Â»Æ’m tra tÃƒÂ­nh hÃ¡Â»Â£p lÃ¡Â»â€¡ trÃ†Â°Ã¡Â»â€ºc khi cho phÃƒÂ©p thay Ã„â€˜Ã¡Â»â€¢i Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      final newMin = pickedTime.hour * 60 + pickedTime.minute;

      int toMinutes(String t) {
        final p = t.split(':');
        return int.parse(p[0]) * 60 + int.parse(p[1]);
      }

      Future<void> showTimeError(String message) async {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                const SizedBox(width: 8),
                const Expanded(child: Text('ThÃ¡Â»Âi gian khÃƒÂ´ng hÃ¡Â»Â£p lÃ¡Â»â€¡')),
              ],
            ),
            content: Text(message),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Ã„ÂÃƒÂ£ hiÃ¡Â»Æ’u',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }

      if (isStart) {
        // Ã„Âang chÃ¡Â»â€°nh giÃ¡Â»Â Ã„ÂÃ¡ÂºÂ¾N Ã¢â€ â€™ phÃ¡ÂºÂ£i trÃ†Â°Ã¡Â»â€ºc giÃ¡Â»Â RÃ¡Â»Å“I hiÃ¡Â»â€¡n tÃ¡ÂºÂ¡i
        final endMin = toMinutes(activity.endTime);
        if (newMin >= endMin) {
          await showTimeError(
            'GiÃ¡Â»Â Ã„â€˜Ã¡ÂºÂ¿n ($newTime) phÃ¡ÂºÂ£i trÃ†Â°Ã¡Â»â€ºc giÃ¡Â»Â rÃ¡Â»Âi (${activity.endTime}) cÃ¡Â»Â§a cÃƒÂ¹ng Ã„â€˜Ã¡Â»â€¹a Ã„â€˜iÃ¡Â»Æ’m.\n\n'
            'Vui lÃƒÂ²ng chÃ¡Â»Ân lÃ¡ÂºÂ¡i thÃ¡Â»Âi gian.',
          );
          return; // KhÃƒÂ´ng ÃƒÂ¡p dÃ¡Â»Â¥ng thay Ã„â€˜Ã¡Â»â€¢i
        }
        if (endMin - newMin > 4 * 60) {
          await showTimeError(
            'KhoÃ¡ÂºÂ£ng thÃ¡Â»Âi gian tham quan quÃƒÂ¡ dÃƒÂ i (hÃ†Â¡n 4 tiÃ¡ÂºÂ¿ng).\n\n'
            'Vui lÃƒÂ²ng chÃ¡Â»Ân giÃ¡Â»Â Ã„â€˜Ã¡ÂºÂ¿n hÃ¡Â»Â£p lÃƒÂ½ hÃ†Â¡n.',
          );
          return;
        }
      } else {
        // Ã„Âang chÃ¡Â»â€°nh giÃ¡Â»Â RÃ¡Â»Å“I Ã¢â€ â€™ phÃ¡ÂºÂ£i sau giÃ¡Â»Â Ã„ÂÃ¡ÂºÂ¾N hiÃ¡Â»â€¡n tÃ¡ÂºÂ¡i
        final startMin = toMinutes(activity.startTime);
        if (newMin <= startMin) {
          await showTimeError(
            'GiÃ¡Â»Â rÃ¡Â»Âi ($newTime) phÃ¡ÂºÂ£i sau giÃ¡Â»Â Ã„â€˜Ã¡ÂºÂ¿n (${activity.startTime}) cÃ¡Â»Â§a cÃƒÂ¹ng Ã„â€˜Ã¡Â»â€¹a Ã„â€˜iÃ¡Â»Æ’m.\n\n'
            'Vui lÃƒÂ²ng chÃ¡Â»Ân lÃ¡ÂºÂ¡i thÃ¡Â»Âi gian.',
          );
          return; // KhÃƒÂ´ng ÃƒÂ¡p dÃ¡Â»Â¥ng thay Ã„â€˜Ã¡Â»â€¢i
        }
        if (newMin - startMin > 4 * 60) {
          await showTimeError(
            'KhoÃ¡ÂºÂ£ng thÃ¡Â»Âi gian tham quan quÃƒÂ¡ dÃƒÂ i (hÃ†Â¡n 4 tiÃ¡ÂºÂ¿ng).\n\n'
            'Vui lÃƒÂ²ng chÃ¡Â»Ân giÃ¡Â»Â rÃ¡Â»Âi hÃ¡Â»Â£p lÃƒÂ½ hÃ†Â¡n.',
          );
          return;
        }
      }
      // Ã¢â€â‚¬Ã¢â€â‚¬ Validate giÃ¡Â»Â mÃ¡Â»Å¸/Ã„â€˜ÃƒÂ³ng cÃ¡Â»Â­a cÃ¡Â»Â§a Ã„â€˜Ã¡Â»â€¹a Ã„â€˜iÃ¡Â»Æ’m Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
      if (activity.openHourCompressed != null) {
        final visitDate = _visitDateForDay(_selectedDay);
        if (visitDate != null) {
          final slot = _parseOpenSlot(activity.openHourCompressed!, visitDate);
          if (slot != null) {
            int toM(String t) {
              final p = t.split(':');
              return int.parse(p[0]) * 60 + int.parse(p[1]);
            }

            final openMin = toM(slot.$1);
            final closeMin = toM(slot.$2);
            final label = isStart ? 'Ã„â€˜Ã¡ÂºÂ¿n' : 'rÃ¡Â»Âi';
            if (newMin < openMin) {
              await showTimeError(
                '${activity.title} chÃ†Â°a mÃ¡Â»Å¸ cÃ¡Â»Â­a lÃƒÂºc $newTime.\n\n'
                'Ã„ÂÃ¡Â»â€¹a Ã„â€˜iÃ¡Â»Æ’m mÃ¡Â»Å¸ cÃ¡Â»Â­a tÃ¡Â»Â« ${slot.$1} Ã¢â‚¬â€œ ${slot.$2}. Vui lÃƒÂ²ng chÃ¡Â»Ân giÃ¡Â»Â $label sau ${slot.$1}.',
              );
              return;
            }
            if (newMin > closeMin) {
              await showTimeError(
                '${activity.title} Ã„â€˜ÃƒÂ£ Ã„â€˜ÃƒÂ³ng cÃ¡Â»Â­a lÃƒÂºc ${slot.$2}.\n\n'
                'GiÃ¡Â»Â $label $newTime vÃ†Â°Ã¡Â»Â£t quÃƒÂ¡ giÃ¡Â»Â Ã„â€˜ÃƒÂ³ng cÃ¡Â»Â­a. Vui lÃƒÂ²ng chÃ¡Â»Ân trÃ†Â°Ã¡Â»â€ºc ${slot.$2}.',
              );
              return;
            }
          }
        }
      }
      // Ã¢â€â‚¬Ã¢â€â‚¬ KÃ¡ÂºÂ¿t thÃƒÂºc validation Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

      if (newTime != currentTime) {
        final oldMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
        final deltaMin = newMin - oldMin;

        final bool hasSubsequent = !(isLastInDay && !isStart);

        if (hasSubsequent) {
          final timeLabel = isStart ? 'thÃ¡Â»Âi gian Ã„â€˜Ã¡ÂºÂ¿n' : 'thÃ¡Â»Âi gian rÃ¡Â»Âi';

          final bool? shouldAdjustSubsequent = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('TÃ¡Â»Â± Ã„â€˜Ã¡Â»â„¢ng Ã„â€˜iÃ¡Â»Âu chÃ¡Â»â€°nh thÃ¡Â»Âi gian?'),
              content: Text(
                'BÃ¡ÂºÂ¡n vÃ¡Â»Â«a thay Ã„â€˜Ã¡Â»â€¢i $timeLabel tÃ¡Â»Â« $currentTime sang $newTime (${deltaMin > 0 ? "+" : ""}$deltaMin phÃƒÂºt).\n\n'
                'BÃ¡ÂºÂ¡n cÃƒÂ³ muÃ¡Â»â€˜n tÃ¡Â»Â± Ã„â€˜Ã¡Â»â„¢ng Ã„â€˜iÃ¡Â»Âu chÃ¡Â»â€°nh (tÃ¡Â»â€¹nh tiÃ¡ÂºÂ¿n) cÃƒÂ¡c Ã„â€˜Ã¡Â»â€¹a Ã„â€˜iÃ¡Â»Æ’m phÃƒÂ­a sau khÃƒÂ´ng?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'KhÃƒÂ´ng',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'CÃƒÂ³',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );

          if (shouldAdjustSubsequent == true && mounted) {
            context.read<ItineraryCubit>().updateActivityTimesWithShift(
              activityId: activity.id,
              deltaMinutes: deltaMin,
              shiftStartTimeOnly: isStart,
            );
            return;
          }
        }
      }

      if (!mounted) return;
      context.read<ItineraryCubit>().updateActivityTimeSingle(
        activity.id,
        startTime: isStart ? newTime : null,
        endTime: isStart ? null : newTime,
      );
    }
  }

  void _onReplaceActivity(ItineraryActivityEntity activity) {
    List<String> existingIds = [];
    final state = context.read<ItineraryCubit>().state;
    if (state is ItineraryLoaded && state.selectedItinerary != null) {
      for (final day in state.selectedItinerary!.days) {
        for (final act in day.activities) {
          existingIds.add(act.id);
        }
      }
    }

    ReplacePlaceSheet.show(
      context,
      activity: activity,
      existingIds: existingIds,
      onReplace: (place) {
        context.read<ItineraryCubit>().replaceActivity(
          activity.id,
          place.id,
          place.name,
          newLat: place.latitude,
          newLng: place.longitude,
          newImageUrl: place.imageUrl,
          newRating: place.rating,
          newReviewCount: place.reviewCount,
          newAddress: place.address,
          newCategory: place.category,
        );
      },
    );
  }

  Future<void> _onRateActivity(ItineraryActivityEntity activity) async {
    if (_openingReviewActivityIds.contains(activity.id)) {
      return;
    }
    setState(() => _openingReviewActivityIds.add(activity.id));
    final reviewCubit = sl<ReviewCubit>();

    try {
      await reviewCubit.loadReviewData(widget.itineraryId);
      if (!mounted) return;

      final state = reviewCubit.state;
      if (state is! ReviewLoaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Khong the mo du lieu danh gia'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (!state.itinerary.locations.any((loc) => loc.id == activity.id)) {
        reviewCubit.ensureLocationAvailable(
          LocationReviewEntity(
            id: activity.id,
            placeId: activity.placeId,
            name: activity.title,
            imageUrl: activity.imageUrl,
            day: _selectedDay,
            isVisited: true,
            rating: activity.rating,
          ),
        );
      }
      final submitted = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PlaceReviewScreen(
            locationId: activity.id,
            reviewCubit: reviewCubit,
          ),
        ),
      );

      if (submitted == true) {
        await reviewCubit.submitReview(widget.itineraryId);
        if (!mounted) return;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ã„ÂÃƒÂ£ lÃ†Â°u Ã„â€˜ÃƒÂ¡nh giÃƒÂ¡ Ã„â€˜Ã¡Â»â€¹a Ã„â€˜iÃ¡Â»Æ’m'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('KhÃƒÂ´ng thÃ¡Â»Æ’ mÃ¡Â»Å¸ giao diÃ¡Â»â€¡n Ã„â€˜ÃƒÂ¡nh giÃƒÂ¡'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      await reviewCubit.close();
      if (mounted) {
        setState(() => _openingReviewActivityIds.remove(activity.id));
      }
    }
  }

  void _onDeleteActivity(ItineraryActivityEntity activity) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('XÃƒÂ³a Ã„â€˜Ã¡Â»â€¹a Ã„â€˜iÃ¡Â»Æ’m'),
        content: Text(
          'BÃ¡ÂºÂ¡n cÃƒÂ³ chÃ¡ÂºÂ¯c chÃ¡ÂºÂ¯n muÃ¡Â»â€˜n xÃƒÂ³a "${activity.title}" khÃ¡Â»Âi lÃ¡Â»â€¹ch trÃƒÂ¬nh khÃƒÂ´ng?',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.r16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'HÃ¡Â»Â§y',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ItineraryCubit>().deleteActivity(activity.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ã„ÂÃƒÂ£ xÃƒÂ³a ${activity.title}'),
                  backgroundColor: AppColorsExt.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'XÃƒÂ³a',
              style: TextStyle(
                color: AppColorsExt.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showShareSheet() {
    final invitedUsers = <String>{};
    final searchController = TextEditingController();
    var searchQuery = '';
    final users = <({String id, String name, String email, String avatar})>[
      (
        id: 'a',
        name: 'NguyÃ¡Â»â€¦n VÃ„Æ’n A',
        email: 'anv@example.com',
        avatar: 'https://i.pravatar.cc/150?u=a',
      ),
      (
        id: 'b',
        name: 'TrÃ¡ÂºÂ§n ThÃ¡Â»â€¹ B',
        email: 'btt@example.com',
        avatar: 'https://i.pravatar.cc/150?u=b',
      ),
      (
        id: 'c',
        name: 'LÃƒÂª VÃ„Æ’n C',
        email: 'clv@example.com',
        avatar: 'https://i.pravatar.cc/150?u=c',
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final normalizedQuery = searchQuery.trim().toLowerCase();
          final filteredUsers = normalizedQuery.isEmpty
              ? users
              : users.where((user) {
                  return user.name.toLowerCase().contains(normalizedQuery) ||
                      user.email.toLowerCase().contains(normalizedQuery);
                }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSizes.r32),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s24,
              vertical: AppSizes.s16,
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColorsExt.divider,
                    borderRadius: BorderRadius.circular(AppSizes.s2),
                  ),
                ),
                const SizedBox(height: AppSizes.s24),
                Text('Chia sÃ¡ÂºÂ» lÃ¡Â»â€¹ch trÃƒÂ¬nh', style: AppTextStyles.heading2),
                const SizedBox(height: AppSizes.s8),
                Text(
                  'MÃ¡Â»Âi bÃ¡ÂºÂ¡n bÃƒÂ¨ cÃƒÂ¹ng tham gia vÃƒÂ  chÃ¡Â»â€°nh sÃ¡Â»Â­a lÃ¡Â»â€¹ch trÃƒÂ¬nh chung cho chuyÃ¡ÂºÂ¿n Ã„â€˜i nÃƒÂ y.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.s24),
                TextField(
                  controller: searchController,
                  onChanged: (value) =>
                      setModalState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'TÃƒÂ¬m kiÃ¡ÂºÂ¿m qua tÃƒÂªn hoÃ¡ÂºÂ·c email...',
                    prefixIcon: const Icon(Icons.search, size: AppSizes.iconMd),
                    suffixIcon: searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              searchController.clear();
                              setModalState(() => searchQuery = '');
                            },
                          ),
                    filled: true,
                    fillColor: AppColorsExt.searchBarBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.r16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: AppSizes.s16,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.s24),
                Expanded(
                  child: filteredUsers.isEmpty
                      ? Center(
                          child: Text(
                            'KhÃƒÂ´ng tÃƒÂ¬m thÃ¡ÂºÂ¥y ngÃ†Â°Ã¡Â»Âi dÃƒÂ¹ng phÃƒÂ¹ hÃ¡Â»Â£p',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView(
                          children: filteredUsers
                              .map(
                                (user) => _shareUserItem(
                                  user.name,
                                  user.email,
                                  user.avatar,
                                  invitedUsers.contains(user.id),
                                  () => setModalState(
                                    () => invitedUsers.add(user.id),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(searchController.dispose);
  }

  Widget _shareUserItem(
    String name,
    String email,
    String avatar,
    bool isInvited,
    VoidCallback onInvite,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(avatar),
            radius: AppSizes.iconMd,
          ),
          const SizedBox(width: AppSizes.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  email,
                  style: AppTextStylesExt.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isInvited ? null : onInvite,
            style: ElevatedButton.styleFrom(
              backgroundColor: isInvited
                  ? AppColorsExt.divider
                  : AppColors.primary,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.r12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s16),
            ),
            child: Text(
              isInvited ? 'Ã„ÂÃƒÂ£ gÃ¡Â»Â­i' : 'GÃ¡Â»Â­i lÃ¡Â»Âi mÃ¡Â»Âi',
              style: AppTextStylesExt.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showReorderSuggestionBanner() {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s20,
          vertical: AppSizes.s8,
        ),
        content: const Text(
          'CÃƒÂ³ lÃ¡Â»â„¢ trÃƒÂ¬nh tÃ¡Â»â€˜i Ã†Â°u hÃ†Â¡n cho ngÃƒÂ y nÃƒÂ y. BÃ¡ÂºÂ¡n cÃƒÂ³ muÃ¡Â»â€˜n ÃƒÂ¡p dÃ¡Â»Â¥ng khÃƒÂ´ng?',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              context.read<ItineraryCubit>().dismissReorderSuggestion();
            },
            child: const Text(
              'GiÃ¡Â»Â¯ nguyÃƒÂªn',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              context.read<ItineraryCubit>().applySuggestedReorder();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Ã„ÂÃƒÂ£ ÃƒÂ¡p dÃ¡Â»Â¥ng lÃ¡Â»â„¢ trÃƒÂ¬nh tÃ¡Â»â€˜i Ã†Â°u!'),
                  backgroundColor: AppColorsExt.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.r12),
                  ),
                ),
              );
            },
            child: Text(
              'SÃ¡ÂºÂ¯p xÃ¡ÂºÂ¿p lÃ¡ÂºÂ¡i',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TrackingCubit, TrackingState>(
      listenWhen: (p, c) =>
          c.nearbyRestaurantName != null &&
          c.nearbyRestaurantName != p.nearbyRestaurantName,
      listener: (ctx, state) => _showFoodProximityPopup(ctx, state),
      child: BlocListener<ItineraryCubit, ItineraryState>(
        listenWhen: (prev, curr) {
          final hasSuggestion =
              curr is ItineraryLoaded && curr.suggestedDays != null;
          final wasNoSuggestion =
              prev is! ItineraryLoaded || prev.suggestedDays == null;
          return hasSuggestion && wasNoSuggestion;
        },
        listener: (context, _) => _showReorderSuggestionBanner(),
        child: Scaffold(
          body: _ItineraryDetailView(
            selectedDay: _selectedDay,
            isPublic: _isPublic,
            onDayChanged: _onDayChanged,
            onPublicChanged: (v) => setState(() => _isPublic = v),
            onAddPlaceTap: _showAddPlaceScreen,
            mapController: _mapController,
            onMapCreated: (controller) => _mapController = controller,
            isMapLoaded: _isMapLoaded,
            onLoadMapTap: () => setState(() => _isMapLoaded = true),
            scrollController: _scrollController,
            activityKeys: _activityKeys,
            onActivityTap: _zoomToActivity,
            onActivityLongPress: _navigateToPlaceDetail,
            onEditActivity: _onEditActivity,
            onReplaceActivity: _onReplaceActivity,
            onDeleteActivity: _onDeleteActivity,
            onRateActivity: _onRateActivity,
            openingReviewActivityIds: _openingReviewActivityIds,
            onEditTime: _onEditTime,
            onDirectionTap: _launchDirections,
            onShareTap: _showShareSheet,
            onFavoriteTap: _toggleItineraryFavorite,
            onMarkerTap: (id) => _scrollToActivity(id),
            highlightedActivityId: _highlightedActivityId,
            isEditMode: _isEditMode,
            onEditModeTap: _onEditModeTap,
            onDiscardTap: _onDiscardChanges,
          ),
        ),
      ),
    );
  }

  void _showFoodProximityPopup(BuildContext ctx, TrackingState state) {
    final name = state.nearbyRestaurantName ?? 'QuÃƒÂ¡n Ã„Æ’n gÃ¡ÂºÂ§n Ã„â€˜ÃƒÂ¢y';
    final detailId = state.nearbyRestaurantDetailId ?? '';
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PreOrderPopup(
        title: 'QuÃƒÂ¡n Ã„Æ’n gÃ¡ÂºÂ§n bÃ¡ÂºÂ¡n!',
        message:
            'BÃ¡ÂºÂ¡n Ã„â€˜ang trong bÃƒÂ¡n kÃƒÂ­nh ${TrackingConfig.foodProximityKm.toInt()} km. Ã„ÂÃ¡ÂºÂ·t trÃ†Â°Ã¡Â»â€ºc Ã„â€˜Ã¡Â»Æ’ khÃƒÂ´ng phÃ¡ÂºÂ£i chÃ¡Â»Â?',
        restaurantName: name,
        estimatedWaitMinutes: 15,
        rating: 0,
        reviewCount: 0,
        onOrderTap: () {
          Navigator.pop(ctx);
          ctx.read<TrackingCubit>().dismissNearbyRestaurant();
          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) =>
                  FoodMenuScreen(placeId: detailId, restaurantName: name),
            ),
          );
        },
        onSkipTap: () {
          Navigator.pop(ctx);
          ctx.read<TrackingCubit>().dismissNearbyRestaurant();
        },
      ),
    ).then((_) {
      // Ã„ÂÃƒÂ³ng popup Ã¢â€ â€™ dismiss Ã„â€˜Ã¡Â»Æ’ khÃƒÂ´ng hiÃ¡Â»â€¡n lÃ¡ÂºÂ¡i ngay
      if (ctx.mounted) {
        ctx.read<TrackingCubit>().dismissNearbyRestaurant();
      }
    });
  }
}

class _DayCostSummaryCard extends StatelessWidget {
  final ItineraryDayEntity day;
  final List<ItineraryActivityEntity> visitActivities;
  final bool Function(ItineraryActivityEntity activity) isHotelStart;

  const _DayCostSummaryCard({
    required this.day,
    required this.visitActivities,
    required this.isHotelStart,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    final hotelCost = day.activities
        .where(isHotelStart)
        .fold<double>(0, (sum, activity) => sum + activity.price);
    final placeCost = visitActivities.fold<double>(
      0,
      (sum, activity) => sum + activity.price,
    );
    final selfDriveCost = day.activities.fold<double>(
      0,
      (sum, activity) => sum + activity.transportCost,
    );
    final visitedCount = visitActivities
        .where((activity) => activity.status == ActivityStatus.daDi)
        .length;
    final totalCost = placeCost + hotelCost + selfDriveCost;

    String money(double value) => '${formatter.format(value)} ${day.currency}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Chi ph\u00ed trong ng\u00e0y',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Text(
                '$visitedCount/${visitActivities.length} \u0111\u00e3 \u0111i',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DayCostRow(
            icon: Icons.receipt_long_rounded,
            label: 'T\u1ed5ng ng\u00e0y',
            value: money(totalCost),
            color: const Color(0xFF10B981),
          ),
          _DayCostRow(
            icon: Icons.place_rounded,
            label: '\u0110\u1ecba \u0111i\u1ec3m & \u0103n u\u1ed1ng',
            value: money(placeCost),
            color: const Color(0xFFF59E0B),
          ),
          _DayCostRow(
            icon: Icons.hotel_rounded,
            label: 'L\u01b0u tr\u00fa',
            value: money(hotelCost),
            color: const Color(0xFF0F766E),
          ),
          _DayCostRow(
            icon: Icons.two_wheeler_rounded,
            label: 'X\u0103ng xe/t\u1ef1 t\u00fac',
            value: money(selfDriveCost),
            color: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }
}

class _DayCostRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DayCostRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _LazyMapPreview extends StatelessWidget {
  final ItineraryDayEntity day;
  final VoidCallback onLoadMapTap;

  const _LazyMapPreview({required this.day, required this.onLoadMapTap});

  @override
  Widget build(BuildContext context) {
    final pointCount = day.activities.where((activity) {
      final sameTime = activity.startTime == activity.endTime;
      final category = (activity.category ?? '').toLowerCase();
      final title = activity.title.toLowerCase();
      final isHotel =
          category.contains('lÃ†Â°u trÃƒÂº') ||
          category.contains('luu tru') ||
          category.contains('khÃƒÂ¡ch sÃ¡ÂºÂ¡n') ||
          category.contains('khach san') ||
          category.contains('hotel') ||
          title.contains('hotel') ||
          title.contains('khÃƒÂ¡ch sÃ¡ÂºÂ¡n') ||
          title.contains('khach san');
      return !(sameTime && isHotel);
    }).length;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.22,
              child: CustomPaint(painter: _MapPreviewGridPainter()),
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            top: MediaQuery.of(context).padding.top + 88,
            child: Container(
              height: 118,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.36),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
              ),
              child: const Center(
                child: Icon(
                  Icons.map_outlined,
                  size: 42,
                  color: Color(0xFF93C5FD),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: MediaQuery.of(context).padding.top + 220,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.route_rounded,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'NgÃƒÂ y ${day.dayNumber} Ã¢â‚¬Â¢ $pointCount Ã„â€˜iÃ¡Â»Æ’m / BÃ¡ÂºÂ£n Ã„â€˜Ã¡Â»â€œ sÃ¡ÂºÂ½ chÃ¡Â»â€° tÃ¡ÂºÂ£i khi bÃ¡ÂºÂ¡n cÃ¡ÂºÂ§n xem tuyÃ¡ÂºÂ¿n Ã„â€˜Ã†Â°Ã¡Â»Âng.',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: onLoadMapTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Xem',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPreviewGridPainter extends CustomPainter {
  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const gap = 42.0;
    for (double x = -gap; x < size.width + gap; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
    for (double y = 0; y < size.height + gap; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - size.width), paint);
    }

    final routePaint = Paint()
      ..color = const Color(0xFFF97316)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.25)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.18,
        size.width * 0.46,
        size.height * 0.48,
        size.width * 0.68,
        size.height * 0.38,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.32,
        size.width * 0.9,
        size.height * 0.55,
        size.width * 0.78,
        size.height * 0.7,
      );
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ItineraryDetailView extends StatelessWidget {
  final int selectedDay;
  final bool isPublic;
  final Function(int) onDayChanged;
  final Function(bool) onPublicChanged;
  final VoidCallback onAddPlaceTap;
  final MapboxMap? mapController;
  final Function(MapboxMap) onMapCreated;
  final bool isMapLoaded;
  final VoidCallback onLoadMapTap;
  final ScrollController scrollController;
  final Map<String, GlobalKey> activityKeys;
  final Function(ItineraryActivityEntity) onActivityTap;
  final Function(ItineraryActivityEntity) onActivityLongPress;
  final Function(ItineraryActivityEntity) onEditActivity;
  final Function(ItineraryActivityEntity) onReplaceActivity;
  final Function(ItineraryActivityEntity) onDeleteActivity;
  final Function(ItineraryActivityEntity) onRateActivity;
  final Set<String> openingReviewActivityIds;
  final Function(ItineraryActivityEntity, bool, bool) onEditTime;
  final Function(ItineraryActivityEntity, ItineraryActivityEntity)
  onDirectionTap;
  final VoidCallback onShareTap;
  final VoidCallback onFavoriteTap;
  final Function(String) onMarkerTap;
  final String? highlightedActivityId;
  final bool isEditMode;
  final VoidCallback onEditModeTap;
  final VoidCallback onDiscardTap;

  const _ItineraryDetailView({
    required this.selectedDay,
    required this.isPublic,
    required this.onDayChanged,
    required this.onPublicChanged,
    required this.onAddPlaceTap,
    this.mapController,
    required this.onMapCreated,
    required this.isMapLoaded,
    required this.onLoadMapTap,
    required this.scrollController,
    required this.activityKeys,
    required this.onActivityTap,
    required this.onActivityLongPress,
    required this.onEditActivity,
    required this.onReplaceActivity,
    required this.onDeleteActivity,
    required this.onRateActivity,
    required this.openingReviewActivityIds,
    required this.onEditTime,
    required this.onDirectionTap,
    required this.onShareTap,
    required this.onFavoriteTap,
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
                      child: Text('ThÃ¡Â»Â­ lÃ¡ÂºÂ¡i'),
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
            final canReview = _canReviewItinerary(itin);

            return Stack(
              children: [
                // Ã¢Å“â€¦ MAP CHIÃ¡ÂºÂ¾M TOÃƒâ‚¬N MÃƒâ‚¬N HÃƒÅ’NH (full-screen, tÃ†Â°Ã†Â¡ng tÃƒÂ¡c hoÃƒÂ n toÃƒÂ n)
                Positioned.fill(
                  child: isMapLoaded
                      ? ItineraryMapView(
                          activities: currentDayData.activities,
                          allDays: itin.days,
                          selectedDay: selectedDay,
                          onMarkerTap: onMarkerTap,
                          onMapCreated: onMapCreated,
                        )
                      : _LazyMapPreview(
                          day: currentDayData,
                          onLoadMapTap: onLoadMapTap,
                        ),
                ),

                // Ã¢Å“â€¦ BOTTOM SHEET KÃƒâ€°O LÃƒÅ N/XUÃ¡Â»ÂNG (DraggableScrollableSheet)
                DraggableScrollableSheet(
                  initialChildSize: 0.45, // MÃ¡Â»Å¸ 45% mÃƒÂ n hÃƒÂ¬nh ban Ã„â€˜Ã¡ÂºÂ§u
                  minChildSize: 0.12, // Thu nhÃ¡Â»Â tÃ¡Â»â€˜i Ã„â€˜a Ã¢â€ â€™ gÃ¡ÂºÂ§n nhÃ†Â° chÃ¡Â»â€° thÃ¡ÂºÂ¥y map
                  maxChildSize: 0.85, // MÃ¡Â»Å¸ rÃ¡Â»â„¢ng tÃ¡Â»â€˜i Ã„â€˜a Ã¢â€ â€™ che gÃ¡ÂºÂ§n hÃ¡ÂºÂ¿t map
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
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Thanh kÃƒÂ©o (drag handle)
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
                          // NÃ¡Â»â„¢i dung cuÃ¡Â»â„¢n Ã„â€˜Ã†Â°Ã¡Â»Â£c
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

                // Ã¢Å“â€¦ FLOATING BUTTONS (Back, Share, Rate) Ã¡Â»Å¸ trÃƒÂªn cÃƒÂ¹ng
                Positioned(
                  top: MediaQuery.of(context).padding.top + AppSizes.s12,
                  left: AppSizes.s20,
                  right: AppSizes.s20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _floatingCircleButton(
                        Icons.arrow_back_ios_new,
                        () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PublicVisibilitySwitch(
                            value: itin.isPublic,
                            dark: true,
                            borderless: true,
                            onChanged: (value) =>
                                _confirmVisibilityChange(context, itin, value),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isEditMode) ...[
                                _floatingCircleButton(
                                  Icons.close_rounded,
                                  onDiscardTap,
                                  iconColor: const Color(0xFFEF4444),
                                ),
                                const SizedBox(width: AppSizes.s12),
                              ],
                              if (canReview) ...[
                                _floatingCircleButton(Icons.star_outline_rounded, () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => ItineraryRatingPopup(
                                      itineraryId: itin.id,
                                      itineraryTitle: itin.title,
                                      totalLocations: itin.totalLocations,
                                      visitedLocations: itin.visitedLocations,
                                    ),
                                  );
                                }),
                                const SizedBox(width: AppSizes.s12),
                              ],
                              _floatingCircleButton(
                                isEditMode ? Icons.check_rounded : Icons.edit_outlined,
                                onEditModeTap,
                                active: isEditMode,
                              ),
                              if (!isEditMode) ...[
                                if (itin.isPublic) ...[
                                  const SizedBox(width: AppSizes.s12),
                                  _floatingCircleButton(
                                    itin.isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    onFavoriteTap,
                                    iconColor: itin.isFavorite
                                        ? Colors.redAccent
                                        : Colors.white,
                                  ),
                                ],
                                const SizedBox(width: AppSizes.s12),
                                _floatingCircleButton(Icons.share_outlined, onShareTap),
                              ],
                            ],
                          ),
                        ],
                      ),
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

  Future<void> _confirmVisibilityChange(
    BuildContext context,
    ItineraryDetailEntity itin,
    bool nextValue,
  ) async {
    if (nextValue == itin.isPublic) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          nextValue ? 'CÃƒÂ´ng khai lÃ¡Â»â€¹ch trÃƒÂ¬nh?' : 'ChuyÃ¡Â»Æ’n vÃ¡Â»Â riÃƒÂªng tÃ†Â°?',
        ),
        content: Text(
          nextValue
              ? 'LÃ¡Â»â€¹ch trÃƒÂ¬nh sÃ¡ÂºÂ½ hiÃ¡Â»Æ’n thÃ¡Â»â€¹ trong khu vÃ¡Â»Â±c khÃƒÂ¡m phÃƒÂ¡ cÃƒÂ´ng khai.'
              : 'NgÃ†Â°Ã¡Â»Âi khÃƒÂ¡c sÃ¡ÂºÂ½ khÃƒÂ´ng cÃƒÂ²n thÃ¡ÂºÂ¥y lÃ¡Â»â€¹ch trÃƒÂ¬nh nÃƒÂ y trong khu vÃ¡Â»Â±c cÃƒÂ´ng khai.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('HÃ¡Â»Â§y'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('XÃƒÂ¡c nhÃ¡ÂºÂ­n'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<ItineraryCubit>().toggleVisibility(itin.id, nextValue);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextValue
                ? 'Ã„ÂÃƒÂ£ cÃƒÂ´ng khai lÃ¡Â»â€¹ch trÃƒÂ¬nh'
                : 'Ã„ÂÃƒÂ£ chuyÃ¡Â»Æ’n lÃ¡Â»â€¹ch trÃƒÂ¬nh vÃ¡Â»Â riÃƒÂªng tÃ†Â°',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('KhÃƒÂ´ng thÃ¡Â»Æ’ cÃ¡ÂºÂ­p nhÃ¡ÂºÂ­t trÃ¡ÂºÂ¡ng thÃƒÂ¡i cÃƒÂ´ng khai'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _canReviewItinerary(ItineraryDetailEntity itin) {
    return itin.status.toUpperCase() == 'COMPLETED';
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
          const SizedBox(height: AppSizes.s8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: displayDays
                  .map<Widget>(
                    (day) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: DaySelectorChip(
                        dayNumber: day.dayNumber,
                        locationCount: day.locationsCount,
                        dateLabel: _formatShortDate(
                          itin.startDate.add(Duration(days: day.dayNumber - 1)),
                        ),
                        isSelected: selectedDay == day.dayNumber,
                        onTap: () => onDayChanged(day.dayNumber),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$destinationCount Ã„â€˜iÃ¡Â»Æ’m trong ngÃƒÂ y',
            style: AppTextStylesExt.bodyMedium.copyWith(
              color: const Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.s12),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onAddPlaceTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.24),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'ThÃƒÂªm Ã„â€˜Ã¡Â»â€¹a Ã„â€˜iÃ¡Â»Æ’m',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.s16),
          _DayCostSummaryCard(
            day: currentDayData,
            visitActivities: _visitActivities(currentDayData),
            isHotelStart: _isHotelStart,
          ),
          const SizedBox(height: AppSizes.s16),
          TrackingSection(
            itineraryId: itin.id,
            date: currentDayData.date,
            itineraryStatus: itin.status,
            activities: currentDayData.activities,
            showStartButton: false,
            dbTrackingActive: itin.trackingActive,
            onStopped: () => context
                .read<ItineraryCubit>()
                .toggleItineraryStatus(itin.id, false),
          ),
          // DÃƒÂ¹ng Builder Ã„â€˜Ã¡Â»Æ’ Ã„â€˜Ã¡Â»Âc TrackingCubit (Ã„â€˜Ã†Â°Ã¡Â»Â£c provide Ã¡Â»Å¸ ItineraryDetailScreen)
          // vÃƒÂ  truyÃ¡Â»Ân trackingStatus cho tÃ¡Â»Â«ng TimelineActivityCard.
          Builder(
            builder: (context) {
              final tracking = context.watch<TrackingCubit>().state;
              final activities = visibleActivities;
              return Column(
                children: activities.asMap().entries.map((entry) {
                  final index = entry.key;
                  final activity = entry.value;
                  final key = activityKeys.putIfAbsent(
                    activity.id,
                    () => GlobalKey(),
                  );
                  final nextActivity = index < activities.length - 1
                      ? activities[index + 1]
                      : null;
                  final nextTransport = nextActivity == null
                      ? null
                      : (activities[index].transportInfo?.isNotEmpty == true
                            ? activities[index].transportInfo
                            : _estimateTransit(
                                activity.latitude,
                                activity.longitude,
                                nextActivity.latitude,
                                nextActivity.longitude,
                              ));
                  final TrackingPlaceStatus? trackingStatus = tracking.isActive
                      ? tracking.byDetailId(activity.id)
                      : null;
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
                    onRateTap: () => onRateActivity(
                      trackingStatus?.status == VisitStatus.visited
                          ? activity.copyWith(status: ActivityStatus.daDi)
                          : activity,
                    ),
                    isOpeningReview: openingReviewActivityIds.contains(
                      activity.id,
                    ),
                    onCardTap: () => onActivityTap(activity),
                    onCardLongPress: () => onActivityLongPress(activity),
                    onViewDetailTap: () => onActivityLongPress(activity),
                    isHighlighted: highlightedActivityId == activity.id,
                    onStartTimeTap: () => onEditTime(
                      activity,
                      true,
                      index == activities.length - 1,
                    ),
                    onEndTimeTap: () => onEditTime(
                      activity,
                      false,
                      index == activities.length - 1,
                    ),
                    isEditMode: isEditMode,
                    onDirectionTap: nextActivity != null
                        ? () => onDirectionTap(activity, nextActivity)
                        : null,
                    trackingStatus: trackingStatus,
                    onCheckIn: trackingStatus != null
                        ? () => context.read<TrackingCubit>().manualCheckIn(
                            activity.id,
                          )
                        : null,
                    isCheckingIn: tracking.checkingInDetailId == activity.id,
                  );
                }).toList(),
              );
            },
          ),
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
        (category.contains('lÃ†Â°u trÃƒÂº') ||
            category.contains('luu tru') ||
            category.contains('khÃƒÂ¡ch sÃ¡ÂºÂ¡n') ||
            category.contains('khach san') ||
            category.contains('hotel') ||
            title.contains('hotel') ||
            title.contains('khÃƒÂ¡ch sÃ¡ÂºÂ¡n') ||
            title.contains('khach san'));
  }

  String _formatShortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  // Ã†Â¯Ã¡Â»â€ºc tÃƒÂ­nh thÃ¡Â»Âi gian di chuyÃ¡Â»Æ’n tÃ¡Â»Â« tÃ¡Â»Âa Ã„â€˜Ã¡Â»â„¢ (Haversine + tÃ¡Â»â€˜c Ã„â€˜Ã¡Â»â„¢ 25 km/h)
  static String _estimateTransit(
    double? lat1,
    double? lng1,
    double? lat2,
    double? lng2,
  ) {
    if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) {
      return 'Di chuyÃ¡Â»Æ’n Ã„â€˜Ã¡ÂºÂ¿n Ã„â€˜iÃ¡Â»Æ’m tiÃ¡ÂºÂ¿p theo';
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
    if (mins < 60) return '~$mins phÃƒÂºt di chuyÃ¡Â»Æ’n';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '~$h giÃ¡Â»Â di chuyÃ¡Â»Æ’n' : '~$h giÃ¡Â»Â $m phÃƒÂºt di chuyÃ¡Â»Æ’n';
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
