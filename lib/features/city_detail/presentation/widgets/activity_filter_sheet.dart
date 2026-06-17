import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/utils/input_formatter.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/entities/filter_enums.dart';
import 'filter_shared.dart';

class ActivityFilterSheet extends StatefulWidget {
  final ActivityFilter currentFilter;
  final ValueChanged<ActivityFilter> onApply;

  const ActivityFilterSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<ActivityFilterSheet> createState() => _ActivityFilterSheetState();
}

class _ActivityFilterSheetState extends State<ActivityFilterSheet> {
  late Set<ActivityCategory> _categories;
  late ActivityPriceType _priceType;
  late SortOption _sortOption;
  late String? _district;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _districts = [
    'Quận 1',
    'Quận 3',
    'Quận 5',
    'Quận 7',
    'Quận 10',
    'Quận 11',
    'Thủ Đức',
    'Bình Thạnh',
  ];

  @override
  void initState() {
    super.initState();
    _categories = Set.from(widget.currentFilter.categories);
    _priceType = widget.currentFilter.priceType;
    _sortOption = widget.currentFilter.sortOption;
    _district = widget.currentFilter.district;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _categories = {};
      _priceType = ActivityPriceType.all;
      _sortOption = SortOption.none;
      _district = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  String _getCategoryEmoji(ActivityCategory category) {
    switch (category) {
      case ActivityCategory.culturalHistory:
        return '📜';
      case ActivityCategory.nature:
        return '🌲';
      case ActivityCategory.entertainment:
        return '🎭';
      case ActivityCategory.restaurant:
        return '🍽️';
      case ActivityCategory.attractions:
        return '📍';
      case ActivityCategory.cafe:
        return '☕';
      case ActivityCategory.photoSpot:
        return '📸';
      case ActivityCategory.museum:
        return '🏛️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Bộ lọc',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SectionTitle('Loại hình địa điểm'),
                    
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm bảo tàng, quán cà phê, v.v.',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                        fillColor: AppColors.inputFill,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category List
                    ...ActivityCategory.values
                        .where((cat) => cat.label.toLowerCase().contains(_searchQuery.toLowerCase()))
                        .map((cat) {
                      final isSelected = _categories.contains(cat);
                      return ListTile(
                        leading: Text(
                          _getCategoryEmoji(cat),
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(
                          cat.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        trailing: isSelected 
                          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                          : null,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _categories.remove(cat);
                            } else {
                              _categories.add(cat);
                            }
                          });
                        },
                      );
                    }),

                    const SectionTitle('Khoảng giá'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ActivityPriceType.values.map((pt) {
                        final isSelected = _priceType == pt;
                        return ChoiceChip(
                          label: Text(pt.label),
                          selected: isSelected,
                          showCheckmark: false,
                          onSelected: (_) {
                            setState(() => _priceType = pt);
                          },
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          backgroundColor: AppColors.inputFill,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                            ),
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : Colors.black87,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),

                    const SectionTitle('Khu vực'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _district,
                          hint: const Text('Chọn quận/huyện'),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Tất cả khu vực'),
                            ),
                            ..._districts.map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d),
                                )),
                          ],
                          onChanged: (val) => setState(() => _district = val),
                        ),
                      ),
                    ),

                    const SectionTitle('Sắp xếp theo'),
                    ...[SortOption.none, SortOption.mostPopular, SortOption.highestRated]
                        .map((opt) => RadioListTile<SortOption>(
                              title: Text(
                                opt.label,
                                style: const TextStyle(fontSize: 14),
                              ),
                              value: opt,
                              groupValue: _sortOption,
                              activeColor: AppColors.primary,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              onChanged: (val) {
                                if (val != null) setState(() => _sortOption = val);
                              },
                            )),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              ActionButtons(
                onReset: _reset,
                onApply: () {
                  widget.onApply(ActivityFilter(
                    categories: _categories,
                    priceType: _priceType,
                    district: _district,
                    sortOption: _sortOption,
                  ));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}