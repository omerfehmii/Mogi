import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String name,
    String? email,
    Map<String, dynamic>? preferences,
    List<String>? savedLocations,
    Map<String, List<String>>? searchHistory,
    Map<String, dynamic>? familyInfo,
    Map<String, dynamic>? jobInfo,
    Map<String, double>? budgetPreferences,
    List<String>? interests,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
} 