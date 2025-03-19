import 'package:hive/hive.dart';
import 'package:mogi/features/ai_assistant/domain/models/message_model.dart';
import 'package:uuid/uuid.dart';

class ChatHistoryService {
  late Box<MessageModel> _box;
  String? _currentThreadId;
  final _uuid = const Uuid();

  Future<void> init() async {
    if (!Hive.isBoxOpen('chat_history')) {
      _box = await Hive.openBox<MessageModel>('chat_history');
    } else {
      _box = Hive.box<MessageModel>('chat_history');
    }
  }

  void startNewThread() {
    _currentThreadId = _uuid.v4();
  }

  void continueThread(String threadId) {
    _currentThreadId = threadId;
  }

  String? getCurrentThreadId() {
    return _currentThreadId;
  }

  List<MessageModel> getMessages() {
    if (_currentThreadId == null) {
      startNewThread();
    }
    final messages = _box.values
        .where((msg) => msg.threadId == _currentThreadId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    return messages;
  }

  List<List<MessageModel>> getAllThreads() {
    final allMessages = _box.values.toList();
    final Map<String, List<MessageModel>> threads = {};
    
    for (var message in allMessages) {
      if (message.threadId == null) continue;
      
      if (!threads.containsKey(message.threadId)) {
        threads[message.threadId!] = [];
      }
      threads[message.threadId!]!.add(message);
    }
    
    final sortedThreads = threads.values.map((messages) {
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    }).toList();
    
    sortedThreads.sort((a, b) {
      if (a.isEmpty || b.isEmpty) return 0;
      final lastMessageA = a.last.createdAt;
      final lastMessageB = b.last.createdAt;
      return lastMessageB.compareTo(lastMessageA);
    });
    
    return sortedThreads;
  }

  List<MessageModel> getThreadMessages(String threadId) {
    return _box.values
        .where((msg) => msg.threadId == threadId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  (MessageModel?, String?) getLastUserMessageAndThreadId(List<MessageModel> thread) {
    if (thread.isEmpty) return (null, null);
    
    final userMessages = thread.where((msg) => !msg.isAIMessage).toList();
    if (userMessages.isEmpty) {
      final firstMessage = thread.firstWhere((msg) => msg.isAIMessage, orElse: () => thread.first);
      return (firstMessage, firstMessage.threadId);
    }
    return (userMessages.last, userMessages.last.threadId);
  }

  Future<void> addMessage(String text, {bool isAIMessage = false}) async {
    if (_currentThreadId == null) {
      startNewThread();
    }
    
    final message = MessageModel(
      text: text,
      createdAt: DateTime.now(),
      isAIMessage: isAIMessage,
      threadId: _currentThreadId,
    );
    await _box.add(message);
  }

  Future<void> clearHistory() async {
    await _box.clear();
    _currentThreadId = null;
  }

  Future<void> deleteThread(String threadId) async {
    final messages = _box.values.where((msg) => msg.threadId == threadId).toList();
    for (var message in messages) {
      await message.delete();
    }
  }
} 