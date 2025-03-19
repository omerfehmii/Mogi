import 'package:hive/hive.dart';

part 'profile_model.g.dart';

@HiveType(typeId: 3)
class ProfileModel extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String city;

  ProfileModel({
    required this.name,
    required this.city,
  });
} 