import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/app_models.dart';
import '../utils/app_colors.dart';

class VoiceBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final String? senderName;
  final String userLang;

  const VoiceBubble({super.key, required this.message, required this.isMe, this.senderName, this.userLang = 'id'});

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble> {
  final _player = AudioPlayer();
  bool _loaded = false;
  bool _loading = false;
  bool _unavailable = false;
  bool _playing = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _playing = state.playing);
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
        if (mounted) setState(() => _position = Duration.zero);
      }
    });
    _player.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
    });
    _player.durationStream.listen((d) {
      if (!mounted || d == null) return;
      setState(() => _duration = d);
    });
  }

  Future<void> _toggle() async {
    final audio = widget.message.audio;
    if (audio == null || _unavailable) return;

    if (!_loaded) {
      setState(() => _loading = true);
      try {
        if (audio.startsWith('assets/')) {
          await _player.setAsset(audio);
        } else {
          await _player.setFilePath(audio);
        }
        _loaded = true;
      } catch (_) {
        if (mounted) setState(() => _unavailable = true);
      }
      if (mounted) setState(() => _loading = false);
      if (!_loaded) return;
    }

    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String get _durationLabel {
    if (_duration <= Duration.zero) return widget.message.durationLabel ?? '0:00';
    final remaining = _duration - _position;
    final show = (_playing || _position > Duration.zero) ? remaining : _duration;
    final clamped = show.isNegative ? Duration.zero : show;
    final m = clamped.inMinutes;
    final s = clamped.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (_duration.inMilliseconds <= 0) return 0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0, 1);
  }

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
          color: AppColors.surface,
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
                loading: _loading,
                unavailable: _unavailable,
                progress: _progress,
                duration: _durationLabel,
                onToggle: _toggle,
              ),
              const SizedBox(height: 10),
              if (widget.message.segments.isNotEmpty)
                ..._buildSegments()
              else
                _buildSimpleTranscript(),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(widget.message.time, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSegments() {
    final bool preferId = widget.userLang != 'en';
    final topLabel    = preferId ? 'Bahasa Indonesia' : 'Bahasa Inggris';
    final bottomLabel = preferId ? 'Bahasa Inggris'  : 'Bahasa Indonesia';
    return [
      Text(topLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 4),
      ...widget.message.segments.map((seg) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(preferId ? seg.textId : seg.textEn,
            style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4)),
      )),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFDCEEFB), borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(bottomLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 4),
            ...widget.message.segments.map((seg) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(preferId ? seg.textEn : seg.textId,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
            )),
          ],
        ),
      ),
    ];
  }

  Widget _buildSimpleTranscript() {
    final bool preferId = widget.userLang != 'en';
    final topLabel    = preferId ? 'Bahasa Indonesia' : 'Bahasa Inggris';
    final bottomLabel = preferId ? 'Bahasa Inggris'  : 'Bahasa Indonesia';
    final topText     = preferId ? (widget.message.textId ?? '') : (widget.message.textEn ?? '');
    final bottomText  = preferId ? (widget.message.textEn ?? '') : (widget.message.textId ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(topLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(topText, style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4)),
        if (bottomText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFDCEEFB), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bottomLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: 4),
                Text(bottomText, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _WaveformPlayer extends StatelessWidget {
  final bool playing;
  final bool loading;
  final bool unavailable;
  final double progress;
  final String duration;
  final VoidCallback onToggle;

  const _WaveformPlayer({
    required this.playing,
    required this.loading,
    required this.unavailable,
    required this.progress,
    required this.duration,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const heights = [6.0, 12.0, 20.0, 10.0, 16.0, 24.0, 14.0, 8.0, 22.0, 12.0, 18.0, 6.0, 14.0, 20.0, 10.0, 18.0, 8.0, 14.0];
    return Row(
      children: [
        GestureDetector(
          onTap: unavailable ? null : onToggle,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: unavailable ? AppColors.textSecondary : AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(
                    unavailable ? Icons.error_outline : (playing ? Icons.pause : Icons.play_arrow),
                    color: Colors.white,
                    size: 22,
                  ),
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
                final isPlayed = progress > 0 && (i / heights.length) < progress;
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
        Text(
          unavailable ? '--:--' : duration,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
