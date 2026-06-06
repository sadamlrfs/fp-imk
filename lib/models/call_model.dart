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

final List<CallModel> dummyCalls = [
  CallModel(id: 'cl1', contactId: 'u1', contactName: 'Rizal Hafiyyan', type: 'video',   direction: 'incoming', date: 'Hari ini',  time: '09.41', duration: '12:34'),
  CallModel(id: 'cl2', contactId: 'u2', contactName: 'Erika',           type: 'voice',   direction: 'missed',   date: 'Hari ini',  time: '08.15', duration: ''),
  CallModel(id: 'cl3', contactId: 'u3', contactName: 'James',           type: 'voice',   direction: 'outgoing', date: 'Kemarin',   time: '21.03', duration: '4:10'),
  CallModel(id: 'cl4', contactId: 'u1', contactName: 'Rizal Hafiyyan', type: 'voice',   direction: 'outgoing', date: 'Kemarin',   time: '17.45', duration: '2:05'),
  CallModel(id: 'cl5', contactId: 'u4', contactName: 'Aiko',            type: 'video',   direction: 'missed',   date: 'Kemarin',   time: '14.22', duration: ''),
  CallModel(id: 'cl6', contactId: 'u2', contactName: 'Erika',           type: 'video',   direction: 'incoming', date: '23 Mei',    time: '10.00', duration: '28:17'),
  CallModel(id: 'cl7', contactId: 'u3', contactName: 'James',           type: 'voice',   direction: 'incoming', date: '22 Mei',    time: '19.30', duration: '7:52'),
  CallModel(id: 'cl8', contactId: 'u5', contactName: 'David',           type: 'voice',   direction: 'outgoing', date: '21 Mei',    time: '08.00', duration: '1:33'),
  CallModel(id: 'cl9', contactId: 'u4', contactName: 'Aiko',            type: 'video',   direction: 'outgoing', date: '20 Mei',    time: '16.11', duration: '45:02'),
  CallModel(id: 'cl10',contactId: 'u1', contactName: 'Rizal Hafiyyan', type: 'voice',   direction: 'missed',   date: '19 Mei',    time: '07.55', duration: ''),
];
