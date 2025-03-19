import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkConnectivityService {
  static final NetworkConnectivityService _instance = NetworkConnectivityService._internal();
  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(true);
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicCheckTimer;

  factory NetworkConnectivityService() {
    return _instance;
  }

  NetworkConnectivityService._internal();

  Future<void> init() async {
    try {
      // Check initial connection status
      await checkConnectivity();
      
      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
        // Bağlantı değişikliği olduğunda hemen güncelle
        _updateConnectionStatus(results);
        
        // Bağlantı değişikliği olduğunda ek bir kontrol yap
        if (results.isEmpty || results.contains(ConnectivityResult.none)) {
          // Bağlantı kesildiğinde hemen güncelle
          isConnected.value = false;
          if (kDebugMode) {
            print('Bağlantı kesildi: Hızlı güncelleme');
          }
        } else {
          // Bağlantı geldiğinde hemen güncelle
          isConnected.value = true;
          if (kDebugMode) {
            print('Bağlantı geldi: Hızlı güncelleme');
          }
        }
      });
      
      // Start periodic connectivity check with shorter interval
      _startPeriodicCheck();
    } catch (e) {
      if (kDebugMode) {
        print('NetworkConnectivityService init error: $e');
      }
      // Default to connected to prevent blocking app functionality
      isConnected.value = true;
    }
  }

  void _startPeriodicCheck() {
    // Cancel existing timer if any
    _periodicCheckTimer?.cancel();
    
    // Check connectivity every 10 seconds
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await checkConnectivity();
    });
  }

  Future<void> checkConnectivity() async {
    try {
      // Connectivity kontrolü yap
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      
      // Bağlantı durumunu güncelle
      final bool wasConnected = isConnected.value;
      final bool nowConnected = results.isNotEmpty && !results.contains(ConnectivityResult.none);
      
      // Sadece bağlantı durumu değiştiyse güncelle
      if (wasConnected != nowConnected) {
        isConnected.value = nowConnected;
        if (kDebugMode) {
          print('Connection status changed: ${isConnected.value}');
        }
      } else if (kDebugMode) {
        print('Manual connectivity check: ${results.map((r) => r.name).join(', ')}, isConnected: ${isConnected.value} (no change)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Check connectivity error: $e');
      }
      // Default to connected to prevent blocking app functionality
      isConnected.value = true;
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final bool wasConnected = isConnected.value;
    final bool nowConnected = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    
    // Only update if the status has changed
    if (wasConnected != nowConnected) {
      isConnected.value = nowConnected;
      if (kDebugMode) {
        print('Connection status changed: ${isConnected.value}');
      }
    }
  }

  // Bağlantı durumunu manuel olarak kontrol etmek için yeni metod
  Future<bool> forceConnectivityCheck() async {
    try {
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      final bool nowConnected = results.isNotEmpty && !results.contains(ConnectivityResult.none);
      
      // Bağlantı durumunu güncelle
      isConnected.value = nowConnected;
      
      if (kDebugMode) {
        print('Force connectivity check: ${results.map((r) => r.name).join(', ')}, isConnected: ${isConnected.value}');
      }
      
      return nowConnected;
    } catch (e) {
      if (kDebugMode) {
        print('Force connectivity check error: $e');
      }
      // Default to connected to prevent blocking app functionality
      isConnected.value = true;
      return true;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicCheckTimer?.cancel();
  }
} 