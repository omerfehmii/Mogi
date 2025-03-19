import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../network/network_connectivity_service.dart';
import 'dart:async';

class NoInternetConnectionWidget extends StatefulWidget {
  final VoidCallback onRetry;
  final String message;

  const NoInternetConnectionWidget({
    Key? key,
    required this.onRetry,
    this.message = 'İnternet bağlantısı bulunamadı. Lütfen bağlantınızı kontrol edin ve tekrar deneyin.',
  }) : super(key: key);

  @override
  State<NoInternetConnectionWidget> createState() => _NoInternetConnectionWidgetState();
}

class _NoInternetConnectionWidgetState extends State<NoInternetConnectionWidget> {
  final NetworkConnectivityService _connectivityService = NetworkConnectivityService();
  bool _isRetrying = false;
  Timer? _autoRetryTimer;

  @override
  void initState() {
    super.initState();
    _connectivityService.isConnected.addListener(_onConnectivityChanged);
    
    // Otomatik yeniden deneme için timer başlat
    _startAutoRetryTimer();
  }

  @override
  void dispose() {
    _connectivityService.isConnected.removeListener(_onConnectivityChanged);
    _autoRetryTimer?.cancel();
    super.dispose();
  }

  void _startAutoRetryTimer() {
    // Her 5 saniyede bir otomatik olarak bağlantıyı kontrol et
    _autoRetryTimer?.cancel();
    _autoRetryTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isRetrying && mounted) {
        _checkConnectivityAndRetry();
      }
    });
  }

  void _onConnectivityChanged() {
    // If connection is restored, automatically retry
    if (_connectivityService.isConnected.value && mounted) {
      _retryConnection();
    }
  }

  // Bağlantıyı kontrol et ve varsa yeniden dene
  Future<void> _checkConnectivityAndRetry() async {
    if (_isRetrying) return;
    
    // Bağlantıyı zorla kontrol et
    final hasConnection = await _connectivityService.forceConnectivityCheck();
    
    if (hasConnection && mounted) {
      if (kDebugMode) {
        print('Auto retry: Connection detected, retrying...');
      }
      _retryConnection();
    }
  }

  Future<void> _retryConnection() async {
    if (_isRetrying) return;
    
    setState(() {
      _isRetrying = true;
    });
    
    try {
      // Force a connectivity check
      await _connectivityService.forceConnectivityCheck();
      
      // Kısa bir bekleme ekleyelim - bağlantı durumunun güncellenmesi için
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Her durumda onRetry callback'i çağıralım, bağlantı durumunu
      // sayfanın kendisi kontrol edecek
      widget.onRetry();
      
      // Debug için bağlantı durumunu yazdıralım
      if (kDebugMode) {
        print('NoInternetConnectionWidget: Retry attempted. Connection status: ${_connectivityService.isConnected.value}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NoInternetConnectionWidget: Retry error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isRetrying ? null : _retryConnection,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: _isRetrying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
} 