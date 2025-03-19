import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mogi/features/location_analysis/domain/repositories/location_analysis_repository.dart';
import 'package:mogi/features/location_analysis/presentation/bloc/location_analysis_event.dart';
import 'package:mogi/features/location_analysis/presentation/bloc/location_analysis_state.dart';

class LocationAnalysisBloc
    extends Bloc<LocationAnalysisEvent, LocationAnalysisState> {
  final LocationAnalysisRepository repository;

  LocationAnalysisBloc({required this.repository})
      : super(LocationAnalysisInitial()) {
    on<AnalyzeLocation>(_onAnalyzeLocation);
    on<GetAIAnalysis>(_onGetAIAnalysis);
    on<SaveLocation>(_onSaveLocation);
    on<LoadSavedLocations>(_onLoadSavedLocations);
    on<SearchLocations>(_onSearchLocations);
  }

  Future<void> _onAnalyzeLocation(
    AnalyzeLocation event,
    Emitter<LocationAnalysisState> emit,
  ) async {
    try {
      emit(LocationAnalysisLoading());
      final analysis = await repository.getLocationAnalysis(
        latitude: event.latitude,
        longitude: event.longitude,
        userPreferences: event.userPreferences,
      );
      emit(LocationAnalysisSuccess(analysis));
    } catch (e) {
      emit(LocationAnalysisError(e.toString()));
    }
  }

  Future<void> _onGetAIAnalysis(
    GetAIAnalysis event,
    Emitter<LocationAnalysisState> emit,
  ) async {
    try {
      emit(AIAnalysisLoading());
      final analysis = await repository.getAIAnalysis(
        location: event.location,
        userProfile: event.userProfile,
        userQuestion: event.userQuestion,
      );
      emit(AIAnalysisSuccess(analysis));
    } catch (e) {
      emit(LocationAnalysisError(e.toString()));
    }
  }

  Future<void> _onSaveLocation(
    SaveLocation event,
    Emitter<LocationAnalysisState> emit,
  ) async {
    try {
      await repository.saveLocation(event.location);
      final savedLocations = await repository.getSavedLocations();
      emit(SavedLocationsSuccess(savedLocations));
    } catch (e) {
      emit(LocationAnalysisError(e.toString()));
    }
  }

  Future<void> _onLoadSavedLocations(
    LoadSavedLocations event,
    Emitter<LocationAnalysisState> emit,
  ) async {
    try {
      emit(SavedLocationsLoading());
      final locations = await repository.getSavedLocations();
      emit(SavedLocationsSuccess(locations));
    } catch (e) {
      emit(LocationAnalysisError(e.toString()));
    }
  }

  Future<void> _onSearchLocations(
    SearchLocations event,
    Emitter<LocationAnalysisState> emit,
  ) async {
    try {
      emit(LocationAnalysisLoading());
      final locations = await repository.searchLocations(event.query);
      // TODO: Convert string locations to LocationAnalysis objects
      emit(SavedLocationsSuccess([]));
    } catch (e) {
      emit(LocationAnalysisError(e.toString()));
    }
  }
} 