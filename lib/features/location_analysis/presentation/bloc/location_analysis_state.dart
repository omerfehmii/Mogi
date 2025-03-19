import 'package:equatable/equatable.dart';
import 'package:mogi/features/location_analysis/domain/entities/location_analysis.dart';

abstract class LocationAnalysisState extends Equatable {
  const LocationAnalysisState();

  @override
  List<Object?> get props => [];
}

class LocationAnalysisInitial extends LocationAnalysisState {}

class LocationAnalysisLoading extends LocationAnalysisState {}

class LocationAnalysisSuccess extends LocationAnalysisState {
  final LocationAnalysis analysis;

  const LocationAnalysisSuccess(this.analysis);

  @override
  List<Object?> get props => [analysis];
}

class LocationAnalysisError extends LocationAnalysisState {
  final String message;

  const LocationAnalysisError(this.message);

  @override
  List<Object?> get props => [message];
}

class AIAnalysisLoading extends LocationAnalysisState {}

class AIAnalysisSuccess extends LocationAnalysisState {
  final String analysis;

  const AIAnalysisSuccess(this.analysis);

  @override
  List<Object?> get props => [analysis];
}

class SavedLocationsLoading extends LocationAnalysisState {}

class SavedLocationsSuccess extends LocationAnalysisState {
  final List<LocationAnalysis> locations;

  const SavedLocationsSuccess(this.locations);

  @override
  List<Object?> get props => [locations];
} 