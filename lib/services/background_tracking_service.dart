import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/location_record.dart';

class BackgroundTrackingService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static bool _configured = false;

  /// Configures the background service entry point and parameters.
  /// Safe to call multiple times — subsequent calls are no-ops.
  static Future<void> initialize() async {
    if (_configured) return;
    try {
      await _service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: false,
          autoStartOnBoot: false,
          isForegroundMode: true,
          foregroundServiceNotificationId: 888,
          initialNotificationTitle: 'Location Tracker',
          initialNotificationContent: 'Tracking inactive',
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );
      _configured = true;
    } catch (e) {
      debugPrint('BackgroundTrackingService.initialize() error: $e');
    }
  }

  /// Starts the background tracking service.
  /// Re-configures if a previous configure was skipped/failed.
  static Future<void> start() async {
    if (!_configured) {
      // Force re-configure — the initial configure may have been skipped
      // because the service was already running from a prior app session.
      _configured = false;
      await initialize();
    }
    await _service.startService();
  }

  static Future<void> stop() async {
    _service.invoke('stop');
  }

  static Future<bool> isRunning() async {
    return await _service.isRunning();
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Initialize Hive in background isolate with a concrete path
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(LocationRecordAdapter());
  }

  final box = await Hive.openBox<LocationRecord>('locations');

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'Location Tracker',
      content: 'Tracking active — acquiring GPS...',
    );
  }

  // Capture immediately, then every 60 seconds
  await _captureLocation(box, service);

  Timer.periodic(const Duration(seconds: 60), (timer) async {
    await _captureLocation(box, service);
  });

  service.on('stop').listen((event) {
    service.stopSelf();
  });
}

Future<void> _captureLocation(
    Box<LocationRecord> box, ServiceInstance service) async {
  try {
    // Use AndroidSettings to explicitly prefer the Google Fused Location
    // Provider for better accuracy (typically 3–10m vs 20m+).
    final position = await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.best,
        forceLocationManager: false,
      ),
    );

    // If the first fix is very poor (>100m), try once more
    Position finalPosition = position;
    if (position.accuracy > 100) {
      try {
        final retry = await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.best,
            forceLocationManager: false,
          ),
        );
        if (retry.accuracy < position.accuracy) {
          finalPosition = retry;
        }
      } catch (_) {
        // Use the first reading if retry fails
      }
    }

    final record = LocationRecord(
      latitude: finalPosition.latitude,
      longitude: finalPosition.longitude,
      timestamp: DateTime.now(),
      accuracy: finalPosition.accuracy,
      isBackground: true,
    );

    await box.add(record);
    await box.flush(); // Ensure bytes are on disk before notifying main isolate
    service.invoke('update');

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Location Tracker',
        content:
            'Last: ${finalPosition.latitude.toStringAsFixed(4)}, ${finalPosition.longitude.toStringAsFixed(4)} · ±${finalPosition.accuracy.toStringAsFixed(0)}m',
      );
    }
  } catch (e) {
    // Don't crash the service on errors
    debugPrint('_captureLocation error: $e');
  }
}