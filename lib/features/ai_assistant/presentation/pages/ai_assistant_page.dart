import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mogi/features/ai_assistant/data/services/ai_assistant_service.dart';
import 'package:mogi/features/ai_assistant/data/services/chat_history_service.dart';
import 'package:mogi/features/ai_assistant/domain/models/message_model.dart';
import 'package:mogi/features/ai_assistant/presentation/widgets/chat_message.dart';
import 'dart:math';
import '../../../location_analysis/data/services/premium_service.dart';
import '../../../location_analysis/presentation/pages/premium_page.dart';
import '../../../../core/network/network_connectivity_service.dart';
import '../../../../core/widgets/no_internet_connection_widget.dart';

class AIAssistantPage extends StatefulWidget {
  final String? initialMessage;
  final String? threadId;

  const AIAssistantPage({
    Key? key,
    this.initialMessage,
    this.threadId,
  }) : super(key: key);

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> with SingleTickerProviderStateMixin {
  final AIAssistantService _aiAssistantService = AIAssistantService();
  final ChatHistoryService _chatHistoryService = ChatHistoryService();
  final PremiumService _premiumService = PremiumService();
  final NetworkConnectivityService _connectivityService = NetworkConnectivityService();
  late final TextEditingController _messageController;
  final List<MessageModel> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _dotAnimationController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: widget.initialMessage);
    _dotAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _initServices();
    
