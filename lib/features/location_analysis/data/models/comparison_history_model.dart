import 'package:hive/hive.dart';

part 'comparison_history_model.g.dart';

@HiveType(typeId: 10) // Uygun bir typeId seçin
class ComparisonHistoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final List<String> locations;

  @HiveField(2)
  final String result;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final String title;

  ComparisonHistoryModel({
    required this.id,
    required this.locations,
    required this.result,
    required this.createdAt,
    required this.title,
  });

  // Başlık oluşturma yardımcı metodu
  static String generateTitle(List<String> locations) {
    return locations.join(' vs ');
  }

  // Kopya oluşturma metodu
  ComparisonHistoryModel copyWith({
    String? id,
    List<String>? locations,
    String? result,
    DateTime? createdAt,
    String? title,
  }) {
    return ComparisonHistoryModel(
      id: id ?? this.id,
      locations: locations ?? this.locations,
      result: result ?? this.result,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
    );
  }
} 