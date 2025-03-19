import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:latlong2/latlong.dart';

class PlacesService {
  final String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  final String _overpassBaseUrl = 'https://overpass-api.de/api/interpreter';
  late Box _cacheBox;
  static const String _cacheBoxName = 'places_cache';

  Future<void> init() async {
    try {
      if (!Hive.isBoxOpen(_cacheBoxName)) {
        _cacheBox = await Hive.openBox(_cacheBoxName);
      } else {
        _cacheBox = Hive.box(_cacheBoxName);
      }
      print('Places cache başarıyla başlatıldı');
    } catch (e) {
      print('Places cache başlatılamadı: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getLocalities(double lat, double lng, {int radius = 50000, int page = 0}) async {
    try {
      final cacheKey = 'localities_${lat}_${lng}_${radius}_$page';
      final cachedData = _cacheBox.get(cacheKey);
      if (cachedData != null) {
        print('Önbellekten bölgeler alınıyor');
        return List<Map<String, dynamic>>.from(json.decode(cachedData));
      }

      print('Bölgeler API\'den alınıyor');

      // Overpass API sorgusu - Tüm gerekli bilgileri tek sorguda al
      final query = """
      [out:json][timeout:25];
      (
        // Parklar ve yeşil alanlar
        nwr(around:15000,${lat},${lng})[leisure=park];
        
        // Okullar
        nwr(around:15000,${lat},${lng})[amenity=school];
        
        // Hastaneler
        nwr(around:15000,${lat},${lng})[amenity=hospital];
        
        // Bankalar
        nwr(around:15000,${lat},${lng})[amenity=bank];
        
        // Eczaneler
        nwr(around:15000,${lat},${lng})[amenity=pharmacy];
        
        // Marketler
        nwr(around:15000,${lat},${lng})[shop=supermarket];
      );
      out body;
      >;
      out skel qt;
      """;

      final response = await http.post(
        Uri.parse(_overpassBaseUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'MOGI_App/1.0',
          'Accept-Language': 'tr'
        },
        body: {'data': query},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Map<String, dynamic>> localities = [];
        final elements = data['elements'] as List;

        // Tüm elementleri grupla
        final Map<String, Map<String, dynamic>> elementMap = {};
        for (var element in elements) {
          if (element['tags'] != null) {
            elementMap[element['id'].toString()] = element;
          }
        }

        // Toplu olarak yer detaylarını al
        final List<String> placeIds = elementMap.keys.toList();
        final placeDetails = await _getBulkPlaceDetails(placeIds);

        // Verileri birleştir
        for (var id in placeIds) {
          final element = elementMap[id];
          final details = placeDetails[id];
          
          if (element != null && element['tags'] != null) {
            final locality = {
              'name': element['tags']['name:tr'] ?? 
                     element['tags']['name'] ?? 
                     element['tags']['addr:suburb'] ?? 
                     element['tags']['addr:district'] ?? 
                     element['tags']['addr:neighbourhood'] ?? 
                     details?['address']?['suburb'] ?? 
                     details?['address']?['neighbourhood'] ?? 
                     details?['name'] ?? 
                     'Seçilen Konum',
              'placeId': id,
              'location': {
                'lat': element['lat'] ?? lat,
                'lng': element['lon'] ?? lng,
              },
              'type': _getLocalityType(element['tags']),
              'formattedAddress': details?['display_name'] ?? element['tags']['addr:full'] ?? '',
              'rating': 4.0,
              'vicinity': element['tags']['addr:suburb'] ?? element['tags']['addr:city'] ?? '',
              'details': details ?? _createDefaultResponse(id),
            };

            localities.add(locality);
          }
        }

        // Özellikleri say
        final features = <String, int>{};
        for (var element in elements) {
          final tags = element['tags'] ?? {};
          
          if (tags['leisure'] == 'park') {
            features['park'] = (features['park'] ?? 0) + 1;
          }
          if (tags['amenity'] == 'school') {
            features['school'] = (features['school'] ?? 0) + 1;
          }
          if (tags['amenity'] == 'hospital') {
            features['hospital'] = (features['hospital'] ?? 0) + 1;
          }
          if (tags['amenity'] == 'bank') {
            features['bank'] = (features['bank'] ?? 0) + 1;
          }
          if (tags['amenity'] == 'pharmacy') {
            features['pharmacy'] = (features['pharmacy'] ?? 0) + 1;
          }
          if (tags['shop'] == 'supermarket') {
            features['supermarket'] = (features['supermarket'] ?? 0) + 1;
          }
        }

        print('Bulunan özellikler:');
        print('Parklar: ${features['park'] ?? 0}');
        print('Okullar: ${features['school'] ?? 0}');
        print('Hastaneler: ${features['hospital'] ?? 0}');
        print('Bankalar: ${features['bank'] ?? 0}');
        print('Eczaneler: ${features['pharmacy'] ?? 0}');
        print('Marketler: ${features['supermarket'] ?? 0}');

        // Önbelleğe kaydet
        await _cacheBox.put(cacheKey, json.encode(localities));
        print('${localities.length} bölge bulundu ve önbelleğe kaydedildi');
        return localities;
      }
      
      print('API yanıt vermedi, varsayılan bölgeler döndürülüyor');
      return _getDefaultLocalities(lat, lng);
    } catch (e) {
      print('Bölgeler alınırken hata: $e');
      return _getDefaultLocalities(lat, lng);
    }
  }

  Future<Map<String, Map<String, dynamic>>> _getBulkPlaceDetails(List<String> placeIds) async {
    final results = <String, Map<String, dynamic>>{};
    final uncachedIds = <String>[];

    // Önce önbellekten kontrol et
    for (final id in placeIds) {
      final cacheKey = 'place_details_$id';
      final cachedData = _cacheBox.get(cacheKey);
      if (cachedData != null) {
        results[id] = json.decode(cachedData);
      } else {
        uncachedIds.add(id);
      }
    }

    if (uncachedIds.isEmpty) {
      return results;
    }

    // Toplu sorgu için idleri grupla (her grupta max 50 id)
    final idGroups = <List<String>>[];
    for (var i = 0; i < uncachedIds.length; i += 50) {
      idGroups.add(
        uncachedIds.sublist(i, i + 50 > uncachedIds.length ? uncachedIds.length : i + 50)
      );
    }

    // Her grup için tek bir istek yap
    for (final group in idGroups) {
      try {
        final wayIds = group.map((id) => 'W$id').join(',');
        final relationIds = group.map((id) => 'R$id').join(',');
        
        final url = '$_nominatimBaseUrl/lookup?osm_ids=$wayIds,$relationIds&format=json&addressdetails=1';
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent': 'MOGI_App/1.0',
            'Accept-Language': 'tr',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          
          for (final place in data) {
            final id = place['osm_id'].toString().replaceAll(RegExp(r'[WR]'), '');
            results[id] = place;
            
            // Önbelleğe kaydet
            final cacheKey = 'place_details_$id';
            await _cacheBox.put(cacheKey, json.encode(place));
          }
        }
      } catch (e) {
        print('Toplu yer detayları alınırken hata: $e');
      }
    }

    // Eksik kalan idler için varsayılan yanıt
    for (final id in uncachedIds) {
      if (!results.containsKey(id)) {
        results[id] = _createDefaultResponse(id);
      }
    }

    return results;
  }

  List<Map<String, dynamic>> _getDefaultLocalities(double lat, double lng) {
    return [
      {
        'name': 'Kadıköy',
        'placeId': '1',
        'location': {'lat': 40.9906, 'lng': 29.0238},
        'type': 'district',
        'formattedAddress': 'Kadıköy, İstanbul, Türkiye',
        'rating': 4.5,
        'vicinity': 'Kadıköy',
      },
      {
        'name': 'Beşiktaş',
        'placeId': '2',
        'location': {'lat': 41.0430, 'lng': 29.0046},
        'type': 'district',
        'formattedAddress': 'Beşiktaş, İstanbul, Türkiye',
        'rating': 4.3,
        'vicinity': 'Beşiktaş',
      },
      {
        'name': 'Üsküdar',
        'placeId': '3',
        'location': {'lat': 41.0234, 'lng': 29.0152},
        'type': 'district',
        'formattedAddress': 'Üsküdar, İstanbul, Türkiye',
        'rating': 4.4,
        'vicinity': 'Üsküdar',
      },
    ];
  }

  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    try {
      final cacheKey = 'place_details_$placeId';
      final cachedData = _cacheBox.get(cacheKey);
      if (cachedData != null) {
        print('Önbellekten veri alınıyor: $placeId');
        return json.decode(cachedData);
      }

      print('Konum detayları alınıyor: $placeId');
      
      // İstek başarısız olursa tekrar deneme sayısı
      int retryCount = 3;
      Exception? lastError;

      while (retryCount > 0) {
        try {
          // Önce way (W) olarak dene
          var url = '$_nominatimBaseUrl/lookup?osm_ids=W$placeId&format=json&addressdetails=1';
          var response = await http.get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'MOGI_App/1.0',
              'Accept-Language': 'tr',
            },
          ).timeout(
            const Duration(seconds: 5),
          );

          List<dynamic> data = [];
          if (response.statusCode == 200) {
            data = json.decode(response.body);
          }

          // Eğer sonuç boşsa, relation (R) olarak dene
          if (data.isEmpty) {
            url = '$_nominatimBaseUrl/lookup?osm_ids=R$placeId&format=json&addressdetails=1';
            response = await http.get(
              Uri.parse(url),
              headers: {
                'User-Agent': 'MOGI_App/1.0',
                'Accept-Language': 'tr',
              },
            ).timeout(
              const Duration(seconds: 5),
            );

            if (response.statusCode == 200) {
              data = json.decode(response.body);
            }
          }

          // Eğer veri bulunduysa önbelleğe kaydet ve döndür
          if (data.isNotEmpty) {
            final result = data[0];
            await _cacheBox.put(cacheKey, json.encode(result));
            return result;
          }

          // Veri bulunamadıysa varsayılan yanıt
          break;
        } catch (e) {
          lastError = e as Exception;
          retryCount--;
          if (retryCount > 0) {
            // Her denemeden önce biraz bekle
            await Future.delayed(Duration(seconds: 2));
            continue;
          }
        }
      }

