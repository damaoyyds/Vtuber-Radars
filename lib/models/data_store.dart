import 'package:vtuber_radar/models/search_result.dart';

class DataStoreItem {
  final String clipId;
  final String radarId;
  final String title;
  final String author;
  final String orgName;
  final String datetime;
  final String? bilibiliUrl;
  final List<Subtitle> subtitles;
  final DateTime storedAt;

  DataStoreItem({
    required this.clipId,
    required this.radarId,
    required this.title,
    required this.author,
    required this.orgName,
    required this.datetime,
    this.bilibiliUrl,
    required this.subtitles,
    required this.storedAt,
  });

  factory DataStoreItem.fromClipItem(ClipItem item, String radarId) {
    return DataStoreItem(
      clipId: item.id,
      radarId: radarId,
      title: item.title,
      author: item.author.name,
      orgName: item.orgName,
      datetime: item.datetime,
      bilibiliUrl: item.bilibiliUrl,
      subtitles: item.subtitles,
      storedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clipId': clipId,
      'radarId': radarId,
      'title': title,
      'author': author,
      'orgName': orgName,
      'datetime': datetime,
      'bilibiliUrl': bilibiliUrl,
      'subtitles': subtitles.map((s) => s.toJson()).toList(),
      'storedAt': storedAt.toIso8601String(),
    };
  }

  factory DataStoreItem.fromJson(Map<String, dynamic> json) {
    return DataStoreItem(
      clipId: json['clipId'],
      radarId: json['radarId'],
      title: json['title'],
      author: json['author'],
      orgName: json['orgName'],
      datetime: json['datetime'],
      bilibiliUrl: json['bilibiliUrl'],
      subtitles: (json['subtitles'] as List).map((s) => Subtitle.fromJson(s)).toList(),
      storedAt: DateTime.parse(json['storedAt']),
    );
  }
}

class DataStore {
  final String radarId;
  final List<DataStoreItem> items;

  DataStore({
    required this.radarId,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'radarId': radarId,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory DataStore.fromJson(Map<String, dynamic> json) {
    return DataStore(
      radarId: json['radarId'],
      items: (json['items'] as List).map((item) => DataStoreItem.fromJson(item)).toList(),
    );
  }
}
