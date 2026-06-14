import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/battery_service.dart';
import '../theme/app_colors.dart';

class BatteryCard extends StatefulWidget {
  const BatteryCard({super.key});

  @override
  State<BatteryCard> createState() => _BatteryCardState();
}

class _BatteryCardState extends State<BatteryCard> {
  late int _batteryLevel = BatteryService.cachedLevel;
  bool _locationEnabled = true;

  StreamSubscription<int>? _batterySubscription;
  StreamSubscription<ServiceStatus>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _checkLocationEnabled();

    // Real-time battery updates from native EventChannel
    _batterySubscription =
        BatteryService.batteryLevelStream.listen((level) {
      if (mounted) setState(() => _batteryLevel = level);
    });

    // Real-time location service status from Geolocator
    _locationSubscription =
        Geolocator.getServiceStatusStream().listen((status) {
      if (mounted) {
        setState(() {
          _locationEnabled = status == ServiceStatus.enabled;
        });
      }
    });
  }

  Future<void> _checkLocationEnabled() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (mounted && enabled != _locationEnabled) {
      setState(() => _locationEnabled = enabled);
    }
  }

  Future<void> _onTap() async {
    if (!_locationEnabled) {
      await Geolocator.openLocationSettings();
    }
  }

  @override
  void dispose() {
    _batterySubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  IconData _batteryIcon() {
    if (_batteryLevel < 0) return Icons.battery_unknown;
    if (_batteryLevel <= 15) return Icons.battery_alert;
    if (_batteryLevel <= 30) return Icons.battery_2_bar;
    if (_batteryLevel <= 50) return Icons.battery_3_bar;
    if (_batteryLevel <= 70) return Icons.battery_4_bar;
    if (_batteryLevel <= 90) return Icons.battery_5_bar;
    return Icons.battery_full;
  }

  Color _batteryColor() {
    if (_batteryLevel < 0) return AppColors.textMuted;
    if (_batteryLevel <= 15) return AppColors.error;
    if (_batteryLevel <= 30) return AppColors.warning;
    return AppColors.accentEmerald;
  }

  @override
  Widget build(BuildContext context) {
    final display = _batteryLevel < 0 ? '--' : '$_batteryLevel%';
    final color = _batteryColor();

    return GestureDetector(
      onTap: _onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.surface, AppColors.scaffoldBg],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 20,
                spreadRadius: -4),
          ],
        ),
        child: Row(
          children: [
            // Battery icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_batteryIcon(), size: 28, color: color),
            ),
            const SizedBox(width: 16),
            // Level + location status — wrapped in Expanded to prevent overflow
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    display,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -1,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        _locationEnabled
                            ? Icons.location_on_rounded
                            : Icons.location_off_rounded,
                        size: 14,
                        color: _locationEnabled
                            ? AppColors.accentEmerald
                            : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _locationEnabled
                              ? 'Location Enabled'
                              : 'Location Disabled · Tap to enable',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: _locationEnabled
                                ? AppColors.accentEmerald
                                : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Label
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'BATTERY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
