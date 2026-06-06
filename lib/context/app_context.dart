import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

class AppContext extends ChangeNotifier {
  static const _currentUserId = 'me';

  List<UserModel> _users = [];
  List<ChatModel> _chats = [];
  Map<String, List<MessageModel>> _messages = {};
  Map<String, List<TranslateScript>> _scripts = {};
  bool _isLoaded = false;

  List<UserModel> get users => _users;
  List<ChatModel> get chats => _chats;
  Map<String, List<MessageModel>> get messages => _messages;
  Map<String, List<TranslateScript>> get scripts => _scripts;
  bool get isLoaded => _isLoaded;
  String get currentUserId => _currentUserId;

  UserModel? get currentUser => _users.isEmpty
      ? null
      : _users.firstWhere((u) => u.id == _currentUserId, orElse: () => _users.first);

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
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();

    final usersJson = await rootBundle.loadString('assets/data/users.json');
    _users = (jsonDecode(usersJson) as List).map((j) => UserModel.fromJson(j)).toList();

    final chatsJson = await rootBundle.loadString('assets/data/chats.json');
    _chats = (jsonDecode(chatsJson) as List).map((j) => ChatModel.fromJson(j)).toList();

    final messagesJson = await rootBundle.loadString('assets/data/messages.json');
    final messagesMap = jsonDecode(messagesJson) as Map<String, dynamic>;
    _messages = messagesMap.map((chatId, msgs) {
      final localKey = 'msgs_$chatId';
      final localRaw = prefs.getString(localKey);
      final base = (msgs as List).map((m) => MessageModel.fromJson(m)).toList();
      if (localRaw != null) {
        final localMsgs = (jsonDecode(localRaw) as List).map((m) => MessageModel.fromJson(m)).toList();
        base.addAll(localMsgs);
      }
      return MapEntry(chatId, base);
    });

    final transJson = await rootBundle.loadString('assets/data/translations.json');
    final transMap = jsonDecode(transJson) as Map<String, dynamic>;
    _scripts = {
      'video': (transMap['videoCallScripts'] as List).map((s) => TranslateScript.fromJson(s)).toList(),
      'group': (transMap['groupCallScripts'] as List).map((s) => TranslateScript.fromJson(s)).toList(),
    };

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> sendMessage(String chatId, MessageModel msg) async {
    _messages[chatId] ??= [];
    _messages[chatId]!.add(msg);

    _chats = _chats.map((c) {
      if (c.id == chatId) {
        return ChatModel(
          id: c.id,
          type: c.type,
          name: c.name,
          avatar: c.avatar,
          participantIds: c.participantIds,
          lastMessage: msg.textId ?? msg.textEn ?? '',
          lastMessageType: msg.type,
          time: msg.time,
          unread: 0,
        );
      }
      return c;
    }).toList();

    final prefs = await SharedPreferences.getInstance();
    final localKey = 'msgs_$chatId';
    final existing = prefs.getString(localKey);
    final localList = existing != null ? jsonDecode(existing) as List : [];
    localList.add(msg.toJson());
    await prefs.setString(localKey, jsonEncode(localList));

    notifyListeners();
  }

  void updateUserName(String userId, String newName) {
    _users = _users
        .map((u) => u.id == userId
            ? UserModel(id: u.id, name: newName, avatar: u.avatar, lang: u.lang)
            : u)
        .toList();
    notifyListeners();
  }

  void updateGroupName(String chatId, String newName) {
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

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isLoaded = false;
    _messages = {};
    await loadData();
  }
}
