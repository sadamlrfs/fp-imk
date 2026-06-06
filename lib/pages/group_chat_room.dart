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

class GroupChatRoomPage extends StatefulWidget {
  final String chatId;
  const GroupChatRoomPage({super.key, required this.chatId});

  @override
  State<GroupChatRoomPage> createState() => _GroupChatRoomPageState();
}

class _GroupChatRoomPageState extends State<GroupChatRoomPage> {
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
      durationLabel: '0:06',
      textEn: 'I will join the meeting in 5 minutes.',
      textId: 'Saya akan bergabung dalam 5 menit lagi.',
      time: timeStr,
    );
    await appCtx.sendMessage(widget.chatId, msg);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final appCtx = context.watch<AppContext>();
    final chat = appCtx.getChatById(widget.chatId);
    final groupName = chat?.name ?? 'Group';
    final memberCount = chat?.participantIds.length ?? 0;
    final messages = appCtx.getMessages(widget.chatId);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _GroupAppBar(
            name: groupName,
            memberCount: memberCount,
            members: chat?.participantIds ?? [],
            appCtx: appCtx,
            onVoiceCall: () => context.push('/call/${widget.chatId}?type=voice'),
            onVideoCall: () => context.push('/group-call/${widget.chatId}'),
            onBack: () => context.pop(),
            onTapInfo: () => context.push('/group-detail/${widget.chatId}'),
          ),
          Expanded(
            child: ChatBackground(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                itemCount: messages.length,
                itemBuilder: (ctx, i) => _buildMessage(messages[i], appCtx),
              ),
            ),
          ),
          ChatInput(
            onSendText: _sendText,
            onSendVoice: _sendVoice,
            onAttachVideo: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(MessageModel msg, AppContext ctx) {
    final isMe = msg.senderId == 'me';
    final sender = ctx.getUserById(msg.senderId);
    final senderName = isMe ? null : (sender?.name ?? 'Unknown');

    if (msg.type == 'voice') {
      return VoiceBubble(message: msg, isMe: isMe, senderName: senderName);
    }
    return ChatBubble(textId: msg.textId, textEn: msg.textEn, time: msg.time, isMe: isMe, senderName: senderName);
  }
}

class _GroupAppBar extends StatelessWidget {
  final String name;
  final int memberCount;
  final List<String> members;
  final AppContext appCtx;
  final VoidCallback onVoiceCall;
  final VoidCallback onVideoCall;
  final VoidCallback onBack;
  final VoidCallback? onTapInfo;

  const _GroupAppBar({
    required this.name,
    required this.memberCount,
    required this.members,
    required this.appCtx,
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
                      SizedBox(
                        width: 52,
                        height: 40,
                        child: Stack(
                          children: [
                            for (int i = 0; i < members.length.clamp(0, 3); i++)
                              Positioned(
                                left: i * 14.0,
                                child: AvatarWidget(
                                  name: appCtx.getUserById(members[i])?.name ?? 'U',
                                  radius: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            Text('$memberCount anggota', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
