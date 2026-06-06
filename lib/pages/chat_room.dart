import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../context/app_context.dart';
import '../models/app_models.dart';
import '../utils/app_colors.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/chat_background.dart';
import '../widgets/voice_bubble.dart';
import '../widgets/video_attachment_bubble.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatId;
  const ChatRoomPage({super.key, required this.chatId});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _scrollCtrl = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _sendText(String text) async {
    final appCtx = context.read<AppContext>();
    final now = TimeOfDay.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';
    final msg = MessageModel(
      id: 'm${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'me',
      type: 'text',
      textId: text,
      textEn: text,
      time: timeStr,
    );
    await appCtx.sendMessage(widget.chatId, msg);
    _scrollToBottom();
  }

  Future<void> _sendVoice() async {
    final appCtx = context.read<AppContext>();
    final now = TimeOfDay.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';
    final msg = MessageModel(
      id: 'm${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'me',
      type: 'voice',
      durationLabel: '0:08',
      textEn: 'Okay, I will check that soon and get back to you.',
      textId: 'Oke, saya akan segera mengecek itu dan menghubungimu kembali.',
      time: timeStr,
    );
    await appCtx.sendMessage(widget.chatId, msg);
    _scrollToBottom();
  }

  Future<void> _attachVideo() async {
    final appCtx = context.read<AppContext>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Video'),
        content: const Text('Lampirkan video dari galeri?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Lampirkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final now = TimeOfDay.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';
    final msgId = 'v${DateTime.now().millisecondsSinceEpoch}';
    final msg = MessageModel(
      id: msgId,
      senderId: 'me',
      type: 'video',
      videoUrl: 'assets/video/sample.mp4',
      durationLabel: '0:45',
      textEn: 'Check out this video!',
      textId: 'Lihat video ini!',
      time: timeStr,
    );
    await appCtx.sendMessage(widget.chatId, msg);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final appCtx = context.watch<AppContext>();
    final chat = appCtx.getChatById(widget.chatId);
    final contactId = chat?.participantIds.firstOrNull ?? '';
    final contact = appCtx.getUserById(contactId);
    final messages = appCtx.getMessages(widget.chatId);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _ChatAppBar(
            name: contact?.name ?? 'Chat',
            onVoiceCall: () => context.push('/call/${widget.chatId}?type=voice'),
            onVideoCall: () => context.push('/call/${widget.chatId}'),
            onBack: () => context.pop(),
            onTapInfo: contactId.isNotEmpty
                ? () => context.push('/contact-detail/$contactId?chatId=${widget.chatId}')
                : null,
          ),
          Expanded(
            child: ChatBackground(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                itemCount: messages.length,
                itemBuilder: (ctx, i) => _buildMessage(messages[i]),
              ),
            ),
          ),
          ChatInput(
            onSendText: _sendText,
            onSendVoice: _sendVoice,
            onAttachVideo: _attachVideo,
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(MessageModel msg) {
    final isMe = msg.senderId == 'me';
    switch (msg.type) {
      case 'voice':
        return VoiceBubble(message: msg, isMe: isMe);
      case 'video':
        return VideoAttachmentBubble(
          message: msg,
          isMe: isMe,
          onTap: () => context.go('/video-translate/${msg.id}?chatId=${widget.chatId}'),
        );
      default:
        return ChatBubble(textId: msg.textId, textEn: msg.textEn, time: msg.time, isMe: isMe);
    }
  }
}

class _ChatAppBar extends StatelessWidget {
  final String name;
  final VoidCallback onVoiceCall;
  final VoidCallback onVideoCall;
  final VoidCallback onBack;
  final VoidCallback? onTapInfo;

  const _ChatAppBar({
    required this.name,
    required this.onVoiceCall,
    required this.onVideoCall,
    required this.onBack,
    this.onTapInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: onBack),
              Expanded(
                child: GestureDetector(
                  onTap: onTapInfo,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      AvatarWidget(name: name, radius: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const Text('Online', style: TextStyle(fontSize: 11, color: Colors.green)),
                          ],
                        ),
                      ),
                      if (onTapInfo != null)
                        const Icon(Icons.keyboard_arrow_right, color: AppColors.textSecondary, size: 18),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.call, color: AppColors.primary),
                onPressed: onVoiceCall,
                tooltip: 'Panggilan Suara',
              ),
              IconButton(
                icon: const Icon(Icons.videocam, color: AppColors.primary),
                onPressed: onVideoCall,
                tooltip: 'Panggilan Video',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
