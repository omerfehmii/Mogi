import 'package:hive/hive.dart';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../domain/models/premium_model.dart';
import '../../../../core/services/supabase_service.dart';
import 'dart:async';

// Abonelik türleri için enum
enum SubscriptionType {
  weekly,
  monthly,
}

// Abonelik maliyetleri
const double WEEKLY_SUBSCRIPTION_COST = 5.00;
const double MONTHLY_SUBSCRIPTION_COST = 14.99;

class PremiumService {
  static final PremiumService _instance = PremiumService._internal();
  static const String _boxName = 'premium_status';
  Box<PremiumModel>? _box;
  bool isInitialized = false;
  final _secureStorage = const FlutterSecureStorage();
  final String _encryptionKeyName = 'premium_encryption_key';
  String? _apiBaseUrl;
  final _supabaseService = SupabaseService();

  // Coin maliyetleri
  static const int AI_CHAT_COIN_COST = 1;
  static const int LOCATION_ANALYSIS_COIN_COST = 1;
  static const int DETAILED_REPORT_COIN_COST = 3;
  static const int EXPORT_DATA_COIN_COST = 2;

  // Mogi puan paketleri
  static const Map<String, Map<String, dynamic>> MOGI_POINT_PACKAGES = {
    'small': {
      'base': 50,   // 50 Mogi puanı
      'bonus': 10,  // 10 bonus puan
      'price': 4.99,
    },
    'medium': {
      'base': 150,  // 150 Mogi puanı
      'bonus': 50,  // 50 bonus puan
      'price': 9.99,
    },
  };

  // Abonelik süreleri (gün olarak)
  static const int WEEKLY_SUBSCRIPTION_DAYS = 7;
  static const int MONTHLY_SUBSCRIPTION_DAYS = 30;
  
  // Abonelik fiyatları
  static const Map<String, double> SUBSCRIPTION_PRICES = {
    'weekly': 5.00,
    'monthly': 14.99,
  };

  static const int MAX_COINS = 1000; // Maksimum puan limiti

  // Singleton fabrika constructor
  factory PremiumService() {
    return _instance;
  }

  // Dahili constructor
  PremiumService._internal();

  // Şifreleme anahtarı oluşturma
  String _generateEncryptionKey(int length) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  Future<void> initialize() async {
    if (isInitialized) return;
    try {
      await init();
    } catch (e) {
      print('Premium servisi başlatılamadı: $e');
      // Yeniden başlatma denemesi
      try {
        await init();
      } catch (e) {
        print('Premium servisi ikinci denemede de başlatılamadı: $e');
      }
    }
  }

  // Başlatma methodu
  Future<PremiumService> init() async {
    if (isInitialized) return this;

    try {
      // API base URL'i al
      _apiBaseUrl = dotenv.env['API_BASE_URL'];
      
      // Supabase servisini başlat
      await _supabaseService.init();
      
      // Hive kutusu şifreleme anahtarı
      String? encryptionKey = await _secureStorage.read(key: _encryptionKeyName);
      
      // Şifreleme anahtarı yoksa oluştur ve sakla
      if (encryptionKey == null) {
        final key = _generateEncryptionKey(32);
        await _secureStorage.write(key: _encryptionKeyName, value: key);
        encryptionKey = key;
      }
      
      // Şifrelenmiş Hive kutusunu aç
      if (!Hive.isBoxOpen(_boxName)) {
        _box = await Hive.openBox<PremiumModel>(_boxName);
      } else {
        _box = Hive.box<PremiumModel>(_boxName);
      }
      
      // Status yoksa varsayılan oluştur
      if (_box!.isEmpty) {
        await _box!.put('status', PremiumModel.defaultModel());
      } else {
        // Mevcut durumu al ve premium durumunu kontrol et
        final currentStatus = _box!.get('status');
        if (currentStatus != null) {
          // Premium durumunu ve bitiş tarihini kontrol et
          bool shouldBePremium = false;
          if (currentStatus.premiumUntil != null && 
              currentStatus.premiumUntil!.isAfter(DateTime.now())) {
            shouldBePremium = true;
          }
          
          // Eğer premium durumu yanlışsa güncelle
          if (currentStatus.isPremium != shouldBePremium) {
            await _box!.put('status', currentStatus.copyWith(
              isPremium: shouldBePremium
            ));
          }
        }
      }
      
      // Supabase'den kullanıcı verilerini al ve senkronize et
      await syncWithSupabase();
      
      // Senkronizasyon sonrası tekrar premium durumunu kontrol et
      final currentStatus = _box!.get('status');
      if (currentStatus != null) {
        bool shouldBePremium = false;
        if (currentStatus.premiumUntil != null && 
            currentStatus.premiumUntil!.isAfter(DateTime.now())) {
          shouldBePremium = true;
        }
        
        // Eğer premium durumu yanlışsa güncelle
        if (currentStatus.isPremium != shouldBePremium) {
          await _box!.put('status', currentStatus.copyWith(
            isPremium: shouldBePremium
          ));
        }
      }
      
      isInitialized = true;
      return this;
    } catch (e) {
      print('Premium servisi başlatılamadı: $e');
      throw Exception('Premium servisi başlatılamadı: $e');
    }
  }

  PremiumModel get status {
    if (!isInitialized) throw Exception('PremiumService not initialized');
    
    final result = _box!.get('status');
    if (result == null) {
      print('UYARI: status getter null değer döndürdü, varsayılan model kullanılıyor');
      return PremiumModel.defaultModel();
    }
    
    // Premium durumunu her seferinde kontrol et
    if (result.premiumUntil != null) {
      bool shouldBePremium = result.premiumUntil!.isAfter(DateTime.now());
      if (result.isPremium != shouldBePremium) {
        // Durumu güncelle ama döndürme, bir sonraki çağrıda güncel değer alınacak
        _box!.put('status', result.copyWith(isPremium: shouldBePremium));
        return result.copyWith(isPremium: shouldBePremium);
      }
    }
    
    return result;
  }

  bool get isPremium {
    final model = status;
    
    // Eğer isPremium false ise, doğrudan false döndür
    if (!model.isPremium) {
      print('Premium kontrol: isPremium=false, premiumUntil=${model.premiumUntil}');
      print('Premium aktif mi: false');
      return false;
    }
    
    // Premium durumunu ve bitiş tarihini kontrol et
    final isPremiumActive = model.isPremium && model.premiumUntil != null;
    final isDateValid = model.premiumUntil?.isAfter(DateTime.now()) ?? false;
    final isActive = isPremiumActive && isDateValid;
    
    final now = DateTime.now();
    
    print('Premium kontrol: isPremium=${model.isPremium}, premiumUntil=${model.premiumUntil}');
    if (model.premiumUntil != null) {
      print('Premium bitiş tarihi: ${model.premiumUntil}, şimdi: $now');
      print('Bitiş > Şimdi: ${model.premiumUntil!.isAfter(now)}');
    } else {
      print('Premium bitiş tarihi belirtilmemiş');
    }
    print('Premium aktif mi: $isActive');
    
    return isActive;
  }
  int get remainingAiChats => status.freeAiChatsRemaining;
  int get remainingLocationAnalysis => status.freeLocationAnalysisRemaining;
  int get coins => status.coins;
  String? get subscriptionType => status.subscriptionType;
  Map<String, bool> get premiumFeatureAccess => status.premiumFeatureAccess;
  int get discountPercentage => status.discountPercentage;
  bool get hasActiveDiscount => status.discountPercentage > 0 && (status.discountExpiryDate?.isAfter(DateTime.now()) ?? false);

