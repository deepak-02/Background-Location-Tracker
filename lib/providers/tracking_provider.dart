import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location_record.dart';
import '../services/background_tracking_service.dart';
import '../services/hive_service.dart';

class TrackingProvider extends ChangeNotifier {
  bool _isTracking = false;
  StreamSubscription? _updateSubscription;
  StreamSubscription<ServiceStatus>? _locationServiceSubscription;

  bool get isTracking => _isTracking;

  List<LocationRecord> get locations => HiveService.getLocations();

  List<MapEntry<dynamic, LocationRecord>> get locationsWithKeys =>
      HiveService.getLocationsWithKeys();

  TrackingProvider() {
    _checkIfServiceRunning();
    _listenForUpdates();
    _watchLocationService();
  }

  Future<void> _checkIfServiceRunning() async {
    try {
      _isTracking = await BackgroundTrackingService.isRunning();
      if (_isTracking) {
        await HiveService.reload();
      }
    } catch (_) {
      _isTracking = false;
    }
    notifyListeners();
  }

  void _listenForUpdates() {
    try {
      _updateSubscription =
          FlutterBackgroundService().on('update').listen((_) async {
        // Small delay to let the background isolate flush its write to disk
        await Future.delayed(const Duration(milliseconds: 300));
        try {
          await HiveService.reload();
        } catch (_) {
          // Reload failed — will retry on next update
        }
        notifyListeners();
      });
    } catch (_) {
      // Service not available — will sync on next manual action
    }
  }

  /// Automatically stop tracking if the user disables location services.
  void _watchLocationService() {
    _locationServiceSubscription =
        Geolocator.getServiceStatusStream().listen((status) {
      if (status == ServiceStatus.disabled && _isTracking) {
        stopTracking();
      }
    });
  }

  Future<void> startTracking() async {
    try {
      _isTracking = true;
      notifyListeners();
      await BackgroundTrackingService.start();
    } catch (e) {
      _isTracking = false;
      notifyListeners();
    }
  }

  Future<void> stopTracking() async {
    try {
      _isTracking = false;
      await BackgroundTrackingService.stop();
      await HiveService.reload();
    } catch (_) {
      // Best-effort stop
    }
    notifyListeners();
  }

  Future<void> deleteLocation(dynamic key) async {
    await HiveService.deleteByKey(key);
    notifyListeners();
  }

  Future<void> deleteLocations(List<dynamic> keys) async {
    await HiveService.deleteByKeys(keys);
    notifyListeners();
  }

  List<MapEntry<dynamic, LocationRecord>> getFilteredLocations(
      DateTime from, DateTime to) {
    return HiveService.getLocationsByDateRange(from, to);
  }

  Future<void> clearAll() async {
    await HiveService.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _updateSubscription?.cancel();
    _locationServiceSubscription?.cancel();
    super.dispose();
  }
}