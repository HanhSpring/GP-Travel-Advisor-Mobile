import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../features/profile/domain/entities/activity_item_entity.dart';
import '../../../../features/profile/domain/entities/profile_entity.dart';
import '../../../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../../../features/profile/presentation/cubit/profile_state.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.85,
      child: BlocProvider(
        create: (_) => sl<ProfileCubit>()..loadProfile(),
        child: const _DrawerContent(),
      ),
    );
  }
}

class _DrawerContent extends StatelessWidget {
  const _DrawerContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading || state is ProfileInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ProfileError) {
          return Center(child: Text(state.message));
        }
        if (state is ProfileLoaded) {
          return _buildBody(context, state.profile, state.activities);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBody(
      BuildContext context, ProfileEntity profile, List<ActivityItemEntity> activities) {
    final itineraryItems =
        activities.where((a) => a.type == ActivityType.itinerary).toList();
    final ratedItems = activities.where((a) => a.type == ActivityType.rated).toList();
    final pendingItems =
        activities.where((a) => a.type == ActivityType.reviewPending).toList();
    final foodItems = activities.where((a) => a.type == ActivityType.food).toList();

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.blobLight, width: 2),
                    ),
                    child: const Icon(Icons.person_outline,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1E))),
                      const SizedBox(height: 4),
                      Text(profile.membershipTier,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280))),
                    ],
                  )
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 20),

            // Lịch trình
            _SectionTitle(title: 'LỊCH TRÌNH & ĐỊA ĐIỂM', color: AppColors.primary),
            const SizedBox(height: 12),
            const _HighlightTile(
                icon: Icons.calendar_today_outlined, label: 'Địa điểm sắp đến'),
            ...itineraryItems
                .map((e) => _ActivityTile(item: e, icon: Icons.bed_outlined)),
            const SizedBox(height: 24),

            // Đánh giá
            _SectionTitle(
                title: 'ĐỊA ĐIỂM ĐÃ ĐÁNH GIÁ', color: Colors.grey.shade500),
            const SizedBox(height: 12),
            const _HighlightTile(
                icon: Icons.star_border_rounded, label: 'Đã đánh giá'),
            ...ratedItems.map((e) => _ActivityTile(
                item: e, icon: Icons.location_on_outlined)),
            const SizedBox(height: 8),

            _MenuTile(
                icon: Icons.map_outlined,
                label: 'Địa điểm chờ đánh giá',
                badge: profile.reviewPendingCount),
            ...pendingItems
                .map((e) => _ActivityTile(item: e, icon: Icons.image_outlined)),
            const SizedBox(height: 24),

            // Ẩm thực
            _SectionTitle(title: 'ẨM THỰC ĐÃ ĐẶT', color: Colors.grey.shade500),
            const SizedBox(height: 12),
            const _MenuTile(icon: Icons.restaurant_outlined, label: 'Đơn hàng của tôi'),
            ...foodItems.map((e) => _FoodOrderCard(item: e)),

            const Divider(height: 32, color: Color(0xFFF3F4F6)),
            const _MenuTile(
                icon: Icons.settings_outlined, label: 'Cài đặt tài khoản'),
            const _MenuTile(icon:Icons.exit_to_app_rounded, label: 'Đăng xuất'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: color),
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HighlightTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.blobLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? badge;
  const _MenuTile({required this.icon, required this.label, this.badge});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4B5563))),
          ),
          if (badge != null && badge! > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                badge.toString(),
                style: const TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityItemEntity item;
  final IconData icon;
  const _ActivityTile({required this.item, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.grey.shade600, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1E))),
                const SizedBox(height: 4),
                if (item.status == ActivityStatus.pendingReview)
                  Row(
                    children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: Colors.green, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('Chờ bạn chia sẻ',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.primary)),
                    ],
                  )
                else
                  Row(
                    children: [
                      if (item.rating != null) ...[
                        const Icon(Icons.star_rounded,
                            size: 14, color: Color(0xFFFFA500)),
                        const SizedBox(width: 4),
                        Text(item.rating.toString(),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        const Text('•',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(width: 8),
                      ],
                      if (item.date != null)
                        Text(DateFormat('dd/MM/yyyy').format(item.date!),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                    ],
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _FoodOrderCard extends StatelessWidget {
  final ActivityItemEntity item;
  const _FoodOrderCard({required this.item});

  @override
  Widget build(BuildContext context) {
    String statusText = '';
    Color statusBgColor = Colors.transparent;
    Color statusTextColor = Colors.transparent;

    if (item.status == ActivityStatus.preparing) {
      statusText = 'Đang chuẩn bị';
      statusBgColor = AppColors.blobLight.withValues(alpha: 0.3);
      statusTextColor = AppColors.primary;
    } else if (item.status == ActivityStatus.delivered) {
      statusText = 'Đã giao';
      statusBgColor = Colors.transparent;
      statusTextColor = Colors.grey.shade500;
    }

    final isPreparing = item.status == ActivityStatus.preparing;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPreparing
                  ? AppColors.blobLight.withValues(alpha: 0.2)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPreparing
                  ? Icons.shopping_bag_outlined
                  : Icons.check_circle_outline,
              color: isPreparing ? AppColors.primary : Colors.grey.shade500,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1E))),
                const SizedBox(height: 2),
                Text(item.code ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          if (statusText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 10,
                  color: statusTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
        ],
      ),
    );
  }
}
