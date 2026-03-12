import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TripStatsGrid extends StatelessWidget {
  const TripStatsGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = (constraints.maxWidth - 16) / 2;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _StatCard(
              width: width,
              title: '6 Ngày',
              subtitle: 'Thời gian',
              iconData: Icons.calendar_today,
              color: Colors.blue,
              bgIconColor: Colors.blue.withOpacity(0.1),
            ),
            _StatCard(
              width: width,
              title: '12 Hoạt động',
              subtitle: 'Đã lên kế hoạch',
              iconData: Icons.local_activity,
              color: Colors.orange,
              bgIconColor: Colors.orange.withOpacity(0.1),
            ),
            _StatCard(
              width: width,
              title: '2 Khách sạn',
              subtitle: 'Chỗ ở',
              iconData: Icons.hotel,
              color: Colors.pink,
              bgIconColor: Colors.pink.withOpacity(0.1),
            ),
            _StatCard(
              width: width,
              title: '5 Lượt',
              subtitle: 'Di chuyển',
              iconData: Icons.directions_car,
              color: Colors.teal,
              bgIconColor: Colors.teal.withOpacity(0.1),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final String title;
  final String subtitle;
  final IconData iconData;
  final Color color;
  final Color bgIconColor;

  const _StatCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.iconData,
    required this.color,
    required this.bgIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgIconColor,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