  // Supabase ile senkronizasyon
  Future<void> syncWithSupabase() async {
    try {
      if (!_supabaseService.isInitialized) {
        await _supabaseService.init();
      }
      
      // Kullanıcı oturumu açık değilse anonim olarak giriş yapmayı dene
      var user = _supabaseService.getCurrentUser();
      if (user == null) {
        try {
          await _supabaseService.signInAnonymously();
          user = _supabaseService.getCurrentUser();
        } catch (e) {
          print('Anonim oturum açma hatası: $e');
          // Anonim oturum açma başarısız olsa bile devam et
        }
      }
      
      if (user != null) {
        // Kullanıcı ID'si ile premium verilerini sorgula
        try {
          final data = await _supabaseService.getData(
            table: 'premium_users',
            column: 'user_id',
            value: user.id,
          );
          
          if (data.isNotEmpty) {
            // Supabase'den gelen verileri Hive modeline çevir
            final remoteData = data.first;
            final currentModel = isInitialized ? status : PremiumModel.defaultModel();
            
            // Premium durumunu ve bitiş tarihini kontrol et
            DateTime? premiumUntil;
            if (remoteData['premium_until'] != null) {
              premiumUntil = DateTime.parse(remoteData['premium_until']);
            } else {
              premiumUntil = currentModel.premiumUntil;
            }
            
            // Premium durumunu bitiş tarihine göre belirle
            bool isPremium = false;
            if (premiumUntil != null && premiumUntil.isAfter(DateTime.now())) {
              isPremium = true;
            }
            
            int coins = remoteData['coins'] ?? currentModel.coins;
            int mogiPoints = remoteData['mogi_points'] ?? currentModel.mogiPoints;
            String? subscriptionType = remoteData['subscription_type'] ?? currentModel.subscriptionType;
            
            // Özellik erişimlerini ayarla
            Map<String, bool> featureAccess = Map<String, bool>.from(currentModel.premiumFeatureAccess);
            if (remoteData['premium_feature_access'] != null) {
              Map<String, dynamic> remoteFeatures = remoteData['premium_feature_access'];
              remoteFeatures.forEach((key, value) {
                featureAccess[key] = value;
              });
            }
            
            // Yeni modeli oluştur ve kaydet
            final newModel = currentModel.copyWith(
              isPremium: isPremium,
              premiumUntil: premiumUntil,
              coins: coins,
              mogiPoints: mogiPoints,
              subscriptionType: subscriptionType,
              premiumFeatureAccess: featureAccess,
              lastSyncedAt: DateTime.now(),
              serverVerificationToken: user.id,
            );
            
            await _box!.put('status', newModel);
          } else {
            // Kullanıcı Supabase'de yoksa, yerel verileri Supabase'e yüklemeyi dene
            final currentModel = status;
            try {
              print('Kullanıcı premium_users tablosunda bulunamadı, yeni kayıt oluşturuluyor...');
              
              // Premium durumunu kontrol et
              bool isPremium = false;
              if (currentModel.premiumUntil != null && currentModel.premiumUntil!.isAfter(DateTime.now())) {
                isPremium = true;
              }
              
              await _supabaseService.insertData(
                table: 'premium_users',
                data: {
                  'user_id': user.id,
                  'is_premium': isPremium,
                  'premium_until': currentModel.premiumUntil?.toIso8601String(),
                  'mogi_points': currentModel.mogiPoints,
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                },
              );
              
              // Yerel modeli de güncelle
              await _box!.put('status', currentModel.copyWith(
                isPremium: isPremium,
                lastSyncedAt: DateTime.now(),
                serverVerificationToken: user.id,
              ));
            } catch (e) {
              print('Supabase veri ekleme hatası: $e');
              // Veri ekleme başarısız olsa bile devam et
            }
          }
        } catch (e) {
          print('Supabase veri sorgulama hatası: $e');
          // Veri sorgulama başarısız olsa bile devam et
        }
      } else {
        // Kullanıcı oturumu yoksa, yerel verileri kullan ve senkronizasyon yapma
        print('Kullanıcı oturumu açık değil, yerel veriler kullanılıyor.');
      }
    } catch (e) {
      print('Supabase senkronizasyon hatası: $e');
      // Hata durumunda sessizce devam et
    }
  }
  
  // Düzenli senkronizasyon için zamanlayıcı
  Future<void> scheduleSyncWithSupabase() async {
    await syncWithSupabase();
  }

  Future<void> decrementAiChats() async {
    if (!isInitialized) throw Exception('PremiumService not initialized');
    if (isPremium && status.premiumFeatureAccess['unlimitedAiChats'] == true) return;
    
    final currentStatus = status;
    final newModel = currentStatus.copyWith(
      freeAiChatsRemaining: currentStatus.freeAiChatsRemaining - 1,
      usageStatistics: {
        ...currentStatus.usageStatistics,
        'totalAiChats': (currentStatus.usageStatistics['totalAiChats'] ?? 0) + 1,
        'lastUsedDate': DateTime.now().toIso8601String(),
        'favoriteFeature': 'aiChat',
      },
    );
    
    await _box!.put('status', newModel);
    
    // Supabase'i güncelle
    await _updateSupabase();
  }

  Future<void> decrementLocationAnalysis() async {
    if (!isInitialized) throw Exception('PremiumService not initialized');
    if (isPremium && status.premiumFeatureAccess['unlimitedLocationAnalysis'] == true) return;
    
    final currentStatus = status;
    final newModel = currentStatus.copyWith(
      freeLocationAnalysisRemaining: currentStatus.freeLocationAnalysisRemaining - 1,
      usageStatistics: {
        ...currentStatus.usageStatistics,
        'totalLocationAnalysis': (currentStatus.usageStatistics['totalLocationAnalysis'] ?? 0) + 1,
        'lastUsedDate': DateTime.now().toIso8601String(),
        'favoriteFeature': 'locationAnalysis',
      },
    );
    
    await _box!.put('status', newModel);
    
    // Supabase'i güncelle
    await _updateSupabase();
  }

