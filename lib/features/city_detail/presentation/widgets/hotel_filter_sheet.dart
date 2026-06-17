import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/utils/input_formatter.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/entities/filter_enums.dart';
import 'filter_shared.dart';

class HotelFilterSheet extends StatefulWidget {
  final HotelFilter currentFilter;
  final ValueChanged<HotelFilter> onApply;

  const HotelFilterSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<HotelFilterSheet> createState() => _HotelFilterSheetState();
}

class _HotelFilterSheetState extends State<HotelFilterSheet> {
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late Set<AccommodationType> _accommodationTypes;
  late Set<HotelAmenity> _amenities;
  late SortOption _sortOption;

  @override
  void initState() {
    super.initState();
    final formatter = NumberFormat.decimalPattern('vi_VN');
    _minPriceController = TextEditingController(
      text: widget.currentFilter.minPrice > 0 
        ? formatter.format(widget.currentFilter.minPrice.toInt()) 
        : '',
    );
    _maxPriceController = TextEditingController(
      text: widget.currentFilter.maxPrice > 0 
        ? formatter.format(widget.currentFilter.maxPrice.toInt()) 
        : '',
    );
    _accommodationTypes = Set.from(widget.currentFilter.accommodationTypes);
    _amenities = Set.from(widget.currentFilter.amenities);
    _sortOption = widget.currentFilter.sortOption;
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _minPriceController.clear();
      _maxPriceController.clear();
      _accommodationTypes = {};
      _amenities = {};
      _sortOption = SortOption.none;
    });
  }

  String _getAccommodationEmoji(AccommodationType type) {
    switch (type) {
      case AccommodationType.hotel:
        return '🏨';
      case AccommodationType.homestay:
        return '🏡';
      case AccommodationType.resort:
        return '🏖️';
      case AccommodationType.apartment:
        return '🏢';
      case AccommodationType.guesthouse:
        return '🛌';
    }
  }

  String _getHotelAmenityEmoji(HotelAmenity amenity) {
    switch (amenity) {
      case HotelAmenity.pool:
        return '🏊';
      case HotelAmenity.freeWifi:
        return '📶';
      case HotelAmenity.breakfast:
        return '🍳';
      case HotelAmenity.gym:
        return '🏋️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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
                    const SectionTitle('Khoảng giá (VNĐ)'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minPriceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyInputFormatter()],
                            decoration: InputDecoration(
                              hintText: 'Từ',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                              fillColor: AppColors.inputFill,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary),
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('-', style: TextStyle(fontSize: 20, color: Colors.grey)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _maxPriceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyInputFormatter()],
                            decoration: InputDecoration(
                              hintText: 'Đến',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                              fillColor: AppColors.inputFill,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SectionTitle('Loại hình lưu trú'),
                    ...AccommodationType.values.map((type) {
                      final isSelected = _accommodationTypes.contains(type);
                      return ListTile(
                        leading: Text(
                          _getAccommodationEmoji(type),
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(
                          type.label,
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
                              _accommodationTypes.remove(type);
                            } else {
                              _accommodationTypes.add(type);
                            }
                          });
                        },
                      );
                    }),
                    const SectionTitle('Tiện nghi'),
                    ...HotelAmenity.values.map((amenity) {
                      final isSelected = _amenities.contains(amenity);
                      return ListTile(
                        leading: Text(
                          _getHotelAmenityEmoji(amenity),
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(
                          amenity.label,
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
                              _amenities.remove(amenity);
                            } else {
                              _amenities.add(amenity);
                            }
                          });
                        },
                      );
                    }),
                    const SectionTitle('Sắp xếp theo'),
                    ...SortOption.values
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
                  final minStr = _minPriceController.text.replaceAll(RegExp(r'\D'), '');
                  final maxStr = _maxPriceController.text.replaceAll(RegExp(r'\D'), '');
                  
                  final minPrice = double.tryParse(minStr) ?? 0;
                  final maxPrice = double.tryParse(maxStr) ?? 0;
                  
                  widget.onApply(HotelFilter(
                    minPrice: minPrice,
                    maxPrice: maxPrice,
                    accommodationTypes: _accommodationTypes,
                    amenities: _amenities,
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