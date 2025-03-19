import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Supabase servisini yöneten sınıf.
/// Bu sınıf Supabase ile ilgili tüm işlemleri ve bağlantıları yönetir.
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient _client;
  bool _isInitialized = false;
  
  // Rate limiting için değişkenler
  final Map<String, DateTime> _lastApiCallTimes = {};
  final Map<String, int> _apiCallCounts = {};
  final Duration _rateLimitWindow = Duration(minutes: 5);
  final int _maxCallsPerWindow = 100;
  
  // Token yenileme için değişkenler
  Timer? _refreshTimer;
  
  // Singleton factory constructor
  factory SupabaseService() {
    return _instance;
  }

  // Internal constructor
  SupabaseService._internal();

  /// Supabase istemcisini getter metodu
  SupabaseClient get client {
    if (!_isInitialized) {
      throw Exception('SupabaseService has not been initialized. Call init() first.');
    }
    return _client;
  }

  /// Servisin başlatılmış olup olmadığını kontrol eder
  bool get isInitialized => _isInitialized;

  /// Supabase servisini başlatır
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (supabaseUrl == null || supabaseUrl.isEmpty) {
        throw Exception('SUPABASE_URL environment variable is not set');
      }

      if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
        throw Exception('SUPABASE_ANON_KEY environment variable is not set');
      }
      
      // Anti-tamper kontrol - manipülasyon olup olmadığını kontrol et
      await verifyIntegrity();

      // Supabase'i başlat
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      
      _client = Supabase.instance.client;
      _isInitialized = true;
      
      // Token yenileyici başlat
      _startTokenRefresher();
      
      // Auth durumunu dinle
      _client.auth.onAuthStateChange.listen(_handleAuthStateChange);
      
      if (kDebugMode) {
        print('SupabaseService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize SupabaseService: $e');
      }
      rethrow;
    }
  }

  // Anti-tamper kontrol - uygulama bütünlüğünü doğrula
  Future<void> verifyIntegrity() async {
    try {
      // SharedPreferences'dan eski hash'i al
      final prefs = await SharedPreferences.getInstance();
      final storedHash = prefs.getString('app_integrity_hash');
      
      // Burada uygulamanızın bütünlüğünü kontrol edebilirsiniz
      // Örneğin, kritik dosyaların hash değerlerini kontrol etmek
      
      // Basit bir örnek: Son çalışma zamanı kontrolü
      final lastRunTime = prefs.getString('last_run_timestamp');
      final now = DateTime.now().toIso8601String();
      
      if (lastRunTime != null) {
        // Eğer son çalışma zamanı gerçekçi değilse, manipülasyon olabilir
        final lastRun = DateTime.parse(lastRunTime);
        final difference = DateTime.now().difference(lastRun);
        
        if (difference.inDays < 0 || difference.inDays > 365) {
          if (kDebugMode) {
            print('Şüpheli zaman farkı tespit edildi: $difference');
          }
          
          // Logla ve monitore et, ancak hata fırlatma
          await _logSecurityEvent('time_manipulation_detected', {
            'last_run': lastRunTime,
            'current_time': now,
            'difference_days': difference.inDays,
          });
        }
      }
      
      // Yeni çalışma zamanını kaydet
      await prefs.setString('last_run_timestamp', now);
    } catch (e) {
      if (kDebugMode) {
        print('Integrity check error: $e');
      }
    }
  }
  
  // Güvenlik olaylarını logla
  Future<void> _logSecurityEvent(String eventType, Map<String, dynamic> details) async {
    try {
      if (_isInitialized) {
        await client.from('security_events').insert({
          'event_type': eventType,
          'user_id': client.auth.currentUser?.id,
          'details': details,
          'timestamp': DateTime.now().toIso8601String(),
          'ip_address': null, // Client tarafında IP adresini doğrudan alamıyoruz
          'device_info': {
            'platform': kIsWeb ? 'web' : 'mobile',
            'is_debug': kDebugMode,
          }
        });
      }
    } catch (e) {
      // Loglama hatası durumunda sessizce devam et
      if (kDebugMode) {
        print('Security event logging error: $e');
      }
    }
  }
  
  // Auth durum değişikliklerini dinleme
  void _handleAuthStateChange(AuthState authState) {
    if (authState.event == AuthChangeEvent.tokenRefreshed) {
      if (kDebugMode) {
        print('Auth token refreshed');
      }
    } else if (authState.event == AuthChangeEvent.signedIn) {
      // Kullanıcı giriş yaptığında güvenlik logunu kaydet
      _logSecurityEvent('user_signed_in', {
        'auth_method': 'anonymous', // Veya diğer metotlar (email, social, vb.)
        'timestamp': DateTime.now().toIso8601String(),
      });
    } else if (authState.event == AuthChangeEvent.signedOut) {
      _logSecurityEvent('user_signed_out', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }
  
  // Token yenileyici başlat
  void _startTokenRefresher() {
    // Her 6 saatte bir token'ı yenile
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(hours: 6), (timer) async {
      try {
        if (_isInitialized && client.auth.currentUser != null) {
          await client.auth.refreshSession();
          if (kDebugMode) {
            print('Auth token refreshed successfully');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to refresh auth token: $e');
        }
      }
    });
  }

  // Rate limiting kontrolü
  Future<bool> _checkRateLimit(String operationType) async {
    final now = DateTime.now();
    
    // Son çağrı zamanını kontrol et
    if (_lastApiCallTimes.containsKey(operationType)) {
      final lastCall = _lastApiCallTimes[operationType]!;
      final timeSinceLast = now.difference(lastCall);
      
      // Rate limit penceresi içerisindeyiz
      if (timeSinceLast < _rateLimitWindow) {
        final currentCount = _apiCallCounts[operationType] ?? 0;
        
        // Rate limit aşıldı
        if (currentCount >= _maxCallsPerWindow) {
          await _logSecurityEvent('rate_limit_exceeded', {
            'operation_type': operationType,
            'count': currentCount,
            'window_minutes': _rateLimitWindow.inMinutes,
          });
          return false;
        }
        
        // Count'u arttır
        _apiCallCounts[operationType] = currentCount + 1;
      } else {
        // Pencere dışında, sayacı sıfırla
        _apiCallCounts[operationType] = 1;
      }
    } else {
      // İlk çağrı
      _apiCallCounts[operationType] = 1;
    }
    
    // Son çağrı zamanını güncelle
    _lastApiCallTimes[operationType] = now;
    return true;
  }

  /// Kullanıcı oturum açma
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Rate limiting
      if (!await _checkRateLimit('sign_in')) {
        throw Exception('Rate limit exceeded for sign in operations');
      }
      
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      await _logSecurityEvent('sign_in_successful', {
        'method': 'email',
        'email': email,
      });
      
      return response;
    } catch (e) {
      await _logSecurityEvent('sign_in_failed', {
        'method': 'email',
        'email': email,
        'error': e.toString(),
      });
      
      if (kDebugMode) {
        print('Supabase sign in error: $e');
      }
      rethrow;
    }
  }

  /// Anonim oturum açma
  Future<User?> signInAnonymously() async {
    try {
      // Rate limiting
      if (!await _checkRateLimit('sign_in_anonymously')) {
        throw Exception('Rate limit exceeded for anonymous sign in operations');
      }
      
      final result = await client.auth.signInAnonymously();
      
      await _logSecurityEvent('sign_in_anonymous_successful', {
        'method': 'anonymous',
      });
      
      return result.user;
    } catch (e) {
      await _logSecurityEvent('sign_in_anonymous_failed', {
        'method': 'anonymous',
        'error': e.toString(),
      });
      
      if (kDebugMode) {
        print('Supabase anonymous sign in error: $e');
      }
      // Anonim oturum başarısız olsa bile devam et
      return null;
    }
  }

  /// Kullanıcı kaydı
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      // Rate limiting
      if (!await _checkRateLimit('sign_up')) {
        throw Exception('Rate limit exceeded for sign up operations');
      }
      
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );
      
      await _logSecurityEvent('sign_up_successful', {
        'method': 'email',
        'email': email,
      });
      
      return response;
    } catch (e) {
      await _logSecurityEvent('sign_up_failed', {
        'method': 'email',
        'email': email,
        'error': e.toString(),
      });
      
      if (kDebugMode) {
        print('Supabase sign up error: $e');
      }
      rethrow;
    }
  }

  /// Kullanıcı oturumunu kapatma
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
      
      await _logSecurityEvent('sign_out_successful', {
        'method': 'explicit',
      });
    } catch (e) {
      await _logSecurityEvent('sign_out_failed', {
        'error': e.toString(),
      });
      
      if (kDebugMode) {
        print('Supabase sign out error: $e');
      }
      rethrow;
    }
  }

  /// Mevcut kullanıcıyı getir
  User? getCurrentUser() {
    return client.auth.currentUser;
  }

  /// Kullanıcı oturumunu dinle
  Stream<AuthState> authStateChanges() {
    return client.auth.onAuthStateChange;
  }

  /// Veri ekle
  Future<List<Map<String, dynamic>>> insertData({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Rate limiting
      if (!await _checkRateLimit('insert_data')) {
        throw Exception('Rate limit exceeded for data insertion operations');
      }
      
      // Verilerin temiz olduğundan emin ol
      final sanitizedData = _sanitizeData(data);
      
      final response = await client.from(table).insert(sanitizedData).select();
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      await _logSecurityEvent('insert_data_failed', {
        'table': table,
        'error': e.toString(),
      });
      
      if (kDebugMode) {
        print('Supabase insert data error: $e');
      }
      rethrow;
    }
  }

  /// Veri güncelle
  Future<List<Map<String, dynamic>>> updateData({
    required String table,
    required Map<String, dynamic> data,
    required String column,
    required dynamic value,
  }) async {
    try {
      // Rate limiting
      if (!await _checkRateLimit('update_data')) {
        throw Exception('Rate limit exceeded for data update operations');
      }
      
      // Güvenlik kontrolü - SQL enjeksiyonuna karşı koruma
      if (value is String) {
        value = _sanitizeString(value);
      }
      
      // Verilerin temiz olduğundan emin ol
      final sanitizedData = _sanitizeData(data);
      
      // Null değerleri doğru şekilde işle
      final Map<String, dynamic> finalData = {};
      sanitizedData.forEach((key, value) {
        // Null değerleri doğrudan aktar
        finalData[key] = value;
      });
      
      try {
        if (kDebugMode) {
          print('Supabase update data: table=$table, column=$column, value=$value');
          print('Update data: $finalData');
        }
        
        final response = await client.from(table).update(finalData).eq(column, value).select();
        return response as List<Map<String, dynamic>>;
      } catch (e) {
        if (kDebugMode) {
          print('Supabase update operation failed for table: $table, column: $column');
          print('Error details: ${e.toString()}');
        }
        
        // Özel hata mesajı hazırla
        String errorMessage = 'Veri güncelleme hatası: ${e.toString()}';
        if (e.toString().contains('permission denied')) {
          errorMessage = 'İzin hatası: Bu tabloda güncelleme yapma yetkiniz yok. Supabase RLS politikalarını kontrol edin.';
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      await _logSecurityEvent('update_data_failed', {
        'table': table,
        'column': column,
        'error': e.toString(),
      });
      
      if (kDebugMode) {
        print('Supabase update data error: $e');
      }
      rethrow;
    }
  }

  /// Veri al
  Future<List<Map<String, dynamic>>> getData({
    required String table,
    String? column,
    dynamic value,
  }) async {
    try {
      // Rate limiting
      if (!await _checkRateLimit('get_data')) {
        throw Exception('Rate limit exceeded for data retrieval operations');
      }
      
      var query = client.from(table).select();
      if (column != null && value != null) {
        // Güvenlik kontrolü - SQL enjeksiyonuna karşı koruma
        if (value is String) {
          value = _sanitizeString(value);
        }
        
        query = query.eq(column, value);
      }
      final response = await query;
      return response;
    } catch (e) {
      await _logSecurityEvent('get_data_failed', {
        'table': table,
        'column': column,
        'error': e.toString(),
      });
      
      if (kDebugMode) {
        print('Supabase get data error: $e');
      }
      rethrow;
    }
  }

  /// Veri sil
  Future<PostgrestResponse> deleteData({
    required String table,
    required String column,
    required dynamic value,
  }) async {
    try {
      // Rate limiting
      if (!await _checkRateLimit('delete_data')) {
        throw Exception('Rate limit exceeded for data deletion operations');
      }
      
      // Güvenlik kontrolü - SQL enjeksiyonuna karşı koruma
      if (value is String) {
        value = _sanitizeString(value);
      }
      
      return await client.from(table).delete().eq(column, value);
    } catch (e) {
      await _logSecurityEvent('delete_data_failed', {
        'table': table,
        'column': column,
        'error': e.toString(),
      });
      
      if (kDebugMode) {
        print('Supabase delete data error: $e');
      }
      rethrow;
    }
  }
  
  // SQL enjeksiyonuna karşı string temizleme
  String _sanitizeString(String input) {
    // En basit temizleme: SQL enjeksiyon karakterlerini escape et
    return input
      .replaceAll("'", "''")
      .replaceAll(";", "")
      .replaceAll("--", "")
      .replaceAll("/*", "")
      .replaceAll("*/", "");
  }
  
  // Tüm veri alanlarını temizleme
  Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    final Map<String, dynamic> sanitized = {};
    
    data.forEach((key, value) {
      if (value is String) {
        sanitized[key] = _sanitizeString(value);
      } else if (value is Map) {
        // Nested map'leri recursively temizle
        sanitized[key] = _sanitizeData(Map<String, dynamic>.from(value));
      } else {
        sanitized[key] = value;
      }
    });
    
    return sanitized;
  }
  
  // Servis kapatıldığında temizlik
  void dispose() {
    _refreshTimer?.cancel();
  }
} 