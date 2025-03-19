import 'package:latlong2/latlong.dart';
import 'package:hive/hive.dart';

part 'saved_location_model.g.dart';

@HiveType(typeId: 0)
class SavedLocationModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String imageUrl;

  @HiveField(4)
  final double latitude;

  @HiveField(5)
  final double longitude;

  @HiveField(6)
  final double securityScore;

  @HiveField(7)
  final String type;

  @HiveField(8)
  final DateTime savedAt;

  @HiveField(9)
  final double transportScore;

  @HiveField(10)
  final Map<String, double> additionalScores;

  LatLng get location => LatLng(latitude, longitude);

  Map<String, double> get scores => {
    'security': securityScore,
    'transport': transportScore,
    ...additionalScores,
  };

  SavedLocationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.securityScore,
    required this.transportScore,
    required this.type,
    required this.savedAt,
    this.additionalScores = const {},
  });
} 