import 'package:flutter/material.dart';
import '../models/radar_config.dart';
import '../theme/app_theme.dart';

class RadarCard extends StatelessWidget {
  final RadarConfig radar;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onSearch;
  final VoidCallback? onToggleAutoSearch;
  final bool showCheckbox;
  final bool isSelected;

  const RadarCard({
    super.key,
    required this.radar,
    required this.onTap,
    required this.onDelete,
    required this.onSearch,
    this.onToggleAutoSearch,
    this.showCheckbox = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration.copyWith(
        border: isSelected
            ? Border.all(color: primaryColor, width: 2)
            : cardDecoration.border,
      ),
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          if (showCheckbox)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => onTap(),
                activeColor: primaryColor,
              ),
            ),
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
                    if (radar.isAutoSearch)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '自动搜索',
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
                  '关键词: ${radar.keyword}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (radar.isAutoSearch && onToggleAutoSearch != null)
            GestureDetector(
              onTap: onToggleAutoSearch,
              child: Container(
                width: 60,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: radar.isAutoSearchEnabled ? statusLive : Colors.grey[300],
                ),
                child: Container(
                  margin: EdgeInsets.only(left: radar.isAutoSearchEnabled ? 26 : 4),
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: onSearch,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [primaryColor, Colors.transparent],
                    radius: 1,
                  ),
                ),
                child: const Icon(
                  Icons.radar,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }
}