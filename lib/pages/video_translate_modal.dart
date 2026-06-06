import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
  bool _playing = false;
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    final appCtx = context.watch<AppContext>();
    final messages = appCtx.getMessages(widget.chatId);
    final msg = messages.where((m) => m.id == widget.messageId).firstOrNull;
    final senderName = widget.chatId.isNotEmpty
        ? (appCtx.getChatById(widget.chatId)?.participantIds.firstOrNull ?? '')
        : '';
    final contact = appCtx.getUserById(senderName);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => context.go('/chat/${widget.chatId}'),
                  ),
                  Expanded(
                    child: Text(
                      'Video dari @${contact?.name ?? 'User'}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            // Video player
            Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: () => setState(() => _playing = !_playing),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFF1A1A2E),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.person, color: Colors.white12, size: 120),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_playing ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 34),
                      ),
                      // Progress bar
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            Slider(
                              value: _progress,
                              onChanged: (v) => setState(() => _progress = v),
                              activeColor: AppColors.primary,
                              inactiveColor: Colors.white30,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Translate panel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, -2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.translate, color: AppColors.primary, size: 16),
                      const SizedBox(width: 6),
                      const Text('Video Translate', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Bahasa Inggris', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    msg?.textEn ?? 'Check out this video from our last meeting!',
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bahasa Indonesia', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        const SizedBox(height: 4),
                        Text(
                          msg?.textId ?? 'Lihat video dari pertemuan terakhir kita ini!',
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
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
}
