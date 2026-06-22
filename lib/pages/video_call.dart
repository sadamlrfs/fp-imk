import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../context/app_context.dart';
import '../services/supabase_service.dart';
import '../services/webrtc_service.dart';
import '../utils/app_colors.dart';
import '../widgets/avatar_widget.dart';

class VideoCallPage extends StatefulWidget {
  final String chatId;
  final bool isVideo;
  final bool isCaller;
  final String callRoomId;
  final String remoteUserId;

  const VideoCallPage({
    super.key,
    required this.chatId,
    this.isVideo = true,
    this.isCaller = true,
    this.callRoomId = '',
    this.remoteUserId = '',
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  // WebRTC
  final _webrtc = WebRTCService();
  final _supa = SupabaseService();
  late String _roomId;
  late String _remoteUserId;
  StreamSubscription<List<Map<String, dynamic>>>? _signalSub;
  bool _connected = false;

  // Call controls
  bool _micOn = true;
  bool _camOn = true;
  Timer? _timer;
  int _elapsed = 0;
  bool _initializing = true;
  String _statusText = 'Menghubungkan...';

  // Call logging
  late AppContext _appCtx;
  bool _logged = false;

  // Dummy realtime-translate overlay (real on-device call STT is blocked by
  // WebRTC sharing the mic, so we simulate a translated conversation).
  Timer? _dummyTimer;
  int _dummyIdx = 0;
  String _translatedEn = '';
  String _translatedId = '';

  static const _dummyConversation = [
    ('Hello, can you hear me okay?', 'Halo, apakah kamu bisa mendengarku?'),
    ('Yes, the connection is clear.', 'Ya, koneksinya jernih.'),
    ('How is the weather over there?', 'Bagaimana cuaca di sana?'),
    ('It is sunny and warm today.', 'Hari ini cerah dan hangat.'),
    ('Let us discuss the project plan.', 'Mari kita bahas rencana proyeknya.'),
    ('That sounds like a great idea.', 'Itu terdengar seperti ide bagus.'),
    ('I will share the documents soon.', 'Saya akan membagikan dokumennya segera.'),
    ('Thank you, talk to you later!', 'Terima kasih, sampai jumpa lagi!'),
  ];

  @override
  void initState() {
    super.initState();
    _appCtx = context.read<AppContext>();
    final appCtx = _appCtx;

    // Determine room ID and remote user
    if (widget.isCaller) {
      _roomId = widget.callRoomId.isNotEmpty ? widget.callRoomId : const Uuid().v4();
      // Find remote user from chat
      final chat = appCtx.getChatById(widget.chatId);
      _remoteUserId = widget.remoteUserId.isNotEmpty
          ? widget.remoteUserId
          : (chat?.participantIds.firstOrNull ?? '');
    } else {
      _roomId = widget.callRoomId;
      _remoteUserId = widget.remoteUserId;
    }

    _initCall();
  }

  Future<void> _initCall() async {
    // Initialize WebRTC (get camera/mic)
    await _webrtc.initialize(widget.isVideo);

    _webrtc.onLocalIceCandidate = (candidate) {
      _supa.sendCallSignal(
        roomId: _roomId,
        toUserId: _remoteUserId,
        signalType: 'ice-candidate',
        payload: {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      );
    };

    _webrtc.onConnectionEstablished = () {
      if (!mounted) return;
      setState(() {
        _connected = true;
        _statusText = 'Terhubung';
      });
      _startTimer();
      // Translate overlay is already running from _initCall.
    };

    _webrtc.onConnectionFailed = () {
      if (!mounted) return;
      setState(() => _statusText = 'Koneksi gagal');
    };

    // Subscribe to signals for this room
    _signalSub = _supa.subscribeToCallSignals(_roomId).listen(_handleSignal);

    if (widget.isCaller) {
      // Create offer and send
      final offer = await _webrtc.createOffer();
      await _supa.sendCallSignal(
        roomId: _roomId,
        toUserId: _remoteUserId,
        signalType: 'offer',
        payload: {
          'sdp': offer['sdp'],
          'type': offer['type'],
          'callType': widget.isVideo ? 'video' : 'voice',
        },
      );
      if (mounted) setState(() => _statusText = 'Memanggil...');
    }
    if (mounted) setState(() => _initializing = false);

    // Start the own-mic translate overlay immediately so it's demonstrable
    // even before a peer connects. NOTE: on Android the OS speech recognizer
    // and WebRTC contend for the microphone, so live transcription may not
    // capture while the call holds the mic — a platform limitation.
    if (_micOn) _startTranslateOverlay();
  }

  final _processedSignalIds = <String>{};

  void _handleSignal(List<Map<String, dynamic>> signals) async {
    if (!mounted) return;
    final myId = _supa.currentUserId;
    for (final signal in signals) {
      final sid = signal['id'] as String? ?? '';
      if (_processedSignalIds.contains(sid)) continue;
      _processedSignalIds.add(sid);

      final fromUser = signal['from_user'] as String? ?? '';
      if (fromUser == myId) continue; // skip own signals

      final type = signal['signal_type'] as String? ?? '';
      final payload = Map<String, dynamic>.from(signal['payload'] as Map? ?? {});

      switch (type) {
        case 'offer':
          // Callee receives the caller's offer: build an answer and send it
          // back. Without this the callee never connects.
          if (!widget.isCaller) {
            if (mounted) setState(() => _statusText = 'Menyambungkan...');
            final answer = await _webrtc.createAnswer(payload);
            await _supa.sendCallSignal(
              roomId: _roomId,
              toUserId: fromUser,
              signalType: 'answer',
              payload: {'sdp': answer['sdp'], 'type': answer['type']},
            );
          }
          break;
        case 'answer':
          await _webrtc.setRemoteAnswer(payload);
          break;
        case 'ice-candidate':
          await _webrtc.addRemoteIceCandidate(payload);
          break;
        case 'hangup':
          _endCall();
          break;
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed++);
    });
  }

  void _startTranslateOverlay() {
    if (_dummyTimer != null) return; // already running
    void tick() {
      if (!mounted) return;
      final p = _dummyConversation[_dummyIdx % _dummyConversation.length];
      setState(() {
        _translatedEn = p.$1;
        _translatedId = p.$2;
      });
      _dummyIdx++;
    }

    tick();
    _dummyTimer = Timer.periodic(const Duration(seconds: 3), (_) => tick());
  }

  void _toggleMic() {
    // Muting only stops sending OUR audio to the other side. The translate
    // overlay keeps running regardless, so it is NOT stopped or cleared here.
    setState(() => _micOn = !_micOn);
    _webrtc.setMicEnabled(_micOn);
    _startTranslateOverlay();
  }

  void _toggleCam() {
    setState(() => _camOn = !_camOn);
    _webrtc.setCameraEnabled(_camOn);
  }

  void _endCall() {
    _supa.sendCallSignal(
      roomId: _roomId,
      toUserId: _remoteUserId,
      signalType: 'hangup',
      payload: {'reason': 'ended'},
    );
    if (mounted) context.pop();
  }

  void _logCall() {
    if (_logged) return;
    _logged = true;
    if (_remoteUserId.isEmpty) return;
    _appCtx.logCall(
      contactId: _remoteUserId,
      type: widget.isVideo ? 'video' : 'voice',
      direction: widget.isCaller ? 'outgoing' : 'incoming',
      durationSeconds: _elapsed,
    );
  }

  @override
  void dispose() {
    _logCall();
    _timer?.cancel();
    _dummyTimer?.cancel();
    _signalSub?.cancel();
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
    final chat = appCtx.getChatById(widget.chatId);
    final contactId = _remoteUserId.isNotEmpty
        ? _remoteUserId
        : (chat?.participantIds.firstOrNull ?? '');
    final contact = appCtx.getUserById(contactId);
    final contactName = contact?.name ?? 'Kontak';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Remote video / voice background ──────────────
          Positioned.fill(
            child: widget.isVideo
                ? (_connected
                    ? RTCVideoView(_webrtc.remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                    : _callWaiting(contactName))
                : _voiceCallBg(contactName),
          ),

          // ── Self PiP (video only) ─────────────────────────
          if (widget.isVideo)
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
                clipBehavior: Clip.hardEdge,
                child: _webrtc.isInitialized
                    ? RTCVideoView(_webrtc.localRenderer,
                        mirror: true,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                    : const Center(child: Icon(Icons.person, color: Colors.white38, size: 36)),
              ),
            ),

          // ── Contact label (video mode) ────────────────────
          if (widget.isVideo)
            Positioned(
              top: 60,
              left: 16,
              child: _LabelChip(text: contactName),
            ),

          // ── Back / close ──────────────────────────────────
          Positioned(
            top: 16,
            left: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _endCall,
              ),
            ),
          ),

          // ── Timer ─────────────────────────────────────────
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Text(
                  _connected ? _timerLabel : _statusText,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),
          ),

