import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

part 'recently_viewed_location_model.g.dart';

@HiveType(typeId: 2)
class RecentlyViewedLocationModel extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final String imageUrl;

  @HiveField(3)
  final double latitude;

  @HiveField(4)
  final double longitude;

  @HiveField(5)
  final String type;

  @HiveField(6)
  final DateTime viewedAt;

  @HiveField(7)
  final Map<String, double> scores;

  RecentlyViewedLocationModel({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.viewedAt,
    this.scores = const {},
  });

  LatLng get location => LatLng(latitude, longitude);
} 