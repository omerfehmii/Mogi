import 'package:mogi/features/location_analysis/domain/entities/location_analysis.dart';

abstract class LocationAnalysisRepository {
  Future<LocationAnalysis> getLocationAnalysis({
    required double latitude,
    required double longitude,
    required Map<String, dynamic> userPreferences,
  });

  Future<List<String>> searchLocations(String query);

  Future<void> saveLocation(LocationAnalysis location);

  Future<List<LocationAnalysis>> getSavedLocations();

  Future<String> getAIAnalysis({
    required LocationAnalysis location,
    required Map<String, dynamic> userProfile,
    String? userQuestion,
  });

  Future<Map<String, double>> getCostOfLiving(String locationName);

  Future<Map<String, List<String>>> getEducationFacilities({
    required double latitude,
    required double longitude,
    required double radius,
  });

  Future<double> getSafetyScore({
    required double latitude,
    required double longitude,
  });

  Future<double> getTransportScore({
    required double latitude,
    required double longitude,
  });
} 