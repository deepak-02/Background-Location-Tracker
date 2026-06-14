import 'package:flutter/services.dart';

class BatteryService {
  static const MethodChannel _channel =
      MethodChannel('com.example.background_location_tracker/battery');

  static const EventChannel _eventChannel =
      EventChannel('com.example.background_location_tracker/battery_stream');

  /// Cached battery level from the last fetch — used for instant display.
  static int _cachedLevel = -1;
  static int get cachedLevel => _cachedLevel;

  /// Pre-fetch at app startup so the first frame has real data.
  static Future<void> init() async {
    try {
      final Map result = await _channel.invokeMethod('getBatteryInfo');
      _cachedLevel = result['level'] as int;
    } on PlatformException {
      // Keep default
    }
  }

  /// Real-time battery level stream from the native EventChannel.
  /// Emits an [int] percentage whenever Android fires ACTION_BATTERY_CHANGED.
  static Stream<int> get batteryLevelStream =>
      _eventChannel.receiveBroadcastStream().map((event) {
        final level = event as int;
        _cachedLevel = level;
        return level;
      });
}
