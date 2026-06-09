import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../models/search_result.dart';
import '../theme/app_theme.dart';

class ClipItemCard extends StatelessWidget {
  final ClipItem item;

  const ClipItemCard({
    super.key,
    required this.item,
  });

  Widget _buildHighlightedText(String text, String pinyin, String textKeyword) {
    List<TextSpan> spans = [];
    String remaining = text;

    List<String> highlights = [];
    if (pinyin.isNotEmpty) highlights.add(pinyin);
    if (textKeyword.isNotEmpty) highlights.add(textKeyword);

    while (remaining.isNotEmpty) {
      int earliestIndex = -1;
      String? foundText;
      TextStyle? foundStyle;

      for (String highlight in highlights) {
        int index = remaining.indexOf(highlight);
        if (index != -1 && (earliestIndex == -1 || index < earliestIndex)) {
          earliestIndex = index;
          foundText = highlight;
          foundStyle = highlight == pinyin
              ? const TextStyle(color: Colors.red)
              : const TextStyle(color: Colors.blue);
        }
      }

      if (earliestIndex == -1) {
        spans.add(TextSpan(text: remaining));
        break;
      }

      if (earliestIndex > 0) {
        spans.add(TextSpan(text: remaining.substring(0, earliestIndex)));
      }
      spans.add(TextSpan(text: foundText!, style: foundStyle));
      remaining = remaining.substring(earliestIndex + foundText!.length);
    }

    return Text.rich(TextSpan(children: spans));
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null) return;

    if (url.contains('bilibili.com/video/')) {
      String? videoId = _extractBilibiliVideoId(url);
      if (videoId != null) {
        String bilibiliScheme = 'bilibili://video/$videoId';
        if (await canLaunchUrlString(bilibiliScheme)) {
          await launchUrlString(bilibiliScheme);
          return;
        }
      }
    }

    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }

  String? _extractBilibiliVideoId(String url) {
    RegExp regex = RegExp(r'bilibili\.com/video/([A-Za-z0-9]+)');
    Match? match = regex.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: primaryColor.withOpacity(0.1),
                ),
                child: (item.author.avatar != null && item.author.avatar!.isNotEmpty)
                    ? ClipOval(
                        child: Image.network(
                          item.author.avatar!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, color: primaryColor, size: 18);
                          },
                        ),
                      )
                    : const Icon(Icons.person, color: primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '主播: ${item.author.name}',
                          style: const TextStyle(fontSize: 12, color: textSecondary),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          item.datetime,
                          style: const TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.bilibiliUrl != null)
            InkWell(
              onTap: () => _launchUrl(item.bilibiliUrl),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  item.bilibiliUrl!,
                  style: const TextStyle(fontSize: 12, color: primaryColor),
                ),
              ),
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
                        _buildHighlightedText(subtitle.cleanContent, subtitle.pinyin, subtitle.text),
                      ],
                    ),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }
}