import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ShortItineraryList extends StatelessWidget {
  const ShortItineraryList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: const [
          _ItineraryItem(
            date: 'Ngày 1 • 15 Th10',
            title: 'Đến nơi & Nhận phòng',
            iconData: Icons.flight_land,
            iconColor: Colors.blueGrey,
          ),
          Divider(height: 1, indent: 64, endIndent: 16),
          _ItineraryItem(
            date: 'Ngày 2 • 16 Th10',
            title: 'Khám phá Hồ Gươm & Lăng Bác',
            iconData: Icons.camera_alt,
            iconColor: Colors.teal,
          ),
          Divider(height: 1, indent: 64, endIndent: 16),
          _ItineraryItem(
            date: 'Ngày 3 • 17 Th10',
            title: 'Tham quan Đền chùa & Văn hóa',
            iconData: Icons.temple_buddhist,
            iconColor: Colors.redAccent,
          ),
          Divider(height: 1, indent: 64, endIndent: 16),
          _ItineraryItem(
            date: 'Ngày 4 • 18 Th10',
            title: 'Mua sắm tại Aeon Mall Long Biên',
            iconData: Icons.shopping_bag,
            iconColor: Colors.pinkAccent,
          ),
          Divider(height: 1, indent: 64, endIndent: 16),
          _ItineraryItem(
            date: 'Ngày 5 • 19 Th10',
            title: 'Nhà tù Hoả Lò & Chợ Đồng Xuân',
            iconData: Icons.star,
            iconColor: Colors.orange,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _ItineraryItem extends StatelessWidget {
  final String date;
  final String title;
  final IconData iconData;
  final Color iconColor;
  final bool isLast;

  const _ItineraryItem({
    required this.date,
    required this.title,
    required this.iconData,
    required this.iconColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(iconData, color: iconColor, size: 20),
      ),
      title: Text(
        date,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
    );
  }
}
