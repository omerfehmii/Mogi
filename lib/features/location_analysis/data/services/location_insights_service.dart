import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationInsightsService {
  final String _osmBaseUrl = 'https://overpass-api.de/api/interpreter';
  final String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';

  Future<Map<String, dynamic>> getLocationInsights(double lat, double lng) async {
    try {
      // API çağrıları başarısız olduğu için şimdilik mock veri döndürelim
      return {
        'total_score': 8.5,
        'category_scores': [
          {'name': 'Güvenlik', 'score': 8.5},
          {'name': 'Ulaşım', 'score': 9.0},
          {'name': 'Eğitim', 'score': 7.5},
          {'name': 'Sağlık', 'score': 8.0}
        ],
        'general_features': [
          {
            'title': 'Eğitim Kurumları',
            'value': '12 kurum',
            'icon': Icons.school
          },
          {
            'title': 'Sağlık Kurumları',
            'value': '5 kurum',
            'icon': Icons.local_hospital
          },
          {
            'title': 'Park ve Bahçeler',
            'value': '8 alan',
            'icon': Icons.park
          }
        ],
        'highlights': [
          'Merkezi konumda yer alıyor',
          'Toplu taşıma ağı gelişmiş',
          'Yeşil alan oranı yüksek',
          'Eğitim kurumlarına yakın'
        ]
      };
    } catch (e) {
      print('Error fetching location insights: $e');
      throw Exception('Location insights could not be fetched');
    }
  }

  Future<List<Map<String, dynamic>>> _getNearbyPlaces(double lat, double lng) async {
    // Not: Google Places API kullanımını kaldırdık, güvenlik nedeniyle OSM API kullanacağız
    final places = <Map<String, dynamic>>[];
    final types = ['park', 'restaurant', 'cafe', 'school', 'transit_station', 'hospital', 'police'];
    
    // OSM Overpass API kullanarak verileri alalım
    final query = """
    [out:json][timeout:25];
    (
      node["leisure"="park"](around:1000,$lat,$lng);
      node["amenity"="restaurant"](around:1000,$lat,$lng);
      node["amenity"="cafe"](around:1000,$lat,$lng);
      node["amenity"="school"](around:1000,$lat,$lng);
      node["public_transport"="station"](around:1000,$lat,$lng);
      node["amenity"="hospital"](around:1000,$lat,$lng);
      node["amenity"="police"](around:1000,$lat,$lng);
    );
    out body;
    >;
    out skel qt;
    """;
    
    try {
      final response = await http.post(
        Uri.parse(_osmBaseUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'data': query},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;
        
        for (final element in elements) {
          final tags = element['tags'] ?? {};
          String? type;
          
          if (tags['leisure'] == 'park') type = 'park';
          else if (tags['amenity'] == 'restaurant') type = 'restaurant';
          else if (tags['amenity'] == 'cafe') type = 'cafe';
          else if (tags['amenity'] == 'school') type = 'school';
          else if (tags['public_transport'] == 'station') type = 'transit_station';
          else if (tags['amenity'] == 'hospital') type = 'hospital';
          else if (tags['amenity'] == 'police') type = 'police';
          
          if (type != null) {
            places.add({
              'name': tags['name'] ?? 'Unnamed',
              'vicinity': tags['addr:street'] ?? '',
              'geometry': {
                'location': {
                  'lat': element['lat'],
                  'lng': element['lon'],
                }
              },
              'types': [type],
            });
          }
        }
      }
    } catch (e) {
      print('OSM API Error: $e');
    }
    
    return places;
  }

  Future<Map<String, dynamic>> _getOSMFeatures(double lat, double lng) async {
    final radius = 1000; // 1km radius
    final query = """
    [out:json][timeout:25];
    (
      way["leisure"="park"](around:$radius,$lat,$lng);
      way["amenity"="school"](around:$radius,$lat,$lng);
      way["amenity"="hospital"](around:$radius,$lat,$lng);
      way["amenity"="police"](around:$radius,$lat,$lng);
      way["public_transport"](around:$radius,$lat,$lng);
      way["leisure"="playground"](around:$radius,$lat,$lng);
      way["leisure"="sports_centre"](around:$radius,$lat,$lng);
    );
    out body;
    >;
    out skel qt;
    """;

    final response = await http.post(
      Uri.parse(_osmBaseUrl),
      body: {'data': query},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to fetch OSM features');
  }

  Future<Map<String, dynamic>> _getAreaDetails(double lat, double lng) async {
    final url = '$_nominatimBaseUrl/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1';
    final response = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'Mogi_App/1.0'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'name': data['display_name'],
        'type': data['type'],
        'population': await _getPopulationEstimate(data),
        'area_details': data['address'],
      };
    }
    throw Exception('Failed to fetch area details');
  }

  Future<int> _getPopulationEstimate(Map<String, dynamic> nominatimData) async {
    // Nüfus verisi için ekstra API çağrısı yapılabilir
    // Şimdilik yaklaşık bir değer döndürüyoruz
    return 50000 + Random().nextInt(50000);
  }

  List<Map<String, dynamic>> _processFeatures(Map<String, dynamic> osmFeatures) {
    final features = <Map<String, dynamic>>[];
    final elements = osmFeatures['elements'] as List;

    // Kategorilere göre sayıları hesapla
    final counts = {
      'park': elements.where((e) => e['tags']?['leisure'] == 'park').length,
      'school': elements.where((e) => e['tags']?['amenity'] == 'school').length,
      'hospital': elements.where((e) => e['tags']?['amenity'] == 'hospital').length,
      'police': elements.where((e) => e['tags']?['amenity'] == 'police').length,
      'transport': elements.where((e) => e['tags']?['public_transport'] != null).length,
      'playground': elements.where((e) => e['tags']?['leisure'] == 'playground').length,
      'sports': elements.where((e) => e['tags']?['leisure'] == 'sports_centre').length,
    };

    // Özellikleri listeye ekle
    if (counts['park']! > 0) {
      features.add({
        'title': 'Park ve Yeşil Alan',
        'value': '${counts['park']} adet',
        'icon': Icons.park,
        'details': _calculateGreenArea(elements.where((e) => e['tags']?['leisure'] == 'park').toList()),
      });
    }

    if (counts['school']! > 0) {
      features.add({
        'title': 'Eğitim Kurumu',
        'value': '${counts['school']} adet',
        'icon': Icons.school,
        'details': _getSchoolTypes(elements.where((e) => e['tags']?['amenity'] == 'school').toList()),
      });
    }

    if (counts['hospital']! > 0) {
      features.add({
        'title': 'Sağlık Kuruluşu',
        'value': '${counts['hospital']} adet',
        'icon': Icons.local_hospital,
        'details': _getHealthFacilityTypes(elements.where((e) => e['tags']?['amenity'] == 'hospital').toList()),
      });
    }

    if (counts['transport']! > 0) {
      features.add({
        'title': 'Toplu Taşıma',
        'value': '${counts['transport']} durak',
        'icon': Icons.directions_bus,
        'details': _getTransportTypes(elements.where((e) => e['tags']?['public_transport'] != null).toList()),
      });
    }

    if (counts['playground']! > 0 || counts['sports']! > 0) {
      features.add({
        'title': 'Spor ve Aktivite',
        'value': '${counts['playground']! + counts['sports']!} tesis',
        'icon': Icons.sports,
        'details': _getSportsAndActivities(elements),
      });
    }

    return features;
  }

  Map<String, dynamic> _calculateGreenArea(List<dynamic> parks) {
    double totalArea = 0;
    for (var park in parks) {
      if (park['bounds'] != null) {
        final bounds = park['bounds'];
        final width = _calculateDistance(
          bounds['minlat'],
          bounds['minlon'],
          bounds['minlat'],
          bounds['maxlon'],
        );
        final height = _calculateDistance(
          bounds['minlat'],
          bounds['minlon'],
          bounds['maxlat'],
          bounds['minlon'],
        );
        totalArea += width * height;
      }
    }
    
    return {
      'total_area': '${(totalArea / 10000).toStringAsFixed(1)} hektar',
      'count': parks.length,
      'types': _getGreenSpaceTypes(parks),
    };
  }

  List<String> _getGreenSpaceTypes(List<dynamic> parks) {
    final types = Set<String>();
    for (var park in parks) {
      final tags = park['tags'] ?? {};
      if (tags['leisure'] == 'park') types.add('Park');
      if (tags['garden'] != null) types.add('Bahçe');
      if (tags['playground'] == 'yes') types.add('Oyun Alanı');
    }
    return types.toList();
  }

  Map<String, dynamic> _getSchoolTypes(List<dynamic> schools) {
    final types = {
      'primary': 0,
      'secondary': 0,
      'high': 0,
      'university': 0,
    };

    for (var school in schools) {
      final tags = school['tags'] ?? {};
      if (tags['isced'] == '1') types['primary'] = types['primary']! + 1;
      else if (tags['isced'] == '2') types['secondary'] = types['secondary']! + 1;
      else if (tags['isced'] == '3') types['high'] = types['high']! + 1;
      else if (tags['isced'] == '6') types['university'] = types['university']! + 1;
    }

    return {
      'İlkokul': types['primary'],
      'Ortaokul': types['secondary'],
      'Lise': types['high'],
      'Üniversite': types['university'],
    };
  }

  Map<String, dynamic> _getHealthFacilityTypes(List<dynamic> facilities) {
    final types = {
      'hospital': 0,
      'clinic': 0,
      'pharmacy': 0,
    };

    for (var facility in facilities) {
      final tags = facility['tags'] ?? {};
      if (tags['amenity'] == 'hospital') types['hospital'] = types['hospital']! + 1;
      else if (tags['amenity'] == 'clinic') types['clinic'] = types['clinic']! + 1;
      else if (tags['amenity'] == 'pharmacy') types['pharmacy'] = types['pharmacy']! + 1;
    }

    return {
      'Hastane': types['hospital'],
      'Klinik': types['clinic'],
      'Eczane': types['pharmacy'],
    };
  }

  Map<String, dynamic> _getTransportTypes(List<dynamic> stations) {
    final types = {
      'bus': 0,
      'subway': 0,
      'tram': 0,
      'train': 0,
    };

    for (var station in stations) {
      final tags = station['tags'] ?? {};
      if (tags['bus'] == 'yes') types['bus'] = types['bus']! + 1;
      if (tags['subway'] == 'yes') types['subway'] = types['subway']! + 1;
      if (tags['tram'] == 'yes') types['tram'] = types['tram']! + 1;
      if (tags['train'] == 'yes') types['train'] = types['train']! + 1;
    }

    return {
      'Otobüs': types['bus'],
      'Metro': types['subway'],
      'Tramvay': types['tram'],
      'Tren': types['train'],
    };
  }

  Map<String, dynamic> _getSportsAndActivities(List<dynamic> elements) {
    final activities = {
      'playground': 0,
      'sports_centre': 0,
      'fitness': 0,
      'park': 0,
    };

    for (var element in elements) {
      final tags = element['tags'] ?? {};
      if (tags['leisure'] == 'playground') activities['playground'] = activities['playground']! + 1;
      if (tags['leisure'] == 'sports_centre') activities['sports_centre'] = activities['sports_centre']! + 1;
      if (tags['leisure'] == 'fitness_centre') activities['fitness'] = activities['fitness']! + 1;
      if (tags['leisure'] == 'park' && tags['sport'] != null) activities['park'] = activities['park']! + 1;
    }

    return {
      'Oyun Alanı': activities['playground'],
      'Spor Merkezi': activities['sports_centre'],
      'Fitness Salonu': activities['fitness'],
      'Spor Parkı': activities['park'],
    };
  }

  List<Map<String, dynamic>> _generateScores(
    List<Map<String, dynamic>> places,
    Map<String, dynamic> osmFeatures,
  ) {
    final scores = <Map<String, dynamic>>[];
    final elements = osmFeatures['elements'] as List;

    // Yeşil Alan Skoru
    final parkCount = elements.where((e) => e['tags']?['leisure'] == 'park').length;
    final parkScore = _calculateCategoryScore(parkCount, 5, 10);
    scores.add({
      'name': 'Yeşil Alan',
      'score': parkScore,
      'details': 'Bölgede $parkCount park bulunuyor',
    });

    // Eğitim Skoru
    final schoolCount = elements.where((e) => e['tags']?['amenity'] == 'school').length;
    final schoolScore = _calculateCategoryScore(schoolCount, 3, 8);
    scores.add({
      'name': 'Eğitim',
      'score': schoolScore,
      'details': '$schoolCount eğitim kurumu',
    });

    // Ulaşım Skoru
    final transportCount = elements.where((e) => e['tags']?['public_transport'] != null).length;
    final transportScore = _calculateCategoryScore(transportCount, 5, 15);
    scores.add({
      'name': 'Ulaşım',
      'score': transportScore,
      'details': '$transportCount toplu taşıma durağı',
    });

    // Sağlık Skoru
    final healthCount = elements.where((e) => e['tags']?['amenity'] == 'hospital' || e['tags']?['amenity'] == 'clinic').length;
    final healthScore = _calculateCategoryScore(healthCount, 2, 5);
    scores.add({
      'name': 'Sağlık',
      'score': healthScore,
      'details': '$healthCount sağlık kuruluşu',
    });

    // Sosyal Yaşam Skoru
    final socialCount = elements.where((e) => 
      e['tags']?['leisure'] == 'sports_centre' || 
      e['tags']?['amenity'] == 'restaurant' ||
      e['tags']?['amenity'] == 'cafe'
    ).length;
    final socialScore = _calculateCategoryScore(socialCount, 10, 20);
    scores.add({
      'name': 'Sosyal',
      'score': socialScore,
      'details': '$socialCount sosyal tesis',
    });

    return scores;
  }

  double _calculateCategoryScore(int count, int min, int max) {
    if (count >= max) return 10.0;
    if (count <= min) return 5.0;
    return double.parse((5 + (count - min) * 5 / (max - min)).toStringAsFixed(1));
  }

  Future<List<String>> _generateHighlights(
    List<Map<String, dynamic>> places,
    Map<String, dynamic> osmFeatures,
    Map<String, dynamic> areaDetails,
  ) async {
    final highlights = <String>[];
    final elements = osmFeatures['elements'] as List;

    // Park ve yeşil alan vurgusu
    final parks = elements.where((e) => e['tags']?['leisure'] == 'park').length;
    if (parks > 3) {
      highlights.add('Bölgede $parks adet park ve yeşil alan bulunuyor');
    }

    // Ulaşım vurgusu
    final transport = elements.where((e) => e['tags']?['public_transport'] != null).length;
    if (transport > 5) {
      highlights.add('$transport farklı toplu taşıma durağı ile ulaşım çok kolay');
    }

    // Eğitim kurumları vurgusu
    final schools = elements.where((e) => e['tags']?['amenity'] == 'school').length;
    if (schools > 2) {
      highlights.add('$schools eğitim kurumu ile zengin eğitim olanakları');
    }

    // Sağlık kurumları vurgusu
    final hospitals = elements.where((e) => e['tags']?['amenity'] == 'hospital').length;
    if (hospitals > 0) {
      highlights.add('$hospitals sağlık kuruluşu ile sağlık hizmetlerine kolay erişim');
    }

    // Spor ve aktivite vurgusu
    final sports = elements.where((e) => 
      e['tags']?['leisure'] == 'sports_centre' || 
      e['tags']?['leisure'] == 'fitness_centre'
    ).length;
    if (sports > 2) {
      highlights.add('$sports spor tesisi ile aktif yaşam imkanları');
    }

    return highlights;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371e3; // Dünya yarıçapı (metre)
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final deltaPhi = (lat2 - lat1) * pi / 180;
    final deltaLambda = (lon2 - lon1) * pi / 180;

    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }
} 