import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:provider/provider.dart';
import '../context/app_context.dart';
import '../services/speech_service.dart';
import '../services/translation_service.dart';
import '../services/webrtc_service.dart';
import '../utils/app_colors.dart';
import '../widgets/avatar_widget.dart';

class GroupVideoCallPage extends StatefulWidget {
  final String chatId;
  const GroupVideoCallPage({super.key, required this.chatId});

  @override
  State<GroupVideoCallPage> createState() => _GroupVideoCallPageState();
}

class _GroupVideoCallPageState extends State<GroupVideoCallPage> {
  final _webrtc = WebRTCService();
  bool _micOn = true;
  bool _camOn = true;
  Timer? _timer;
  Timer? _translateDebounce;
  int _elapsed = 0;
  bool _initializing = true;

  late SpeechService _speech;
  late TranslationService _translator;
  late TranslateLanguage _fallbackSource;
  late String _localeId;

  String _translatedEn = '';
  String _translatedId = '';
  String? _activeSpeakerId;

  List<String> _participantIds = [];

  @override
  void initState() {
    super.initState();
    final appCtx = context.read<AppContext>();
    final myLang = appCtx.currentUser?.lang ?? 'id';
    _fallbackSource =
        myLang == 'en' ? TranslateLanguage.english : TranslateLanguage.indonesian;
    _localeId = myLang == 'en' ? 'en_US' : 'id_ID';
    _speech = context.read<SpeechService>();
    _translator = context.read<TranslationService>();

    final chat = appCtx.getChatById(widget.chatId);
    _participantIds = List<String>.from(chat?.participantIds ?? []);
    _activeSpeakerId = appCtx.currentUserId;

    _initCall();
  }

  Future<void> _initCall() async {
    await _webrtc.initialize(true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed++);
    });
    await _speech.startContinuousListening(
      localeId: _localeId,
      onResult: (text, isFinal) {
        if (!mounted || text.trim().isEmpty) return;
        _scheduleTranslate(text);
      },
    );
    if (mounted) setState(() => _initializing = false);
  }

  void _scheduleTranslate(String text) {
    _translateDebounce?.cancel();
    _translateDebounce = Timer(const Duration(milliseconds: 500), () async {
      final result = await _translator.translateAuto(text, fallbackSource: _fallbackSource);
      if (!mounted) return;
      setState(() {
        _translatedEn = result.textEn;
        _translatedId = result.textId;
      });
    });
  }

  void _toggleMic() {
    setState(() => _micOn = !_micOn);
    _webrtc.setMicEnabled(_micOn);
    if (!_micOn) {
      _translateDebounce?.cancel();
      _speech.stopContinuousListening();
      setState(() { _translatedEn = ''; _translatedId = ''; });
    } else {
      _speech.startContinuousListening(localeId: _localeId, onResult: (t, _) {
        if (!mounted || t.trim().isEmpty) return;
        _scheduleTranslate(t);
      });
    }
  }

  void _toggleCam() {
    setState(() => _camOn = !_camOn);
    _webrtc.setCameraEnabled(_camOn);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _translateDebounce?.cancel();
    _speech.stopContinuousListening();
    _webrtc.dispose();
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
    final myId = appCtx.currentUserId ?? '';
    final chat = appCtx.getChatById(widget.chatId);
    final allIds = [myId, ...(_participantIds.where((id) => id != myId))].take(4).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 2×2 grid of participants
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: allIds.length,
                    itemBuilder: (ctx, i) {
                      final uid = allIds[i];
                      final isMe = uid == myId;
                      final isActive = uid == _activeSpeakerId;
                      final user = appCtx.getUserById(uid);
                      final name = isMe ? 'Saya' : (user?.name ?? 'Peserta');

                      return GestureDetector(
                        onTap: () => setState(() => _activeSpeakerId = uid),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16213E),
                            border: isActive
                                ? Border.all(color: Colors.green, width: 2.5)
                                : null,
                          ),
                          child: Stack(
                            children: [
                              // Self tile shows local WebRTC stream; others show avatar
                              if (isMe && _webrtc.isInitialized)
                                Positioned.fill(
                                  child: RTCVideoView(
                                    _webrtc.localRenderer,
                                    mirror: true,
                                    objectFit: RTCVideoViewObjectFit
                                        .RTCVideoViewObjectFitCover,
                                  ),
                                )
                              else
                                Center(child: AvatarWidget(name: name, radius: 30)),

                              // Name label
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(name,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 11)),
                                ),
                              ),

                              // Mic indicator on active
                              if (isActive && _micOn)
                                const Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Icon(Icons.mic, color: Colors.green, size: 16),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
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

          // Timer + group name
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Column(
                  children: [
                    Text(chat?.name ?? 'Panggilan Grup',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(_timerLabel,
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls + translate
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_micOn && (_translatedEn.isNotEmpty || _translatedId.isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.translate, color: AppColors.primary, size: 13),
                              const SizedBox(width: 4),
                              Text('Realtime Translate',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                            ]),
                            const SizedBox(height: 6),
                            Text(_translatedEn.isEmpty ? '...' : _translatedEn,
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(_translatedId.isEmpty ? '...' : _translatedId,
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.textPrimary)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 0, 40, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ControlBtn(
                          icon: _camOn ? Icons.videocam : Icons.videocam_off,
                          onTap: _toggleCam,
                          bg: Colors.white.withValues(alpha: 0.2),
                        ),
                        _ControlBtn(
                          icon: _micOn ? Icons.mic : Icons.mic_off,
                          onTap: _toggleMic,
                          bg: Colors.white.withValues(alpha: 0.2),
                        ),
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

          if (_initializing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
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
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      );
}
