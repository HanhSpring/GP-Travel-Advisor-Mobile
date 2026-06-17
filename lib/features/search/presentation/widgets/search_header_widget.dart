import 'package:flutter/material.dart';

import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';

class SearchHeaderWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;
  final ValueChanged<String>? onChanged;

  const SearchHeaderWidget({
    super.key,
    required this.controller,
    required this.onClear,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: AppSizes.s12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.only(right: AppSizes.s16),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black,
                size: AppSizes.iconMd,
              ),
            ),
          ),
          
          Expanded(
            child: Container(
              height: AppSizes.searchBarHeight,
              decoration: BoxDecoration(
                color: AppColorsExt.searchBarBg,
                border: Border.all(color: Colors.black, width: 1.0),
                borderRadius: BorderRadius.circular(AppSizes.r24),
              ),
              padding: const EdgeInsets.only(left: AppSizes.s12, right: AppSizes.s16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search,
                    color: Colors.black,
                    size: AppSizes.iconMd,
                  ),
                  const SizedBox(width: AppSizes.s8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      readOnly: false,
                      autofocus: true,
                      textAlignVertical: TextAlignVertical.center,
                      onChanged: onChanged,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm thành phố, địa điểm, nhà hàng...',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: onClear,
                      child: const Icon(
                        Icons.cancel,
                        color: AppColors.textSecondary,
                        size: AppSizes.iconMd,
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