import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math';
import '../../../../core/network/network_connectivity_service.dart';

class AreaAnalysisService {
  final String _googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  final NetworkConnectivityService _connectivityService = NetworkConnectivityService();

  Future<Map<String, dynamic>> getAreaAnalysis(LatLng location) async {
    try {
      // Check internet connection
      if (!_connectivityService.isConnected.value) {
        throw Exception('No internet connection. Please check your connection and try again.');
      }
      
      print('Starting area analysis...');
      print('Location: ${location.latitude}, ${location.longitude}');
      
      // 1. Bölge detayları
      print('Getting area details...');
      final areaDetails = await _getAreaDetails(location);
      print('Area details received: $areaDetails');
      
      // 2. Konum özellikleri
      print('Getting location features...');
      final locationFeatures = await _getLocationFeatures(location);
      print('Location features received: $locationFeatures');
      
      // 3. Hava kalitesi
      print('Getting air quality data...');
      final airQuality = await _getAirQuality(location);
      print('Air quality data received: $airQuality');
      
      // 4. Genel puanlama
      print('Calculating overall score...');
      final scores = _calculateScores(locationFeatures, airQuality);
      print('Overall score calculated: $scores');

      return {
        'area_info': {
          'name': areaDetails['name'],
          'type': areaDetails['type'],
          'district': areaDetails['district'],
          'city': areaDetails['city'],
          'features': locationFeatures['features'],
          'descriptions': locationFeatures['descriptions'],
        },
        'air_quality': airQuality,
        'scores': scores,
      };
    } catch (e, stackTrace) {
      print('Area analysis error: $e');
      print('Error details: $stackTrace');
      
      // Check if it's a connectivity error
      if (!_connectivityService.isConnected.value) {
        throw Exception('No internet connection. Please check your connection and try again.');
      }
      
      throw Exception('Failed to analyze location: $e');
    }
  }

  Future<Map<String, dynamic>> _getAreaDetails(LatLng location) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?lat=${location.latitude}&lon=${location.longitude}&format=json&addressdetails=1';
      
