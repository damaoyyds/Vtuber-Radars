import 'package:vtuber_radar/models/search_result.dart';

class Message {
  final String id;
  final String radarName;
  final DateTime timestamp;
  final MessageType type;
  final String? text;
  final ClipItem? clipItem;
  final String? keyword;

  Message({
    required this.id,
    required this.radarName,
    required this.timestamp,
    required this.type,
    this.text,
    this.clipItem,
    this.keyword,
  });
}

enum MessageType {
  searching,
  searchComplete,
  searchError,
}