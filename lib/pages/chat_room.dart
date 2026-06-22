import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
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
import '../widgets/video_attachment_bubble.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatId;
  const ChatRoomPage({super.key, required this.chatId});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final _scrollCtrl = ScrollController();
  final _supa = SupabaseService();
  int _prevMsgCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appCtx = context.read<AppContext>();
      appCtx.setActiveChat(widget.chatId);
      appCtx.loadMessages(widget.chatId);
    });
  }

  @override
  void dispose() {
    // Best-effort: clear the active chat so background notifications resume.
    try {
      context.read<AppContext>().setActiveChat(null);
    } catch (_) {}
    _scrollCtrl.dispose();
    super.dispose();
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

    // Optimistic local msg
    final tempId = const Uuid().v4();
    final localMsg = MessageModel(
      id: tempId,
      senderId: appCtx.currentUserId ?? '',
      type: 'text',
      textId: result.textId,
      textEn: result.textEn,
      time: _timeStr,
    );
    appCtx.addLocalMessage(widget.chatId, localMsg);
    _scrollToBottom();

    // Persist to Supabase
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

    // Optimistic local msg
    final tempId = const Uuid().v4();
    final localMsg = MessageModel(
      id: tempId,
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

    // Upload + persist
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
    final tempId = const Uuid().v4();

    try {
      MessageModel sent;
      if (attachment.type == 'image') {
        final localMsg = MessageModel(
          id: tempId,
          senderId: appCtx.currentUserId ?? '',
          type: 'image',
          imageUrl: attachment.filePath,
          time: _timeStr,
        );
        appCtx.addLocalMessage(widget.chatId, localMsg);
        _scrollToBottom();
        sent = await _supa.sendImageMessage(widget.chatId, attachment.filePath);
      } else if (attachment.type == 'video') {
        // Dummy auto-translate of the video's "spoken" content (real on-device
        // video STT isn't wired yet) — no caption is asked from the user.
        const textEn = 'Hi everyone, thanks for watching this video. '
            'Hope you find it useful and have a wonderful day!';
        const textId = 'Hai semuanya, terima kasih sudah menonton video ini. '
            'Semoga bermanfaat dan semoga harimu menyenangkan!';
        final localMsg = MessageModel(
          id: tempId,
          senderId: appCtx.currentUserId ?? '',
          type: 'video',
          videoUrl: attachment.filePath,
          durationLabel: '0:00',
          textEn: textEn,
          textId: textId,
          time: _timeStr,
        );
        appCtx.addLocalMessage(widget.chatId, localMsg);
        _scrollToBottom();
        sent = await _supa.sendVideoMessage(
            widget.chatId, attachment.filePath, attachment.targetLang ?? 'id',
            textEn: textEn, textId: textId);
      } else {
        final localMsg = MessageModel(
          id: tempId,
          senderId: appCtx.currentUserId ?? '',
          type: 'file',
          fileName: attachment.fileName,
          fileUrl: attachment.filePath,
          time: _timeStr,
        );
        appCtx.addLocalMessage(widget.chatId, localMsg);
        _scrollToBottom();
        sent = await _supa.sendFileMessage(
            widget.chatId, attachment.filePath, attachment.fileName);
      }
      // Swap the optimistic copy for the confirmed server message so the
      // attachment stays visible even if the realtime stream lags.
      appCtx.replaceLocalMessage(widget.chatId, tempId, sent);
    } catch (e) {
      debugPrint('_sendAttachment error: $e');
      // Remove the stuck optimistic bubble so it doesn't look half-sent.
      appCtx.removeLocalMessage(widget.chatId, tempId);
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
    final contactId = chat?.participantIds.firstOrNull ?? '';
    final contact = appCtx.getUserById(contactId);
    final messages = appCtx.getMessages(widget.chatId);
    final userLang = appCtx.currentUser?.lang ?? 'id';

    // Auto-scroll to bottom whenever new messages arrive (from others or self)
    if (messages.length > _prevMsgCount) {
      _prevMsgCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _ChatAppBar(
            name: contact?.name ?? 'Chat',
            onVoiceCall: () => context.push(
                '/call/${widget.chatId}?type=voice&remoteUserId=$contactId'),
            onVideoCall: () => context.push(
                '/call/${widget.chatId}?remoteUserId=$contactId'),
            onBack: () => context.pop(),
            onTapInfo: contactId.isNotEmpty
                ? () => context.push(
                    '/contact-detail/$contactId?chatId=${widget.chatId}')
                : null,
          ),
          Expanded(
            child: ChatBackground(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                itemCount: messages.length,
                itemBuilder: (ctx, i) => _buildMessage(messages[i], myId, userLang),
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

  Widget _buildMessage(MessageModel msg, String myId, String userLang) {
    final isMe = msg.senderId == myId;
    switch (msg.type) {
      case 'voice':
        return VoiceBubble(message: msg, isMe: isMe, userLang: userLang);
      case 'video':
        return VideoAttachmentBubble(
          message: msg,
          isMe: isMe,
          onTap: () => context.push(
              '/video-translate/${msg.id}?chatId=${widget.chatId}'),
        );
      case 'image':
        return _ImageBubble(msg: msg, isMe: isMe);
      case 'file':
        return _FileBubble(msg: msg, isMe: isMe);
      default:
        return ChatBubble(
            textId: msg.textId, textEn: msg.textEn,
            time: msg.time, isMe: isMe, userLang: userLang);
    }
  }
}

// ── Image bubble ──────────────────────────────────────────

class _ImageBubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  const _ImageBubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final url = msg.imageUrl ?? '';
    final isNetwork = url.startsWith('http');
    final isLocal = url.isNotEmpty && !isNetwork;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: const BoxConstraints(maxWidth: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            if (isNetwork)
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                width: 220,
                placeholder: (ctx, url2) => const SizedBox(
                  width: 220, height: 160,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (ctx, url2, err) => const SizedBox(
                  width: 220, height: 160,
                  child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                ),
              )
            else if (isLocal)
              Image.file(File(url), fit: BoxFit.cover, width: 220,
                  errorBuilder: (ctx, err, stack) => const SizedBox(
                    width: 220, height: 160,
                    child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                  ))
            else
              const SizedBox(
                width: 220, height: 160,
                child: Center(child: Icon(Icons.image, color: Colors.grey, size: 40)),
              ),
            // Upload indicator for local files (not yet uploaded)
            if (isLocal)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: const Center(
                    child: SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)),
                  ),
                ),
              ),
            Positioned(
              bottom: 6,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(msg.time,
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── File bubble ───────────────────────────────────────────

class _FileBubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  const _FileBubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file,
                color: isMe ? Colors.white : AppColors.primary, size: 28),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.fileName ?? 'Berkas',
                    style: TextStyle(
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(msg.time,
                      style: TextStyle(
                          color: isMe ? Colors.white70 : AppColors.textSecondary,
                          fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── App bar ───────────────────────────────────────────────

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
                            Text(name,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            const Text('Online',
                                style: TextStyle(fontSize: 11, color: Colors.green)),
                          ],
                        ),
                      ),
                      if (onTapInfo != null)
                        Icon(Icons.keyboard_arrow_right,
                            color: AppColors.textSecondary, size: 18),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.call, color: AppColors.primary),
                onPressed: onVoiceCall,
              ),
              IconButton(
                icon: const Icon(Icons.videocam, color: AppColors.primary),
                onPressed: onVideoCall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