      print('Making request for area details: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mogi_App/1.0',
          'Accept-Language': 'tr',
        },
      ).timeout(const Duration(seconds: 10));

      print('Area details response: ${response.statusCode}');
      print('Area details content: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>;
        
        return {
          'name': address['suburb'] ?? address['neighbourhood'] ?? address['quarter'] ?? 'Bilinmeyen Bölge',
          'type': data['type'] ?? 'unknown',
          'district': address['city_district'] ?? address['district'] ?? address['town'] ?? '',
          'city': address['city'] ?? address['state'] ?? 'İstanbul',
        };
      }
      
      print('Could not get area details: ${response.statusCode}');
      throw Exception('Could not get area details: ${response.statusCode}');
    } catch (e, stackTrace) {
      print('Area details error: $e');
      print('Error details: $stackTrace');
      
      return {
        'name': 'Bilinmeyen Bölge',
        'type': 'unknown',
        'district': '',
        'city': 'İstanbul',
      };
    }
  }

  Future<Map<String, dynamic>> _getLocationFeatures(LatLng location) async {
    try {
      final query = """
      [out:json][timeout:25];
      (
        way(around:1000,${location.latitude},${location.longitude})[leisure=park];
        way(around:1000,${location.latitude},${location.longitude})[amenity~"school|hospital|bank|pharmacy"];
        way(around:1000,${location.latitude},${location.longitude})[shop=supermarket];
      );
      out body;
      >;
      out skel qt;
      """;

      print('Making request for location features...');
      
      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'data': query},
      ).timeout(const Duration(seconds: 15));

      print('Location features response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;
        final features = <String, int>{};
        final descriptions = <String>[];

        print('Number of features found: ${elements.length}');

        // Özellikleri say
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

        print('Feature counts: $features');

        // Açıklamaları oluştur
        for (var entry in features.entries) {
          if (entry.value > 0) {
            descriptions.add(_getFeatureDescription(entry.key, entry.value));
          }
        }

        return {
          'features': features,
          'descriptions': descriptions,
        };
      }
      
      print('Could not get location features: ${response.statusCode}');
      throw Exception('Could not get location features: ${response.statusCode}');
    } catch (e, stackTrace) {
      print('Location features error: $e');
      print('Error details: $stackTrace');
      
      return {
        'features': {
          'park': 0,
          'school': 0,
          'hospital': 0,
          'bank': 0,
          'pharmacy': 0,
          'supermarket': 0,
        },
        'descriptions': [],
      };
    }
  }

  Future<Map<String, dynamic>> _getAirQuality(LatLng location) async {
    try {
      final url = 'https://api.openweathermap.org/data/2.5/air_pollution?lat=${location.latitude}&lon=${location.longitude}&appid=${dotenv.env['OPENWEATHER_API_KEY']}';
      
      final response = await http.get(Uri.parse(url));

      print('Air Quality API Response: ${response.statusCode}');
      print('Air Quality API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final components = data['list'][0]['components'];
        final aqi = data['list'][0]['main']['aqi'];

        // OpenWeather API'den gelen AQI değerini WHO standartlarına dönüştür
        final normalizedAqi = _normalizeOpenWeatherAqi(aqi);
        
        return {
          'aqi': normalizedAqi,
          'category': _getAqiCategory(normalizedAqi),
          'dominantPollutant': _getDominantPollutant(components),
          'components': components,
          'healthRecommendations': {
            'general': _getHealthRecommendation(normalizedAqi),
            'elderly': _getElderlyRecommendation(normalizedAqi),
            'children': _getChildrenRecommendation(normalizedAqi),
            'athletes': _getAthletesRecommendation(normalizedAqi),
          },
          'pollutants': [
            {
              'name': 'PM2.5',
              'value': components['pm2_5'],
              'unit': 'µg/m³',
              'description': _getPollutantDescription('pm2_5'),
            },
            {
              'name': 'PM10',
              'value': components['pm10'],
              'unit': 'µg/m³',
              'description': _getPollutantDescription('pm10'),
            },
            {
              'name': 'NO2',
              'value': components['no2'],
              'unit': 'µg/m³',
              'description': _getPollutantDescription('no2'),
            },
            {
              'name': 'O3',
              'value': components['o3'],
              'unit': 'µg/m³',
              'description': _getPollutantDescription('o3'),
            },
          ],
        };
      }
      
      print('Air Quality API failed with status: ${response.statusCode}');
      return _getDefaultAirQuality();
    } catch (e) {
      print('Error getting air quality data: $e');
      return _getDefaultAirQuality();
    }
  }

  // OpenWeather API'nin AQI değerini (1-5) WHO standartlarına (0-500) dönüştür
  double _normalizeOpenWeatherAqi(int openWeatherAqi) {
    switch (openWeatherAqi) {
      case 1: // İyi
        return 30.0;
      case 2: // Orta
        return 80.0;
      case 3: // Hassas gruplar için sağlıksız
        return 150.0;
      case 4: // Sağlıksız
        return 200.0;
      case 5: // Çok sağlıksız
        return 300.0;
      default:
        return 150.0; // Varsayılan değer
    }
  }

  String _getAqiCategory(double aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  String _getDominantPollutant(Map<String, dynamic> components) {
    final pollutants = {
      'PM2.5': _calculatePM25Score(components['pm2_5']),
      'PM10': _calculatePM10Score(components['pm10']),
      'NO2': _calculateNO2Score(components['no2']),
      'O3': _calculateO3Score(components['o3']),
    };

    var maxScore = 0.0;
    var dominantPollutant = 'PM2.5';

    pollutants.forEach((pollutant, score) {
      if (score > maxScore) {
        maxScore = score;
        dominantPollutant = pollutant;
      }
    });

    return dominantPollutant;
  }

  // WHO standartlarına göre PM2.5 skoru (24 saatlik ortalama)
  double _calculatePM25Score(double value) {
    if (value <= 15) return 20; // İyi
    if (value <= 30) return 40; // Orta
    if (value <= 55) return 60; // Hassas
    if (value <= 110) return 80; // Sağlıksız
    return 100; // Çok Sağlıksız
  }

  // WHO standartlarına göre PM10 skoru (24 saatlik ortalama)
  double _calculatePM10Score(double value) {
    if (value <= 45) return 20; // İyi
    if (value <= 90) return 40; // Orta
    if (value <= 180) return 60; // Hassas
    if (value <= 300) return 80; // Sağlıksız
    return 100; // Çok Sağlıksız
  }

  // WHO standartlarına göre NO2 skoru (1 saatlik ortalama)
  double _calculateNO2Score(double value) {
    if (value <= 40) return 20; // İyi
    if (value <= 80) return 40; // Orta
    if (value <= 180) return 60; // Hassas
    if (value <= 280) return 80; // Sağlıksız
    return 100; // Çok Sağlıksız
  }

  // WHO standartlarına göre O3 skoru (8 saatlik ortalama)
  double _calculateO3Score(double value) {
    if (value <= 60) return 20; // İyi
    if (value <= 120) return 40; // Orta
    if (value <= 180) return 60; // Hassas
    if (value <= 240) return 80; // Sağlıksız
    return 100; // Çok Sağlıksız
  }

  String _getHealthRecommendation(double aqi) {
    if (aqi <= 20) {
      return 'Air quality is excellent. Ideal for all outdoor activities.';
    } else if (aqi <= 40) {
      return 'Air quality is good. Suitable for outdoor activities.';
    } else if (aqi <= 60) {
      return 'Air quality is acceptable. Some precautions may be needed for sensitive groups.';
    } else if (aqi <= 80) {
      return 'Health effects may occur for sensitive groups. Avoid prolonged outdoor activities.';
    } else if (aqi <= 100) {
      return 'Everyone may experience health effects. Limit outdoor activities.';
    }
    return 'Emergency conditions. Avoid going outside.';
  }

  String _getElderlyRecommendation(double aqi) {
    if (aqi <= 20) {
      return 'Air quality is excellent. You can continue your normal activities.';
    } else if (aqi <= 40) {
      return 'You can continue your normal activities.';
    } else if (aqi <= 60) {
      return 'If you have sensitivities, limit outdoor activities.';
    } else if (aqi <= 80) {
      return 'Avoid prolonged outdoor activities.';
    }
    return 'Stay indoors if possible.';
  }

  String _getChildrenRecommendation(double aqi) {
    if (aqi <= 20) {
      return 'Air quality is excellent. Ideal for all outdoor activities.';
    } else if (aqi <= 40) {
      return 'Suitable conditions for outdoor games.';
    } else if (aqi <= 60) {
      return 'Limit long-duration intense activities.';
    } else if (aqi <= 80) {
      return 'Keep outdoor activities short.';
    }
    return 'Stay indoors.';
  }

  String _getAthletesRecommendation(double aqi) {
    if (aqi <= 20) {
      return 'Air quality is excellent. Ideal for all outdoor sports.';
    } else if (aqi <= 40) {
      return 'Suitable for all outdoor sports.';
    } else if (aqi <= 60) {
      return 'Limit intense training.';
    } else if (aqi <= 80) {
      return 'Prefer indoor training.';
    }
    return 'Do all training indoors.';
  }

  String _getPollutantDescription(String pollutant) {
    switch (pollutant) {
      case 'pm2_5':
        return 'Fine particulate matter can penetrate deep into the respiratory system.';
      case 'pm10':
        return 'Inhalable particulate matter can affect upper respiratory tract.';
      case 'no2':
        return 'Nitrogen dioxide can cause respiratory diseases.';
      case 'o3':
        return 'Ozone can lead to respiratory problems and lung diseases.';
      default:
        return 'Air pollutant.';
    }
  }

  Map<String, dynamic> _getDefaultAirQuality() {
    return {
      'aqi': 50.0,
      'category': 'Good',
      'dominantPollutant': 'PM2.5',
      'components': {
        'pm2_5': 10.0,
        'pm10': 20.0,
        'no2': 25.0,
        'o3': 30.0,
      },
      'healthRecommendations': {
        'general': 'Air quality is good. You can spend time outside.',
        'elderly': 'Air quality is suitable for elderly people.',
        'children': 'Air quality is safe for children.',
        'athletes': 'Suitable conditions for outdoor sports.',
      },
      'pollutants': [
        {
          'name': 'PM2.5',
          'value': 10.0,
          'unit': 'µg/m³',
          'description': _getPollutantDescription('pm2_5'),
        },
        {
          'name': 'PM10',
          'value': 20.0,
          'unit': 'µg/m³',
          'description': _getPollutantDescription('pm10'),
        },
        {
          'name': 'NO2',
          'value': 25.0,
          'unit': 'µg/m³',
          'description': _getPollutantDescription('no2'),
        },
        {
          'name': 'O3',
          'value': 30.0,
          'unit': 'µg/m³',
          'description': _getPollutantDescription('o3'),
        },
      ],
    };
  }

  Map<String, dynamic> _processAreaDetails(Map<String, dynamic> geocodeResult) {
    final addressComponents = geocodeResult['address_components'] as List;
    String areaType = 'unknown';
    String areaName = '';
    String district = '';
    String city = '';

    for (final component in addressComponents) {
      final types = component['types'] as List;
      if (types.contains('sublocality_level_1')) {
        areaName = component['long_name'];
        areaType = 'mahalle';
      } else if (types.contains('administrative_area_level_2')) {
        district = component['long_name'];
        if (areaName.isEmpty) {
          areaName = district;
          areaType = 'ilçe';
        }
      } else if (types.contains('administrative_area_level_1')) {
        city = component['long_name'];
        if (areaName.isEmpty) {
          areaName = city;
          areaType = 'il';
        }
      }
    }

    return {
      'name': areaName,
      'type': areaType,
      'district': district,
      'city': city,
    };
  }

  String _getFeatureDescription(String type, int count) {
    final countText = count >= 20 ? '>20' : count.toString();
    switch (type) {
      case 'park':
        return '$countText parks and green areas';
      case 'school':
        return '$countText educational institutions';
      case 'hospital':
        return '$countText healthcare facilities';
      case 'bank':
        return '$countText bank branches';
      case 'pharmacy':
        return '$countText pharmacies';
      case 'supermarket':
        return '$countText supermarkets';
      default:
        return '';
    }
  }

  Map<String, dynamic> _calculateScores(
    Map<String, dynamic> features,
    Map<String, dynamic> airQuality,
  ) {
    final featureMap = features['features'] as Map<String, int>;
    
    final greenScore = _calculateGreenScore(featureMap['park'] ?? 0);
    final basicScore = _calculateBasicScore(
      featureMap['school'] ?? 0,
      featureMap['hospital'] ?? 0,
      featureMap['pharmacy'] ?? 0,
      featureMap['supermarket'] ?? 0,
      featureMap['bank'] ?? 0,
    );
    final airScore = _calculateAirQualityScore(airQuality['aqi'] ?? 0);

    final weights = {
      'green_areas': 0.3,
      'basic_needs': 0.4,
      'air_quality': 0.3
    };

    final overallScore = (
      greenScore * weights['green_areas']! +
      basicScore * weights['basic_needs']! +
      airScore * weights['air_quality']!
    );

    final roundedScore = double.parse(overallScore.toStringAsFixed(1));
    
    return {
      'green_areas': double.parse(greenScore.toStringAsFixed(1)),
      'basic_needs': double.parse(basicScore.toStringAsFixed(1)),
      'air_quality': double.parse(airScore.toStringAsFixed(1)),
      'overall': roundedScore,
      'description': _getScoreDescription(roundedScore),
      'category': _getScoreCategory(roundedScore),
      'recommendations': _getRecommendations({
        'green_areas': greenScore,
        'basic_needs': basicScore,
        'air_quality': airScore,
      }),
    };
  }

  double _calculateGreenScore(int parkCount) {
    if (parkCount > 20) return 10.0;
    final logScore = parkCount > 0 ? 4 + (2.5 * log(parkCount + 1)) : 4.0;
    return logScore.clamp(4.0, 10.0);
  }

  double _calculateBasicScore(int schools, int hospitals, int pharmacies, int markets, int banks) {
    final schoolScore = schools > 20 ? 4.5 : (schools > 0 ? 1.5 * log(schools + 1) : 0);
    final hospitalScore = hospitals > 20 ? 4.5 : (hospitals > 0 ? 1.5 * log(hospitals + 1) : 0);
    final pharmacyScore = pharmacies > 20 ? 3.0 : (pharmacies > 0 ? log(pharmacies + 1) : 0);
    final marketScore = markets > 20 ? 3.0 : (markets > 0 ? log(markets + 1) : 0);
    final bankScore = banks > 20 ? 1.5 : (banks > 0 ? 0.5 * log(banks + 1) : 0);
    
    final weightedScore = 4 + ((schoolScore + hospitalScore + pharmacyScore + marketScore + bankScore) / 7) * 6;
    return weightedScore.clamp(4.0, 10.0);
  }

  double _calculateAirQualityScore(double aqi) {
    if (aqi == 0) return 7.0;
    
    if (aqi <= 50) {
      return 8.5 + ((50 - aqi) / 50) * 1.5;
    } else if (aqi <= 100) {
      return 7.0 + ((100 - aqi) / 50) * 1.4;
    } else if (aqi <= 150) {
      return 5.5 + ((150 - aqi) / 50) * 1.4;
    } else if (aqi <= 200) {
      return 4.0 + ((200 - aqi) / 50) * 1.4;
    }
    return 4.0;
  }

  String _getScoreCategory(double score) {
    if (score >= 9.0) return 'Excellent';
    if (score >= 8.0) return 'Very Good';
    if (score >= 7.0) return 'Good';
    if (score >= 6.0) return 'Moderate';
    if (score >= 5.0) return 'Developing';
    return 'Needs Improvement';
  }

  String _getScoreDescription(double score) {
    if (score >= 9.0) {
      return 'This area has the highest quality of life standards. All basic needs are easily accessible. Green areas are sufficient and air quality is very good.';
    } else if (score >= 8.0) {
      return 'The area has the basic amenities required for modern urban life. Daily life is quite comfortable and environmental planning is in good condition.';
    } else if (score >= 7.0) {
      return 'Quality of life is generally good. Most basic needs can be met, though there are some minor deficiencies in certain areas.';
    } else if (score >= 6.0) {
      return 'Basic living standards are met but there are areas that need improvement.';
    } else if (score >= 5.0) {
      return 'The area has a developing structure. Basic needs are partially met but significant infrastructure and service improvements are needed.';
    } else {
      return 'The area needs significant improvements in infrastructure and services. Access to basic needs is limited and living standards can be improved.';
    }
  }

  List<String> _getRecommendations(Map<String, double> scores) {
    final recommendations = <String>[];

    if (scores['green_areas']! < 6.0) {
      recommendations.add('Creating more parks and green spaces could improve the quality of life.');
    }
    if (scores['basic_needs']! < 6.0) {
      recommendations.add('Improving access to basic services (health, education, markets) is a priority need.');
    }
    if (scores['air_quality']! < 6.0) {
      recommendations.add('Environmental regulations can be made to improve air quality.');
    }

    if (recommendations.isEmpty) {
      recommendations.add('The area is generally in good condition, maintaining the current standard is important.');
    }

    return recommendations;
  }
} 