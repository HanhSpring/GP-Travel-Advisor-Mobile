import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ImportantNotesCard extends StatelessWidget {
  const ImportantNotesCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info, color: AppColors.textSecondary, size: 18),
              SizedBox(width: 8),
              Text(
                'Ghi chú quan trọng',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _NoteItem(text: 'Mang theo hộ chiếu/ CCCD và bảo hiểm du lịch.'),
          _NoteItem(text: 'Chuẩn bị quần áo phù hợp với thời tiết.'),
          _NoteItem(text: 'Pin dự phòng cho điện thoại.'),
        ],
      ),
    );
  }
}

class _NoteItem extends StatelessWidget {
  final String text;

  const _NoteItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0, right: 8.0, left: 4.0),
            child: CircleAvatar(
              radius: 2,
              backgroundColor: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
