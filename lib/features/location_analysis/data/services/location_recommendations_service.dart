import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/recently_viewed_location_model.dart';
import '../../domain/models/saved_location_model.dart';

class LocationRecommendationsService {
  late Box<RecentlyViewedLocationModel> _recentlyViewedBox;
  late Box<SavedLocationModel> _savedLocationsBox;
  late Box _cacheBox;
  final _uuid = const Uuid();
  static const _recentlyViewedBoxName = 'recently_viewed_locations';
  static const _savedLocationsBoxName = 'saved_locations';
  static const _cacheBoxName = 'recommendations_cache';
  static const _cacheDuration = Duration(hours: 24);
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      // Adapter kayıtlarını kontrol et ve kaydet
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(SavedLocationModelAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(RecentlyViewedLocationModelAdapter());
      }
      
      // Box'ları aç
      _recentlyViewedBox = await Hive.openBox<RecentlyViewedLocationModel>(_recentlyViewedBoxName);
      _savedLocationsBox = await Hive.openBox<SavedLocationModel>(_savedLocationsBoxName);
      _cacheBox = await Hive.openBox(_cacheBoxName);

      // Süresi dolmuş önbelleği temizle
      await _cleanExpiredCache();
      
      _isInitialized = true;
      print('LocationRecommendationsService başarıyla başlatıldı');
    } catch (e, stackTrace) {
      print('LocationRecommendationsService başlatılırken hata: $e');
      print('Stack trace: $stackTrace');
      _isInitialized = false;
      rethrow;
    }
  }

  // Servisin başlatılıp başlatılmadığını kontrol et
  bool get isInitialized => _isInitialized;

  Future<void> _cleanExpiredCache() async {
    try {
      final now = DateTime.now();
      final keysToDelete = <dynamic>[];

      for (final key in _cacheBox.keys) {
        final cacheData = _cacheBox.get(key);
        if (cacheData != null && cacheData is Map && cacheData.containsKey('timestamp')) {
          final timestamp = DateTime.parse(cacheData['timestamp']);
          if (now.difference(timestamp) > _cacheDuration) {
            keysToDelete.add(key);
          }
        } else {
          // Geçersiz önbellek verisi, temizle
          keysToDelete.add(key);
        }
      }

      for (final key in keysToDelete) {
        await _cacheBox.delete(key);
      }

      print('${keysToDelete.length} süresi dolmuş önbellek öğesi temizlendi');
    } catch (e) {
      print('Önbellek temizlenirken hata: $e');
      // Hata durumunda işlemi kesme, devam et
    }
  }

  String _generateCacheKey() {
    try {
      // Son görüntülenen konumların ID'lerini al
      final recentIds = _recentlyViewedBox.values
          .take(5) // Performans için sadece son 5 konumu kullan
          .map((l) => '${l.latitude.toStringAsFixed(4)},${l.longitude.toStringAsFixed(4)}')
          .join('-');
      
      // Kaydedilen konumların ID'lerini al
      final savedIds = _savedLocationsBox.values
          .take(5) // Performans için sadece son 5 konumu kullan
          .map((l) => l.id)
          .join('-');
      
      // Boş olma durumunu kontrol et
      final cacheKey = '${recentIds.isNotEmpty ? recentIds : "empty"}|${savedIds.isNotEmpty ? savedIds : "empty"}';
      return cacheKey;
    } catch (e) {
      print('Önbellek anahtarı oluşturulurken hata: $e');
      // Hata durumunda benzersiz bir anahtar döndür
      return 'error-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<void> _saveToCache(String key, List<Map<String, dynamic>> recommendations) async {
    try {
      // Önbelleğe kaydetmeden önce veriyi doğrula
      if (key.isEmpty) {
        print('Boş önbellek anahtarı, kaydetme işlemi atlanıyor');
        return;
      }
      
      if (recommendations.isEmpty) {
        print('Boş öneri listesi, kaydetme işlemi atlanıyor');
        return;
      }
      
      // Önbelleğe kaydet
      await _cacheBox.put(key, {
        'recommendations': recommendations,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      print('Öneriler önbelleğe kaydedildi. Anahtar: $key');
    } catch (e) {
      print('Öneriler önbelleğe kaydedilirken hata: $e');
      // Hata durumunda işlemi kesme, devam et
    }
  }

  Future<void> clearCache() async {
    await _cacheBox.clear();
    print('Önbellek temizlendi');
  }

  Future<void> addRecentlyViewedLocation({
    required String name,
    required String description,
    required String imageUrl,
    required double latitude,
    required double longitude,
    required String type,
    required Map<String, double> scores,
  }) async {
    final location = RecentlyViewedLocationModel(
      name: name,
      description: description,
      imageUrl: imageUrl,
      latitude: latitude,
      longitude: longitude,
      type: type,
      scores: scores,
      viewedAt: DateTime.now(),
    );

    await _recentlyViewedBox.add(location);

    // Sadece son 20 konumu tut
    if (_recentlyViewedBox.length > 20) {
      final oldestKey = _recentlyViewedBox.keys.first;
      await _recentlyViewedBox.delete(oldestKey);
    }
  }

  List<Map<String, dynamic>> _getDefaultRecommendations() {
    return [
      {
        'id': _uuid.v4(),
        'name': 'Kadıköy',
        'description': 'İstanbul\'un kültür ve sanat merkezi',
        'imageUrl': 'assets/images/default_location.png',
        'location': {
          'latitude': 40.9906,
          'longitude': 29.0238,
        },
        'type': 'district',
        'matchScore': 0.85,
        'scores': {
          'security': 4.5,
          'transport': 4.8,
          'education': 4.2,
          'health': 4.0,
          'social': 4.7,
        },
      },
      {
        'id': _uuid.v4(),
        'name': 'Beşiktaş',
        'description': 'Canlı ve dinamik sahil bölgesi',
        'imageUrl': 'assets/images/default_location.png',
        'location': {
          'latitude': 41.0430,
          'longitude': 29.0046,
        },
        'type': 'district',
        'matchScore': 0.82,
        'scores': {
          'security': 4.3,
          'transport': 4.6,
          'education': 4.4,
          'health': 4.1,
          'social': 4.5,
        },
      },
      {
        'id': _uuid.v4(),
        'name': 'Üsküdar',
        'description': 'Tarihi atmosferiyle öne çıkan sahil semti',
        'imageUrl': 'assets/images/default_location.png',
        'location': {
          'latitude': 41.0234,
          'longitude': 29.0152,
        },
        'type': 'district',
        'matchScore': 0.78,
        'scores': {
          'security': 4.4,
          'transport': 4.3,
          'education': 4.2,
          'health': 4.3,
          'social': 4.1,
        },
      },
    ];
  }

  Map<String, int> _analyzeTypePreferences(
    List<RecentlyViewedLocationModel> recentlyViewed,
    List<SavedLocationModel> savedLocations,
  ) {
    try {
      final typeCount = <String, int>{};

      // Son görüntülenen konumların tiplerini say
      for (final location in recentlyViewed) {
        final type = location.type.isNotEmpty ? location.type : 'unknown';
        typeCount[type] = (typeCount[type] ?? 0) + 1;
      }

      // Kaydedilen konumların tiplerini say (2 kat ağırlıklı)
      for (final location in savedLocations) {
        final type = location.type.isNotEmpty ? location.type : 'unknown';
        typeCount[type] = (typeCount[type] ?? 0) + 2;
      }

      // Eğer hiç tip yoksa, varsayılan olarak 'district' ekle
      if (typeCount.isEmpty) {
        typeCount['district'] = 1;
      }

      return typeCount;
    } catch (e) {
      print('Tür tercihleri analiz edilirken hata: $e');
      return {'district': 1}; // Varsayılan olarak 'district' döndür
    }
  }

  double _calculateMatchScore(
    SavedLocationModel location,
    Map<String, int> typePreferences,
  ) {
    try {
      double score = 0;
      double totalWeight = 0;

      // 1. Tür eşleşmesi (30%)
      final typeWeight = 0.3;
      if (location.type.isNotEmpty && typePreferences.containsKey(location.type)) {
        final typePreferenceTotal = typePreferences.values.fold(0, (sum, count) => sum + count);
        if (typePreferenceTotal > 0) {
          score += (typePreferences[location.type]! / typePreferenceTotal) * typeWeight;
        } else {
          score += 0.5 * typeWeight; // Varsayılan değer
        }
      } else {
        score += 0.3 * typeWeight; // Tip yoksa veya eşleşme yoksa daha düşük bir skor
      }
      totalWeight += typeWeight;

      // 2. Konum skorları (70%)
      final locationScores = location.scores;

      // Güvenlik skoru (20%)
      final securityWeight = 0.2;
      if (locationScores.containsKey('security') && locationScores['security'] != null) {
        score += (locationScores['security']! / 5.0) * securityWeight;
      } else {
        score += 0.6 * securityWeight; // Varsayılan değer
      }
      totalWeight += securityWeight;

      // Ulaşım skoru (15%)
      final transportWeight = 0.15;
      if (locationScores.containsKey('transport') && locationScores['transport'] != null) {
        score += (locationScores['transport']! / 5.0) * transportWeight;
      } else {
        score += 0.6 * transportWeight; // Varsayılan değer
      }
      totalWeight += transportWeight;

      // Eğitim skoru (15%)
      final educationWeight = 0.15;
      if (locationScores.containsKey('education') && locationScores['education'] != null) {
        score += (locationScores['education']! / 5.0) * educationWeight;
      } else {
        score += 0.6 * educationWeight; // Varsayılan değer
      }
      totalWeight += educationWeight;

      // Sağlık skoru (10%)
      final healthWeight = 0.1;
      if (locationScores.containsKey('health') && locationScores['health'] != null) {
        score += (locationScores['health']! / 5.0) * healthWeight;
      } else {
        score += 0.6 * healthWeight; // Varsayılan değer
      }
      totalWeight += healthWeight;

      // Sosyal skor (10%)
      final socialWeight = 0.1;
      if (locationScores.containsKey('social') && locationScores['social'] != null) {
        score += (locationScores['social']! / 5.0) * socialWeight;
      } else {
        score += 0.6 * socialWeight; // Varsayılan değer
      }
      totalWeight += socialWeight;

      // Toplam ağırlık 0'dan büyükse skoru normalize et
      return totalWeight > 0 ? score / totalWeight : 0.5;
    } catch (e) {
      print('Eşleşme skoru hesaplanırken hata: $e');
      return 0.5; // Hata durumunda orta bir değer döndür
    }
  }

  Future<void> clearRecentlyViewed() async {
    await _recentlyViewedBox.clear();
  }

  Future<List<RecentlyViewedLocationModel>> getRecentlyViewedLocations() async {
    return _recentlyViewedBox.values.toList()
      ..sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
  }

  Future<List<SavedLocationModel>> getSavedLocations() async {
    return _savedLocationsBox.values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  Future<List<SavedLocationModel>> getPersonalizedRecommendations() async {
    if (!_isInitialized) {
      try {
        await init();
      } catch (e) {
        print('Servis başlatılamadı: $e');
        return _getDefaultRecommendationsAsModels();
      }
    }
    
    try {
      final recentlyViewed = await getRecentlyViewedLocations();
      final savedLocations = await getSavedLocations();

      print('Son görüntülenen konum sayısı: ${recentlyViewed.length}');
      print('Kaydedilen konum sayısı: ${savedLocations.length}');

      // Eğer hiç kayıtlı veya son görüntülenen konum yoksa varsayılan önerileri döndür
      if (recentlyViewed.isEmpty && savedLocations.isEmpty) {
        print('Kayıtlı veya son görüntülenen konum yok, varsayılan öneriler döndürülüyor');
        return _getDefaultRecommendationsAsModels();
      }

      // Tüm lokasyonları birleştir
      final List<SavedLocationModel> allLocations = [];
      
      // Son görüntülenen konumları ekle
      for (final location in recentlyViewed) {
        try {
          allLocations.add(SavedLocationModel(
            id: const Uuid().v4(),
            name: location.name,
            description: location.description,
            imageUrl: location.imageUrl,
            latitude: location.latitude,
            longitude: location.longitude,
            type: location.type,
            securityScore: location.scores['security'] ?? 0.0,
            transportScore: location.scores['transport'] ?? 0.0,
            savedAt: DateTime.now(),
            additionalScores: {
              'education': location.scores['education'] ?? 0.0,
              'health': location.scores['health'] ?? 0.0,
              'social': location.scores['social'] ?? 0.0,
            },
          ));
        } catch (e) {
          print('Son görüntülenen konum dönüştürülürken hata: $e');
          // Hatalı konumu atla
          continue;
        }
      }
      
      // Kaydedilen konumları ekle
      allLocations.addAll(savedLocations);

      // İşlenmiş lokasyonları takip et
      final Set<String> processedLocations = {};
      final List<SavedLocationModel> recommendations = [];

      // Tür tercihlerini hesapla
      final Map<String, int> typePreferences = _analyzeTypePreferences(recentlyViewed, savedLocations);
      print('Hesaplanan tür tercihleri: $typePreferences');

      // Her lokasyon için eşleşme skorunu hesapla
      for (final location in allLocations) {
        try {
          final locationKey = '${location.latitude},${location.longitude}';
          
          // Eğer bu lokasyon zaten işlendiyse atla
          if (processedLocations.contains(locationKey)) {
            continue;
          }
          processedLocations.add(locationKey);

          final matchScore = _calculateMatchScore(location, typePreferences);
          
          // Sadece 0.5'ten yüksek skorlu lokasyonları ekle
          if (matchScore > 0.5) {
            recommendations.add(location);
          }
        } catch (e) {
          print('Konum işlenirken hata: $e');
          // Hatalı konumu atla
          continue;
        }
      }

      // Yeterli öneri yoksa varsayılan önerileri ekle
      if (recommendations.isEmpty) {
        print('Yeterli öneri bulunamadı, varsayılan öneriler ekleniyor');
        return _getDefaultRecommendationsAsModels();
      }

      // Eşleşme skoruna göre sırala ve en iyi 10 öneriyi döndür
      recommendations.sort((a, b) {
        final scoreA = _calculateMatchScore(a, typePreferences);
        final scoreB = _calculateMatchScore(b, typePreferences);
        return scoreB.compareTo(scoreA);
      });
      
      final result = recommendations.take(10).toList();
      print('Döndürülen öneri sayısı: ${result.length}');
      return result;
    } catch (e, stackTrace) {
      print('Kişiselleştirilmiş öneriler alınırken hata: $e');
      print('Stack trace: $stackTrace');
      // Hata durumunda varsayılan önerileri döndür
      return _getDefaultRecommendationsAsModels();
    }
  }
  
  // Varsayılan önerileri model olarak döndüren yardımcı metod
  List<SavedLocationModel> _getDefaultRecommendationsAsModels() {
    final defaultRecommendations = _getDefaultRecommendations();
    return defaultRecommendations.map((rec) => SavedLocationModel(
      id: rec['id'] as String,
      name: rec['name'] as String,
      description: rec['description'] as String,
      imageUrl: rec['imageUrl'] as String,
      latitude: rec['location']['latitude'] as double,
      longitude: rec['location']['longitude'] as double,
      type: rec['type'] as String,
      securityScore: rec['scores']['security'] as double,
      transportScore: rec['scores']['transport'] as double,
      savedAt: DateTime.now(),
      additionalScores: {
        'education': rec['scores']['education'] as double,
        'health': rec['scores']['health'] as double,
        'social': rec['scores']['social'] as double,
      },
    )).toList();
  }

  Future<List<Map<String, dynamic>>> getRecommendedLocations() async {
    if (!_isInitialized) {
      try {
        await init();
      } catch (e) {
        print('Servis başlatılamadı: $e');
        return _getDefaultRecommendations();
      }
    }
    
    try {
      print('getRecommendedLocations başlatıldı');
      
      // Önbellekten kontrol et
      final cacheKey = _generateCacheKey();
      final cachedData = _cacheBox.get(cacheKey);
      
      if (cachedData != null && cachedData is Map) {
        try {
          final timestamp = DateTime.parse(cachedData['timestamp'] as String);
          if (DateTime.now().difference(timestamp) <= _cacheDuration) {
            print('Öneriler önbellekten alındı');
            return List<Map<String, dynamic>>.from(cachedData['recommendations'] as List);
          } else {
            print('Önbellek süresi dolmuş, yeni öneriler hesaplanıyor');
            await _cacheBox.delete(cacheKey);
          }
        } catch (e) {
          print('Önbellek verisi işlenirken hata: $e');
          await _cacheBox.delete(cacheKey);
        }
      }

      // Yeni öneriler oluştur
      final recommendations = <Map<String, dynamic>>[];
      
      // Box'ların boş olup olmadığını kontrol et
      if (_recentlyViewedBox.isEmpty && _savedLocationsBox.isEmpty) {
        print('Box\'lar boş, varsayılan öneriler döndürülüyor');
        final defaultRecommendations = _getDefaultRecommendations();
        await _saveToCache(cacheKey, defaultRecommendations);
        return defaultRecommendations;
      }

      print('Son görüntülenen konumlar: ${_recentlyViewedBox.values.length}');
      print('Kaydedilen konumlar: ${_savedLocationsBox.values.length}');

      final recentlyViewed = _recentlyViewedBox.values.toList();
      final savedLocations = _savedLocationsBox.values.toList();

      // Kullanıcının ilgilendiği bölge tiplerini analiz et
      final typePreferences = _analyzeTypePreferences(recentlyViewed, savedLocations);
      print('Tip tercihleri: $typePreferences');

      // Tüm konumları birleştir ve işle
      final processedLocations = <String>{};
      
      // Önce kaydedilen konumları işle (daha yüksek öncelik)
      for (final location in savedLocations) {
        final locationKey = '${location.latitude.toStringAsFixed(4)},${location.longitude.toStringAsFixed(4)}';
        
        if (processedLocations.contains(locationKey)) {
          continue;
        }
        processedLocations.add(locationKey);
        
        try {
          final matchScore = _calculateMatchScore(location, typePreferences);
          
          if (matchScore > 0.5) {
            recommendations.add({
              'id': location.id,
              'name': location.name,
              'description': location.description,
              'imageUrl': location.imageUrl,
              'location': {
                'latitude': location.latitude,
                'longitude': location.longitude,
              },
              'type': location.type,
              'matchScore': matchScore,
              'scores': location.scores,
            });
          }
        } catch (e) {
          print('Kaydedilen konum işlenirken hata: $e');
          continue;
        }
      }
      
      // Sonra son görüntülenen konumları işle
      for (final location in recentlyViewed) {
        final locationKey = '${location.latitude.toStringAsFixed(4)},${location.longitude.toStringAsFixed(4)}';
        
        if (processedLocations.contains(locationKey)) {
          continue;
        }
        processedLocations.add(locationKey);
        
        try {
          // RecentlyViewedLocationModel'i SavedLocationModel'e dönüştür
          final savedLocation = SavedLocationModel(
            id: const Uuid().v4(),
            name: location.name,
            description: location.description,
            imageUrl: location.imageUrl,
            latitude: location.latitude,
            longitude: location.longitude,
            type: location.type,
            securityScore: location.scores['security'] ?? 0.0,
            transportScore: location.scores['transport'] ?? 0.0,
            savedAt: DateTime.now(),
            additionalScores: {
              'education': location.scores['education'] ?? 0.0,
              'health': location.scores['health'] ?? 0.0,
              'social': location.scores['social'] ?? 0.0,
            },
          );
          
          final matchScore = _calculateMatchScore(savedLocation, typePreferences);
          
          if (matchScore > 0.5) {
            recommendations.add({
              'id': savedLocation.id,
              'name': savedLocation.name,
              'description': savedLocation.description,
              'imageUrl': savedLocation.imageUrl,
              'location': {
                'latitude': savedLocation.latitude,
                'longitude': savedLocation.longitude,
              },
              'type': savedLocation.type,
              'matchScore': matchScore,
              'scores': savedLocation.scores,
            });
          }
        } catch (e) {
          print('Son görüntülenen konum işlenirken hata: $e');
          continue;
        }
      }
      
      // Yeterli öneri yoksa varsayılan önerileri ekle
      if (recommendations.isEmpty) {
        print('Öneri bulunamadı, varsayılan öneriler döndürülüyor');
        final defaultRecommendations = _getDefaultRecommendations();
        await _saveToCache(cacheKey, defaultRecommendations);
        return defaultRecommendations;
      }

      // Eşleşme skoruna göre sırala
      recommendations.sort((a, b) => (b['matchScore'] as double).compareTo(a['matchScore'] as double));
      
      // En iyi 10 öneriyi al
      final result = recommendations.take(10).toList();
      
      // Önbelleğe kaydet
      await _saveToCache(cacheKey, result);
      
      print('Döndürülen öneri sayısı: ${result.length}');
      return result;
    } catch (e, stackTrace) {
      print('getRecommendedLocations hatası: $e');
      print('Stack trace: $stackTrace');
      return _getDefaultRecommendations();
    }
  }
} 