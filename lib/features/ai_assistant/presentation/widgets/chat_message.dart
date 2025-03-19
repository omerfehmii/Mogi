import 'package:flutter/material.dart';
import '../../domain/models/message_model.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatMessage extends StatelessWidget {
  final MessageModel message;

  const ChatMessage({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = !message.isAIMessage;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6339F9).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.assistant,
                color: Color(0xFF6339F9),
                size: 24,
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF6339F9)
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? const Color(0xFF6339F9).withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: message.text,
                    selectable: false,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: isUser ? Colors.white : const Color(0xFF08104F),
                        fontSize: 16,
                        height: 1.5,
                      ),
                      strong: TextStyle(
                        color: isUser ? Colors.white : const Color(0xFF08104F),
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                      em: TextStyle(
                        color: isUser ? Colors.white : const Color(0xFF08104F),
                        fontSize: 16,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                      blockquote: TextStyle(
                        color: isUser ? Colors.white.withOpacity(0.8) : const Color(0xFF08104F).withOpacity(0.8),
                        fontSize: 16,
                        height: 1.5,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: isUser ? Colors.white.withOpacity(0.5) : const Color(0xFF6339F9).withOpacity(0.5),
                            width: 4,
                          ),
                        ),
                      ),
                      listBullet: TextStyle(
                        color: isUser ? Colors.white : const Color(0xFF08104F),
                        fontSize: 16,
                        height: 1.5,
                      ),
                      code: TextStyle(
                        color: isUser ? Colors.white.withOpacity(0.9) : const Color(0xFF6339F9),
                        fontSize: 14,
                        height: 1.5,
                        fontFamily: 'monospace',
                        backgroundColor: isUser 
                            ? Colors.white.withOpacity(0.1) 
                            : const Color(0xFF6339F9).withOpacity(0.1),
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: isUser 
                            ? Colors.white.withOpacity(0.1) 
                            : const Color(0xFF6339F9).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      color: isUser 
                          ? Colors.white.withOpacity(0.7) 
                          : const Color(0xFF08104F).withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              margin: const EdgeInsets.only(left: 12),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF6339F9).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'U',
                  style: TextStyle(
                    color: const Color(0xFF6339F9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
} 