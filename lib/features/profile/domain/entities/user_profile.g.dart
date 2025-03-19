// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserProfileImpl _$$UserProfileImplFromJson(Map<String, dynamic> json) =>
    _$UserProfileImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      preferences: json['preferences'] as Map<String, dynamic>?,
      savedLocations: (json['savedLocations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      searchHistory: (json['searchHistory'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
      familyInfo: json['familyInfo'] as Map<String, dynamic>?,
      jobInfo: json['jobInfo'] as Map<String, dynamic>?,
      budgetPreferences:
          (json['budgetPreferences'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      interests: (json['interests'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'preferences': instance.preferences,
      'savedLocations': instance.savedLocations,
      'searchHistory': instance.searchHistory,
      'familyInfo': instance.familyInfo,
      'jobInfo': instance.jobInfo,
      'budgetPreferences': instance.budgetPreferences,
      'interests': instance.interests,
    };
