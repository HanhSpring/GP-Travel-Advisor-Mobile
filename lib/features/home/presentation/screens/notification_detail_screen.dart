import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_theme.dart';
import 'package:travel_advisor_mobile/features/home/domain/entities/notification_entity.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/notification_cubit.dart';
import 'package:travel_advisor_mobile/features/home/presentation/cubit/notification_state.dart';

class NotificationDetailScreen extends StatelessWidget {
  final String notificationId;
  final NotificationEntity? initialNotification;

  const NotificationDetailScreen({
    super.key,
    required this.notificationId,
    this.initialNotification,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<NotificationCubit>()..loadNotificationDetail(notificationId),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Chi tiết thông báo'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            final notification = state is NotificationDetailLoaded
                ? state.notification
                : initialNotification;

            if (notification == null &&
                (state is NotificationLoading ||
                    state is NotificationInitial)) {
              return const Center(child: CircularProgressIndicator());
            }

            if (notification == null && state is NotificationError) {
              return _DetailMessage(
                icon: Icons.error_outline,
                message: state.message,
              );
            }

            if (notification == null) {
              return const _DetailMessage(
                icon: Icons.notifications_none,
                message: 'Không tìm thấy thông báo.',
              );
            }

            return RefreshIndicator(
              onRefresh: () => context
                  .read<NotificationCubit>()
                  .loadNotificationDetail(notification.id),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.s24,
                  AppSizes.s16,
                  AppSizes.s24,
                  AppSizes.s32,
                ),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _iconColorFor(
                            notification.notificationType,
                          ).withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _iconFor(notification.iconKey),
                          color: _iconColorFor(notification.notificationType),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSizes.s16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: AppTextStyles.heading2.copyWith(
                                fontSize: 22,
                                color: AppColorsExt.textDark,
                              ),
                            ),
                            const SizedBox(height: AppSizes.s8),
                            Text(
                              notification.timeLabel,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.s24),
                  const Divider(height: 1),
                  const SizedBox(height: AppSizes.s24),
                  Text(
                    notification.content,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 16,
                      height: 1.55,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (state is NotificationLoading) ...[
                    const SizedBox(height: AppSizes.s24),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _iconFor(String key) {
    final lowerKey = key.toLowerCase();
    if (lowerKey.contains('map')) {
      return Icons.map;
    } else if (lowerKey.contains('star')) {
      return Icons.star;
    } else if (lowerKey.contains('restaurant') || lowerKey.contains('food')) {
      return Icons.restaurant;
    } else if (lowerKey.contains('info')) {
      return Icons.info;
    }
    return Icons.notifications;
  }

  Color _iconColorFor(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains('review')) {
      return Colors.orange;
    } else if (lowerType.contains('food')) {
      return Colors.red;
    } else if (lowerType.contains('itinerary') || lowerType.contains('trip')) {
      return AppColors.primary;
    }
    return Colors.grey;
  }
}

class _DetailMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _DetailMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: AppSizes.s12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
