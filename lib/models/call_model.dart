class CallModel {
  final String id;
  final String contactId;
  final String contactName;
  final String type; // 'voice' | 'video'
  final String direction; // 'incoming' | 'outgoing' | 'missed'
  final String date;
  final String time;
  final String duration; // '' if missed

  const CallModel({
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
}