    // Bağlantı durumu değişikliklerini dinle
    _connectivityService.isConnected.addListener(_onConnectivityChanged);
  }
  
  void _onConnectivityChanged() {
    if (mounted) {
      setState(() {
        // Bağlantı durumu değiştiğinde UI'ı güncelle
        if (_connectivityService.isConnected.value) {
          // İnternet bağlantısı geri geldiğinde UI'ı güncelle
          print("AI Assistant: Internet connection restored");
          // Sadece mesajlar boşsa servisleri yeniden başlat
          if (_messages.isEmpty) {
            _initServices();
          }
        } else {
          // İnternet bağlantısı kesildiğinde UI'ı güncelle
          print("AI Assistant: Internet connection lost");
        }
      });
    }
  }

  Future<void> _initServices() async {
    try {
      await _premiumService.init();
      await _chatHistoryService.init();
      _aiAssistantService.onMessageReceived = _handleAIResponse;
      await _aiAssistantService.init();
      
      if (widget.threadId != null) {
        _chatHistoryService.continueThread(widget.threadId!);
      } else {
        _chatHistoryService.startNewThread();
      }
      
      if (mounted) {
        final messages = _chatHistoryService.getMessages();
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI Assistant could not be started: $e')),
        );
      }
    }
  }

  void _handleAIResponse(String message) async {
    if (mounted) {
      final messageModel = MessageModel(
        text: message,
        isAIMessage: true,
        createdAt: DateTime.now(),
        threadId: _chatHistoryService.getCurrentThreadId(),
      );
      
      await _chatHistoryService.addMessage(message, isAIMessage: true);
      
      setState(() {
        _messages.add(messageModel);
        _isLoading = false;
      });
      
      Future.delayed(const Duration(milliseconds: 100), () {
        // Short messages: scroll to bottom completely
        if (message.length < 1000) {
          _scrollToBottom();
        } 
        // Long messages: scroll partially down to show more content
        else if (_scrollController.hasClients) {
          // Get current position
          final currentPosition = _scrollController.position.pixels;
          // Calculate how far to scroll (just a little bit, around 200 pixels down)
          final targetPosition = currentPosition + 100;
          // Make sure we don't scroll past the end
          final maxPosition = _scrollController.position.maxScrollExtent;
          final scrollTo = targetPosition > maxPosition ? maxPosition : targetPosition;
          
          _scrollController.animateTo(
            scrollTo,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      // İnternet bağlantısını kontrol et
      if (!_connectivityService.isConnected.value) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İnternet bağlantısı bulunamadı. Lütfen bağlantınızı kontrol edin ve tekrar deneyin.')),
          );
        }
        return;
      }
      
      if (!_premiumService.isInitialized) {
        await _initServices();
      }

      // Mesajı UI'da hemen göster ve input'u temizle
      final messageModel = MessageModel(
        text: message,
        isAIMessage: false,
        createdAt: DateTime.now(),
        threadId: _chatHistoryService.getCurrentThreadId(),
      );

      setState(() {
        _messages.add(messageModel);
        _isLoading = true;
        _messageController.clear();
      });
      
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });

      // Mesajı history'ye ekle
      await _chatHistoryService.addMessage(message, isAIMessage: false);

      // Premium kontrolünü asenkron olarak yap
      final canSendMessage = await _checkPremiumStatus();
      
      // Mesaj gönderme izni yoksa işlemi sonlandır
      if (!canSendMessage) {
        setState(() => _isLoading = false);
        return;
      }

      // Mesajı AI'a gönder
      await _aiAssistantService.sendMessage(message);
      
      // UI'ı yeniden oluştur, Mogi puanları güncellemesi için
      if (mounted) {
        setState(() {
          // State'i zorunlu olarak güncelle ki widget rebuild olsun
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message could not be sent: $e')),
        );
      }
    }
  }

  // Premium durumunu kontrol eden ayrı bir metod
  Future<bool> _checkPremiumStatus() async {
    print('AI sohbeti gönderiliyor - Başlangıç durumu:');
    print('Premium: ${_premiumService.isPremium}');
    print('Premium Kontrol: isPremium = ${_premiumService.status.isPremium}, premiumUntil = ${_premiumService.status.premiumUntil}');
    print('Mogi Puanları: ${_premiumService.mogiPoints}');

    // Premium kontrolü
    if (_premiumService.isPremium) {
      print('Kullanıcı PREMIUM, mesaj doğrudan gönderilecek');
      return true;
    }
    
    print('Kullanıcı premium DEĞİL, Mogi puanları kontrol ediliyor');
    // Premium olmayan kullanıcılar için Mogi puanı kontrolü
    if (_premiumService.mogiPoints > 0) {
      print('Mogi puanları kullanılıyor: ${_premiumService.mogiPoints}');
      final success = await _premiumService.useMogiPointsForAiChat();
      print('Mogi puanı kullanımı sonucu: $success, Kalan puan: ${_premiumService.mogiPoints}');
      
      if (success) {
        print('AI chat için Mogi puanı kullanıldı. Kalan: ${_premiumService.mogiPoints}');
        return true;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mogi puanları kullanılamadı. Lütfen daha sonra tekrar deneyin.')),
          );
        }
      }
    } else {
      // Mogi puanı yoksa Premium sayfasına yönlendir
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yetersiz Mogi puanı. Lütfen daha fazla Mogi puanı satın alın.')),
        );
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const PremiumPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 200),
          ),
        );
      }
    }
    
    print('Mesaj gönderme izni yok, işlem sonlandırılıyor');
    return false;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFBF7),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
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
            const SizedBox(width: 12),
            const Text(
              'AI Assistant',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF08104F),
                fontSize: 20,
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 22,
            color: Color(0xFF6339F9),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: !_connectivityService.isConnected.value && _messages.isEmpty
          ? NoInternetConnectionWidget(
              onRetry: () async {
                print("AI Assistant: Retry button pressed, checking connectivity...");
                // Bağlantıyı kontrol et
                await _connectivityService.checkConnectivity();
                
                // Kısa bir bekleme ekleyelim
                await Future.delayed(const Duration(milliseconds: 500));
                
                print("AI Assistant: Connection status after retry: ${_connectivityService.isConnected.value}");
                
                // Her durumda servisleri yeniden başlatmayı deneyelim
                _initServices();
              },
              message: 'AI Asistanı kullanmak için internet bağlantısı gereklidir. Lütfen bağlantınızı kontrol edin ve tekrar deneyin.',
            )
          : Stack(
        children: [
          // Arka plan deseni
          Positioned(
            right: -100,
            top: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6339F9).withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            left: -80,
            bottom: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7E5BED).withOpacity(0.05),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: _isLoading && _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6339F9).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const CircularProgressIndicator(
                                color: Color(0xFF6339F9),
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'AI Assistant is preparing...',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: const Color(0xFF08104F),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return ChatMessage(message: message);
                        },
                      ),
              ),
              if (_isLoading && _messages.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(
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
                      const SizedBox(width: 8),
                      _buildTypingIndicator(),
                    ],
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F5F1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: _connectivityService.isConnected.value 
                                ? 'Type your message...' 
                                : 'No internet connection...',
                            hintStyle: TextStyle(
                              color: _connectivityService.isConnected.value 
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFFEF4444),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9F5F1),
                            prefixIcon: Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: const Color(0xFF6339F9).withOpacity(0.5),
                              size: 20,
                            ),
                            counterText: '',
                          ),
                          style: const TextStyle(
                            color: Color(0xFF08104F),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                          enabled: !_isLoading && _connectivityService.isConnected.value,
                          onSubmitted: (_) => _connectivityService.isConnected.value ? _sendMessage() : null,
                          maxLines: null,
                          maxLength: 500,
                          textInputAction: TextInputAction.send,
                          cursorColor: const Color(0xFF6339F9),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6339F9),
                            Color(0xFF8B6DFA),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6339F9).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading || !_connectivityService.isConnected.value ? null : _sendMessage,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: Icon(
                              Icons.send_rounded,
                              color: _isLoading || !_connectivityService.isConnected.value ? Colors.white.withOpacity(0.5) : Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _dotAnimationController.dispose();
    _connectivityService.isConnected.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: List.generate(3, (index) => _buildDot(index * 300)),
    );
  }

  Widget _buildDot(int delay) {
    return AnimatedBuilder(
      animation: _dotAnimationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          child: Transform.translate(
            offset: Offset(0, -6 * sin((_dotAnimationController.value * 2 * pi) + (delay / 500))),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.6 + (0.4 * sin((_dotAnimationController.value * 2 * pi) + (delay / 500)))),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
} 