      // Tüm denemeler başarısız olduysa veya veri bulunamadıysa varsayılan yanıt
      final defaultResponse = _createDefaultResponse(placeId);
      await _cacheBox.put(cacheKey, json.encode(defaultResponse));
      
      if (lastError != null) {
        print('Konum detayları alınamadı: $lastError');
      }
      
      return defaultResponse;
    } catch (e) {
      print('Konum detayları hatası: $e');
      return _createDefaultResponse(placeId);
    }
  }

  Map<String, dynamic> _createDefaultResponse(String placeId) {
    return {
      'display_name': 'İstanbul',
      'address': {
        'city': 'İstanbul',
        'country': 'Türkiye',
      },
      'type': 'district',
      'lat': 41.0082,
      'lon': 28.9784,
      'name': 'İstanbul',
      'amenity': 'residential',
      'osm_id': placeId,
    };
  }

  String _getLocalityType(Map<String, dynamic> tags) {
    if (tags['admin_level'] == '8') return 'district';
    if (tags['admin_level'] == '9') return 'neighborhood';
    if (tags['admin_level'] == '10') return 'suburb';
    if (tags['place'] == 'city') return 'city';
    if (tags['place'] == 'town') return 'town';
    if (tags['place'] == 'village') return 'village';
    return 'unknown';
  }

  Future<List<Map<String, dynamic>>> searchPlaces(String input) async {
    if (input.isEmpty) return [];

    final url = '$_nominatimBaseUrl/search?q=${Uri.encodeComponent(input)}&format=json&addressdetails=1&limit=10';
    final response = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'MOGI_App/1.0'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((place) {
        return {
          'name': place['display_name'],
          'placeId': place['osm_id'].toString(),
          'location': {
            'lat': double.parse(place['lat']),
            'lng': double.parse(place['lon']),
          },
          'type': _getLocalityType(place['type'] ?? {}),
          'formattedAddress': place['display_name'],
          'rating': 4.0,
        };
      }).toList();
    }
    return [];
  }

  Future<String> getPlacePhoto(String osmId, {int maxWidth = 400}) async {
    // OpenStreetMap'in kendi fotoğraf servisi olmadığı için Wikimedia Commons'dan fotoğraf almaya çalışalım
    final url = 'https://commons.wikimedia.org/w/api.php?action=query&format=json&prop=images&titles=$osmId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Eğer fotoğraf bulunamazsa varsayılan bir fotoğraf URL'si döndür
      return 'assets/images/default_location.png';
    }
    return 'assets/images/default_location.png';
  }

  Future<void> clearCache() async {
    await _cacheBox.clear();
  }
} 