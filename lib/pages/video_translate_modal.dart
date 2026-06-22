import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../context/app_context.dart';
import '../utils/app_colors.dart';

class VideoTranslateModalPage extends StatefulWidget {
  final String messageId;
  final String chatId;

  const VideoTranslateModalPage({super.key, required this.messageId, required this.chatId});

  @override
  State<VideoTranslateModalPage> createState() => _VideoTranslateModalPageState();
}

class _VideoTranslateModalPageState extends State<VideoTranslateModalPage> {
  VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final appCtx = context.read<AppContext>();
    final messages = appCtx.getMessages(widget.chatId);
    final msg = messages.where((m) => m.id == widget.messageId).firstOrNull;
    final url = msg?.videoUrl;
    if (url == null || url.isEmpty) {
      setState(() => _error = true);
      return;
    }
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      if (!mounted) { controller.dispose(); return; }
      controller.addListener(() {
        if (mounted) setState(() {});
      });
      setState(() { _ctrl = controller; _initialized = true; });
    } catch (e) {
      debugPrint('Video init error: $e');
      if (mounted) setState(() => _error = true);
    }
  }

  void _togglePlay() {
    if (_ctrl == null) return;
    if (_ctrl!.value.isPlaying) {
      _ctrl!.pause();
    } else {
      _ctrl!.play();
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appCtx = context.watch<AppContext>();
    final messages = appCtx.getMessages(widget.chatId);
    final msg = messages.where((m) => m.id == widget.messageId).firstOrNull;
    final userLang = appCtx.currentUser?.lang ?? 'id';
    final preferId = userLang != 'en';
    String txt(String? s) => (s == null || s.trim().isEmpty) ? 'Tidak ada keterangan' : s;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text('Video Translate',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ),
            ),
            // Video player area
            Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: double.infinity,
                  color: Colors.black,
                  child: _buildVideoArea(),
                ),
              ),
            ),
            // Controls
            if (_initialized && _ctrl != null)
              Container(
                color: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      _formatDuration(_ctrl!.value.position),
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    Expanded(
                      child: Slider(
                        value: _ctrl!.value.duration.inMilliseconds > 0
                            ? (_ctrl!.value.position.inMilliseconds /
                                    _ctrl!.value.duration.inMilliseconds)
                                .clamp(0.0, 1.0)
                            : 0.0,
                        onChanged: (v) {
                          final pos = Duration(
                              milliseconds: (v * _ctrl!.value.duration.inMilliseconds).toInt());
                          _ctrl!.seekTo(pos);
                        },
                        activeColor: AppColors.primary,
                        inactiveColor: Colors.white30,
                      ),
                    ),
                    Text(
                      _formatDuration(_ctrl!.value.duration),
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            // Translate panel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Icon(Icons.translate, color: AppColors.primary, size: 16),
                    SizedBox(width: 6),
                    Text('Video Translate',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                  ]),
                  const SizedBox(height: 12),
                  Text(preferId ? 'Bahasa Indonesia' : 'Bahasa Inggris',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    txt(preferId ? msg?.textId : msg?.textEn),
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEEFB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(preferId ? 'Bahasa Inggris' : 'Bahasa Indonesia',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                        const SizedBox(height: 4),
                        Text(
                          txt(preferId ? msg?.textEn : msg?.textId),
                          style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoArea() {
    if (_error) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.white38, size: 48),
            SizedBox(height: 8),
            Text('Tidak dapat memutar video',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      );
    }
    if (!_initialized || _ctrl == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _ctrl!.value.aspectRatio.clamp(0.5, 2.0),
            child: VideoPlayer(_ctrl!),
          ),
        ),
        if (!_ctrl!.value.isPlaying)
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
          ),
      ],
    );
  }
}
