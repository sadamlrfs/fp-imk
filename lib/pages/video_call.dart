import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../context/app_context.dart';
import '../utils/app_colors.dart';
import '../widgets/avatar_widget.dart';

class VideoCallPage extends StatefulWidget {
  final String chatId;
  final bool isVideo;
  const VideoCallPage({super.key, required this.chatId, this.isVideo = true});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  int _scriptIndex = 0;
  bool _micOn = true;
  bool _camOn = true;
  Timer? _timer;
  int _elapsed = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed++);
      if (_elapsed % 3 == 0) {
        final ctx = context.read<AppContext>();
        final scripts = ctx.scripts['video'] ?? [];
        if (scripts.isNotEmpty) {
          setState(() => _scriptIndex = (_scriptIndex + 1) % scripts.length);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timerLabel {
    final m = _elapsed ~/ 60;
    final s = _elapsed % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final appCtx = context.watch<AppContext>();
    final chat = appCtx.getChatById(widget.chatId);
    final contactId = chat?.participantIds.firstOrNull ?? '';
    final contact = appCtx.getUserById(contactId);
    final scripts = appCtx.scripts['video'] ?? [];
    final currentScript = scripts.isNotEmpty ? scripts[_scriptIndex] : null;

    final isVideo = widget.isVideo;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main background
          Positioned.fill(
            child: isVideo
                ? Stack(children: [
                    // Dummy video: person photo as remote camera feed
                    Positioned.fill(
                      child: Image.asset('assets/dummy_call.jpg', fit: BoxFit.cover),
                    ),
                    // Dark overlay to make it look like a video call
                    Positioned.fill(
                      child: Container(color: Colors.black.withValues(alpha: 0.35)),
                    ),
                  ])
                : Container(
                    color: const Color(0xFF1A1A2E),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AvatarWidget(name: contact?.name ?? 'R', radius: 60),
                        const SizedBox(height: 20),
                        Text(contact?.name ?? 'Rizal Hafiyyan',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Panggilan Suara', style: TextStyle(color: Colors.white60, fontSize: 14)),
                      ],
                    ),
                  ),
          ),
          // Contact name label (video mode only)
          if (isVideo)
            Positioned(
              top: 60,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(contact?.name ?? 'Rizal Hafiyyan',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          // Self PiP top right (video mode only)
          if (isVideo)
            Positioned(
              top: 56,
              right: 12,
              child: Container(
                width: 100,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Center(child: Icon(Icons.person, color: Colors.white38, size: 40)),
              ),
            ),
          // Back button
          Positioned(
            top: 16,
            left: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          // Timer
          Positioned(
            top: 24,
            right: 0,
            left: 0,
            child: SafeArea(
              child: Center(
                child: Text(_timerLabel, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ),
            ),
          ),
          // Bottom: translate + controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Translate overlay card
                  if (currentScript != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.translate, color: AppColors.primary, size: 14),
                                const SizedBox(width: 6),
                                Text('Realtime Translate',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text('Bahasa Inggris', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text(currentScript.textEn, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Bahasa Indonesia', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                  const SizedBox(height: 4),
                                  Text(currentScript.textId, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Control buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 0, 40, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (isVideo)
                          _ControlBtn(
                            icon: _camOn ? Icons.videocam : Icons.videocam_off,
                            onTap: () => setState(() => _camOn = !_camOn),
                            bg: Colors.white.withValues(alpha: 0.2),
                          ),
                        _ControlBtn(
                          icon: _micOn ? Icons.mic : Icons.mic_off,
                          onTap: () => setState(() => _micOn = !_micOn),
                          bg: Colors.white.withValues(alpha: 0.2),
                        ),
                        // End call button (red pill)
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 64,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                          ),
                        ),
                      ],
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

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color bg;

  const _ControlBtn({required this.icon, this.onTap, required this.bg});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
