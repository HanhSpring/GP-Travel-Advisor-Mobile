import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/core/error/region_allocation_required_exception.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/features/trip_planner/domain/usecases/create_itinerary_usecase.dart';
import 'package:travel_advisor_mobile/features/trip_planner/presentation/cubit/trip_planner_cubit.dart';

/// Wizard phân bổ vùng: sau khi backend phân cụm địa lý xong, người dùng
/// xem trước từng vùng (kèm vài địa điểm mẫu) và tự chọn số ngày muốn dành
/// cho vùng đó bằng stepper (-0+), giới hạn 0..maxDays. Nút "Tạo lịch trình"
/// chỉ bật khi tổng số ngày đã phân bổ khớp đúng tổng số ngày chuyến đi.
class TripPlannerRegionAllocationScreen extends StatefulWidget {
  final String message;
  final List<RegionInfo> regions;
  final int numDays;

  const TripPlannerRegionAllocationScreen({
    super.key,
    required this.message,
    required this.regions,
    required this.numDays,
  });

  @override
  State<TripPlannerRegionAllocationScreen> createState() =>
      _TripPlannerRegionAllocationScreenState();
}

class _TripPlannerRegionAllocationScreenState
    extends State<TripPlannerRegionAllocationScreen> {
  late final Map<RegionInfo, int> _days;

  @override
  void initState() {
    super.initState();
    _days = {for (final r in widget.regions) r: 0};
    // Mặc định điền sẵn Vùng Trung Tâm (nhiều POI nhất) cho vừa đủ số ngày —
    // trường hợp phổ biến nhất (chỉ 1 vùng) sẽ tự khớp tổng ngay từ đầu.
    if (widget.regions.isNotEmpty) {
      final central = widget.regions.first;
      _days[central] = central.maxDays.clamp(0, widget.numDays);
    }
  }

  int get _totalAllocated => _days.values.fold(0, (a, b) => a + b);

  bool get _canSubmit => _totalAllocated == widget.numDays;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Phân bổ vùng tham quan',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                ...widget.regions.map(_buildRegionCard),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildRegionCard(RegionInfo region) {
    final days = _days[region] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                region.regionName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (region.isRemote)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Ở xa',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB45309),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text('${region.placeIds.length} địa điểm'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: region.placeNames
                  .take(6)
                  .map(
                    (name) => Chip(
                      label: Text(name, style: const TextStyle(fontSize: 12)),
                      backgroundColor: const Color(0xFFF8FAFC),
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Địa điểm này có thể đi nhiều nhất trong ${region.maxDays} ngày',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Số ngày dành cho vùng này',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              _buildStepper(region, days),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(RegionInfo region, int days) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepperButton(
          icon: Icons.remove,
          enabled: days > 0,
          onTap: () => _updateDays(region, days - 1),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$days',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _stepperButton(
          icon: Icons.add,
          enabled: days < region.maxDays,
          onTap: () => _updateDays(region, days + 1),
        ),
      ],
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : const Color(0xFFE2E8F0),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  Future<void> _updateDays(RegionInfo region, int newDays) async {
    final previous = Map<RegionInfo, int>.from(_days);

    if (newDays > 1 && region.isRemote) {
      final confirmed = await _confirmWarning(
        title: 'Vùng ở xa trung tâm',
        message: _roundTripWarning(region),
      );
      if (confirmed != true) return;
    }

    setState(() => _days[region] = newDays);

    final crossWarning = _crossRegionWarning();
    if (crossWarning != null) {
      final confirmed = await _confirmWarning(
        title: 'Cân nhắc trước khi chọn nhiều vùng xa',
        message: crossWarning,
      );
      if (confirmed != true) {
        setState(() => _days
          ..clear()
          ..addAll(previous));
      }
    }
  }

  String _roundTripWarning(RegionInfo region) {
    final oneWayHours = (region.travelMinutesFromCentral / 60).toStringAsFixed(1);
    final roundTripHours =
        (region.travelMinutesFromCentral * 2 / 60).toStringAsFixed(1);
    return 'Vùng này cách khu vực trung tâm khoảng $oneWayHours giờ di chuyển '
        'một chiều. Hệ thống chỉ hỗ trợ 1 khách sạn duy nhất, nên nếu chọn '
        'nhiều hơn 1 ngày ở đây, mỗi ngày bạn sẽ phải di chuyển khứ hồi '
        'khoảng $roundTripHours giờ.';
  }

  /// Nếu người dùng chọn ≥2 vùng ở xa với số lượng địa điểm không quá chênh
  /// lệch (không vùng nào áp đảo), việc đặt 1 khách sạn duy nhất sẽ bất lợi
  /// cho cả 2 — cảnh báo rõ trước khi họ tiếp tục.
  String? _crossRegionWarning() {
    final selectedRemote = widget.regions
        .where((r) => r.isRemote && (_days[r] ?? 0) > 0)
        .toList();
    if (selectedRemote.length < 2) return null;

    for (var i = 0; i < selectedRemote.length; i++) {
      for (var j = i + 1; j < selectedRemote.length; j++) {
        final countA = selectedRemote[i].placeIds.length;
        final countB = selectedRemote[j].placeIds.length;
        if (countA == 0 || countB == 0) continue;
        final ratio = countA > countB ? countA / countB : countB / countA;
        if (ratio < 1.5) {
          return 'Bạn đang chọn nhiều vùng ở xa nhau (${selectedRemote[i].regionName}, '
              '${selectedRemote[j].regionName}) với số địa điểm gần tương đương — '
              'không có vùng nào đủ nổi bật để đặt khách sạn thuận tiện cho cả 2. '
              'Vì hệ thống chỉ hỗ trợ 1 khách sạn duy nhất, việc di chuyển giữa '
              'khách sạn và cả 2 vùng này có thể khá bất tiện.';
        }
      }
    }
    return null;
  }

  Future<bool?> _confirmWarning({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Chỉnh lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Tôi hiểu, tiếp tục'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Đã phân bổ: $_totalAllocated/${widget.numDays} ngày',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _canSubmit
                    ? const Color(0xFF16A34A)
                    : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _canSubmit
                ? () => context.read<TripPlannerCubit>().submitRegionAllocations(
                      widget.regions
                          .where((r) => (_days[r] ?? 0) > 0)
                          .map(
                            (r) => RegionAllocationInput(
                              placeIds: r.placeIds,
                              days: _days[r] ?? 0,
                            ),
                          )
                          .toList(),
                    )
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Tạo lịch trình',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
