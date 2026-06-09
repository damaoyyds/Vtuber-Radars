import 'dart:io';

import 'package:flutter/material.dart';
import '../components/clip_item_card.dart';
import '../models/message.dart';
import '../models/radar_config.dart';
import '../models/search_result.dart';
import '../theme/app_theme.dart';

class ChatDetailPage extends StatelessWidget {
  final String radarName;
  final List<Message> messages;
  final Function(String)? onDeleteMessage;
  final Function()? onClearAll;
  final RadarConfig? radarConfig;

  const ChatDetailPage({
    super.key,
    required this.radarName,
    required this.messages,
    this.onDeleteMessage,
    this.onClearAll,
    this.radarConfig,
  });

  

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

  Widget _buildRadarAvatar() {
    if (radarConfig?.avatarPath != null && radarConfig!.avatarPath!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: FileImage(File(radarConfig!.avatarPath!)),
      );
    } else {
      return CircleAvatar(
        radius: 20,
        backgroundColor: primaryColor.withOpacity(0.1),
        child: const Icon(Icons.radar, color: primaryColor, size: 20),
      );
    }
  }

  Widget _buildChatMessage(BuildContext context, Message message) {
    return InkWell(
      onLongPress: () => _showDeleteMessageDialog(context, message.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.type != MessageType.searchComplete || message.clipItem == null)
              Row(
                children: [
                  _buildMessageAvatar(message),
                  const SizedBox(width: 8),
                  Text(
                    '${message.timestamp.month.toString().padLeft(2, '0')}/${message.timestamp.day.toString().padLeft(2, '0')} ${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 12, color: textTertiary),
                  ),
                ],
              ),
            if (message.type != MessageType.searchComplete || message.clipItem == null)
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

  Widget _buildMessageAvatar(Message message) {
    if (message.avatarUrl != null && message.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: primaryColor.withOpacity(0.1),
        child: ClipOval(
          child: Image.network(
            message.avatarUrl!,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.person, color: primaryColor, size: 18);
            },
          ),
        ),
      );
    }
    return _buildRadarAvatar();
  }

  Widget _buildClipItem(ClipItem item) {
    return ClipItemCard(item: item);
  }
}
