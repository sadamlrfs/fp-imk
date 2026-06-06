import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../context/app_context.dart';
import '../models/app_models.dart';
import '../utils/app_colors.dart';
import '../widgets/avatar_widget.dart';

class GroupVideoCallPage extends StatefulWidget {
  final String chatId;
  const GroupVideoCallPage({super.key, required this.chatId});

  @override
  State<GroupVideoCallPage> createState() => _GroupVideoCallPageState();
}

class _GroupVideoCallPageState extends State<GroupVideoCallPage> {
  String _activeSpeakerId = 'u1';
  int _scriptIndex = 0;
  bool _micOn = true;
  bool _camOn = true;
  Timer? _timer;
  int _elapsed = 0;

  final _participants = ['u1', 'u2', 'u3', 'me'];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed++);
      if (_elapsed % 3 == 0) {
        final ctx = context.read<AppContext>();
        final scripts = ctx.scripts['group'] ?? [];
        if (scripts.isNotEmpty) {
          final nextIndex = (_scriptIndex + 1) % scripts.length;
          final nextSpeaker = scripts[nextIndex].speakerId;
          setState(() {
            _scriptIndex = nextIndex;
            _activeSpeakerId = nextSpeaker;
          });
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
    final scripts = appCtx.scripts['group'] ?? [];
    final currentScript = scripts.isNotEmpty ? scripts[_scriptIndex] : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/group/${widget.chatId}'),
                    child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Group IMK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ),
                  Text(_timerLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            // 2x2 grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _participants.map((uid) {
                    final user = uid == 'me'
                        ? appCtx.getUserById('me')
                        : appCtx.getUserById(uid);
                    final label = uid == 'me' ? 'You' : (user?.name ?? uid);
                    return _ParticipantTile(
                      name: label,
                      isActive: uid == _activeSpeakerId,
                      onTap: () => setState(() => _activeSpeakerId = uid),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Translate panel
            if (currentScript != null)
              _TranslatePanel(
                script: currentScript,
                appCtx: appCtx,
              ),
            // Controls
            _BottomControls(
              micOn: _micOn,
              camOn: _camOn,
              onMicToggle: () => setState(() => _micOn = !_micOn),
              onCamToggle: () => setState(() => _camOn = !_camOn),
              onEnd: () => context.go('/group/${widget.chatId}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final String name;
  final bool isActive;
  final VoidCallback onTap;

  const _ParticipantTile({required this.name, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? Colors.green : Colors.transparent,
            width: 3,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AvatarWidget(name: name, radius: 36),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  AvatarWidget(name: name, radius: 10),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isActive)
                    const Icon(Icons.mic, color: Colors.white, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TranslatePanel extends StatelessWidget {
  final TranslateScript script;
  final AppContext appCtx;

  const _TranslatePanel({required this.script, required this.appCtx});

  @override
  Widget build(BuildContext context) {
    final speaker = appCtx.getUserById(script.speakerId);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(name: speaker?.name ?? script.speakerName, radius: 14),
              const SizedBox(width: 8),
              Text(script.speakerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Bahasa Inggris', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(script.textEn, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
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
                Text(script.textId, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final bool micOn;
  final bool camOn;
  final VoidCallback onMicToggle;
  final VoidCallback onCamToggle;
  final VoidCallback onEnd;

  const _BottomControls({
    required this.micOn,
    required this.camOn,
    required this.onMicToggle,
    required this.onCamToggle,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(40, 12, 40, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Btn(icon: camOn ? Icons.videocam : Icons.videocam_off, onTap: onCamToggle),
          _Btn(icon: micOn ? Icons.mic : Icons.mic_off, onTap: onMicToggle),
          // End call pill
          GestureDetector(
            onTap: onEnd,
            child: Container(
              width: 72,
              height: 52,
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(26)),
              child: const Icon(Icons.call_end, color: Colors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _Btn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
    );
  }
}
