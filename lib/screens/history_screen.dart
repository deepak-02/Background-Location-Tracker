
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/location_record.dart';
import '../providers/tracking_provider.dart';
import '../theme/app_colors.dart';

// ── Filter enum ──
enum HistoryFilter {
  lastHour('Last 1 Hour'),
  last6Hours('Last 6 Hours'),
  last24Hours('Last 24 Hours'),
  last3Days('Last 3 Days'),
  last7Days('Last 7 Days'),
  lastMonth('Last Month'),
  currentMonth('Current Month');

  const HistoryFilter(this.label);
  final String label;

  DateTime get from {
    final now = DateTime.now();
    switch (this) {
      case HistoryFilter.lastHour:
        return now.subtract(const Duration(hours: 1));
      case HistoryFilter.last6Hours:
        return now.subtract(const Duration(hours: 6));
      case HistoryFilter.last24Hours:
        return now.subtract(const Duration(hours: 24));
      case HistoryFilter.last3Days:
        return now.subtract(const Duration(days: 3));
      case HistoryFilter.last7Days:
        return now.subtract(const Duration(days: 7));
      case HistoryFilter.lastMonth:
        return now.subtract(const Duration(days: 30));
      case HistoryFilter.currentMonth:
        return DateTime(now.year, now.month, 1);
    }
  }

  DateTime get to => DateTime.now();
}

// ── History Screen ──
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryFilter _selectedFilter = HistoryFilter.last24Hours;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrackingProvider>();
    final filtered = provider.getFilteredLocations(
      _selectedFilter.from,
      _selectedFilter.to,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (filtered.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded,
                  color: AppColors.error),
              tooltip: 'Delete all filtered',
              onPressed: () =>
                  _showDeleteAllDialog(context, provider, filtered),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter chips ──
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: HistoryFilter.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = HistoryFilter.values[index];
                final isSelected = filter == _selectedFilter;
                return FilterChip(
                  label: Text(filter.label),
                  selected: isSelected,
                  onSelected: (_) =>
                      setState(() => _selectedFilter = filter),
                  selectedColor:
                      AppColors.primaryIndigo.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primaryIndigo,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.primaryIndigo
                        : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primaryIndigo.withValues(alpha: 0.5)
                        : AppColors.cardBorder,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                );
              },
            ),
          ),

          // ── Count badge ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryIndigo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filtered.length} location${filtered.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: AppColors.primaryIndigo,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── List ──
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_list_off_rounded,
                            size: 48,
                            color:
                                AppColors.textMuted.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No locations in ${_selectedFilter.label.toLowerCase()}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final entry = filtered[index];
                      return _HistoryTile(
                        entry: entry,
                        onDelete: () =>
                            provider.deleteLocation(entry.key),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(
    BuildContext context,
    TrackingProvider provider,
    List<MapEntry<dynamic, LocationRecord>> entries,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete All?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Delete ${entries.length} locations from "${_selectedFilter.label}"?\nThis cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider
                  .deleteLocations(entries.map((e) => e.key).toList());
              Navigator.pop(ctx);
            },
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── History tile with swipe-to-delete ──
class _HistoryTile extends StatelessWidget {
  final MapEntry<dynamic, LocationRecord> entry;
  final VoidCallback onDelete;

  const _HistoryTile({required this.entry, required this.onDelete});

  Color _accuracyColor(double accuracy) {
    if (accuracy <= 5) return AppColors.accentEmerald;
    if (accuracy <= 15) return AppColors.accentCyan;
    if (accuracy <= 30) return AppColors.warning;
    return AppColors.error;
  }

  String _accuracyLabel(double accuracy) {
    if (accuracy <= 5) return 'Excellent';
    if (accuracy <= 15) return 'Good';
    if (accuracy <= 30) return 'Fair';
    return 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    final loc = entry.value;
    final dateStr = DateFormat('MMM dd, yyyy').format(loc.timestamp);
    final timeStr = DateFormat('hh:mm:ss a').format(loc.timestamp);
    final accColor = _accuracyColor(loc.accuracy);

    return Dismissible(
      key: ValueKey(entry.key),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryIndigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.location_on_rounded,
                  color: AppColors.primaryIndigo, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${loc.latitude.toStringAsFixed(6)}, ${loc.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$dateStr • $timeStr',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    '±${loc.accuracy.toStringAsFixed(0)}m',
                    style: TextStyle(
                        color: accColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                  Text(
                    _accuracyLabel(loc.accuracy),
                    style: TextStyle(
                        color: accColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
