import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/tracking_provider.dart';
import '../theme/app_colors.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _mapReady = false;

  void _fitAllPoints(List<LatLng> points) {
    if (!_mapReady || points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, 17);
      return;
    }

    double minLat = double.infinity, maxLat = -double.infinity;
    double minLng = double.infinity, maxLng = -double.infinity;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    // If all points are within ~100m, just center on the mean
    // instead of fitting bounds (which would over-zoom)
    final latSpan = maxLat - minLat;
    final lngSpan = maxLng - minLng;
    if (latSpan < 0.001 && lngSpan < 0.001) {
      _mapController.move(
        LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2),
        17,
      );
      return;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
        padding: const EdgeInsets.all(60),
        maxZoom: 17,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrackingProvider>();
    final locations = provider.locations;

    // Reversed so oldest → newest for the polyline trail
    final chronological =
        locations.reversed.map((l) => LatLng(l.latitude, l.longitude)).toList();
    // Newest first for marker display
    final newestFirst =
        locations.map((l) => LatLng(l.latitude, l.longitude)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
        actions: [
          if (newestFirst.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.fit_screen_rounded),
              tooltip: 'Fit all points',
              onPressed: () => _fitAllPoints(newestFirst),
            ),
        ],
      ),
      body: newestFirst.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, size: 64, color: AppColors.textMuted),
                  SizedBox(height: 16),
                  Text('No locations to display',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Start tracking to see your route',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: newestFirst.first,
                    initialZoom: 15.0,
                    minZoom: 2.0,
                    maxZoom: 18.0,
                    onMapReady: () {
                      _mapReady = true;
                    },
                  ),
                  children: [
                    // Dark map tiles
                    TileLayer(
                      urlTemplate:
                          'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
                      userAgentPackageName:
                          'com.example.background_location_tracker',
                    ),
                    // Route polyline (chronological)
                    if (chronological.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: chronological,
                            color: AppColors.primaryIndigo,
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                    // Markers
                    MarkerLayer(markers: _buildMarkers(newestFirst)),
                  ],
                ),
                // Points count overlay
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pin_drop_rounded,
                            size: 16, color: AppColors.accentCyan),
                        const SizedBox(width: 6),
                        Text('${locations.length} points',
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                // Tracking indicator
                if (provider.isTracking)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                AppColors.accentEmerald.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle,
                              size: 8, color: AppColors.accentEmerald),
                          SizedBox(width: 6),
                          Text('LIVE',
                              style: TextStyle(
                                  color: AppColors.accentEmerald,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: newestFirst.isNotEmpty
          ? FloatingActionButton.small(
              backgroundColor: AppColors.primaryIndigo,
              onPressed: () {
                if (_mapReady) _mapController.move(newestFirst.first, 16);
              },
              child: const Icon(Icons.my_location_rounded, color: Colors.white),
            )
          : null,
    );
  }

  List<Marker> _buildMarkers(List<LatLng> points) {
    if (points.isEmpty) return [];

    final markers = <Marker>[];

    // Latest location — large green marker
    markers.add(Marker(
      point: points.first,
      width: 24,
      height: 24,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.accentEmerald,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
                color: AppColors.accentEmerald.withValues(alpha: 0.4),
                blurRadius: 8)
          ],
        ),
      ),
    ));

    // Other points — small dots
    for (int i = 1; i < points.length; i++) {
      markers.add(Marker(
        point: points[i],
        width: 10,
        height: 10,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryIndigo.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
          ),
        ),
      ));
    }

    return markers;
  }
}
