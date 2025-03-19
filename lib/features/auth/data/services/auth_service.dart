import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _userKey = 'local_user';
  final String _usersListKey = 'local_users_list';
  
  // Kullanıcı durumu
  bool _isLoggedIn = false;
  String? _userId;
  
  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  
  factory AuthService() {
    return _instance;
  }
  
  AuthService._internal();
  
  // Uygulama başlangıcında oturum durumunu kontrol et
  Future<void> init() async {
    try {
      final userIdStr = await _secureStorage.read(key: 'user_id');
      _isLoggedIn = userIdStr != null;
      _userId = userIdStr;
    } catch (e) {
      print('Oturum durumu kontrolünde hata: $e');
      _isLoggedIn = false;
      _userId = null;
    }
  }
  
  // Kullanıcı girişi
  Future<Map<String, dynamic>> signInWithEmailAndPassword(String email, String password) async {
    try {
      // SharedPreferences üzerinden kullanıcılar listesini al
      final prefs = await SharedPreferences.getInstance();
      final usersList = prefs.getStringList(_usersListKey) ?? [];
      
      // Kullanıcıları kontrol et
      for (final userIdStr in usersList) {
        final userData = prefs.getString('$_userKey:$userIdStr');
        if (userData != null) {
          final user = jsonDecode(userData) as Map<String, dynamic>;
          
          if (user['email'] == email) {
            // Şifre kontrolü - gerçek uygulamada güvenli hash kontrolü yapılmalı
            final storedPassword = user['password'];
            if (storedPassword == password) {
              // Başarılı giriş
              _isLoggedIn = true;
              _userId = userIdStr;
              
              // Kullanıcı kimlik bilgilerini güvenli depolamaya kaydet
              await _saveUserCredentials(userIdStr);
              
              // Oturum token'ı oluştur
              final token = _generateToken();
              await _secureStorage.write(key: 'auth_token', value: token);
              
              // Son giriş zamanını güncelle
              user['lastLoginAt'] = DateTime.now().toIso8601String();
              await prefs.setString('$_userKey:$userIdStr', jsonEncode(user));
              
              return {
                'success': true,
                'userId': userIdStr,
                'user': {...user}..remove('password'), // Şifreyi gönderme
              };
            } else {
              // Yanlış şifre
              throw Exception('Incorrect password');
            }
          }
        }
      }
      
      // Kullanıcı bulunamadı
      throw Exception('User not found with this email');
    } catch (e) {
      print('Giriş hatası: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Kullanıcı kaydı
  Future<Map<String, dynamic>> registerWithEmailAndPassword(String email, String password, String name) async {
    try {
      // SharedPreferences üzerinden kullanıcılar listesini al
      final prefs = await SharedPreferences.getInstance();
      final usersList = prefs.getStringList(_usersListKey) ?? [];
      
      // E-posta adresi daha önce kullanılmış mı kontrol et
      for (final userIdStr in usersList) {
        final userData = prefs.getString('$_userKey:$userIdStr');
        if (userData != null) {
          final user = jsonDecode(userData) as Map<String, dynamic>;
          if (user['email'] == email) {
            throw Exception('Email already in use');
          }
        }
      }
      
      // Yeni kullanıcı kimliği oluştur
      final uuid = Uuid();
      final userId = uuid.v4();
      
      // Kullanıcı verilerini oluştur
      final now = DateTime.now().toIso8601String();
      final newUser = {
        'id': userId,
        'email': email,
        'password': password, // Gerçek uygulamada hash kullanılmalı
        'name': name,
        'createdAt': now,
        'lastLoginAt': now,
        'isPremium': false,
        'premiumUntil': null,
        'freeAiChatsRemaining': 3,
        'freeLocationAnalysisRemaining': 2,
        'coins': 0,
      };
      
      // Kullanıcıyı kaydet
      usersList.add(userId);
      await prefs.setStringList(_usersListKey, usersList);
      await prefs.setString('$_userKey:$userId', jsonEncode(newUser));
      
      // Giriş durumunu ayarla
      _isLoggedIn = true;
      _userId = userId;
      
      // Kullanıcı kimlik bilgilerini güvenli depolamaya kaydet
      await _saveUserCredentials(userId);
      
      // Oturum token'ı oluştur
      final token = _generateToken();
      await _secureStorage.write(key: 'auth_token', value: token);
      
      return {
        'success': true,
        'userId': userId,
        'user': {...newUser}..remove('password'), // Şifreyi gönderme
      };
    } catch (e) {
      print('Kayıt hatası: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Kullanıcı çıkışı
  Future<void> signOut() async {
    try {
      _isLoggedIn = false;
      _userId = null;
      await _clearUserCredentials();
    } catch (e) {
      print('Çıkış hatası: $e');
      rethrow;
    }
  }
  
  // Kullanıcı kimlik bilgilerini güvenli depolamaya kaydet
  Future<void> _saveUserCredentials(String uid) async {
    try {
      await _secureStorage.write(key: 'user_id', value: uid);
      await _secureStorage.write(key: 'device_id', value: _generateDeviceId());
    } catch (e) {
      print('Kimlik bilgileri kaydedilemedi: $e');
    }
  }
  
  // Kullanıcı kimlik bilgilerini temizle
  Future<void> _clearUserCredentials() async {
    try {
      await _secureStorage.delete(key: 'user_id');
      await _secureStorage.delete(key: 'auth_token');
    } catch (e) {
      print('Kimlik bilgileri temizlenemedi: $e');
    }
  }
  
  // Cihaz kimliği oluştur
  String _generateDeviceId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  // Oturum token'ı oluştur
  String _generateToken() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }
  
  // Kullanıcı bilgilerini getir
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (!isLoggedIn || _userId == null) return null;
      
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('$_userKey:$_userId');
      
      if (userData == null) return null;
      
      final user = jsonDecode(userData) as Map<String, dynamic>;
      return {...user}..remove('password'); // Şifreyi gönderme
    } catch (e) {
      print('Kullanıcı bilgileri alınamadı: $e');
      return null;
    }
  }
  
  // Kullanıcı token'ını yenile
  Future<String?> refreshToken() async {
    try {
      if (!isLoggedIn) return null;
      
      final token = _generateToken();
      await _secureStorage.write(key: 'auth_token', value: token);
      return token;
    } catch (e) {
      print('Token yenilenemedi: $e');
      return null;
    }
  }
  
  // Kullanıcı token'ını getir
  Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: 'auth_token');
    } catch (e) {
      print('Token alınamadı: $e');
      return null;
    }
  }

  // Kullanıcı bilgilerini güncelle
  Future<bool> updateUserData(Map<String, dynamic> updates) async {
    try {
      if (!isLoggedIn || _userId == null) return false;
      
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('$_userKey:$_userId');
      
      if (userData == null) return false;
      
      final user = jsonDecode(userData) as Map<String, dynamic>;
      final updatedUser = {...user, ...updates};
      
      await prefs.setString('$_userKey:$_userId', jsonEncode(updatedUser));
      return true;
    } catch (e) {
      print('Kullanıcı bilgileri güncellenemedi: $e');
      return false;
    }
  }
} 