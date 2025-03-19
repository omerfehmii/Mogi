// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_analysis.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LocationAnalysisImpl _$$LocationAnalysisImplFromJson(
        Map<String, dynamic> json) =>
    _$LocationAnalysisImpl(
      locationName: json['locationName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      safetyScore: (json['safetyScore'] as num).toDouble(),
      transportScore: (json['transportScore'] as num).toDouble(),
      costOfLiving: (json['costOfLiving'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      nearbyAmenities: (json['nearbyAmenities'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      educationFacilities:
          (json['educationFacilities'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
      demographicData: json['demographicData'] as Map<String, dynamic>,
      analysis: json['analysis'] as String?,
      pros: (json['pros'] as List<dynamic>?)?.map((e) => e as String).toList(),
      cons: (json['cons'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$$LocationAnalysisImplToJson(
        _$LocationAnalysisImpl instance) =>
    <String, dynamic>{
      'locationName': instance.locationName,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'safetyScore': instance.safetyScore,
      'transportScore': instance.transportScore,
      'costOfLiving': instance.costOfLiving,
      'nearbyAmenities': instance.nearbyAmenities,
      'educationFacilities': instance.educationFacilities,
      'demographicData': instance.demographicData,
      'analysis': instance.analysis,
      'pros': instance.pros,
      'cons': instance.cons,
    };
