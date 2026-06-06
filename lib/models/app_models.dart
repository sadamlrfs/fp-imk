class UserModel {
  final String id;
  final String name;
  final String avatar;
  final String lang;

  UserModel({required this.id, required this.name, required this.avatar, required this.lang});

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'],
        name: j['name'],
        avatar: j['avatar'],
        lang: j['lang'],
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
        id: j['id'],
        type: j['type'],
        name: j['name'],
        avatar: j['avatar'],
        participantIds: List<String>.from(j['participantIds']),
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
        speakerId: j['speakerId'],
        textEn: j['textEn'],
        textId: j['textId'],
      );
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
  final String? thumbnail;
  final List<MessageSegment> segments;
  final String time;

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
    this.thumbnail,
    this.segments = const [],
    required this.time,
  });

  factory MessageModel.fromJson(Map<String, dynamic> j) => MessageModel(
        id: j['id'],
        senderId: j['senderId'],
        type: j['type'],
        textEn: j['textEn'],
        textId: j['textId'],
        audio: j['audio'],
        duration: j['duration'],
        durationLabel: j['durationLabel'],
        videoUrl: j['videoUrl'],
        thumbnail: j['thumbnail'],
        segments: j['segments'] != null
            ? (j['segments'] as List).map((s) => MessageSegment.fromJson(s)).toList()
            : [],
        time: j['time'] ?? '',
      );

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
        'thumbnail': thumbnail,
        'segments': segments.map((s) => {'speakerId': s.speakerId, 'textEn': s.textEn, 'textId': s.textId}).toList(),
        'time': time,
      };
}

class TranslateScript {
  final String speakerId;
  final String speakerName;
  final String textEn;
  final String textId;

  TranslateScript({
    required this.speakerId,
    required this.speakerName,
    required this.textEn,
    required this.textId,
  });

  factory TranslateScript.fromJson(Map<String, dynamic> j) => TranslateScript(
        speakerId: j['speakerId'],
        speakerName: j['speakerName'],
        textEn: j['textEn'],
        textId: j['textId'],
      );
}
