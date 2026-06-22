import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../services/speech_service.dart';
import '../utils/app_colors.dart';

enum ChatInputMode { normal, recording }

class VoiceRecordingResult {
  final String filePath;
  final int durationSeconds;
  final String transcript;

  VoiceRecordingResult({
    required this.filePath,
    required this.durationSeconds,
    required this.transcript,
  });
}

class AttachmentResult {
  final String filePath;
  final String type; // 'image' | 'video' | 'file'
  final String fileName;
  final String? targetLang; // only for video: language code to translate to

  AttachmentResult({required this.filePath, required this.type, required this.fileName, this.targetLang});
}

class ChatInput extends StatefulWidget {
  final Future<void> Function(String text) onSendText;
  final void Function(VoiceRecordingResult result) onSendVoice;
  final void Function(AttachmentResult result) onSendAttachment;
  final String speechLocaleId;

  const ChatInput({
    super.key,
    required this.onSendText,
    required this.onSendVoice,
    required this.onSendAttachment,
    this.speechLocaleId = 'id_ID',
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _ctrl = TextEditingController();
  ChatInputMode _mode = ChatInputMode.normal;
  bool _hasText = false;
  bool _sending = false;

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

  Future<void> _send() async {
    if (_ctrl.text.trim().isEmpty || _sending) return;
    final text = _ctrl.text.trim();
    _ctrl.clear();
    setState(() => _sending = true);
    try {
      await widget.onSendText(text);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showAttachMenu() async {
    // Use a callback directly — avoids Navigator.pop(parentContext, r) which
    // could accidentally pop the chat room route when the sheet is already closed.
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AttachSheet(onResult: widget.onSendAttachment),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == ChatInputMode.recording) {
      return _VoiceRecorderBar(
        speechLocaleId: widget.speechLocaleId,
        speechService: context.read<SpeechService>(),
        onCancel: () => setState(() => _mode = ChatInputMode.normal),
        onSend: (result) {
          setState(() => _mode = ChatInputMode.normal);
          widget.onSendVoice(result);
        },
      );
    }

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Icon(Icons.sentiment_satisfied_alt_outlined,
                color: AppColors.textSecondary, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _ctrl,
                enabled: !_sending,
                decoration: InputDecoration(
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
            if (_sending)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              )
            else if (_hasText)
              GestureDetector(
                onTap: _send,
                child: const Icon(Icons.send, color: AppColors.primary, size: 24),
              )
            else ...[
              GestureDetector(
                onTap: _showAttachMenu,
                child: Icon(Icons.attach_file, color: AppColors.textSecondary, size: 24),
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

// ── Attachment sheet ───────────────────────────────────────

class _AttachSheet extends StatelessWidget {
  final void Function(AttachmentResult) onResult;
  const _AttachSheet({required this.onResult});

  Future<void> _pickImage(BuildContext context) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    onResult(AttachmentResult(filePath: file.path, type: 'image', fileName: file.name));
  }

  Future<void> _pickCamera(BuildContext context) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (file == null) return;
    onResult(AttachmentResult(filePath: file.path, type: 'image', fileName: file.name));
  }

  Future<void> _pickVideo(BuildContext context) async {
    // Show lang picker FIRST while the attach sheet is still mounted (context valid).
    // Capture navigator before any await to avoid stale-context lint.
    final nav = Navigator.of(context);
    final targetLang = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _VideoLangSheet(),
    );
    if (targetLang == null) return; // user cancelled lang selection

    nav.pop(); // close attach sheet now
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    onResult(AttachmentResult(
      filePath: file.path,
      type: 'video',
      fileName: file.name,
      targetLang: targetLang,
    ));
  }

  Future<void> _pickFile(BuildContext context) async {
    Navigator.pop(context);
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    if (f.path == null) return;
    onResult(AttachmentResult(filePath: f.path!, type: 'file', fileName: f.name));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Lampirkan',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AttachOption(
                  icon: Icons.photo_library,
                  label: 'Galeri',
                  color: Colors.purple,
                  onTap: () => _pickImage(context),
                ),
                _AttachOption(
                  icon: Icons.camera_alt,
                  label: 'Kamera',
                  color: Colors.blue,
                  onTap: () => _pickCamera(context),
                ),
                _AttachOption(
                  icon: Icons.videocam,
                  label: 'Video',
                  color: Colors.red,
                  onTap: () => _pickVideo(context),
                ),
                _AttachOption(
                  icon: Icons.insert_drive_file,
                  label: 'Berkas',
                  color: Colors.orange,
                  onTap: () => _pickFile(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Video language selection sheet ─────────────────────────

class _VideoLangSheet extends StatelessWidget {
  const _VideoLangSheet();

  static const _langs = [
    ('id', 'Bahasa Indonesia', '🇮🇩'),
    ('en', 'English', '🇬🇧'),
    ('zh', 'Mandarin', '🇨🇳'),
    ('ja', 'Japanese', '🇯🇵'),
    ('ko', 'Korean', '🇰🇷'),
    ('es', 'Spanish', '🇪🇸'),
    ('ar', 'Arabic', '🇸🇦'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Row(children: [
            Icon(Icons.translate, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Terjemahkan Video ke Bahasa',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 4),
          Text('Pilih bahasa tujuan untuk subtitle video',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ..._langs.map((l) => InkWell(
                onTap: () => Navigator.pop(context, l.$1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Text(l.$3, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 14),
                    Text(l.$2,
                        style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                  ]),
                ),
              )),
        ],
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      );
}

// ── Voice recorder bar ────────────────────────────────────

class _VoiceRecorderBar extends StatefulWidget {
  final VoidCallback onCancel;
  final void Function(VoiceRecordingResult result) onSend;
  final String speechLocaleId;
  final SpeechService speechService;

  const _VoiceRecorderBar({
    required this.onCancel,
    required this.onSend,
    required this.speechLocaleId,
    required this.speechService,
  });

  @override
  State<_VoiceRecorderBar> createState() => _VoiceRecorderBarState();
}

class _VoiceRecorderBarState extends State<_VoiceRecorderBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  final _recorder = AudioRecorder();
  int _seconds = 0;
  bool _active = true;
  bool _starting = true;
  bool _finishing = false;
  String? _filePath;
  String _transcript = '';
  String? _error;
  Completer<String>? _finalTranscriptCompleter;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _startTimer();
    _startRecording();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_active) return false;
      setState(() => _seconds++);
      return true;
    });
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) setState(() => _error = 'Izin mikrofon ditolak');
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    _filePath = path;

    await widget.speechService.startListening(
      localeId: widget.speechLocaleId,
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() => _transcript = text);
        if (isFinal) _finalTranscriptCompleter?.complete(text);
      },
    );

    if (mounted) setState(() => _starting = false);
  }

  Future<void> _cancel() async {
    if (_finishing) return;
    _active = false;
    try {
      await _recorder.cancel();
      await widget.speechService.cancelListening();
    } catch (_) {}
    widget.onCancel();
  }

  Future<void> _send() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    _active = false;

    String? path = _filePath;
    try {
      path = await _recorder.stop() ?? _filePath;
    } catch (_) {}

    String finalTranscript = _transcript;
    try {
      _finalTranscriptCompleter = Completer<String>();
      await widget.speechService.stopListening();
      finalTranscript = await _finalTranscriptCompleter!.future
          .timeout(const Duration(seconds: 2), onTimeout: () => _transcript);
    } catch (_) {}

    if (path == null) {
      widget.onCancel();
      return;
    }

    widget.onSend(VoiceRecordingResult(
      filePath: path,
      durationSeconds: _seconds,
      transcript: finalTranscript.trim(),
    ));
  }

  @override
  void dispose() {
    _active = false;
    _pulse.dispose();
    _recorder.dispose();
    super.dispose();
  }

  String get _timeLabel {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              const Icon(Icons.mic_off, color: Colors.red),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_error!,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
              TextButton(onPressed: widget.onCancel, child: const Text('Tutup')),
            ],
          ),
        ),
      );
    }

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: _finishing ? null : _cancel,
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
                                  color: Colors.red.withValues(
                                      alpha: 0.5 + _pulse.value * 0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(_timeLabel,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _finishing
                              ? 'Menerjemahkan...'
                              : (_transcript.isEmpty ? 'Mendengarkan...' : _transcript),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: (_starting || _finishing) ? null : _send,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: (_starting || _finishing)
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: _finishing
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
