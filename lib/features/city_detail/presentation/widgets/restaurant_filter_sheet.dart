import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/utils/input_formatter.dart';
import 'package:travel_advisor_mobile/features/city_detail/domain/entities/filter_enums.dart';
import 'filter_shared.dart';

class RestaurantFilterSheet extends StatefulWidget {
  final RestaurantFilter currentFilter;
  final ValueChanged<RestaurantFilter> onApply;

  const RestaurantFilterSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<RestaurantFilterSheet> createState() => _RestaurantFilterSheetState();
}

class _RestaurantFilterSheetState extends State<RestaurantFilterSheet> {
  late Set<RestaurantCuisine> _cuisines;
  late RestaurantPriceLevel _priceLevel;
  late Set<RestaurantAmenity> _amenities;
  late SortOption _sortOption;

  @override
  void initState() {
    super.initState();
    _cuisines = Set.from(widget.currentFilter.cuisines);
    _priceLevel = widget.currentFilter.priceLevel;
    _amenities = Set.from(widget.currentFilter.amenities);
    _sortOption = widget.currentFilter.sortOption;
  }

  void _reset() {
    setState(() {
      _cuisines = {};
      _priceLevel = RestaurantPriceLevel.all;
      _amenities = {};
      _sortOption = SortOption.none;
    });
  }

  String _getRestaurantAmenityEmoji(RestaurantAmenity amenity) {
    switch (amenity) {
      case RestaurantAmenity.parking:
        return '🅿️';
      case RestaurantAmenity.airCon:
        return '❄️';
      case RestaurantAmenity.kidFriendly:
        return '👶';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
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
                    const SectionTitle('Danh mục'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: RestaurantCuisine.values.map((c) {
                        final isSelected = _cuisines.contains(c);
                        return FilterChip(
                          label: Text(c.label),
                          selected: isSelected,
                          showCheckmark: false,
                          onSelected: (selected) {
                            setState(() {
                              selected ? _cuisines.add(c) : _cuisines.remove(c);
                            });
                          },
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primary,
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
                    const SectionTitle('Mức giá'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: RestaurantPriceLevel.values.map((pl) {
                        final isSelected = _priceLevel == pl;
                        return ChoiceChip(
                          label: Text(pl.label),
                          selected: isSelected,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _priceLevel = pl),
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
                    const SectionTitle('Tiện ích'),
                    ...RestaurantAmenity.values.map((amenity) {
                      final isSelected = _amenities.contains(amenity);
                      return ListTile(
                        leading: Text(
                          _getRestaurantAmenityEmoji(amenity),
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
                  widget.onApply(RestaurantFilter(
                    cuisines: _cuisines,
                    priceLevel: _priceLevel,
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