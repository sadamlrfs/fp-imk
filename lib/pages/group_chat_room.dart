import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../context/app_context.dart';
import '../models/app_models.dart';
import '../services/supabase_service.dart';
import '../services/translation_service.dart';
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
  final _supa = SupabaseService();
  int _prevMsgCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppContext>().loadMessages(widget.chatId);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String get _timeStr {
    final now = TimeOfDay.now();
    return '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _sendText(String text) async {
    final translator = context.read<TranslationService>();
    final appCtx = context.read<AppContext>();
    final result = await translator.translateAuto(text);

    final localMsg = MessageModel(
      id: const Uuid().v4(),
      senderId: appCtx.currentUserId ?? '',
      type: 'text',
      textId: result.textId,
      textEn: result.textEn,
      time: _timeStr,
    );
    appCtx.addLocalMessage(widget.chatId, localMsg);
    _scrollToBottom();

    await _supa.sendTextMessage(widget.chatId, result.textEn, result.textId);
  }

  Future<void> _sendVoice(VoiceRecordingResult recording) async {
    final translator = context.read<TranslationService>();
    final appCtx = context.read<AppContext>();

    final transcript = recording.transcript.trim();
    final result = transcript.isEmpty
        ? TranslationResult(sourceLanguageCode: 'id', textEn: '', textId: '')
        : await translator.translateAuto(transcript);

    final noSpeech = '(tidak ada ucapan terdeteksi)';
    final localMsg = MessageModel(
      id: const Uuid().v4(),
      senderId: appCtx.currentUserId ?? '',
      type: 'voice',
      audio: recording.filePath,
      duration: recording.durationSeconds,
      durationLabel: _fmtDuration(recording.durationSeconds),
      textEn: transcript.isEmpty ? noSpeech : result.textEn,
      textId: transcript.isEmpty ? noSpeech : result.textId,
      time: _timeStr,
    );
    appCtx.addLocalMessage(widget.chatId, localMsg);
    _scrollToBottom();

    await _supa.sendVoiceMessage(
      widget.chatId,
      recording.filePath,
      recording.durationSeconds,
      transcript.isEmpty ? noSpeech : result.textEn,
      transcript.isEmpty ? noSpeech : result.textId,
    );
  }

  Future<void> _sendAttachment(AttachmentResult attachment) async {
    final appCtx = context.read<AppContext>();
    try {
      if (attachment.type == 'image') {
        final localMsg = MessageModel(
          id: const Uuid().v4(),
          senderId: appCtx.currentUserId ?? '',
          type: 'image',
          imageUrl: attachment.filePath,
          time: _timeStr,
        );
        appCtx.addLocalMessage(widget.chatId, localMsg);
        _scrollToBottom();
        await _supa.sendImageMessage(widget.chatId, attachment.filePath);
      } else if (attachment.type == 'video') {
        final localMsg = MessageModel(
          id: const Uuid().v4(),
          senderId: appCtx.currentUserId ?? '',
          type: 'video',
          videoUrl: attachment.filePath,
          durationLabel: '0:00',
          time: _timeStr,
        );
        appCtx.addLocalMessage(widget.chatId, localMsg);
        _scrollToBottom();
        await _supa.sendVideoMessage(
            widget.chatId, attachment.filePath, attachment.targetLang ?? 'id');
      } else {
        final localMsg = MessageModel(
          id: const Uuid().v4(),
          senderId: appCtx.currentUserId ?? '',
          type: 'file',
          fileName: attachment.fileName,
          fileUrl: attachment.filePath,
          time: _timeStr,
        );
        appCtx.addLocalMessage(widget.chatId, localMsg);
        _scrollToBottom();
        await _supa.sendFileMessage(
            widget.chatId, attachment.filePath, attachment.fileName);
      }
    } catch (e) {
      debugPrint('_sendAttachment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim: ${e.toString().split('\n').first}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _fmtDuration(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final appCtx = context.watch<AppContext>();
    final chat = appCtx.getChatById(widget.chatId);
    final myId = appCtx.currentUserId ?? '';
    final groupName = chat?.name ?? 'Grup';
    final memberCount = (chat?.participantIds.length ?? 0) + 1;
    final messages = appCtx.getMessages(widget.chatId);
    final userLang = appCtx.currentUser?.lang ?? 'id';

    if (messages.length > _prevMsgCount) {
      _prevMsgCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _GroupAppBar(
            name: groupName,
            memberCount: memberCount,
            onBack: () => context.pop(),
            onGroupCall: () => context.push('/group-call/${widget.chatId}'),
            onInfo: () => context.push('/group-detail/${widget.chatId}'),
          ),
          Expanded(
            child: ChatBackground(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                itemCount: messages.length,
                itemBuilder: (ctx, i) => _buildMessage(messages[i], myId, appCtx, userLang),
              ),
            ),
          ),
          ChatInput(
            onSendText: _sendText,
            onSendVoice: _sendVoice,
            onSendAttachment: _sendAttachment,
            speechLocaleId: appCtx.currentUser?.lang == 'en' ? 'en_US' : 'id_ID',
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(MessageModel msg, String myId, AppContext appCtx, String userLang) {
    final isMe = msg.senderId == myId;
    final sender = appCtx.getUserById(msg.senderId);
    final senderName = isMe ? null : sender?.name;

    if (msg.type == 'voice') {
      return VoiceBubble(message: msg, isMe: isMe, senderName: senderName, userLang: userLang);
    }
    return ChatBubble(
      textId: msg.textId,
      textEn: msg.textEn,
      time: msg.time,
      isMe: isMe,
      senderName: senderName,
      userLang: userLang,
    );
  }
}

class _GroupAppBar extends StatelessWidget {
  final String name;
  final int memberCount;
  final VoidCallback onBack;
  final VoidCallback onGroupCall;
  final VoidCallback onInfo;

  const _GroupAppBar({
    required this.name,
    required this.memberCount,
    required this.onBack,
    required this.onGroupCall,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: onBack,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onInfo,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      AvatarWidget(name: name, radius: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            Text('$memberCount anggota',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_right,
                          color: AppColors.textSecondary, size: 18),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.videocam, color: AppColors.primary),
                onPressed: onGroupCall,
                tooltip: 'Panggilan Grup',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
