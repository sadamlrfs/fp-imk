import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/app_models.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // ── Auth ──────────────────────────────────────────────────
  User? get currentUser => client.auth.currentUser;
  String? get currentUserId => client.auth.currentUser?.id;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password, String name, String lang) async {
    await client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'lang': lang},
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> signInWithGoogle() async {
    const webClientId =
        '758102825814-sv4jg3bl0egedahc6vc6gb9d349q0kt8.apps.googleusercontent.com';
    const androidClientId =
        '758102825814-v6rgi0430ottk6cf1u40vtdbejq0v2ur.apps.googleusercontent.com';

    final googleSignIn = GoogleSignIn(
      clientId: androidClientId,
      serverClientId: webClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return; // user cancelled

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) throw Exception('Google ID token not received');

    await client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
  }

  // ── Profiles ──────────────────────────────────────────────
  Future<UserModel?> getProfile(String userId) async {
    try {
      final data = await client.from('profiles').select().eq('id', userId).maybeSingle();
      if (data == null) return null;
      return UserModel.fromSupabase(data);
    } catch (e) {
      debugPrint('getProfile error: $e');
      return null;
    }
  }

  Future<List<UserModel>> getAllProfiles() async {
    try {
      final data = await client.from('profiles').select();
      return (data as List).map((d) => UserModel.fromSupabase(d)).toList();
    } catch (e) {
      debugPrint('getAllProfiles error: $e');
      return [];
    }
  }

  Future<void> updateProfile(String userId, {
    String? name,
    String? bio,
    String? phone,
    String? avatarUrl,
    String? lang,
  }) async {
    final updates = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};
    if (name != null) updates['name'] = name;
    if (bio != null) updates['bio'] = bio;
    if (phone != null) updates['phone'] = phone;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (lang != null) updates['preferred_lang'] = lang;
    await client.from('profiles').update(updates).eq('id', userId);
  }

  // ── Contacts ──────────────────────────────────────────────
  Future<List<String>> getMyContactIds() async {
    try {
      final myId = currentUserId;
      if (myId == null) return [];
      final data = await client
          .from('contacts')
          .select('contact_id')
          .eq('user_id', myId);
      return (data as List).map((r) => r['contact_id'] as String).toList();
    } catch (e) {
      debugPrint('getMyContactIds error: $e');
      return [];
    }
  }

  Future<void> addContact(String contactId) async {
    final myId = currentUserId!;
    await client.from('contacts').upsert({
      'user_id': myId,
      'contact_id': contactId,
    }, onConflict: 'user_id,contact_id');
  }

  Future<void> removeContact(String contactId) async {
    final myId = currentUserId!;
    await client
        .from('contacts')
        .delete()
        .eq('user_id', myId)
        .eq('contact_id', contactId);
  }

  // ── Chats ─────────────────────────────────────────────────
  Future<List<ChatModel>> getChats() async {
    try {
      final myId = currentUserId;
      if (myId == null) return [];

      final memberRows = await client
          .from('chat_members')
          .select('chat_id')
          .eq('user_id', myId);

      final chatIds = (memberRows as List).map((m) => m['chat_id'] as String).toList();
      if (chatIds.isEmpty) return [];

      final chatsData = await client.from('chats').select().inFilter('id', chatIds);

      final List<ChatModel> result = [];
      for (final chatData in (chatsData as List)) {
        final cId = chatData['id'] as String;

        final membersData = await client
            .from('chat_members')
            .select('user_id')
            .eq('chat_id', cId);

        final participantIds = (membersData as List)
            .map((m) => m['user_id'] as String)
            .where((id) => id != myId)
            .toList();

        final lastMsgData = await client
            .from('messages')
            .select()
            .eq('chat_id', cId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        result.add(ChatModel(
          id: cId,
          type: chatData['type'] as String,
          name: chatData['name'] as String?,
          avatar: chatData['avatar_url'] as String?,
          participantIds: participantIds,
          lastMessage: _lastMsgText(lastMsgData),
          lastMessageType: (lastMsgData?['type'] as String?) ?? 'text',
          time: _fmtTime(
              (lastMsgData?['created_at'] as String?) ?? (chatData['created_at'] as String)),
          unread: 0,
        ));
      }

      result.sort((a, b) => b.time.compareTo(a.time));
      return result;
    } catch (e) {
      debugPrint('getChats error: $e');
      return [];
    }
  }

  String _lastMsgText(Map? msg) {
    if (msg == null) return 'Mulai percakapan';
    switch (msg['type']) {
      case 'voice': return '🎵 Pesan suara';
      case 'image': return '📷 Foto';
      case 'video': return '🎬 Video';
      case 'file': return '📄 Berkas';
      default: return (msg['text_id'] as String?) ?? (msg['text_en'] as String?) ?? '';
    }
  }

  String _fmtTime(String isoString) {
    final dt = DateTime.tryParse(isoString)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return '${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }

  Future<String?> findDirectChat(String otherUserId) async {
    try {
      final myId = currentUserId;
      if (myId == null) return null;

      final myRows = await client.from('chat_members').select('chat_id').eq('user_id', myId);
      final myChatIds = (myRows as List).map((m) => m['chat_id'] as String).toList();
      if (myChatIds.isEmpty) return null;

      final otherRows = await client
          .from('chat_members')
          .select('chat_id')
          .eq('user_id', otherUserId)
          .inFilter('chat_id', myChatIds);

      final sharedIds = (otherRows as List).map((m) => m['chat_id'] as String).toList();
      if (sharedIds.isEmpty) return null;

      final directChat = await client
          .from('chats')
          .select('id')
          .eq('type', 'direct')
          .inFilter('id', sharedIds)
          .maybeSingle();

      return directChat?['id'] as String?;
    } catch (e) {
      debugPrint('findDirectChat error: $e');
      return null;
    }
  }

  Future<String> createDirectChat(String otherUserId) async {
    final myId = currentUserId!;
    final existing = await findDirectChat(otherUserId);
    if (existing != null) return existing;

    // Generate ID client-side so we can insert members without a SELECT round-trip.
    // Doing .insert().select() would fail: the chats SELECT policy checks chat_members,
    // which doesn't exist yet at that point.
    final chatId = const Uuid().v4();
    await client.from('chats').insert({
      'id': chatId,
      'type': 'direct',
      'created_by': myId,
    });
    await client.from('chat_members').insert([
      {'chat_id': chatId, 'user_id': myId},
      {'chat_id': chatId, 'user_id': otherUserId},
    ]);
    return chatId;
  }

  Future<String> createGroupChat(String name, List<String> memberIds) async {
    final myId = currentUserId!;
    final chatId = const Uuid().v4();
    await client.from('chats').insert({
      'id': chatId,
      'type': 'group',
      'name': name,
      'created_by': myId,
    });
    final allMembers = {myId, ...memberIds};
    await client.from('chat_members').insert(
      allMembers.map((uid) => {'chat_id': chatId, 'user_id': uid}).toList(),
    );
    return chatId;
  }

  Future<void> updateChatName(String chatId, String name) async {
    await client.from('chats').update({'name': name}).eq('id', chatId);
  }

  Future<void> addChatMember(String chatId, String userId) async {
    await client.from('chat_members').insert({'chat_id': chatId, 'user_id': userId});
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final q = query.trim();
      if (q.isEmpty) return [];
      final data = await client
          .from('profiles')
          .select()
          .or('name.ilike.%$q%,phone.ilike.%$q%')
          .neq('id', currentUserId ?? '')
          .limit(10);
      return (data as List).map((d) => UserModel.fromSupabase(d)).toList();
    } catch (e) {
      debugPrint('searchUsers error: $e');
      return [];
    }
  }

  // ── Messages ──────────────────────────────────────────────
  Future<List<MessageModel>> getMessages(String chatId) async {
    try {
      final data = await client
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at');
      return (data as List).map((d) => MessageModel.fromSupabase(d)).toList();
    } catch (e) {
      debugPrint('getMessages error: $e');
      return [];
    }
  }

  Future<MessageModel> sendTextMessage(String chatId, String? textEn, String? textId) async {
    final myId = currentUserId!;
    final data = await client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': myId,
      'type': 'text',
      'text_en': textEn,
      'text_id': textId,
    }).select().single();
    return MessageModel.fromSupabase(data);
  }

  Future<MessageModel> sendVoiceMessage(
    String chatId,
    String localPath,
    int durationSeconds,
    String? textEn,
    String? textId,
  ) async {
    final myId = currentUserId!;
    final url = await uploadVoiceNote(localPath);
    final data = await client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': myId,
      'type': 'voice',
      'text_en': textEn,
      'text_id': textId,
      'file_url': url,
      'duration_seconds': durationSeconds,
    }).select().single();
    return MessageModel.fromSupabase(data);
  }

  Future<MessageModel> sendImageMessage(String chatId, String localPath) async {
    final myId = currentUserId!;
    final ext = localPath.split('.').last.toLowerCase();
    final contentType = _contentType(ext);
    final url = await uploadAttachment(localPath, contentType);
    final data = await client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': myId,
      'type': 'image',
      'file_url': url,
    }).select().single();
    return MessageModel.fromSupabase(data);
  }

  Future<MessageModel> sendFileMessage(
      String chatId, String localPath, String fileName) async {
    final myId = currentUserId!;
    final ext = localPath.split('.').last.toLowerCase();
    final contentType = _contentType(ext);
    final url = await uploadAttachment(localPath, contentType);
    final data = await client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': myId,
      'type': 'file',
      'file_url': url,
      'file_name': fileName,
    }).select().single();
    return MessageModel.fromSupabase(data);
  }

  Future<MessageModel> sendVideoMessage(
      String chatId, String localPath, String targetLang,
      {String? textEn, String? textId}) async {
    final myId = currentUserId!;
    final ext = localPath.split('.').last.toLowerCase();
    final contentType = _contentType(ext);
    final url = await uploadAttachment(localPath, contentType);
    final data = await client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': myId,
      'type': 'video',
      'file_url': url,
      'file_name': 'video_$targetLang.$ext',
      'text_en': textEn,
      'text_id': textId,
    }).select().single();
    return MessageModel.fromSupabase(data);
  }

  String _contentType(String ext) {
    switch (ext) {
      case 'pdf': return 'application/pdf';
      case 'doc':
      case 'docx': return 'application/msword';
      case 'mp4': return 'video/mp4';
      case 'mov': return 'video/quicktime';
      case 'avi': return 'video/x-msvideo';
      case 'mkv': return 'video/x-matroska';
      case '3gp': return 'video/3gpp';
      case 'webm': return 'video/webm';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'webp': return 'image/webp';
      case 'heic':
      case 'heif': return 'image/heic';
      default: return 'application/octet-stream';
    }
  }

  Stream<List<Map<String, dynamic>>> subscribeToMessages(String chatId) {
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at');
  }

  // ── Storage ───────────────────────────────────────────────
  Future<String> uploadVoiceNote(String localPath) async {
    final bytes = await File(localPath).readAsBytes();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '$currentUserId/voice_$ts.m4a';
    await client.storage.from('voice-notes').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'audio/mp4'),
    );
    return client.storage.from('voice-notes').getPublicUrl(path);
  }

  Future<String> uploadAttachment(String localPath, String contentType) async {
    final bytes = await File(localPath).readAsBytes();
    final ext = localPath.split('.').last;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '$currentUserId/attach_$ts.$ext';
    await client.storage.from('attachments').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType),
    );
    return client.storage.from('attachments').getPublicUrl(path);
  }

  Future<String> uploadAvatar(String localPath) async {
    final bytes = await File(localPath).readAsBytes();
    final ext = localPath.split('.').last;
    final path = '$currentUserId/avatar.$ext';
    await client.storage.from('avatars').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
    );
    return client.storage.from('avatars').getPublicUrl(path);
  }

  // ── WebRTC Signaling ──────────────────────────────────────
  Future<void> sendCallSignal({
    required String roomId,
    required String toUserId,
    required String signalType,
    required Map<String, dynamic> payload,
  }) async {
    await client.from('call_signals').insert({
      'room_id': roomId,
      'from_user': currentUserId,
      'to_user': toUserId,
      'signal_type': signalType,
      'payload': payload,
    });
  }

  Stream<List<Map<String, dynamic>>> subscribeToCallSignals(String roomId) {
    return client
        .from('call_signals')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at');
  }

  RealtimeChannel subscribeToIncomingCalls(
    String userId,
    void Function(Map<String, dynamic> signal) onSignal,
  ) {
    return client
        .channel('incoming-calls-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'call_signals',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'to_user',
            value: userId,
          ),
          callback: (payload) => onSignal(payload.newRecord),
        )
        .subscribe();
  }

  /// Fires for every newly inserted message the current user is allowed to see
  /// (RLS limits it to their own chats). Used to keep the chat list live and to
  /// raise in-app notifications, independent of which chat is open.
  RealtimeChannel subscribeToAllMessages(
    void Function(Map<String, dynamic> message) onInsert,
  ) {
    return client
        .channel('messages-feed-${currentUserId ?? 'anon'}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) => onInsert(payload.newRecord),
        )
        .subscribe();
  }

  // ── Call log ──────────────────────────────────────────────
  Future<void> logCall({
    required String contactId,
    required String type,
    required String direction,
    required int durationSeconds,
  }) async {
    final myId = currentUserId;
    if (myId == null) return;
    try {
      await client.from('calls').insert({
        'user_id': myId,
        'contact_id': contactId,
        'type': type,
        'direction': direction,
        'duration_seconds': durationSeconds,
      });
    } catch (e) {
      debugPrint('logCall error: $e');
    }
  }

  Future<List<CallModel>> getCalls() async {
    try {
      final myId = currentUserId;
      if (myId == null) return [];
      final data = await client
          .from('calls')
          .select()
          .eq('user_id', myId)
          .order('created_at', ascending: false)
          .limit(100);
      return (data as List)
          .map((r) => _callFromRow(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getCalls error: $e');
      return [];
    }
  }

  RealtimeChannel subscribeToCalls(void Function() onChange) {
    return client
        .channel('calls-feed-${currentUserId ?? 'anon'}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'calls',
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  CallModel _callFromRow(Map<String, dynamic> r) {
    final dt = DateTime.tryParse(r['created_at'] as String? ?? '')?.toLocal();
    final dur = (r['duration_seconds'] as int?) ?? 0;
    return CallModel(
      id: r['id'] as String? ?? '',
      contactId: r['contact_id'] as String? ?? '',
      contactName: '', // resolved against profiles in the UI layer
      type: r['type'] as String? ?? 'voice',
      direction: r['direction'] as String? ?? 'outgoing',
      date: dt != null ? '${dt.day}/${dt.month}/${dt.year}' : '',
      time: dt != null
          ? '${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')}'
          : '',
      duration: _fmtCallDuration(dur),
    );
  }

  static String _fmtCallDuration(int seconds) {
    if (seconds <= 0) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
