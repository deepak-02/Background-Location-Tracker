import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/location_record.dart';

class HiveService {
  static const String locationBox = 'locations';

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LocationRecordAdapter());
    }

    await _safeOpenBox();
  }

  static Box<LocationRecord> get box =>
      Hive.box<LocationRecord>(locationBox);

  /// Close and reopen the Hive box to re-read data written
  /// by the background isolate.
  ///
  /// This can fail with `RangeError` if the background isolate
  /// is mid-write when we re-read. We catch and retry once after
  /// a short delay.
  static Future<void> reload() async {
    try {
      if (Hive.isBoxOpen(locationBox)) {
        await Hive.box<LocationRecord>(locationBox).close();
      }
      await Hive.openBox<LocationRecord>(locationBox);
    } catch (e) {
      // First retry: wait for the background write to flush
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        if (Hive.isBoxOpen(locationBox)) {
          await Hive.box<LocationRecord>(locationBox).close();
        }
        await Hive.openBox<LocationRecord>(locationBox);
      } catch (e2) {
        // File is corrupted beyond recovery — delete and recreate
        debugPrint('HiveService: box corrupted, recreating. $e2');
        await _deleteAndRecreateBox();
      }
    }
  }

  /// Safely open the box, recovering from corruption if needed.
  static Future<void> _safeOpenBox() async {
    try {
      if (!Hive.isBoxOpen(locationBox)) {
        await Hive.openBox<LocationRecord>(locationBox);
      }
    } catch (e) {
      debugPrint('HiveService: init failed, recreating box. $e');
      await _deleteAndRecreateBox();
    }
  }

  /// Delete the corrupted Hive files and open a fresh box.
  static Future<void> _deleteAndRecreateBox() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final hiveFile = File('${dir.path}/$locationBox.hive');
      final lockFile = File('${dir.path}/$locationBox.lock');
      if (await hiveFile.exists()) await hiveFile.delete();
      if (await lockFile.exists()) await lockFile.delete();
    } catch (_) {
      // Best effort cleanup
    }
    try {
      await Hive.openBox<LocationRecord>(locationBox);
    } catch (_) {
      // If even a fresh open fails, app can still work without persisted data
    }
  }



  static List<LocationRecord> getLocations() {
    try {
      return box.values.toList().reversed.toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns locations as (key, record) pairs, sorted newest-first.
  /// Keys are needed for deletion support.
  static List<MapEntry<dynamic, LocationRecord>> getLocationsWithKeys() {
    try {
      final entries = box.toMap().entries.toList();
      entries.sort((a, b) => b.value.timestamp.compareTo(a.value.timestamp));
      return entries;
    } catch (_) {
      return [];
    }
  }

  /// Returns locations within [from, to] range, sorted newest-first.
  static List<MapEntry<dynamic, LocationRecord>> getLocationsByDateRange(
      DateTime from, DateTime to) {
    return getLocationsWithKeys()
        .where((e) =>
            !e.value.timestamp.isBefore(from) &&
            !e.value.timestamp.isAfter(to))
        .toList();
  }

  static Future<void> deleteByKey(dynamic key) async {
    await box.delete(key);
  }

  static Future<void> deleteByKeys(List<dynamic> keys) async {
    await box.deleteAll(keys);
  }

  static Future<void> clear() async {
    await box.clear();
  }
}