          // ── Bottom: translate panel + controls ────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Live-translate overlay — always shown during the call so it
                  // keeps translating the conversation even while muted.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _TranslatePanel(
                      textEn: _translatedEn,
                      textId: _translatedId,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 0, 40, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (widget.isVideo)
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
                        // End call
                        GestureDetector(
                          onTap: _endCall,
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
                        if (widget.isVideo)
                          _ControlBtn(
                            icon: Icons.flip_camera_ios_outlined,
                            onTap: () => _webrtc.switchCamera(),
                            bg: Colors.white.withValues(alpha: 0.2),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Initializing overlay ──────────────────────────
          if (_initializing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _callWaiting(String name) => Container(
        color: const Color(0xFF1A1A2E),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AvatarWidget(name: name, radius: 56),
            const SizedBox(height: 20),
            Text(name,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_statusText, style: const TextStyle(color: Colors.white60, fontSize: 14)),
            const SizedBox(height: 24),
            const _PulsingDots(),
          ],
        ),
      );

  Widget _voiceCallBg(String name) => Container(
        color: const Color(0xFF1A1A2E),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AvatarWidget(name: name, radius: 60),
            const SizedBox(height: 20),
            Text(name,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_connected ? 'Panggilan Suara' : _statusText,
                style: const TextStyle(color: Colors.white60, fontSize: 14)),
          ],
        ),
      );
}

// ── Widgets ────────────────────────────────────────────────

class _TranslatePanel extends StatelessWidget {
  final String textEn;
  final String textId;
  const _TranslatePanel({required this.textEn, required this.textId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const Spacer(),
              _ListeningDot(),
            ],
          ),
          const SizedBox(height: 8),
          Text('Bahasa Inggris',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(
            textEn.isEmpty ? 'Mendengarkan...' : textEn,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
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
                const Text('Bahasa Indonesia',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: 4),
                Text(
                  textId.isEmpty ? 'Mendengarkan...' : textId,
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  final String text;
  const _LabelChip({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      );
}

class _ListeningDot extends StatefulWidget {
  @override
  State<_ListeningDot> createState() => _ListeningDotState();
}

class _ListeningDotState extends State<_ListeningDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.4 + _ctrl.value * 0.6),
            shape: BoxShape.circle,
          ),
        ),
      );
}

class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final t = ((_ctrl.value - delay) % 1.0 + 1.0) % 1.0;
            final opacity = (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.2, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  // Always-dark call screen: keep dots white regardless of theme.
                  color: Colors.white.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ),
      );
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
