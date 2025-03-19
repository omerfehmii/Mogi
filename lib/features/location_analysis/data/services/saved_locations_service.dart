import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/saved_location_model.dart';

class SavedLocationsService {
  late Box<SavedLocationModel> _box;
  static const String _boxName = 'saved_locations';

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SavedLocationModelAdapter());
    }
    _box = await Hive.openBox<SavedLocationModel>(_boxName);
  }

  Future<List<SavedLocationModel>> getSavedLocations() async {
    return _box.values.toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  Future<bool> isLocationSaved(String locationId) async {
    return _box.values.any((location) => location.id == locationId);
  }

  Future<SavedLocationModel?> getLocationById(String locationId) async {
    try {
      return _box.values.firstWhere(
        (location) => location.id == locationId,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> saveLocation({
    required String name,
    required String description,
    required String imageUrl,
    required double latitude,
    required double longitude,
    required double securityScore,
    required double transportScore,
    required String type,
    Map<String, double>? additionalScores,
  }) async {
    try {
      // Önce aynı koordinatlarda konum var mı kontrol et
      SavedLocationModel? existingLocation;
      try {
        existingLocation = _box.values.firstWhere(
          (location) => 
            location.latitude == latitude && 
            location.longitude == longitude,
        );
      } catch (e) {
        // Konum bulunamadı, devam et
      }

      final location = SavedLocationModel(
        id: existingLocation?.id ?? const Uuid().v4(),
        name: name,
        description: description,
        imageUrl: imageUrl,
        latitude: latitude,
        longitude: longitude,
        securityScore: securityScore,
        transportScore: transportScore,
        type: type,
        additionalScores: additionalScores ?? {},
        savedAt: DateTime.now(),
      );

      await _box.put(location.id, location);
    } catch (e) {
      throw Exception('Konum kaydedilirken hata oluştu: $e');
    }
  }

  Future<void> removeLocationById(String locationId) async {
    try {
      final location = await getLocationById(locationId);
      if (location != null) {
        await _box.delete(location.key);
      } else {
        throw Exception('Konum bulunamadı');
      }
    } catch (e) {
      throw Exception('Konum silinirken hata oluştu: $e');
    }
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
} 