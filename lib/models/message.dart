import 'package:vtuber_radar/models/search_result.dart';

class Message {
  final String id;
  final String radarName;
  final DateTime timestamp;
  final MessageType type;
  final String? text;
  final ClipItem? clipItem;
  final String? keyword;
  final bool isRead;

  Message({
    required this.id,
    required this.radarName,
    required this.timestamp,
    required this.type,
    this.text,
    this.clipItem,
    this.keyword,
    this.isRead = false,
  });

  Message copyWith({bool? isRead}) {
    return Message(
      id: id,
      radarName: radarName,
      timestamp: timestamp,
      type: type,
      text: text,
      clipItem: clipItem,
      keyword: keyword,
      isRead: isRead ?? this.isRead,
    );
  }
}

enum MessageType {
  searching,
  searchComplete,
  searchError,
}