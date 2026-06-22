import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/app_models.dart';


class VideoAttachmentBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback? onTap;

  const VideoAttachmentBubble({super.key, required this.message, required this.isMe, this.onTap});

  @override
  State<VideoAttachmentBubble> createState() => _VideoAttachmentBubbleState();
}

class _VideoAttachmentBubbleState extends State<VideoAttachmentBubble> {
  VideoPlayerController? _ctrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final url = widget.message.videoUrl ?? '';
    if (url.isEmpty) return;
    try {
      final controller = url.startsWith('http')
          ? VideoPlayerController.networkUrl(Uri.parse(url))
          : VideoPlayerController.file(File(url));
      await controller.initialize();
      if (mounted) setState(() { _ctrl = controller; _initialized = true; });
    } catch (_) {
      // Can't generate thumbnail — show fallback
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: EdgeInsets.only(
            left: widget.isMe ? 48 : 0,
            right: widget.isMe ? 0 : 48,
            bottom: 10,
          ),
          constraints: const BoxConstraints(maxWidth: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.black,
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Thumbnail (first frame)
              if (_initialized && _ctrl != null)
                AspectRatio(
                  aspectRatio: _ctrl!.value.aspectRatio.clamp(0.5, 2.0),
                  child: VideoPlayer(_ctrl!),
                )
              else
                const SizedBox(
                  width: 220, height: 140,
                  child: Center(
                    child: Icon(Icons.videocam, color: Colors.white24, size: 48),
                  ),
                ),
              // Play button overlay
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
              ),
              // Time badge
              Positioned(
                bottom: 6,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam, color: Colors.white, size: 10),
                      const SizedBox(width: 3),
                      Text(widget.message.time,
                          style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
