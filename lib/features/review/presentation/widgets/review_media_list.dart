import 'dart:io';

import 'package:flutter/material.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/review_media_item.dart';
import 'package:video_player/video_player.dart';

class ReviewMediaList extends StatelessWidget {
  final List<ReviewMediaItem> mediaItems;
  final VoidCallback onAddImages;
  final VoidCallback onAddVideo;
  final ValueChanged<String> onRemoveMedia;
  final VoidCallback onClearAllMedia;
  final double imageSize;

  const ReviewMediaList({
    super.key,
    required this.mediaItems,
    required this.onAddImages,
    required this.onAddVideo,
    required this.onRemoveMedia,
    required this.onClearAllMedia,
    this.imageSize = 140,
  });

  bool _isBusy(ReviewMediaItem item) {
    return item.status == ReviewMediaUploadStatus.requestingUrl ||
        item.status == ReviewMediaUploadStatus.uploading ||
        item.status == ReviewMediaUploadStatus.compressing;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thêm hình ảnh & video',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.only(top: 12, right: 12, bottom: 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showMediaPicker(context),
                child: Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              ...mediaItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: imageSize,
                        height: imageSize,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(16),
                          image: item.type == ReviewMediaType.image
                              ? DecorationImage(
                                  image: FileImage(File(item.localPath)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: item.type == ReviewMediaType.video
                            ? _ReviewVideoPreview(item: item)
                            : null,
                      ),
                      if (_isBusy(item))
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (item.status == ReviewMediaUploadStatus.failed)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(8),
                            alignment: Alignment.center,
                            child: Text(
                              item.errorMessage ?? 'Tải ảnh thất bại',
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: -12,
                        right: -12,
                        child: GestureDetector(
                          onTap: () => onRemoveMedia(item.id),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (mediaItems.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onClearAllMedia,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Xóa toàn bộ media',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showMediaPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Chọn hình ảnh'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onAddImages();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.video_library_outlined),
                  title: const Text('Chọn video'),
                  subtitle: const Text('Tối đa 20MB và 20 giây'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onAddVideo();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReviewVideoPreview extends StatefulWidget {
  final ReviewMediaItem item;

  const _ReviewVideoPreview({required this.item});

  @override
  State<_ReviewVideoPreview> createState() => _ReviewVideoPreviewState();
}

class _ReviewVideoPreviewState extends State<_ReviewVideoPreview> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant _ReviewVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.localPath != widget.item.localPath) {
      _controller?.dispose();
      _controller = null;
      _initialize();
    }
  }

  Future<void> _initialize() async {
    final controller = VideoPlayerController.file(File(widget.item.localPath));
    _controller = controller;
    try {
      await controller.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      await controller.dispose();
      if (mounted) {
        setState(() => _controller = null);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isReady = controller?.value.isInitialized == true;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isReady)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller!.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            )
          else
            Container(color: const Color(0xFF111827)),
          Container(color: Colors.black.withValues(alpha: 0.18)),
          const Center(
            child: Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatDuration(widget.item.duration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDuration(Duration? duration) {
    final value = duration ?? Duration.zero;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
