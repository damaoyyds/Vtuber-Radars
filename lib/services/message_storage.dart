import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../models/search_result.dart';

class MessageStorage {
  static const String _key = 'vtuber_radar_messages';

  static Future<List<Message>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) {
      return [];
    }
    try {
      final List<dynamic> data = json.decode(jsonString);
      return data.map((item) => _messageFromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveMessages(List<Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> data = messages.map((msg) => _messageToJson(msg)).toList();
    await prefs.setString(_key, json.encode(data));
  }

  static Future<void> addMessage(Message message) async {
    final messages = await loadMessages();
    messages.insert(0, message);
    await saveMessages(messages);
  }

  static Future<void> addMessages(List<Message> messages) async {
    final allMessages = await loadMessages();
    allMessages.insertAll(0, messages);
    await saveMessages(allMessages);
  }

  static Future<void> removeMessage(String messageId) async {
    final messages = await loadMessages();
    messages.removeWhere((msg) => msg.id == messageId);
    await saveMessages(messages);
  }

  static Future<void> removeMessagesByRadarName(String radarName) async {
    final messages = await loadMessages();
    messages.removeWhere((msg) => msg.radarName == radarName);
    await saveMessages(messages);
  }

  static Future<void> clearAllMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Map<String, dynamic> _messageToJson(Message message) {
    return {
      'id': message.id,
      'radarName': message.radarName,
      'timestamp': message.timestamp.toIso8601String(),
      'type': message.type.index,
      'text': message.text,
      'clipItem': message.clipItem != null ? _clipItemToJson(message.clipItem!) : null,
      'keyword': message.keyword,
    };
  }

  static Message _messageFromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      radarName: json['radarName'],
      timestamp: DateTime.parse(json['timestamp']),
      type: MessageType.values[json['type']],
      text: json['text'],
      clipItem: json['clipItem'] != null ? _clipItemFromJson(json['clipItem']) : null,
      keyword: json['keyword'],
    );
  }

  static Map<String, dynamic> _clipItemToJson(ClipItem item) {
    return {
      'id': item.id,
      'title': item.title,
      'author': {'name': item.author.name},
      'datetime': item.datetime,
      'playUrl': item.playUrl,
      'bilibiliUrl': item.bilibiliUrl,
      'orgName': item.orgName,
      'orgId': item.orgId,
      'subtitles': item.subtitles.map((sub) => _subtitleToJson(sub)).toList(),
    };
  }

  static ClipItem _clipItemFromJson(Map<String, dynamic> json) {
    return ClipItem(
      id: json['id'],
      title: json['title'],
      author: Author(name: json['author']['name']),
      datetime: json['datetime'],
      playUrl: json['playUrl'],
      bilibiliUrl: json['bilibiliUrl'],
      orgName: json['orgName'],
      orgId: json['orgId'],
      subtitles: (json['subtitles'] as List).map((sub) => _subtitleFromJson(sub)).toList(),
    );
  }

  static Map<String, dynamic> _subtitleToJson(Subtitle item) {
    return {
      'clipId': item.clipId,
      'start': item.start,
      'end': item.end,
      'markedContent': item.markedContent,
      'cleanContent': item.cleanContent,
      'pinyin': item.pinyin,
      'text': item.text,
    };
  }

  static Subtitle _subtitleFromJson(Map<String, dynamic> json) {
    return Subtitle(
      clipId: json['clipId'],
      start: json['start'],
      end: json['end'],
      markedContent: json['markedContent'],
      cleanContent: json['cleanContent'],
      pinyin: json['pinyin'],
      text: json['text'],
    );
  }
}