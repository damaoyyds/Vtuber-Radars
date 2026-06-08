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
  final String? avatarUrl;
  final String? authorId;

  Message({
    required this.id,
    required this.radarName,
    required this.timestamp,
    required this.type,
    this.text,
    this.clipItem,
    this.keyword,
    this.isRead = false,
    this.avatarUrl,
    this.authorId,
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
      avatarUrl: avatarUrl,
      authorId: authorId,
    );
  }
}

enum MessageType {
  searching,
  searchComplete,
  searchError,
}