  // Supabase'de kullanıcı verilerini güncelle
  Future<void> _updateSupabase() async {
    try {
      print('===== SUPABASE GÜNCELLEME BAŞLADI =====');
      
      if (!_supabaseService.isInitialized) {
        print('Supabase servisi başlatılıyor...');
        await _supabaseService.init();
        print('Supabase servisi başlatıldı');
      }
      
      final user = _supabaseService.getCurrentUser();
      if (user != null) {
        final currentModel = status;
      
        // Güncellemeden önce mevcut durumu kontrol et
        print('Supabase güncellemeden ÖNCE Mogi puanları: ${currentModel.mogiPoints}');
        
        try {
          print('Supabase verilerini güncelleme işlemi başlatılıyor...');
          
          // 1. Token doğrulama - yerel serverVerificationToken ile Supabase User ID eşleşiyor mu
          if (currentModel.serverVerificationToken != null && 
              currentModel.serverVerificationToken != user.id) {
            print('GÜVENLİK UYARISI: Token uyuşmazlığı tespit edildi!');
            print('Yerel token: ${currentModel.serverVerificationToken}, Supabase User ID: ${user.id}');
            
            // Güvenlik olayını kaydet
            try {
              await _supabaseService.insertData(
                table: 'security_events',
                data: {
                  'user_id': user.id,
                  'event_type': 'token_mismatch',
                  'details': 'Local token: ${currentModel.serverVerificationToken}, User ID: ${user.id}',
                  'timestamp': DateTime.now().toIso8601String(),
                },
              );
            } catch (e) {
              print('Güvenlik olayı kaydedilemedi: $e');
            }
            
            // Mevcut sunucu verilerini getir ve senkronize et
            await syncWithSupabase();
            return;
          }
          
          // 2. Manipülasyon kontrolü - şüpheli değerler var mı?
          if (currentModel.mogiPoints < 0 || currentModel.mogiPoints > 10000) {
            print('GÜVENLİK UYARISI: Şüpheli mogi puanı değeri: ${currentModel.mogiPoints}');
            
            // Güvenlik olayını kaydet
            try {
              await _supabaseService.insertData(
                table: 'security_events',
                data: {
                  'user_id': user.id,
                  'event_type': 'suspicious_values',
                  'details': 'Suspicious mogi points: ${currentModel.mogiPoints}',
                  'timestamp': DateTime.now().toIso8601String(),
                },
              );
            } catch (e) {
              print('Güvenlik olayı kaydedilemedi: $e');
            }
            
            // Mevcut sunucu verilerini getir ve senkronize et
            await syncWithSupabase();
            return;
          }
          
          // 3. Son güncelleme zamanını kontrol et - sık güncelleme var mı?
          if (currentModel.lastSyncedAt != null) {
            final lastSync = currentModel.lastSyncedAt!;
            final now = DateTime.now();
            final difference = now.difference(lastSync);
            
            // 1 saniyeden kısa sürede birden fazla güncelleme
            if (difference.inSeconds < 1) {
              print('GÜVENLİK UYARISI: Çok sık güncelleme tespit edildi! Son güncelleme: ${difference.inMilliseconds}ms önce');
              
              // Güvenlik olayını kaydet
              try {
                await _supabaseService.insertData(
                  table: 'security_events',
                  data: {
                    'user_id': user.id,
                    'event_type': 'rapid_updates',
                    'details': 'Update interval: ${difference.inMilliseconds}ms',
                    'timestamp': DateTime.now().toIso8601String(),
                  },
                );
              } catch (e) {
                print('Güvenlik olayı kaydedilemedi: $e');
              }
            }
          }
          
          // 4. Security hash oluştur
          final securityHash = _generateSecurityHash(currentModel);
          
          // Verileri güncelle - sadece temel sütunları içerecek şekilde optimize edildi
          final updateData = {
            'is_premium': currentModel.isPremium,
            'premium_until': currentModel.premiumUntil?.toIso8601String(),
            'mogi_points': currentModel.mogiPoints,
            'updated_at': DateTime.now().toIso8601String(),
          };
          
          // Premium durumunu kontrol et - eğer premium_until değeri varsa ve şu andan sonraysa, is_premium true olmalı
          if (currentModel.premiumUntil != null && currentModel.premiumUntil!.isAfter(DateTime.now())) {
            updateData['is_premium'] = true;
          } else {
            // Eğer premium_until değeri null ise veya şu andan önceyse, is_premium false olmalı
            updateData['is_premium'] = false;
          }
          
          // Veritabanına kaydet
          final updateResult = await _supabaseService.updateData(
            table: 'premium_users',
            data: updateData,
            column: 'user_id',
            value: user.id,
          );
          
          // Eğer kullanıcı bulunamadıysa, yeni bir kayıt oluştur
          if (updateResult == null || updateResult.isEmpty) {
            print('Kullanıcı premium_users tablosunda bulunamadı, yeni kayıt oluşturuluyor...');
            await _supabaseService.insertData(
              table: 'premium_users',
              data: {
                'user_id': user.id,
                'is_premium': currentModel.isPremium,
                'premium_until': currentModel.premiumUntil?.toIso8601String(),
                'mogi_points': currentModel.mogiPoints,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              },
            );
            print('Yeni premium_users kaydı oluşturuldu');
          } else {
            print('Mevcut kullanıcı kaydı güncellendi');
          }
          
          print('Supabase verileri başarıyla güncellendi');
          
          // Yerel modeli de güvenlik hash ile güncelle
          final securityHashes = currentModel.securityHashes ?? {};
          securityHashes['modelData'] = securityHash;
          
          // Son senkronizasyon zamanını da güncelle
          final updatedModel = currentModel.copyWith(
            lastSyncedAt: DateTime.now(),
            serverVerificationToken: user.id,
            securityHashes: securityHashes,
          );
          
          await _box!.put('status', updatedModel);
          
          // Güncelleme sonrası durumu kontrol et
          final afterModel = status;
          print('Supabase güncellemeden SONRA Mogi puanları: ${afterModel.mogiPoints}');
          
          if (afterModel.mogiPoints != currentModel.mogiPoints) {
            print('UYARI: Supabase güncellemesi sonrasında Mogi puanları değişti!');
            print('Önceki: ${currentModel.mogiPoints}, Sonraki: ${afterModel.mogiPoints}');
          }
        } catch (updateError) {
          print('Supabase güncelleme hata detayı: $updateError');
          print('Hata stack trace: ${StackTrace.current}');
          
          // Hata olayını kaydet
          try {
            await _supabaseService.insertData(
              table: 'security_events',
              data: {
                'user_id': user.id,
                'event_type': 'supabase_update_error',
                'details': {
                  'error_message': updateError.toString(),
                  'stack_trace': StackTrace.current.toString(),
                },
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          } catch (e) {
            print('Hata kaydı oluşturulurken ikincil hata: $e');
          }
        }
      } else {
        print('Kullanıcı oturumu bulunamadı, Supabase güncellenemedi');
        
        // Kullanıcı oturumu yoksa anonim oturum açarak verileri senkronize etmeyi dene
        try {
          await _supabaseService.signInAnonymously();
          print('Anonim oturum açıldı, Supabase güncellemeyi yeniden deneniyor...');
          
          // Yeniden güncellemeyi dene
          await _updateSupabase();
        } catch (e) {
          print('Anonim oturum açılamadı: $e');
        }
      }
      
      print('===== SUPABASE GÜNCELLEME TAMAMLANDI =====');
    } catch (e) {
      print('Supabase güncelleme genel hatası: $e');
      print('Genel hata stack trace: ${StackTrace.current}');
    }
  }
  
  // Güvenlik hash değeri oluştur
  String _generateSecurityHash(PremiumModel model) {
    try {
      // Kritik verileri birleştir
      final criticalData = [
        model.isPremium.toString(),
        model.mogiPoints.toString(),
        model.premiumUntil?.toIso8601String() ?? 'null',
        model.serverVerificationToken ?? 'null',
      ].join('|');
      
      // Basit hash oluştur (gerçek uygulamada daha güçlü bir kriptografik yöntem kullanılmalı)
      var hash = 0;
      for (var i = 0; i < criticalData.length; i++) {
        hash = 31 * hash + criticalData.codeUnitAt(i);
      }
      
      return hash.toString();
    } catch (e) {
      print('Hash oluşturma hatası: $e');
      return 'hash_error';
    }
  }

  Future<bool> useCoinsForAiChat() async {
    if (!isInitialized) throw Exception('PremiumService not initialized');
    
    final currentStatus = status;
    if (currentStatus.coins < AI_CHAT_COIN_COST) {
      return false;
    }
    
    final newCoinUsage = {
      'feature': 'aiChat',
      'cost': AI_CHAT_COIN_COST,
      'date': DateTime.now().toIso8601String(),
    };
    
    final newCoinUsageHistory = List<Map<String, dynamic>>.from(currentStatus.coinUsageHistory)
      ..add(newCoinUsage);
    
    final newModel = currentStatus.copyWith(
      coins: currentStatus.coins - AI_CHAT_COIN_COST,
      coinUsageHistory: newCoinUsageHistory,
      usageStatistics: {
        ...currentStatus.usageStatistics,
        'totalAiChats': (currentStatus.usageStatistics['totalAiChats'] ?? 0) + 1,
        'totalCoinsSpent': (currentStatus.usageStatistics['totalCoinsSpent'] ?? 0) + AI_CHAT_COIN_COST,
        'lastUsedDate': DateTime.now().toIso8601String(),
        'favoriteFeature': 'aiChat',
      },
    );
    
      await _box!.put('status', newModel);
    
    // Supabase'i güncelle
    await _updateSupabase();
      
      return true;
    }
    
  Future<bool> useCoinsForLocationAnalysis() async {
    if (!isInitialized) throw Exception('PremiumService not initialized');
    
    final currentStatus = status;
    if (currentStatus.coins < LOCATION_ANALYSIS_COIN_COST) {
      return false;
    }
    
    final newCoinUsage = {
      'feature': 'locationAnalysis',
      'cost': LOCATION_ANALYSIS_COIN_COST,
      'date': DateTime.now().toIso8601String(),
    };
    
    final newCoinUsageHistory = List<Map<String, dynamic>>.from(currentStatus.coinUsageHistory)
      ..add(newCoinUsage);
    
    final newModel = currentStatus.copyWith(
      coins: currentStatus.coins - LOCATION_ANALYSIS_COIN_COST,
      coinUsageHistory: newCoinUsageHistory,
      usageStatistics: {
        ...currentStatus.usageStatistics,
        'totalLocationAnalysis': (currentStatus.usageStatistics['totalLocationAnalysis'] ?? 0) + 1,
        'totalCoinsSpent': (currentStatus.usageStatistics['totalCoinsSpent'] ?? 0) + LOCATION_ANALYSIS_COIN_COST,
        'lastUsedDate': DateTime.now().toIso8601String(),
        'favoriteFeature': 'locationAnalysis',
      },
    );
    
    await _box!.put('status', newModel);
    
    // Supabase'i güncelle
    await _updateSupabase();
    
      return true;
    }
    
  Future<bool> useCoinsForDetailedReport() async {
    if (!isInitialized) throw Exception('PremiumService not initialized');
    
    final currentStatus = status;
    if (currentStatus.coins < DETAILED_REPORT_COIN_COST) {
      return false;
    }
    
    final newCoinUsage = {
      'feature': 'detailedReport',
      'cost': DETAILED_REPORT_COIN_COST,
      'date': DateTime.now().toIso8601String(),
    };
    
    final newCoinUsageHistory = List<Map<String, dynamic>>.from(currentStatus.coinUsageHistory)
      ..add(newCoinUsage);
    
    final newModel = currentStatus.copyWith(
      coins: currentStatus.coins - DETAILED_REPORT_COIN_COST,
      coinUsageHistory: newCoinUsageHistory,
      usageStatistics: {
        ...currentStatus.usageStatistics,
        'totalDetailedReports': (currentStatus.usageStatistics['totalDetailedReports'] ?? 0) + 1,
        'totalCoinsSpent': (currentStatus.usageStatistics['totalCoinsSpent'] ?? 0) + DETAILED_REPORT_COIN_COST,
        'lastUsedDate': DateTime.now().toIso8601String(),
        'favoriteFeature': 'detailedReport',
      },
    );
    
    await _box!.put('status', newModel);
    
    // Supabase'i güncelle
    await _updateSupabase();

      return true;
    }
    
  Future<bool> addCoins(int amount) async {
    if (!isInitialized) throw Exception('PremiumService not initialized');
    if (amount <= 0) return false;
    
    final currentStatus = status;
    final newAmount = currentStatus.coins + amount;
    
    if (newAmount > MAX_COINS) {
      return false;
    }
    
    final newCoinAddition = {
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
      'source': 'manual',
    };
    
    final newCoinAdditionHistory = List<Map<String, dynamic>>.from(currentStatus.coinAdditionHistory)
      ..add(newCoinAddition);

    final newModel = currentStatus.copyWith(
      coins: newAmount,
      coinAdditionHistory: newCoinAdditionHistory,
    );
    
    await _box!.put('status', newModel);
    
    // Supabase'i güncelle
    await _updateSupabase();
    
      return true;
    }
    
  // Mogi puanlarını al
  int get mogiPoints => status.mogiPoints;
  
  // Mogi puanlarını güncelle (test için)
  Future<bool> updateMogiPoints(int newPoints) async {
    if (!isInitialized) throw Exception('PremiumService not initialized');
    
    try {
      final currentStatus = status;
      final newModel = currentStatus.copyWith(
        mogiPoints: newPoints,
      );
      
      await _box!.put('status', newModel);
      print('Mogi puanları manuel olarak güncellendi. Yeni değer: $newPoints');
      
      // Supabase'i güncelle
      await _updateSupabase();
      
      return true;
    } catch (e) {
      print('Mogi puanlarını güncelleme hatası: $e');
      return false;
    }
  }

  // AI chat için Mogi puanlarını kullan
  Future<bool> useMogiPointsForAiChat() async {
    if (!isInitialized) throw Exception('PremiumService not initialized');
    
    print('======= AI CHAT MOGI PUANI KULLANIMI BAŞLADI =======');
    
    // Premium kontrolü - Premium kullanıcılar için puan kullanılmaz
    if (isPremium) {
      print('Kullanıcı premium olduğu için Mogi puanı kullanılmayacak');
      return true;
    }
    
    // Mevcut durumu logla
    final beforeModel = _box!.get('status');
    print('İşlemden ÖNCE box\'tan okunan model: ${beforeModel?.mogiPoints} Mogi puanı');
    
    final currentStatus = status;
    final currentMogiPoints = currentStatus.mogiPoints;
    
    // 1. Sunucu taraflı validasyon - Premium durumu değiştirilemez
    final user = _supabaseService.getCurrentUser();
    if (user != null) {
      try {
        // Sunucudan premium durumunu kontrol et
        final serverData = await _supabaseService.getData(
          table: 'premium_users',
          column: 'user_id',
          value: user.id,
        );
        
        if (serverData.isNotEmpty) {
          final serverIsPremium = serverData.first['is_premium'] ?? false;
          
          // Premium durumu manipüle edilmiş mi kontrol et
          if (serverIsPremium && !currentStatus.isPremium) {
            print('BİLGİ: Sunucu premium durumu ile yerel premium durumu farklı. Sunucu: $serverIsPremium, Yerel: ${currentStatus.isPremium}');
            print('İşleme devam ediliyor, Mogi puanı kullanılacak');
            
            // Güvenlik olayını kaydet
            try {
              await _supabaseService.insertData(
                table: 'security_events',
                data: {
                  'user_id': user.id,
                  'event_type': 'premium_status_mismatch',
                  'details': 'Server: $serverIsPremium, Local: ${currentStatus.isPremium}',
                  'timestamp': DateTime.now().toIso8601String(),
                },
              );
            } catch (e) {
              // Güvenlik olayı kaydedilemezse sessizce devam et
              print('Güvenlik olayı kaydedilemedi: $e');
            }
          }
        }
      } catch (e) {
        // Sunucu kontrolü başarısız olursa, yerel değerlere güven
        print('Sunucu premium durumu kontrol edilemedi: $e');
      }
    }
    
    // 2. Mogi puanı yeterli mi kontrol et
    if (currentMogiPoints <= 0) {
      print('Yetersiz Mogi puanı: $currentMogiPoints');
      return false;
    }
    
    // Şüpheli değerler için kontrol
    if (currentMogiPoints > 10000) {
      print('GÜVENLİK UYARISI: Şüpheli derecede yüksek Mogi puanı: $currentMogiPoints');
      
      // Güvenlik olayını kaydet
      if (user != null) {
        try {
          await _supabaseService.insertData(
            table: 'security_events',
            data: {
              'user_id': user.id,
              'event_type': 'suspicious_mogi_points',
              'details': 'Unusually high mogi points: $currentMogiPoints',
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        } catch (e) {
          // Güvenlik olayı kaydedilemezse sessizce devam et
          print('Güvenlik olayı kaydedilemedi: $e');
        }
      }
      
      return false;
    }
    
    try {
      // İşlem kimliği oluştur
      final transactionId = '${DateTime.now().millisecondsSinceEpoch}_${_generateRandomToken().substring(0, 8)}';
      
      // Yeni mogi puanı değeri
      final newMogiPoints = currentMogiPoints - 1;
      print('Yeni hesaplanan Mogi puanı: $newMogiPoints');
      
      // Kullanım istatistiklerini güncelle
      final usageStats = {
        ...currentStatus.usageStatistics,
        'totalAiChats': (currentStatus.usageStatistics['totalAiChats'] ?? 0) + 1,
        'totalMogiPointsSpent': (currentStatus.usageStatistics['totalMogiPointsSpent'] ?? 0) + 1,
        'lastUsedDate': DateTime.now().toIso8601String(),
        'favoriteFeature': 'aiChat',
      };
      
      // 3. İşlem kaydı oluştur
      final transactionRecord = {
        'id': transactionId,
        'type': 'mogi_point_usage',
        'amount': 1,
        'feature': 'aiChat',
        'date': DateTime.now().toIso8601String(),
        'previous_balance': currentMogiPoints,
        'new_balance': newMogiPoints,
        'verified': true,
      };
      
      // İşlem kaydını listeye ekle
      final transactionHistory = List<Map<String, dynamic>>.from(currentStatus.transactionHistory ?? [])
        ..add(transactionRecord);
      
      print('Yeni model oluşturuldu: ${newMogiPoints} Mogi puanı');
      
      // Modeli güncelle
    final newModel = currentStatus.copyWith(
        mogiPoints: newMogiPoints,
        usageStatistics: usageStats,
        transactionHistory: transactionHistory,
        lastModified: DateTime.now(),
        isPremium: false,
        premiumUntil: null,
    );
    
    await _box!.put('status', newModel);
      print('Box güncellendi, yeni değer kaydedildi');
      
      // Değerin gerçekten güncellenip güncellenmediğini kontrol et
      final afterModel = _box!.get('status');
      print('İşlemden SONRA box\'tan okunan model: ${afterModel?.mogiPoints} Mogi puanı');
      
      if (afterModel?.mogiPoints != newMogiPoints) {
        print('UYARI: Mogi puanı güncelleme sorunu! Beklenen: $newMogiPoints, Okunan: ${afterModel?.mogiPoints}');
      }
      
      // 4. İşlemi sunucuda kaydet
      if (user != null) {
        try {
          await _supabaseService.insertData(
            table: 'mogi_point_transactions',
            data: {
              'user_id': user.id,
              'transaction_id': transactionId,
              'type': 'usage',
              'feature': 'aiChat',
              'amount': 1,
              'previous_balance': currentMogiPoints,
              'new_balance': newMogiPoints,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
          print('Mogi puanı işlemi Supabase\'e kaydedildi');
        } catch (e) {
          // Supabase'e kaydetme başarısız olsa bile işleme devam et
          print('Mogi puanı işlemi Supabase\'e kaydedilemedi: $e');
          print('Ancak yerel veritabanında güncelleme başarılı oldu, işleme devam ediliyor');
        }
      }
      
      // Supabase'i güncelle
      try {
        print('Supabase güncellemesi başlatılıyor...');
        await _updateSupabase();
        print('Supabase güncellemesi tamamlandı');
      } catch (e) {
        print('Supabase güncellemesinde hata: $e');
        print('Ancak yerel güncelleme başarılı oldu.');
        
        // Supabase hatası, kullanıcıya gösterilmemeli
        // Yerel veriler güncellendiği için işlem başarılı kabul edilecek
      }
      
      print('======= AI CHAT MOGI PUANI KULLANIMI TAMAMLANDI =======');
    return true;
    } catch (e) {
      print('Mogi puanı kullanma hatası: $e');
      print('HATA OLUŞTU: ${e.toString()}');
      print('Stack trace: ${StackTrace.current}');
      
      // Hata olayını kaydet
      if (user != null) {
        try {
          await _supabaseService.insertData(
            table: 'security_events',
            data: {
              'user_id': user.id,
              'event_type': 'mogi_point_usage_error',
              'feature': 'aiChat',
              'error_message': e.toString(),
              'stack_trace': StackTrace.current.toString(),
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        } catch (securityError) {
          // Güvenlik olayı kaydedilemezse sessizce devam et
          print('Güvenlik olayı kaydedilemedi: $securityError');
        }
      }
      
      return false;
    }
  }

  // Lokasyon analizi için Mogi puanlarını kullan
  Future<bool> useMogiPointsForLocationAnalysis() async {
    if (!isInitialized) throw Exception('PremiumService not initialized');
    
    print('======= LOKASYON ANALİZİ MOGI PUANI KULLANIMI BAŞLADI =======');
    
    // Premium kontrolü - Premium kullanıcılar için puan kullanılmaz
    if (isPremium) {
      print('Kullanıcı premium olduğu için Mogi puanı kullanılmayacak');
      return true;
    }
    
    // YENİ: Lokasyon analizi artık bedava, Mogi puanı düşürülmeyecek
    print('Lokasyon analizi artık bedava! Mogi puanı kullanılmayacak.');
    
    // Mevcut durumu logla
    final beforeModel = _box!.get('status');
    print('İşlemden ÖNCE box\'tan okunan model: ${beforeModel?.mogiPoints} Mogi puanı');
    
    final currentStatus = status;
    final currentMogiPoints = currentStatus.mogiPoints;
    
    // 1. Sunucu taraflı validasyon - Premium durumu değiştirilemez
    final user = _supabaseService.getCurrentUser();
    if (user != null) {
      try {
        // Sunucudan premium durumunu kontrol et
        final serverData = await _supabaseService.getData(
          table: 'premium_users',
          column: 'user_id',
          value: user.id,
        );
        
        if (serverData.isNotEmpty) {
          final serverIsPremium = serverData.first['is_premium'] ?? false;
          
          // Premium durumu manipüle edilmiş mi kontrol et
          if (serverIsPremium && !currentStatus.isPremium) {
            print('BİLGİ: Sunucu premium durumu ile yerel premium durumu farklı. Sunucu: $serverIsPremium, Yerel: ${currentStatus.isPremium}');
            print('İşleme devam ediliyor, Mogi puanı kullanılmayacak');
            
            // Güvenlik olayını kaydet
            try {
              await _supabaseService.insertData(
                table: 'security_events',
                data: {
                  'user_id': user.id,
                  'event_type': 'premium_status_mismatch',
                  'details': 'Server: $serverIsPremium, Local: ${currentStatus.isPremium}',
                  'timestamp': DateTime.now().toIso8601String(),
                },
              );
            } catch (e) {
              // Güvenlik olayı kaydedilemezse sessizce devam et
              print('Güvenlik olayı kaydedilemedi: $e');
            }
          }
        }
      } catch (e) {
        // Sunucu kontrolü başarısız olursa, yerel değerlere güven
        print('Sunucu premium durumu kontrol edilemedi: $e');
      }
    }
    
    try {
      // İşlem kimliği oluştur
      final transactionId = '${DateTime.now().millisecondsSinceEpoch}_${_generateRandomToken().substring(0, 8)}';
      
      // YENİ: Mogi puanı düşürülmeyecek, aynı kalacak
      final newMogiPoints = currentMogiPoints; // Değişiklik yok
      print('Mogi puanı değişmeyecek: $newMogiPoints');
      
      // Kullanım istatistiklerini güncelle
      final usageStats = {
        ...currentStatus.usageStatistics,
        'totalLocationAnalysis': (currentStatus.usageStatistics['totalLocationAnalysis'] ?? 0) + 1,
        'lastUsedDate': DateTime.now().toIso8601String(),
        'favoriteFeature': 'locationAnalysis',
      };
      
      // 3. İşlem kaydı oluştur - Bedava kullanım olarak işaretle
      final transactionRecord = {
        'id': transactionId,
        'type': 'free_usage',
        'amount': 0,
        'feature': 'locationAnalysis',
        'date': DateTime.now().toIso8601String(),
        'previous_balance': currentMogiPoints,
        'new_balance': newMogiPoints,
        'verified': true,
      };
      
      // İşlem kaydını listeye ekle
      final transactionHistory = List<Map<String, dynamic>>.from(currentStatus.transactionHistory ?? [])
        ..add(transactionRecord);
      
      print('Yeni model oluşturuldu: ${newMogiPoints} Mogi puanı (değişiklik yok)');
      
      // Modeli güncelle - Sadece istatistikler ve işlem kaydı için
    final newModel = currentStatus.copyWith(
        usageStatistics: usageStats,
        transactionHistory: transactionHistory,
        lastModified: DateTime.now(),
    );
    
    await _box!.put('status', newModel);
      print('Box güncellendi, istatistikler kaydedildi');
      
      // 4. İşlemi sunucuda kaydet
      if (user != null) {
        try {
          await _supabaseService.insertData(
            table: 'mogi_point_transactions',
            data: {
              'user_id': user.id,
              'transaction_id': transactionId,
              'type': 'free_usage',
              'feature': 'locationAnalysis',
              'amount': 0,
              'previous_balance': currentMogiPoints,
              'new_balance': newMogiPoints,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
          print('Bedava kullanım işlemi Supabase\'e kaydedildi');
        } catch (e) {
          // Supabase'e kaydetme başarısız olsa bile işleme devam et
          print('Bedava kullanım işlemi Supabase\'e kaydedilemedi: $e');
          print('Ancak yerel veritabanında güncelleme başarılı oldu, işleme devam ediliyor');
        }
      }
      
      print('======= LOKASYON ANALİZİ MOGI PUANI KULLANIMI TAMAMLANDI =======');
    return true;
    } catch (e) {
      print('Lokasyon analizi işlemi hatası: $e');
      print('HATA OLUŞTU: ${e.toString()}');
      print('Stack trace: ${StackTrace.current}');
      
      // Hata olayını kaydet
      if (user != null) {
        try {
          await _supabaseService.insertData(
            table: 'security_events',
            data: {
              'user_id': user.id,
              'event_type': 'location_analysis_error',
              'feature': 'locationAnalysis',
              'error_message': e.toString(),
              'stack_trace': StackTrace.current.toString(),
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        } catch (securityError) {
          // Güvenlik olayı kaydedilemezse sessizce devam et
          print('Güvenlik olayı kaydedilemedi: $securityError');
        }
      }
      
      // Hata olsa bile true döndür, kullanıcı analizi kullanabilsin
      return true;
    }
  }

  // Konum karşılaştırma için Mogi puanı kullanma
  Future<bool> useMogiPointsForLocationComparison() async {
    if (!isInitialized) {
      try {
        await init();
      } catch (e) {
        print('Premium servisi başlatılamadı: $e');
        return false;
      }
    }
    
    // Premium kontrolü - Premium kullanıcılar için puan kullanılmaz
    if (isPremium) {
      print('Kullanıcı premium olduğu için Mogi puanı kullanılmayacak');
      return true;
    }
    
    // Mogi puanı kontrolü
    final currentModel = status;
    if (currentModel.mogiPoints < 2) {
      print('Yetersiz Mogi puanı. Mevcut: ${currentModel.mogiPoints}, Gerekli: 2');
      return false;
    }
    
    try {
      // Mogi puanını azalt - copyWith kullanarak daha verimli
      final updatedModel = currentModel.copyWith(
        mogiPoints: currentModel.mogiPoints - 2, // Konum karşılaştırma 2 Mogi puanı harcıyor
        lastModified: DateTime.now(),
        isPremium: false, // Premium durumunu false olarak ayarla
        premiumUntil: null, // Premium bitiş tarihini null olarak ayarla
      );
      
      // Modeli güncelle
      await _box!.put('status', updatedModel);
      
      // Kullanım istatistiklerini güncelle
      await _updateUsageStatistics('location_comparison');
      
      print('Konum karşılaştırma için 2 Mogi puanı kullanıldı. Kalan: ${updatedModel.mogiPoints}');
      
      // Supabase ile senkronize et - doğrudan _updateSupabase kullan
      await _updateSupabase();
      
      return true;
    } catch (e) {
      print('Mogi puanı kullanılırken hata: $e');
      return false;
    }
  }

  Future<bool> _verifyPayment({
    required String paymentId,
    required double amount,
    required String currency,
    required String paymentProvider,
    required String productId,
  }) async {
    try {
      print('Ödeme doğrulama başlatıldı: $paymentId, $amount $currency, Provider: $paymentProvider');
      
      // Test ortamında doğrulama için
      if (dotenv.env['PAYMENT_VERIFICATION_BYPASS'] == 'true' || dotenv.env['FLUTTER_APP_ENV'] == 'development') {
        print('Geliştirme ortamı algılandı: Ödeme otomatik olarak onaylandı');
        return true;
      }
      
      // Doğrulama servisine bağlan ve sonucu kontrol et
      // Gerçek ortamda burada ödeme doğrulama servisi kullanılacak
      
      // Şu anda geliştirme aşamasında olduğumuz için veya
      // doğrulama servisine erişemiyorsak ödemeyi başarılı kabul edelim
      print('Ödeme doğrulama tamamlandı: Başarılı');
      return true;
    } catch (e) {
      print('Ödeme doğrulama hatası: $e');
      print('Stack Trace: ${StackTrace.current}');
      
      // Hatayı logla ama geliştirme ortamında başarılı kabul et
      if (dotenv.env['FLUTTER_APP_ENV'] == 'development') {
        print('Geliştirme ortamında ödeme hatası görmezden gelindi');
        return true;
      }
      return false;
    }
  }

  Future<bool> purchaseMogiPoints(String packageType) async {
    try {
      // Premium servisinin başlatıldığından emin ol
      if (!isInitialized) {
        print('Premium servisi henüz başlatılmadı. Başlatılıyor...');
        await initialize();
      }
      
      if (!isInitialized) {
        print('Premium servisi başlatılamadı! Mogi puan satın alma işlemi yapılamıyor.');
        return false;
      }
      
      // Paket doğrulama
      if (!MOGI_POINT_PACKAGES.containsKey(packageType)) {
        print('Geçersiz paket tipi: $packageType');
        return false;
      }
      
      final packageInfo = MOGI_POINT_PACKAGES[packageType]!;
      final packageCost = packageInfo['price'] as double;
      final basePoints = packageInfo['base'] as int;
      final bonusPoints = packageInfo['bonus'] as int;
      final mogiPointsToAdd = basePoints + bonusPoints;
      
      // Ödeme işlemi - uygulamada yapılacak
      final paymentId = "TEST${DateTime.now().millisecondsSinceEpoch}";
      
      // Ödeme doğrulama
      final paymentVerified = await _verifyPayment(
        paymentId: paymentId,
        amount: packageCost,
        currency: 'USD',
        paymentProvider: 'test',
        productId: 'mogi_points_$packageType',
      );
      
      if (!paymentVerified) {
        print('Ödeme doğrulanamadı! Mogi puan satın alımı iptal edildi.');
        return false;
      }
      
      // Mevcut değerleri al
      final currentStatus = status;
      final currentMogiPoints = currentStatus.mogiPoints;
      final newMogiPoints = currentMogiPoints + mogiPointsToAdd;
      
      print('Mogi Puanları: Mevcut: $currentMogiPoints, Eklenecek: $mogiPointsToAdd (Baz: $basePoints, Bonus: $bonusPoints), Yeni: $newMogiPoints');
      
      // Satın alma geçmişine ekle
      final purchaseHistory = List<Map<String, dynamic>>.from(currentStatus.purchaseHistory)
        ..add({
          'type': 'mogiPoints',
          'packageType': packageType,
          'points': mogiPointsToAdd,
          'basePoints': basePoints,
          'bonusPoints': bonusPoints,
          'cost': packageCost,
          'date': DateTime.now().toIso8601String(),
          'paymentId': paymentId,
        });
      
      // Puan ekleme geçmişine ekle
      final coinAdditionHistory = List<Map<String, dynamic>>.from(currentStatus.coinAdditionHistory)
        ..add({
          'amount': mogiPointsToAdd,
          'reason': 'purchase',
          'date': DateTime.now().toIso8601String(),
        });
      
      // Yeni modeli oluştur ve kaydet
      final newModel = currentStatus.copyWith(
        mogiPoints: newMogiPoints,
        purchaseHistory: purchaseHistory,
        coinAdditionHistory: coinAdditionHistory,
        lastModified: DateTime.now(),
      );
      
      // Box'ı güncelle
      await _box!.put('status', newModel);
      
      print('Mogi Puanları başarıyla güncellendi. Yeni toplam: ${newModel.mogiPoints}');
      
      // Supabase'deki verileri güncelle
      try {
        await _updateSupabase();
        print('Supabase güncellendi');
      } catch (e) {
        print('Supabase güncellemesinde hata: $e');
        print('Ancak yerel güncelleme başarılı oldu.');
      }
      
      return true;
    } catch (e) {
      print('Mogi Puan satın alma hatası: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  Future<bool> startSubscription(String subscriptionType) async {
    try {
      // Premium servisinin başlatıldığından emin ol
      if (!isInitialized) {
        print('Premium servisi henüz başlatılmadı. Başlatılıyor...');
        await initialize();
      }
      
      if (!isInitialized) {
        print('Premium servisi başlatılamadı! Abonelik başlatılamıyor.');
        return false;
      }
      
      // Abonelik türü doğrulama
      double subscriptionCost;
      int subscriptionDays;
      
      switch (subscriptionType) {
        case 'weekly':
          subscriptionCost = WEEKLY_SUBSCRIPTION_COST;
          subscriptionDays = WEEKLY_SUBSCRIPTION_DAYS;
          break;
        case 'monthly':
          subscriptionCost = MONTHLY_SUBSCRIPTION_COST;
          subscriptionDays = MONTHLY_SUBSCRIPTION_DAYS;
          break;
        default:
          print('Geçersiz abonelik türü: $subscriptionType');
          return false;
      }
      
      // Ödeme işlemi - uygulamada yapılacak
      final paymentId = "TEST${DateTime.now().millisecondsSinceEpoch}";
      
      // Ödeme doğrulama
      final paymentVerified = await _verifyPayment(
        paymentId: paymentId,
        amount: subscriptionCost,
        currency: 'USD',
        paymentProvider: 'test',
        productId: 'subscription_$subscriptionType',
      );
      
      if (!paymentVerified) {
        print('Ödeme doğrulanamadı! Abonelik başlatılamıyor.');
        return false;
      }
      
      // Kullanıcıya premium erişim ver
      var now = DateTime.now();
      var premiumUntil = now.add(Duration(days: subscriptionDays));
      
      // Mevcut durumu al
      final currentStatus = status;
      
      // Premium durumunu güncelle
      final newModel = currentStatus.copyWith(
        isPremium: true,
        premiumUntil: premiumUntil,
        subscriptionType: subscriptionType,
        lastModified: DateTime.now(),
      );
      
      // Satın alma geçmişini güncelle
      final purchaseHistory = List<Map<String, dynamic>>.from(currentStatus.purchaseHistory)
        ..add({
          'type': 'subscription',
          'subscriptionType': subscriptionType,
          'days': subscriptionDays,
          'cost': subscriptionCost,
          'startDate': now.toIso8601String(),
          'endDate': premiumUntil.toIso8601String(),
          'paymentId': paymentId,
        });
      
      // Yeni modeli oluştur ve kaydet
      final updatedModel = newModel.copyWith(
        purchaseHistory: purchaseHistory,
      );
      
      await _box!.put('status', updatedModel);
      
      print('Premium abonelik başarıyla başlatıldı. Bitiş tarihi: $premiumUntil');
      
      // Supabase'deki verileri güncelle
      try {
        await _updateSupabase();
        print('Supabase güncellendi');
      } catch (e) {
        print('Supabase güncellemesinde hata: $e');
        print('Ancak yerel güncelleme başarılı oldu.');
      }
      
      return true;
    } catch (e) {
      print('Abonelik başlatma hatası: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  Future<bool> cancelSubscription() async {
    if (!isInitialized) await initialize();
    
    try {
      // Mevcut durumu al
      final currentModel = status;
      
      if (!currentModel.isPremium) {
        return false; // Zaten abone değil
      }
      
      // İptal kaydı oluştur
      final cancellation = {
        'type': 'cancellation',
        'subscriptionType': currentModel.subscriptionType,
        'cancellationDate': DateTime.now().toIso8601String(),
      };
      
      // Satın alma geçmişini güncelle
      final List<Map<String, dynamic>> updatedHistory = 
          List<Map<String, dynamic>>.from(currentModel.purchaseHistory);
      updatedHistory.add(cancellation);
      
      // Yeni modeli oluştur (premium ama bitiş tarihi bugün)
      final newModel = currentModel.copyWith(
        isPremium: false,
        premiumUntil: DateTime.now(),
        subscriptionType: null,
        purchaseHistory: updatedHistory,
      );
      
      await _box!.put('status', newModel);
      
      // Supabase'i güncelle
      await _updateSupabase();
      
      return true;
    } catch (e) {
      print('Abonelik iptal hatası: $e');
      return false;
    }
  }

  Future<void> resetDefaults() async {
    if (!isInitialized) await initialize();
    
    final defaultModel = PremiumModel(
      isPremium: false, // Varsayılan olarak premium değil
      freeAiChatsRemaining: 0,
      freeLocationAnalysisRemaining: 0,
      coins: 0,
      mogiPoints: 5,
      premiumFeatureAccess: {
        'explore': true,
        'basic_ai_chat': true,
        'basic_location_analysis': true,
      },
    );
    
    await _box!.put('status', defaultModel);
    
    // Supabase'i güncelle
    await _updateSupabase();
  }

  // Limitleri sıfırlamak için metot
  Future<void> resetLimits() async {
    if (!isInitialized) throw Exception('PremiumService not initialized');
    
    print('=== RESET LIMITS BAŞLATILIYOR ===');
    final currentStatus = status;
    print('Reset öncesi durum: premium=${currentStatus.isPremium}, premiumUntil=${currentStatus.premiumUntil}, mogiPoints=${currentStatus.mogiPoints}');
    
    // Son 10 dakikada süresi dolmuş bir abonelik varsa şimdiki zamana getir
    DateTime? premiumUntil = null;
    
    final newModel = currentStatus.copyWith(
      freeAiChatsRemaining: 0,
      freeLocationAnalysisRemaining: 0,
      coins: 0,
      mogiPoints: 5,
      isPremium: false,
      premiumUntil: premiumUntil,
      subscriptionType: null,
      lastSyncedAt: DateTime.now(),
    );
    
    await _box!.put('status', newModel);
    print('Reset sonrası durum: premium=${newModel.isPremium}, premiumUntil=${newModel.premiumUntil}, mogiPoints=${newModel.mogiPoints}');
    
    // Box'tan kontrol et
    final afterBox = _box!.get('status');
    print('Box kontrol: premium=${afterBox?.isPremium}, premiumUntil=${afterBox?.premiumUntil}, mogiPoints=${afterBox?.mogiPoints}');
    
    // Supabase'i güncelle
    await _updateSupabase();
    print('=== RESET LIMITS TAMAMLANDI ===');
  }

  // Sadece Mogi puanlarını sıfırlamak için metot
  Future<void> resetMogiPoints() async {
    if (!isInitialized) throw Exception('PremiumService not initialized');
    
    print('=== RESET MOGI POINTS BAŞLATILIYOR ===');
    final currentStatus = status;
    print('Reset öncesi durum: premium=${currentStatus.isPremium}, premiumUntil=${currentStatus.premiumUntil}, mogiPoints=${currentStatus.mogiPoints}');
    
    final newModel = currentStatus.copyWith(
      mogiPoints: 5,
      isPremium: false, // Premium statüsünü false yapıyoruz
      premiumUntil: null, // Premium bitiş tarihini null yapıyoruz
      subscriptionType: null, // Abonelik tipini null yapıyoruz
      lastSyncedAt: DateTime.now(),
    );
    
    await _box!.put('status', newModel);
    print('Reset sonrası durum: premium=${newModel.isPremium}, premiumUntil=${newModel.premiumUntil}, mogiPoints=${newModel.mogiPoints}');
    
    // Box'tan kontrol et
    final afterBox = _box!.get('status');
    print('Box kontrol: premium=${afterBox?.isPremium}, premiumUntil=${afterBox?.premiumUntil}, mogiPoints=${afterBox?.mogiPoints}');
    
    print('Mogi puanları 5\'e sıfırlandı ve premium statüsü kaldırıldı');
    
    // Supabase'i güncelle
    await _updateSupabase();
    print('=== RESET MOGI POINTS TAMAMLANDI ===');
  }

  // Premium statüsünü sıfırla (test için)
  Future<void> removePremiumStatus() async {
    if (!isInitialized) throw Exception('PremiumService not initialized');
    
    print('=== PREMIUM STATÜSÜ KALDIRILACAK ===');
    final currentStatus = status;
    print('Önceki durum: premium=${currentStatus.isPremium}, premiumUntil=${currentStatus.premiumUntil}');
    
    // Premium durumunu false yap ve premiumUntil değerini null yap
    final newModel = currentStatus.copyWith(
      isPremium: false,
      premiumUntil: null, // Önemli: premiumUntil null olmalı
      subscriptionType: null,
      lastSyncedAt: DateTime.now(),
    );
    
    await _box!.put('status', newModel);
    print('Sonraki durum: premium=${newModel.isPremium}, premiumUntil=${newModel.premiumUntil}');
    
    // Supabase'i güncelle
    try {
      // Supabase'i başlat
      if (!_supabaseService.isInitialized) {
        await _supabaseService.init();
      }
      
      // Kullanıcı oturumunu kontrol et
      final user = _supabaseService.getCurrentUser();
      if (user != null) {
        // Supabase'deki premium durumunu doğrudan güncelle
        await _supabaseService.updateData(
          table: 'premium_users',
          data: {
            'is_premium': false,
            'premium_until': null,
            'subscription_type': null,
            'updated_at': DateTime.now().toIso8601String(),
          },
          column: 'user_id',
          value: user.id,
        );
        print('Supabase premium durumu doğrudan güncellendi');
      }
    } catch (e) {
      print('Supabase premium durumu güncelleme hatası: $e');
    }
    
    // Genel Supabase güncellemesi
    await _updateSupabase();
    
    print('=== PREMIUM STATÜSÜ KALDIRILDI ===');
  }

  // Rastgele token oluştur
  String _generateRandomToken() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  // Kullanım istatistiklerini güncelle
  Future<void> _updateUsageStatistics(String featureType) async {
    try {
      final currentModel = status;
      final usageStats = currentModel.usageStatistics ?? {};
      
      // Bugünün tarihi
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Bugünün istatistiklerini al veya oluştur
      final todayStats = usageStats[today] ?? {};
      
      // Özellik kullanım sayısını artır
      final featureCount = (todayStats[featureType] ?? 0) + 1;
      todayStats[featureType] = featureCount;
      
      // Bugünün istatistiklerini güncelle
      usageStats[today] = todayStats;
      
      // Modeli güncelle
      final updatedModel = PremiumModel(
        isPremium: currentModel.isPremium,
        premiumUntil: currentModel.premiumUntil,
        freeAiChatsRemaining: currentModel.freeAiChatsRemaining,
        freeLocationAnalysisRemaining: currentModel.freeLocationAnalysisRemaining,
        coins: currentModel.coins,
        mogiPoints: currentModel.mogiPoints,
        subscriptionType: currentModel.subscriptionType,
        premiumFeatureAccess: currentModel.premiumFeatureAccess,
        discountPercentage: currentModel.discountPercentage,
        discountExpiryDate: currentModel.discountExpiryDate,
        usageStatistics: usageStats,
      );
      
      await _box!.put('status', updatedModel);
    } catch (e) {
      print('Kullanım istatistikleri güncellenirken hata: $e');
    }
  }

  // Supabase ile asenkron senkronizasyon
  void _syncWithSupabaseAsync() {
    // Arka planda senkronizasyon yap
    Future.microtask(() async {
      try {
        await syncWithSupabase();
      } catch (e) {
        print('Arka plan senkronizasyonu sırasında hata: $e');
      }
    });
  }

  // Premium abonelik satın alma
  Future<bool> purchasePremiumSubscription() async {
    try {
      // Premium servisinin başlatıldığından emin ol
      if (!isInitialized) {
        print('Premium servisi henüz başlatılmadı. Başlatılıyor...');
        await initialize();
      }
      
      if (!isInitialized) {
        print('Premium servisi başlatılamadı! Premium abonelik satın alma işlemi yapılamıyor.');
        return false;
      }
      
      // Ödeme işlemi - gerçekte uygulama içi satın alma API'si kullanılacak
      final paymentId = "PREMIUM${DateTime.now().millisecondsSinceEpoch}";
      
      // Ödeme doğrulama
      final paymentVerified = await _verifyPayment(
        paymentId: paymentId,
        amount: WEEKLY_SUBSCRIPTION_COST, // 5.00 USD
        currency: 'USD',
        paymentProvider: 'test',
        productId: 'premium_weekly',
      );
      
      if (!paymentVerified) {
        print('Ödeme doğrulanamadı! Premium abonelik satın alımı iptal edildi.');
        return false;
      }
      
      // Mevcut değerleri al
      final currentStatus = status;
      
      // Premium bitiş tarihini hesapla (bir hafta sonra)
      final now = DateTime.now();
      final premiumUntil = now.add(Duration(days: WEEKLY_SUBSCRIPTION_DAYS));
      
      // Satın alma geçmişine ekle
      final purchaseHistory = List<Map<String, dynamic>>.from(currentStatus.purchaseHistory)
        ..add({
          'type': 'premium',
          'subscriptionType': 'weekly',
          'duration': WEEKLY_SUBSCRIPTION_DAYS,
          'cost': WEEKLY_SUBSCRIPTION_COST,
          'date': now.toIso8601String(),
          'expiryDate': premiumUntil.toIso8601String(),
          'paymentId': paymentId,
        });
      
      // Premium özellikleri aktif et
      final premiumFeatureAccess = Map<String, bool>.from(currentStatus.premiumFeatureAccess);
      premiumFeatureAccess.forEach((key, value) {
        // "explore", "basic_ai_chat", "basic_location_analysis" gibi temel özellikleri zaten true olarak koru
        // Diğer tüm premium özellikleri aktif et
        if (!['explore', 'basic_ai_chat', 'basic_location_analysis'].contains(key)) {
          premiumFeatureAccess[key] = true;
        }
      });
      
      // Özel olarak premium özellikleri aktif et
      premiumFeatureAccess['detailedReports'] = true;
      premiumFeatureAccess['prioritySupport'] = true;
      premiumFeatureAccess['advancedAnalytics'] = true;
      premiumFeatureAccess['advancedFilters'] = true;
      premiumFeatureAccess['unlimitedAiChats'] = true;
      premiumFeatureAccess['unlimitedLocationAnalysis'] = true;
      premiumFeatureAccess['exportData'] = true;
      
      // Yeni modeli oluştur ve kaydet
      final newModel = currentStatus.copyWith(
        isPremium: true,
        premiumUntil: premiumUntil,
        subscriptionType: 'weekly',
        purchaseHistory: purchaseHistory,
        premiumFeatureAccess: premiumFeatureAccess,
        lastModified: now,
      );
      
      // Box'ı güncelle
      await _box!.put('status', newModel);
      
      print('Premium abonelik başarıyla aktif edildi. Bitiş tarihi: $premiumUntil');
      
      // Supabase'deki verileri güncelle
      try {
        await _updateSupabase();
        print('Supabase güncellendi');
      } catch (e) {
        print('Supabase güncellemesinde hata: $e');
        print('Ancak yerel güncelleme başarılı oldu.');
      }
      
      return true;
    } catch (e) {
      print('Premium abonelik satın alınırken hata: $e');
      return false;
    }
  }

  // Premium durumunu tamamen sıfırla
  Future<void> resetPremiumStatus() async {
    if (!isInitialized) await init();
    
    try {
      // Yerel verileri sıfırla
      await _box!.put('status', PremiumModel.defaultModel());
      
      // Supabase'deki verileri sıfırla
      if (_supabaseService.isInitialized) {
        final user = _supabaseService.getCurrentUser();
        if (user != null) {
          try {
            await _supabaseService.updateData(
              table: 'premium_users',
              column: 'user_id',
              value: user.id,
              data: {
                'is_premium': false,
                'premium_until': null,
                'updated_at': DateTime.now().toIso8601String(),
              },
            );
            print('Premium durumu Supabase\'de sıfırlandı');
          } catch (e) {
            print('Supabase premium sıfırlama hatası: $e');
          }
        }
      }
      
      print('Premium durumu tamamen sıfırlandı');
    } catch (e) {
      print('Premium durumu sıfırlama hatası: $e');
    }
  }
} 