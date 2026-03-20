import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/budget_summary_section.dart';
import '../widgets/destination_summary_card.dart';
import '../widgets/important_notes_card.dart';
import '../widgets/short_itinerary_list.dart';
import '../widgets/trip_stats_grid.dart';

class TripSummaryScreen extends StatelessWidget {
  const TripSummaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(), // Pop to home
        ),
        title: const Text(
          'Tóm tắt lịch trình',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {
              // Action menu
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DestinationSummaryCard(
              destination: 'Hà Nội',
              dates: '15 Th10 - 20 Th10, 2023',
            ),
            const SizedBox(height: 32),
            const Text(
              'Thống kê của lịch trình',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const TripStatsGrid(),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lịch trình rút gọn',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Xem chi tiết',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const ShortItineraryList(),
            const SizedBox(height: 32),
            const BudgetSummarySection(),
            const SizedBox(height: 32),
            const ImportantNotesCard(),
            const SizedBox(height: 60), // Spacing below
          ],
        ),
      ),
    );
  }
}
