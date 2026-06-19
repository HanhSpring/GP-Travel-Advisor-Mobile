import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/review_media_item.dart';
import 'package:video_player/video_player.dart';

class ReviewMediaPicker {
  static const int maxVideoSizeBytes = 20 * 1024 * 1024;
  static const Duration maxVideoDuration = Duration(seconds: 20);

  static Future<List<ReviewMediaItem>> pickImages({
    required int startSortOrder,
  }) async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isEmpty) {
      return const [];
    }

    return pickedFiles
        .asMap()
        .entries
        .map((entry) {
          return ReviewMediaItem.localImage(
            localPath: entry.value.path,
            sortOrder: startSortOrder + entry.key,
          );
        })
        .toList(growable: false);
  }

  static Future<ReviewMediaItem?> pickVideo({required int sortOrder}) async {
    final pickedFile = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: maxVideoDuration,
    );

    if (pickedFile == null) {
      return null;
    }

    final file = File(pickedFile.path);
    final size = await file.length();
    if (size <= 0 || size > maxVideoSizeBytes) {
      throw const ReviewMediaSelectionException(
        'Video phải nhỏ hơn hoặc bằng 20MB',
      );
    }

    final duration = await _readVideoDuration(file);
    if (duration > maxVideoDuration) {
      throw const ReviewMediaSelectionException(
        'Video phải ngắn hơn hoặc bằng 20 giây',
      );
    }

    return ReviewMediaItem.localVideo(
      localPath: pickedFile.path,
      sortOrder: sortOrder,
      fileSize: size,
      duration: duration,
    );
  }

  static Future<Duration> _readVideoDuration(File file) async {
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      return controller.value.duration;
    } finally {
      await controller.dispose();
    }
  }
}

class ReviewMediaSelectionException implements Exception {
  final String message;

  const ReviewMediaSelectionException(this.message);

  @override
  String toString() => message;
}
