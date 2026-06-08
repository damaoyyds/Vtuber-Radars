import 'dart:io';
import 'package:flutter/material.dart';
import '../models/radar_config.dart';
import '../theme/app_theme.dart';

class RadarCard extends StatelessWidget {
  final RadarConfig radar;
  final VoidCallback onTap;
  final VoidCallback onSearch;
  final VoidCallback? onToggleAutoSearch;
  final VoidCallback? onDoubleTap;
  final bool showCheckbox;
  final bool isSelected;

  const RadarCard({
    super.key,
    required this.radar,
    required this.onTap,
    required this.onSearch,
    this.onToggleAutoSearch,
    this.onDoubleTap,
    this.showCheckbox = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            if (showCheckbox)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => onTap(),
                  activeColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundImage: radar.avatarPath != null
                    ? FileImage(File(radar.avatarPath!))
                    : const NetworkImage(
                        'https://neeko-copilot.bytedance.net/api/text_to_image?prompt=anime%20girl%20avatar%20cute%20blue%20hair&image_size=square',
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          radar.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (radar.isAutoSearch)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: radar.isAutoSearchEnabled 
                                ? const Color(0xFF10B981).withOpacity(0.15)
                                : const Color(0xFF9CA3AF).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: radar.isAutoSearchEnabled 
                                      ? const Color(0xFF10B981) 
                                      : const Color(0xFF9CA3AF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                radar.isAutoSearchEnabled ? '自动搜索' : '已暂停',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: radar.isAutoSearchEnabled 
                                      ? const Color(0xFF10B981) 
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '关键词: ${radar.keywords.join(', ')}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: onSearch,
                      child: const Padding(
                        padding: EdgeInsets.all(14),
                        child: Icon(
                          Icons.search,
                          color: primaryColor,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                if (radar.isAutoSearch && onToggleAutoSearch != null)
                  const SizedBox(width: 8),
                if (radar.isAutoSearch && onToggleAutoSearch != null)
                  Container(
                    decoration: BoxDecoration(
                      color: radar.isAutoSearchEnabled 
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : const Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: radar.isAutoSearchEnabled
                            ? const Color(0xFF10B981).withOpacity(0.3)
                            : const Color(0xFFF59E0B).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: onToggleAutoSearch!,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Icon(
                            radar.isAutoSearchEnabled ? Icons.pause : Icons.play_arrow,
                            color: radar.isAutoSearchEnabled 
                                ? const Color(0xFF10B981) 
                                : const Color(0xFFF59E0B),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
