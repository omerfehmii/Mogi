import 'package:freezed_annotation/freezed_annotation.dart';

part 'location_analysis.freezed.dart';
part 'location_analysis.g.dart';

@freezed
class LocationAnalysis with _$LocationAnalysis {
  const factory LocationAnalysis({
    required String locationName,
    required double latitude,
    required double longitude,
    required double safetyScore,
    required double transportScore,
    required Map<String, double> costOfLiving,
    required List<String> nearbyAmenities,
    required Map<String, List<String>> educationFacilities,
    required Map<String, dynamic> demographicData,
    String? analysis,
    List<String>? pros,
    List<String>? cons,
  }) = _LocationAnalysis;

  factory LocationAnalysis.fromJson(Map<String, dynamic> json) =>
      _$LocationAnalysisFromJson(json);
} 