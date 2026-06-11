import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../models/search_result.dart';

class MessageStorage {
  static const String _key = 'vtuber_radar_messages';
  static final _lock = _StorageLock();

  static const int _maxMessages = 1000;

  static Future<List<Message>> loadMessages() async {
    return _lock.execute(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final jsonString = prefs.getString(_key);
        if (jsonString == null) {
          return [];
        }
        final List<dynamic> data = json.decode(jsonString);
        return data.map((item) => _messageFromJson(item)).toList();
      } catch (e, stackTrace) {
        print('MessageStorage.loadMessages error: $e\n$stackTrace');
        return [];
      }
    });
  }

  static Future<void> saveMessages(List<Message> messages) async {
    return _lock.execute(() async {
      try {
        if (messages.length > _maxMessages) {
          messages = messages.take(_maxMessages).toList();
        }
        final prefs = await SharedPreferences.getInstance();
        final List<Map<String, dynamic>> data = messages.map((msg) => _messageToJson(msg)).toList();
        await prefs.setString(_key, json.encode(data));
      } catch (e, stackTrace) {
        print('MessageStorage.saveMessages error: $e\n$stackTrace');
      }
    });
  }

  static Future<void> addMessage(Message message) async {
    return _lock.execute(() async {
      try {
        final messages = await _getMessages();
        messages.insert(0, message);
        await _saveMessagesInternal(messages);
      } catch (e, stackTrace) {
        print('MessageStorage.addMessage error: $e\n$stackTrace');
      }
    });
  }

  static Future<void> addMessages(List<Message> messages) async {
    return _lock.execute(() async {
      try {
        final allMessages = await _getMessages();
        allMessages.insertAll(0, messages);
        await _saveMessagesInternal(allMessages);
      } catch (e, stackTrace) {
        print('MessageStorage.addMessages error: $e\n$stackTrace');
      }
    });
  }

  static Future<void> removeMessage(String messageId) async {
    return _lock.execute(() async {
      try {
        final messages = await _getMessages();
        messages.removeWhere((msg) => msg.id == messageId);
        await _saveMessagesInternal(messages);
      } catch (e, stackTrace) {
        print('MessageStorage.removeMessage error: $e\n$stackTrace');
      }
    });
  }

  static Future<void> removeMessagesByRadarName(String radarName) async {
    return _lock.execute(() async {
      try {
        final messages = await _getMessages();
        messages.removeWhere((msg) => msg.radarName == radarName);
        await _saveMessagesInternal(messages);
      } catch (e, stackTrace) {
        print('MessageStorage.removeMessagesByRadarName error: $e\n$stackTrace');
      }
    });
  }

  static Future<void> clearAllMessages() async {
    return _lock.execute(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_key);
      } catch (e, stackTrace) {
        print('MessageStorage.clearAllMessages error: $e\n$stackTrace');
      }
    });
  }

  static Future<void> markMessagesAsRead(String radarName) async {
    return _lock.execute(() async {
      try {
        final messages = await _getMessages();
        for (var i = 0; i < messages.length; i++) {
          if (messages[i].radarName == radarName && !messages[i].isRead) {
            messages[i] = messages[i].copyWith(isRead: true);
          }
        }
        await _saveMessagesInternal(messages);
      } catch (e, stackTrace) {
        print('MessageStorage.markMessagesAsRead error: $e\n$stackTrace');
      }
    });
  }

  static Future<List<Message>> _getMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) {
      return [];
    }
    final List<dynamic> data = json.decode(jsonString);
    return data.map((item) => _messageFromJson(item)).toList();
  }

  static Future<void> _saveMessagesInternal(List<Message> messages) async {
    if (messages.length > _maxMessages) {
      messages = messages.take(_maxMessages).toList();
    }
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> data = messages.map((msg) => _messageToJson(msg)).toList();
    await prefs.setString(_key, json.encode(data));
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
      'isRead': message.isRead,
      'avatarUrl': message.avatarUrl,
      'authorId': message.authorId,
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
      isRead: json['isRead'] as bool? ?? false,
      avatarUrl: json['avatarUrl'],
      authorId: json['authorId'],
    );
  }

  static Map<String, dynamic> _clipItemToJson(ClipItem item) {
    return {
      'id': item.id,
      'title': item.title,
      'author': {
        'name': item.author.name,
        'avatar': item.author.avatar,
      },
      'datetime': item.datetime,
      'playUrl': item.playUrl,
      'bilibiliUrl': item.bilibiliUrl,
      'orgName': item.orgName,
      'orgId': item.orgId,
      'subtitles': item.subtitles.map((sub) => _subtitleToJson(sub)).toList(),
    };
  }

  static ClipItem _clipItemFromJson(Map<String, dynamic> json) {
    var authorJson = json['author'] as Map<String, dynamic>? ?? {};
    return ClipItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      author: Author(
        name: authorJson['name'] as String? ?? '',
        avatar: authorJson['avatar'] as String?,
      ),
      datetime: json['datetime'] as String? ?? '',
      playUrl: json['playUrl'] as String? ?? '',
      bilibiliUrl: json['bilibiliUrl'] as String? ?? '',
      orgName: json['orgName'] as String? ?? '',
      orgId: json['orgId'] as String? ?? '',
      subtitles: (json['subtitles'] as List? ?? []).map((sub) => _subtitleFromJson(sub)).toList(),
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
      clipId: json['clipId'] as String? ?? '',
      start: (json['start'] as num?)?.toInt() ?? 0,
      end: (json['end'] as num?)?.toInt() ?? 0,
      markedContent: json['markedContent'] as String? ?? '',
      cleanContent: json['cleanContent'] as String? ?? '',
      pinyin: json['pinyin'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }
}

class _StorageLock {
  Completer<void>? _currentTask;

  Future<T> execute<T>(Future<T> Function() action) async {
    while (_currentTask != null) {
      await _currentTask!.future;
    }

    final completer = Completer<void>();
    _currentTask = completer;

    try {
      return await action();
    } finally {
      _currentTask = null;
      completer.complete();
    }
  }
}