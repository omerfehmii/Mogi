import 'package:equatable/equatable.dart';
import 'package:mogi/features/location_analysis/domain/entities/location_analysis.dart';

abstract class LocationAnalysisEvent extends Equatable {
  const LocationAnalysisEvent();

  @override
  List<Object?> get props => [];
}

class AnalyzeLocation extends LocationAnalysisEvent {
  final double latitude;
  final double longitude;
  final Map<String, dynamic> userPreferences;

  const AnalyzeLocation({
    required this.latitude,
    required this.longitude,
    required this.userPreferences,
  });

  @override
  List<Object?> get props => [latitude, longitude, userPreferences];
}

class GetAIAnalysis extends LocationAnalysisEvent {
  final LocationAnalysis location;
  final Map<String, dynamic> userProfile;
  final String? userQuestion;

  const GetAIAnalysis({
    required this.location,
    required this.userProfile,
    this.userQuestion,
  });

  @override
  List<Object?> get props => [location, userProfile, userQuestion];
}

class SaveLocation extends LocationAnalysisEvent {
  final LocationAnalysis location;

  const SaveLocation(this.location);

  @override
  List<Object?> get props => [location];
}

class LoadSavedLocations extends LocationAnalysisEvent {}

class SearchLocations extends LocationAnalysisEvent {
  final String query;

  const SearchLocations(this.query);

  @override
  List<Object?> get props => [query];
} 