import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';
import '../services/supabase_service.dart';

class IncomingCallInfo {
  final String roomId;
  final String fromUserId;
  final String fromUserName;
  final String callType;
  final Map<String, dynamic> offerPayload;

  IncomingCallInfo({
    required this.roomId,
    required this.fromUserId,
    required this.fromUserName,
    required this.callType,
    required this.offerPayload,
  });
}

class AppNotification {
  final String id;
  final String type; // 'message' | 'call'
  final String title;
  final String body;
  final String? chatId;
  final DateTime time;
  bool read;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.chatId,
    DateTime? time,
    this.read = false,
  }) : time = time ?? DateTime.now();
}

class AppContext extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();

  List<UserModel> _users = [];
  List<ChatModel> _chats = [];
  List<CallModel> _calls = [];
  final Map<String, List<MessageModel>> _messages = {};
  Set<String> _contactIds = {};
  bool _isLoaded = false;
  String? _currentUserId;

  // Realtime subscriptions per chat
  final Map<String, StreamSubscription<List<Map<String, dynamic>>>> _msgSubs = {};

  // Incoming call
  RealtimeChannel? _callChannel;
  ValueNotifier<IncomingCallInfo?> incomingCallNotifier = ValueNotifier(null);

  // Global message feed + notifications
  RealtimeChannel? _msgFeedChannel;
  RealtimeChannel? _callsFeedChannel;
  final List<AppNotification> _notifications = [];
  ValueNotifier<AppNotification?> bannerNotifier = ValueNotifier(null);
  String? _activeChatId; // chat currently open, so we don't notify for it

  List<UserModel> get users => _users;
  List<ChatModel> get chats => _chats;
  List<CallModel> get calls => _calls;
  Set<String> get contactIds => _contactIds;
  bool get isLoaded => _isLoaded;
  String? get currentUserId => _currentUserId;

  // Newest first.
  List<AppNotification> get notifications => _notifications.reversed.toList();
  int get unreadNotificationCount => _notifications.where((n) => !n.read).length;

  void setActiveChat(String? chatId) {
    _activeChatId = chatId;
    if (chatId != null) {
      // Opening a chat clears its pending notifications.
      var changed = false;
      for (final n in _notifications) {
        if (n.chatId == chatId && !n.read) {
          n.read = true;
          changed = true;
        }
      }
      if (changed) notifyListeners();
    }
  }

  void markAllNotificationsRead() {
    for (final n in _notifications) {
      n.read = true;
    }
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  List<UserModel> get contacts =>
      _users.where((u) => _contactIds.contains(u.id)).toList();

  UserModel? get currentUser {
    if (_currentUserId == null || _users.isEmpty) return null;
    try {
      return _users.firstWhere((u) => u.id == _currentUserId);
    } catch (_) {
      return null;
    }
  }

  UserModel? getUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  ChatModel? getChatById(String id) {
    try {
      return _chats.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<MessageModel> getMessages(String chatId) => _messages[chatId] ?? [];

  Future<void> loadData() async {
    _currentUserId = _supabase.currentUserId;
    if (_currentUserId == null) return;

    try {
      _users = await _supabase.getAllProfiles();
      _chats = await _supabase.getChats();
      _calls = await _supabase.getCalls();
      _contactIds = (await _supabase.getMyContactIds()).toSet();
      _isLoaded = true;
      notifyListeners();
      _setupIncomingCallListener();
      _setupMessageFeed();
      _setupCallsFeed();
    } catch (e) {
      debugPrint('AppContext.loadData error: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String chatId) async {
    final msgs = await _supabase.getMessages(chatId);
    msgs.sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
    _messages[chatId] = msgs;
    notifyListeners();

    // Subscribe to real-time updates for this chat
    _msgSubs[chatId]?.cancel();
    _msgSubs[chatId] = _supabase.subscribeToMessages(chatId).listen((data) {
      final updated = data.map((d) => MessageModel.fromSupabase(d)).toList();
      updated.sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
      _messages[chatId] = updated;
      _syncChatLastMessage(chatId, updated.isNotEmpty ? updated.last : null);
      notifyListeners();
    });
  }

  void _syncChatLastMessage(String chatId, MessageModel? last) {
    if (last == null) return;
    _chats = _chats.map((c) {
      if (c.id != chatId) return c;
      return ChatModel(
        id: c.id,
        type: c.type,
        name: c.name,
        avatar: c.avatar,
        participantIds: c.participantIds,
        lastMessage: _msgPreview(last),
        lastMessageType: last.type,
        time: last.time,
        unread: c.unread,
      );
    }).toList();
  }

  String _msgPreview(MessageModel m) {
    switch (m.type) {
      case 'voice': return '🎵 Pesan suara';
      case 'image': return '📷 Foto';
      case 'video': return '🎬 Video';
      case 'file': return '📄 ${m.fileName ?? 'Berkas'}';
      default: return m.textId ?? m.textEn ?? '';
    }
  }

  // Called by pages to send a text message
  Future<void> sendMessage(String chatId, MessageModel msg) async {
    // Optimistic local insert
    _messages[chatId] ??= [];
    _messages[chatId]!.add(msg);
    _syncChatLastMessage(chatId, msg);
    notifyListeners();
  }

  // For caller: add a local voice/image message temporarily before Supabase confirms
  void addLocalMessage(String chatId, MessageModel msg) {
    _messages[chatId] ??= [];
    _messages[chatId]!.add(msg);
    _syncChatLastMessage(chatId, msg);
    notifyListeners();
  }

  /// Swap an optimistic message (keyed by [tempId]) for the confirmed server
  /// copy. Keeps the attachment visible with its real URL even if the realtime
  /// stream is slow or never fires.
  void replaceLocalMessage(String chatId, String tempId, MessageModel real) {
    final list = _messages[chatId];
    if (list == null) return;
    final i = list.indexWhere((m) => m.id == tempId);
    if (i == -1) {
      // Optimistic copy already replaced (e.g. by realtime); avoid duplicates.
      if (list.any((m) => m.id == real.id)) return;
      list.add(real);
    } else {
      list[i] = real;
    }
    _syncChatLastMessage(chatId, real);
    notifyListeners();
  }

  /// Drop an optimistic message that failed to send so it doesn't sit there
  /// stuck on a loading spinner.
  void removeLocalMessage(String chatId, String tempId) {
    final list = _messages[chatId];
    if (list == null) return;
    list.removeWhere((m) => m.id == tempId);
    notifyListeners();
  }

  Future<String> getOrCreateDirectChat(String otherUserId) async {
    final chatId = await _supabase.createDirectChat(otherUserId);
    // Refresh chat list
    _chats = await _supabase.getChats();
    notifyListeners();
    return chatId;
  }

  Future<void> updateUserName(String userId, String newName) async {
    await _supabase.updateProfile(userId, name: newName);
    _users = _users.map((u) {
      if (u.id != userId) return u;
      return u.copyWith(name: newName);
    }).toList();
    notifyListeners();
  }

  Future<void> updateUserBio(String userId, String bio) async {
    await _supabase.updateProfile(userId, bio: bio);
    _users = _users.map((u) {
      if (u.id != userId) return u;
      return u.copyWith(bio: bio);
    }).toList();
    notifyListeners();
  }

  Future<void> updateUserPhone(String userId, String phone) async {
    await _supabase.updateProfile(userId, phone: phone);
    _users = _users.map((u) {
      if (u.id != userId) return u;
      return u.copyWith(phone: phone);
    }).toList();
    notifyListeners();
  }

  Future<void> updateUserLang(String userId, String lang) async {
    await _supabase.updateProfile(userId, lang: lang);
    _users = _users.map((u) {
      if (u.id != userId) return u;
      return u.copyWith(lang: lang);
    }).toList();
    notifyListeners();
  }

  Future<void> saveMyProfile({required String name, required String bio, required String phone}) async {
    final myId = currentUserId;
    if (myId == null) return;
    await _supabase.updateProfile(myId, name: name, bio: bio, phone: phone);
    _users = _users.map((u) {
      if (u.id != myId) return u;
      return u.copyWith(name: name, bio: bio, phone: phone);
    }).toList();
    notifyListeners();
  }

  Future<void> updateMyAvatar(String localPath) async {
    final myId = currentUserId;
    if (myId == null) return;
    final url = await _supabase.uploadAvatar(localPath);
    await _supabase.updateProfile(myId, avatarUrl: url);
    _users = _users.map((u) {
      if (u.id != myId) return u;
      return u.copyWith(avatarUrl: url);
    }).toList();
    notifyListeners();
  }

  bool isContact(String userId) => _contactIds.contains(userId);

  Future<void> addContact(String contactId) async {
    await _supabase.addContact(contactId);
    _contactIds = {..._contactIds, contactId};
    notifyListeners();
  }

  Future<void> removeContact(String contactId) async {
    await _supabase.removeContact(contactId);
    _contactIds = {..._contactIds}..remove(contactId);
    notifyListeners();
  }

  Future<String> createGroup(String name, List<String> memberIds) async {
    final chatId = await _supabase.createGroupChat(name, memberIds);
    _chats = await _supabase.getChats();
    notifyListeners();
    return chatId;
  }

  Future<void> addMemberToGroup(String chatId, String userId) async {
    await _supabase.addChatMember(chatId, userId);
    _chats = await _supabase.getChats();
    notifyListeners();
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    // Local match first: covers name, phone, AND the user ID (full UUID or the
    // short 8-char form shown in the contact sheet). The server query can't
    // ilike a uuid column, so ID search has to happen here.
    final idQuery = q.replaceAll('-', '');
    final local = _users.where((u) {
      if (u.id == _currentUserId) return false;
      final id = u.id.toLowerCase().replaceAll('-', '');
      return u.name.toLowerCase().contains(q) ||
          (u.phone?.toLowerCase().contains(q) ?? false) ||
          id.startsWith(idQuery) ||
          id.contains(idQuery);
    }).toList();

    // Fall back to the server (e.g. profiles loaded after this user joined).
    final remote = await _supabase.searchUsers(query);

    final seen = <String>{};
    final merged = <UserModel>[];
    for (final u in [...local, ...remote]) {
      if (u.id == _currentUserId) continue;
      if (seen.add(u.id)) merged.add(u);
    }
    return merged;
  }

  Future<void> updateGroupName(String chatId, String newName) async {
    await _supabase.updateChatName(chatId, newName);
    _chats = _chats.map((c) {
      if (c.id != chatId) return c;
      return ChatModel(
        id: c.id,
        type: c.type,
        name: newName,
        avatar: c.avatar,
        participantIds: c.participantIds,
        lastMessage: c.lastMessage,
        lastMessageType: c.lastMessageType,
        time: c.time,
        unread: c.unread,
      );
    }).toList();
    notifyListeners();
  }

  // Incoming call global listener
  void _setupIncomingCallListener() {
    final uid = _currentUserId;
    if (uid == null) return;
    _callChannel?.unsubscribe();
    _callChannel = _supabase.subscribeToIncomingCalls(uid, (signal) {
      final type = signal['signal_type'] as String?;
      if (type != 'offer') return;

      final fromUserId = signal['from_user'] as String? ?? '';
      final caller = getUserById(fromUserId);
      incomingCallNotifier.value = IncomingCallInfo(
        roomId: signal['room_id'] as String? ?? '',
        fromUserId: fromUserId,
        fromUserName: caller?.name ?? 'Seseorang',
        callType: (signal['payload'] as Map?)?['callType'] as String? ?? 'voice',
        offerPayload: Map<String, dynamic>.from(
          (signal['payload'] as Map?)?['sdp'] != null
              ? signal['payload'] as Map
              : {'sdp': '', 'type': 'offer'},
        ),
      );
    });
  }

  void dismissIncomingCall() {
    incomingCallNotifier.value = null;
  }

  /// Decline an incoming call: tell the caller to stop and record it as missed.
  Future<void> declineCall(IncomingCallInfo incoming) async {
    dismissIncomingCall();
    await _supabase.sendCallSignal(
      roomId: incoming.roomId,
      toUserId: incoming.fromUserId,
      signalType: 'hangup',
      payload: {'reason': 'declined'},
    );
    await logCall(
      contactId: incoming.fromUserId,
      type: incoming.callType,
      direction: 'missed',
      durationSeconds: 0,
    );
  }

  // ── Global message feed → chat list + notifications ───────
  void _setupMessageFeed() {
    _msgFeedChannel?.unsubscribe();
    _msgFeedChannel = _supabase.subscribeToAllMessages((row) {
      final chatId = row['chat_id'] as String?;
      final senderId = row['sender_id'] as String?;
      if (chatId == null) return;

      final msg = MessageModel.fromSupabase(row);

      // Keep the cached thread live if it's loaded.
      final cached = _messages[chatId];
      if (cached != null && !cached.any((m) => m.id == msg.id)) {
        cached.add(msg);
        cached.sort((a, b) =>
            (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
      }

      final known = _chats.any((c) => c.id == chatId);
      if (known) {
        _syncChatLastMessage(chatId, msg);
      } else {
        // A brand-new chat someone started with us — pull the list again.
        _supabase.getChats().then((c) {
          _chats = c;
          notifyListeners();
        });
      }

      // Raise a notification for incoming messages that aren't from us and
      // aren't for the chat we're already looking at.
      if (senderId != null &&
          senderId != _currentUserId &&
          chatId != _activeChatId) {
        final sender = getUserById(senderId);
        _addNotification(AppNotification(
          id: msg.id,
          type: 'message',
          title: sender?.name ?? 'Pesan baru',
          body: _msgPreview(msg),
          chatId: chatId,
        ));
      }

      notifyListeners();
    });
  }

  void _setupCallsFeed() {
    _callsFeedChannel?.unsubscribe();
    _callsFeedChannel = _supabase.subscribeToCalls(() async {
      _calls = await _supabase.getCalls();
      notifyListeners();
    });
  }

  void _addNotification(AppNotification n) {
    // De-dupe by id (a realtime row can be delivered more than once).
    if (_notifications.any((e) => e.id == n.id)) return;
    _notifications.add(n);
    if (_notifications.length > 100) _notifications.removeAt(0);
    bannerNotifier.value = n; // transient banner
  }

  void pushLocalNotification({
    required String type,
    required String title,
    required String body,
    String? chatId,
  }) {
    _addNotification(AppNotification(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      title: title,
      body: body,
      chatId: chatId,
    ));
    notifyListeners();
  }

  // ── Call log ──────────────────────────────────────────────
  Future<void> logCall({
    required String contactId,
    required String type,
    required String direction,
    required int durationSeconds,
  }) async {
    await _supabase.logCall(
      contactId: contactId,
      type: type,
      direction: direction,
      durationSeconds: durationSeconds,
    );
    _calls = await _supabase.getCalls();
    notifyListeners();
  }

  Future<void> signOut() async {
    for (final sub in _msgSubs.values) {
      await sub.cancel();
    }
    _msgSubs.clear();
    _callChannel?.unsubscribe();
    _callChannel = null;
    _msgFeedChannel?.unsubscribe();
    _msgFeedChannel = null;
    _callsFeedChannel?.unsubscribe();
    _callsFeedChannel = null;
    _users = [];
    _chats = [];
    _calls = [];
    _messages.clear();
    _notifications.clear();
    _contactIds = {};
    _isLoaded = false;
    _currentUserId = null;
    _activeChatId = null;
    incomingCallNotifier.value = null;
    bannerNotifier.value = null;
    await _supabase.signOut();
    notifyListeners();
  }

  Future<void> resetAll() async {
    _isLoaded = false;
    _messages.clear();
    await loadData();
  }

  @override
  void dispose() {
    for (final sub in _msgSubs.values) {
      sub.cancel();
    }
    _callChannel?.unsubscribe();
    _msgFeedChannel?.unsubscribe();
    _callsFeedChannel?.unsubscribe();
    incomingCallNotifier.dispose();
    bannerNotifier.dispose();
    super.dispose();
  }
}
