
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/location_record.dart';
import '../theme/app_colors.dart';


class LocationListTile extends StatelessWidget {
  final LocationRecord location;

  const LocationListTile({super.key, required this.location});

  Color _accuracyColor(double accuracy) {
    if (accuracy <= 5) return AppColors.accentEmerald;
    if (accuracy <= 15) return AppColors.accentCyan;
    if (accuracy <= 30) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('hh:mm a').format(location.timestamp);
    final dateStr = DateFormat('MMM dd').format(location.timestamp);
    final color = _accuracyColor(location.accuracy);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          // Accuracy dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Coordinates + time + BG/FG
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text('$dateStr • $timeStr',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          // Accuracy badge
          Text(
            '±${location.accuracy.toStringAsFixed(0)}m',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}