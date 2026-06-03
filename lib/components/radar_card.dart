import 'package:flutter/material.dart';
import '../models/radar_config.dart';
import '../theme/app_theme.dart';

class RadarCard extends StatelessWidget {
  final RadarConfig radar;
  final bool isLive;
  final int viewerCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const RadarCard({
    super.key,
    required this.radar,
    this.isLive = false,
    this.viewerCount = 0,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundImage: NetworkImage(
              'https://neeko-copilot.bytedance.net/api/text_to_image?prompt=anime%20girl%20avatar%20cute%20blue%20hair&image_size=square',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      radar.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusLive,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '正在直播',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isLive
                      ? '正在直播中 · ${viewerCount}k 人观看'
                      : '关键词: ${radar.keyword}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              _buildRadarVisual(isLive),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadarVisual(bool isLive) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isLive
            ? const RadialGradient(
                colors: [statusLive, Colors.transparent],
                radius: 1,
              )
            : const RadialGradient(
                colors: [primaryColor, Colors.transparent],
                radius: 1,
              ),
      ),
      child: const Icon(
        Icons.radar,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}