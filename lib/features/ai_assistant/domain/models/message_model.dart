import 'package:hive/hive.dart';

part 'message_model.g.dart';

@HiveType(typeId: 1)
class MessageModel extends HiveObject {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final DateTime createdAt;

  @HiveField(2)
  final bool isAIMessage;

  @HiveField(3)
  final String? threadId;

  MessageModel({
    required this.text,
    required this.createdAt,
    required this.isAIMessage,
    this.threadId,
  });
} 