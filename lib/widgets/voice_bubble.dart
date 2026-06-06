import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../utils/app_colors.dart';

class VoiceBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final String? senderName;

  const VoiceBubble({super.key, required this.message, required this.isMe, this.senderName});

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble> {
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: widget.isMe ? 32 : 0,
          right: widget.isMe ? 0 : 32,
          bottom: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.senderName != null) ...[
                Text(
                  widget.senderName!,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
              ],
              _WaveformPlayer(
                playing: _playing,
                duration: widget.message.durationLabel ?? '0:00',
                onToggle: () => setState(() => _playing = !_playing),
              ),
              const SizedBox(height: 10),
              if (widget.message.segments.isNotEmpty)
                ..._buildSegments()
              else
                _buildSimpleTranscript(),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(widget.message.time, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSegments() {
    return [
      const Text('Bahasa Inggris', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 4),
      ...widget.message.segments.map((seg) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(seg.textEn, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4)),
      )),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bahasa Indonesia', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            ...widget.message.segments.map((seg) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(seg.textId, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
            )),
          ],
        ),
      ),
    ];
  }

  Widget _buildSimpleTranscript() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bahasa Inggris', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(widget.message.textEn ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bahasa Indonesia', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(widget.message.textId ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _WaveformPlayer extends StatelessWidget {
  final bool playing;
  final String duration;
  final VoidCallback onToggle;

  const _WaveformPlayer({required this.playing, required this.duration, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    const heights = [6.0, 12.0, 20.0, 10.0, 16.0, 24.0, 14.0, 8.0, 22.0, 12.0, 18.0, 6.0, 14.0, 20.0, 10.0, 18.0, 8.0, 14.0];
    return Row(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Icon(playing ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 28,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(heights.length, (i) {
                final isPlayed = playing && i < heights.length ~/ 2;
                return Container(
                  width: 3,
                  height: heights[i],
                  decoration: BoxDecoration(
                    color: isPlayed ? AppColors.primary : const Color(0xFFBDCCE8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(duration, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
