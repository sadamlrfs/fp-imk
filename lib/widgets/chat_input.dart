import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

enum ChatInputMode { normal, recording }

class ChatInput extends StatefulWidget {
  final void Function(String text) onSendText;
  final VoidCallback onSendVoice;
  final VoidCallback onAttachVideo;

  const ChatInput({
    super.key,
    required this.onSendText,
    required this.onSendVoice,
    required this.onAttachVideo,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _ctrl = TextEditingController();
  ChatInputMode _mode = ChatInputMode.normal;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() => _hasText = _ctrl.text.isNotEmpty));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send() {
    if (_ctrl.text.trim().isEmpty) return;
    widget.onSendText(_ctrl.text.trim());
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == ChatInputMode.recording) {
      return _VoiceRecorderBar(
        onCancel: () => setState(() => _mode = ChatInputMode.normal),
        onSend: () {
          setState(() => _mode = ChatInputMode.normal);
          widget.onSendVoice();
        },
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(Icons.sentiment_satisfied_alt_outlined, color: AppColors.textSecondary, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  hintText: 'type here...',
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                style: const TextStyle(fontSize: 14),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            if (_hasText)
              GestureDetector(
                onTap: _send,
                child: const Icon(Icons.send, color: AppColors.primary, size: 24),
              )
            else ...[
              GestureDetector(
                onTap: widget.onAttachVideo,
                child: const Icon(Icons.attach_file, color: AppColors.textSecondary, size: 24),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => _mode = ChatInputMode.recording),
                child: const Icon(Icons.mic, color: AppColors.primary, size: 26),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VoiceRecorderBar extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const _VoiceRecorderBar({required this.onCancel, required this.onSend});

  @override
  State<_VoiceRecorderBar> createState() => _VoiceRecorderBarState();
}

class _VoiceRecorderBarState extends State<_VoiceRecorderBar> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  int _seconds = 0;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_active) return false;
      setState(() => _seconds++);
      return true;
    });
  }

  @override
  void dispose() {
    _active = false;
    _pulse.dispose();
    super.dispose();
  }

  String get _timeLabel {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Trash button
            GestureDetector(
              onTap: widget.onCancel,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
              ),
            ),
            // Timer + waveform
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, child) => Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.5 + _pulse.value * 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(_timeLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _MiniWaveform(),
                  ],
                ),
              ),
            ),
            // Send button
            GestureDetector(
              onTap: widget.onSend,
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.send, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniWaveform extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const heights = [4.0, 8.0, 14.0, 6.0, 12.0, 18.0, 10.0, 6.0, 14.0, 8.0, 12.0, 4.0];
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: heights.map((h) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 3,
          height: h,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        )).toList(),
      ),
    );
  }
}
