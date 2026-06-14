import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/tracking_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/battery_card.dart';
import '../widgets/location_list.dart';
import '../widgets/tracking_controls.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<bool> _handlePermissions(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Location services are disabled. Please enable GPS.')),
        );
      }
      return false;
    }

    if (Platform.isAndroid) {
      final notifStatus = await Permission.notification.status;
      if (!notifStatus.isGranted) {
        await Permission.notification.request();
      }
    }

    var locStatus = await Permission.location.status;
    if (!locStatus.isGranted) {
      locStatus = await Permission.location.request();
      if (!locStatus.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
        }
        return false;
      }
    }

    if (Platform.isAndroid) {
      var bgStatus = await Permission.locationAlways.status;
      if (!bgStatus.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                duration: Duration(seconds: 4),
                content: Text(
                    'Please select "Allow all the time" for background tracking.')),
          );
        }
        bgStatus = await Permission.locationAlways.request();
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrackingProvider>();
    final recentLocations = provider.locations.take(10).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // ── Header ──
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Location Tracker',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5)),
                    Text('Background GPS Tracking',
                        style:
                            TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Battery Card ──
            const BatteryCard(),

            const SizedBox(height: 14),

            // ── Tracking Card ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: provider.isTracking
                      ? AppColors.accentEmerald.withValues(alpha: 0.3)
                      : AppColors.cardBorder,
                ),
                boxShadow: provider.isTracking
                    ? [
                        BoxShadow(
                            color:
                                AppColors.accentEmerald.withValues(alpha: 0.08),
                            blurRadius: 24,
                            spreadRadius: -4)
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PulsingDot(isActive: provider.isTracking),
                      const SizedBox(width: 10),
                      Text(
                        provider.isTracking
                            ? 'Tracking Active'
                            : 'Tracking Stopped',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: provider.isTracking
                              ? AppColors.accentEmerald
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TrackingControls(
                    isTracking: provider.isTracking,
                    onStart: () async {
                      final granted = await _handlePermissions(context);
                      if (granted && context.mounted) {
                        context.read<TrackingProvider>().startTracking();
                      }
                    },
                    onStop: () {
                      context.read<TrackingProvider>().stopTracking();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ── Recent Locations Header ──
            Row(
              children: [
                const Text('Recent Locations',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const Spacer(),
                Text('${provider.locations.length} total',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 10),

            // ── Location List ──
            if (recentLocations.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Column(
                  children: [
                    Icon(Icons.location_off_rounded,
                        size: 48,
                        color: AppColors.textMuted.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    const Text('No locations recorded',
                        style:
                            TextStyle(color: AppColors.textMuted, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('Press START to begin tracking',
                        style:
                            TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              )
            else
              ...recentLocations
                  .map((loc) => LocationListTile(location: loc)),
          ],
        ),
      ),
    );
  }
}

// ── Pulsing status dot ──
class _PulsingDot extends StatefulWidget {
  final bool isActive;
  const _PulsingDot({required this.isActive});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);
    _anim = Tween(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.isActive) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isActive && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isActive ? AppColors.accentEmerald : AppColors.error;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                        color: color.withValues(alpha: _anim.value * 0.6),
                        blurRadius: 8,
                        spreadRadius: 2)
                  ]
                : null,
          ),
        );
      },
    );
  }
}