import 'package:hive/hive.dart';

part 'location_record.g.dart';

@HiveType(typeId: 0)
class LocationRecord {

  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final double accuracy;

  @HiveField(4, defaultValue: true)
  final bool isBackground;

  const LocationRecord({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.accuracy,
    this.isBackground = true,
  });
}