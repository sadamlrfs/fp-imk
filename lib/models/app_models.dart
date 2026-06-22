class UserModel {
  final String id;
  final String name;
  final String avatar;
  final String lang;
  final String? bio;
  final String? phone;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lang,
    this.bio,
    this.phone,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] ?? '',
        name: j['name'] ?? 'User',
        avatar: j['avatar'] ?? j['avatar_url'] ?? '',
        lang: j['lang'] ?? j['preferred_lang'] ?? 'id',
        bio: j['bio'],
        phone: j['phone'],
        avatarUrl: j['avatarUrl'] ?? j['avatar_url'],
      );

  factory UserModel.fromSupabase(Map<String, dynamic> j) => UserModel(
        id: j['id'] ?? '',
        name: j['name'] ?? 'User',
        avatar: j['avatar_url'] ?? '',
        lang: j['preferred_lang'] ?? 'id',
        bio: j['bio'] ?? '',
        phone: j['phone'] ?? '',
        avatarUrl: j['avatar_url'],
      );

  UserModel copyWith({
    String? name,
    String? avatar,
    String? lang,
    String? bio,
    String? phone,
    String? avatarUrl,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        avatar: avatar ?? this.avatar,
        lang: lang ?? this.lang,
        bio: bio ?? this.bio,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );
}

class ChatModel {
  final String id;
  final String type;
  final String? name;
  final String? avatar;
  final List<String> participantIds;
  final String lastMessage;
  final String lastMessageType;
  final String time;
  final int unread;

  ChatModel({
    required this.id,
    required this.type,
    this.name,
    this.avatar,
    required this.participantIds,
    required this.lastMessage,
    required this.lastMessageType,
    required this.time,
    required this.unread,
  });

  factory ChatModel.fromJson(Map<String, dynamic> j) => ChatModel(
        id: j['id'] ?? '',
        type: j['type'] ?? 'direct',
        name: j['name'],
        avatar: j['avatar'],
        participantIds: List<String>.from(j['participantIds'] ?? []),
        lastMessage: j['lastMessage'] ?? '',
        lastMessageType: j['lastMessageType'] ?? 'text',
        time: j['time'] ?? '',
        unread: j['unread'] ?? 0,
      );
}

class MessageSegment {
  final String speakerId;
  final String textEn;
  final String textId;

  MessageSegment({required this.speakerId, required this.textEn, required this.textId});

  factory MessageSegment.fromJson(Map<String, dynamic> j) => MessageSegment(
        speakerId: j['speakerId'] ?? '',
        textEn: j['textEn'] ?? '',
        textId: j['textId'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'speakerId': speakerId,
        'textEn': textEn,
        'textId': textId,
      };
}

class MessageModel {
  final String id;
  final String senderId;
  final String type;
  final String? textEn;
  final String? textId;
  final String? audio;
  final int? duration;
  final String? durationLabel;
  final String? videoUrl;
  final String? imageUrl;
  final String? fileUrl;
  final String? fileName;
  final String? thumbnail;
  final List<MessageSegment> segments;
  final String time;
  final DateTime? createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.type,
    this.textEn,
    this.textId,
    this.audio,
    this.duration,
    this.durationLabel,
    this.videoUrl,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    this.thumbnail,
    this.segments = const [],
    required this.time,
    this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> j) => MessageModel(
        id: j['id'] ?? '',
        senderId: j['senderId'] ?? '',
        type: j['type'] ?? 'text',
        textEn: j['textEn'],
        textId: j['textId'],
        audio: j['audio'],
        duration: j['duration'],
        durationLabel: j['durationLabel'],
        videoUrl: j['videoUrl'],
        imageUrl: j['imageUrl'],
        fileUrl: j['fileUrl'],
        fileName: j['fileName'],
        thumbnail: j['thumbnail'],
        segments: j['segments'] != null
            ? (j['segments'] as List).map((s) => MessageSegment.fromJson(s)).toList()
            : [],
        time: j['time'] ?? '',
      );

  factory MessageModel.fromSupabase(Map<String, dynamic> j) {
    final createdAt = j['created_at'] != null ? DateTime.tryParse(j['created_at']) : null;
    final local = createdAt?.toLocal();
    final timeStr = local != null
        ? '${local.hour.toString().padLeft(2, '0')}.${local.minute.toString().padLeft(2, '0')}'
        : '';

    final type = j['type'] ?? 'text';
    final fileUrl = j['file_url'] as String?;

    return MessageModel(
      id: j['id'] ?? '',
      senderId: j['sender_id'] ?? '',
      type: type,
      textEn: j['text_en'],
      textId: j['text_id'],
      audio: type == 'voice' ? fileUrl : null,
      videoUrl: type == 'video' ? fileUrl : null,
      imageUrl: type == 'image' ? fileUrl : null,
      fileUrl: type == 'file' ? fileUrl : null,
      fileName: j['file_name'],
      duration: j['duration_seconds'],
      durationLabel: _fmtDuration(j['duration_seconds']),
      thumbnail: j['thumbnail_url'],
      segments: [],
      time: timeStr,
      createdAt: local,
    );
  }

  static String _fmtDuration(int? seconds) {
    if (seconds == null) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'type': type,
        'textEn': textEn,
        'textId': textId,
        'audio': audio,
        'duration': duration,
        'durationLabel': durationLabel,
        'videoUrl': videoUrl,
        'imageUrl': imageUrl,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'thumbnail': thumbnail,
        'segments': segments.map((s) => s.toJson()).toList(),
        'time': time,
      };
}

class CallModel {
  final String id;
  final String contactId;
  final String contactName;
  final String type;
  final String direction;
  final String date;
  final String time;
  final String duration;

  CallModel({
    required this.id,
    required this.contactId,
    required this.contactName,
    required this.type,
    required this.direction,
    required this.date,
    required this.time,
    required this.duration,
  });

  bool get isMissed => direction == 'missed';
  bool get isVideo => type == 'video';
  bool get isIncoming => direction == 'incoming';

  factory CallModel.fromJson(Map<String, dynamic> j) => CallModel(
        id: j['id'] ?? '',
        contactId: j['contactId'] ?? '',
        contactName: j['contactName'] ?? 'Unknown',
        type: j['type'] ?? 'voice',
        direction: j['direction'] ?? 'outgoing',
        date: j['date'] ?? '',
        time: j['time'] ?? '',
        duration: j['duration'] ?? '',
      );
}
