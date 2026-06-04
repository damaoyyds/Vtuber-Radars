import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../models/message.dart';
import '../models/search_result.dart';
import '../theme/app_theme.dart';

class ChatDetailPage extends StatelessWidget {
  final String radarName;
  final List<Message> messages;
  final Function(String)? onDeleteMessage;
  final Function()? onClearAll;

  const ChatDetailPage({
    super.key,
    required this.radarName,
    required this.messages,
    this.onDeleteMessage,
    this.onClearAll,
  });

  String? get _keyword {
    for (var msg in messages) {
      if (msg.keyword != null && msg.keyword!.isNotEmpty) {
        return msg.keyword;
      }
    }
    return null;
  }

  Widget _buildHighlightedText(String text, String pinyin, String? keyword) {
    List<TextSpan> spans = [];
    String remaining = text;

    if (pinyin.isNotEmpty) {
      int index = remaining.indexOf(pinyin);
      if (index != -1) {
        if (index > 0) {
          spans.add(TextSpan(text: remaining.substring(0, index)));
        }
        spans.add(TextSpan(
          text: pinyin,
          style: const TextStyle(color: Colors.red),
        ));
        remaining = remaining.substring(index + pinyin.length);
      }
    }

    if (keyword != null && keyword.isNotEmpty && remaining.contains(keyword)) {
      int index = remaining.indexOf(keyword);
      if (index != -1) {
        if (index > 0) {
          spans.add(TextSpan(text: remaining.substring(0, index)));
        }
        spans.add(TextSpan(
          text: keyword,
          style: const TextStyle(color: Colors.blue),
        ));
        remaining = remaining.substring(index + keyword.length);
      }
    }

    if (remaining.isNotEmpty) {
      spans.add(TextSpan(text: remaining));
    }

    return Text.rich(TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(radarName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (onClearAll != null && messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showClearAllDialog(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...messages.map((message) => _buildChatMessage(context, message)),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('清空消息'),
          content: const Text('确定要清空所有消息吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                onClearAll?.call();
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('清空'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteMessageDialog(BuildContext context, String messageId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除消息'),
          content: const Text('确定要删除这条消息吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                onDeleteMessage?.call(messageId);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChatMessage(BuildContext context, Message message) {
    return InkWell(
      onLongPress: () => _showDeleteMessageDialog(context, message.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: const Icon(Icons.radar, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (message.type == MessageType.searching)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(message.text ?? '搜索中...'),
                  ],
                ),
              ),
            if (message.type == MessageType.searchComplete && message.text != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(message.text!),
              ),
            if (message.type == MessageType.searchComplete && message.clipItem != null)
              _buildClipItem(message.clipItem!),
            if (message.type == MessageType.searchError)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  message.text ?? '搜索失败',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClipItem(ClipItem item) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '作者: ${item.author.name}',
                style: const TextStyle(fontSize: 12, color: textSecondary),
              ),
              const SizedBox(width: 16),
              Text(
                item.datetime,
                style: const TextStyle(fontSize: 12, color: textSecondary),
              ),
            ],
          ),
          if (item.subtitles.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  '匹配的字幕 (${item.subtitles.length}条):',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...item.subtitles.map((subtitle) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '[${subtitle.formatTime(subtitle.start)} ~ ${subtitle.formatTime(subtitle.end)}]',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        _buildHighlightedText(subtitle.cleanContent, subtitle.pinyin, _keyword),
                      ],
                    ),
                  );
                }),
              ],
            ),
          const SizedBox(height: 8),
          if (item.bilibiliUrl != null)
            InkWell(
              onTap: () => _launchUrl(item.bilibiliUrl),
              child: Text(
                item.bilibiliUrl!,
                style: const TextStyle(fontSize: 12, color: primaryColor),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String? url) async {
    if (url != null && await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }
}