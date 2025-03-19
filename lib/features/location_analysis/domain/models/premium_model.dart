import 'package:hive/hive.dart';

part 'premium_model.g.dart';

@HiveType(typeId: 4)
class PremiumModel extends HiveObject {
  @HiveField(0)
  final bool isPremium;

  @HiveField(1)
  final DateTime? premiumUntil;

  @HiveField(2)
  final int freeAiChatsRemaining;

  @HiveField(3)
  final int freeLocationAnalysisRemaining;

  @HiveField(4)
  final int coins;

  @HiveField(5)
  final String? subscriptionType; // 'weekly', 'monthly', null

  @HiveField(6)
  final String? referralCode; // Referans kodu

  @HiveField(7)
  final Map<String, bool> premiumFeatureAccess; // Premium özelliklere erişim hakları

  @HiveField(8)
  final Map<String, dynamic> usageStatistics; // Kullanım istatistikleri

  @HiveField(9)
  final List<Map<String, dynamic>> purchaseHistory; // Satın alma geçmişi

  @HiveField(10)
  final int discountPercentage; // Mevcut indirim yüzdesi

  @HiveField(11)
  final DateTime? discountExpiryDate; // İndirim bitiş tarihi
  
  @HiveField(12)
  final DateTime? lastSyncedAt; // Son sunucu senkronizasyon zamanı
  
  @HiveField(13)
  final String? serverVerificationToken; // Sunucu doğrulama jetonu
  
  @HiveField(14)
  final Map<String, dynamic> securityMetadata; // Güvenlik meta verileri

  @HiveField(15)
  final DateTime? subscriptionEndDate; // Abonelik bitiş tarihi
  
  @HiveField(16)
  final int mogiPoints; // Mogi puanları
  
  @HiveField(17)
  final List<Map<String, dynamic>> coinUsageHistory; // Coin kullanım geçmişi
  
  @HiveField(18)
  final List<Map<String, dynamic>> coinAdditionHistory; // Coin ekleme geçmişi

  @HiveField(19)
  final List<Map<String, dynamic>>? transactionHistory; // İşlem geçmişi
  
  @HiveField(20)
  final String? deviceFingerprint; // Cihaz parmak izi
  
  @HiveField(21)
  final DateTime? lastModified; // Son değişiklik tarihi
  
  @HiveField(22)
  final Map<String, String>? securityHashes; // Güvenlik hash değerleri

  PremiumModel({
    this.isPremium = false,
    this.premiumUntil,
    this.freeAiChatsRemaining = 0,
    this.freeLocationAnalysisRemaining = 0,
    this.coins = 0,
    this.subscriptionType,
    this.referralCode,
    Map<String, bool>? premiumFeatureAccess,
    Map<String, dynamic>? usageStatistics,
    List<Map<String, dynamic>>? purchaseHistory,
    this.discountPercentage = 0,
    this.discountExpiryDate,
    this.lastSyncedAt,
    this.serverVerificationToken,
    Map<String, dynamic>? securityMetadata,
    this.subscriptionEndDate,
    this.mogiPoints = 6,
    this.coinUsageHistory = const [],
    this.coinAdditionHistory = const [],
    this.transactionHistory,
    this.deviceFingerprint,
    this.lastModified,
    this.securityHashes,
  }) : 
      this.premiumFeatureAccess = premiumFeatureAccess ?? {
        'detailedReports': false,
        'prioritySupport': false,
        'advancedAnalytics': false,
        'advancedFilters': false,
        'unlimitedAiChats': false,
        'unlimitedLocationAnalysis': false,
        'exportData': false,
      },
      this.usageStatistics = usageStatistics ?? {
        'totalAiChats': 0,
        'totalLocationAnalysis': 0,
        'lastUsedDate': DateTime.now().toIso8601String(),
        'favoriteFeature': null,
      },
      this.purchaseHistory = purchaseHistory ?? [],
      this.securityMetadata = securityMetadata ?? {
        'lastVerifiedAt': DateTime.now().toIso8601String(),
        'deviceId': null,
        'verificationCount': 0,
        'integrityChecksum': null,
      };

  PremiumModel copyWith({
    bool? isPremium,
    DateTime? premiumUntil,
    int? freeAiChatsRemaining,
    int? freeLocationAnalysisRemaining,
    int? coins,
    String? subscriptionType,
    String? referralCode,
    Map<String, bool>? premiumFeatureAccess,
    Map<String, dynamic>? usageStatistics,
    List<Map<String, dynamic>>? purchaseHistory,
    int? discountPercentage,
    DateTime? discountExpiryDate,
    DateTime? lastSyncedAt,
    String? serverVerificationToken,
    Map<String, dynamic>? securityMetadata,
    DateTime? subscriptionEndDate,
    int? mogiPoints,
    List<Map<String, dynamic>>? coinUsageHistory,
    List<Map<String, dynamic>>? coinAdditionHistory,
    List<Map<String, dynamic>>? transactionHistory,
    String? deviceFingerprint,
    DateTime? lastModified,
    Map<String, String>? securityHashes,
  }) {
    return PremiumModel(
      isPremium: isPremium ?? this.isPremium,
      premiumUntil: premiumUntil ?? this.premiumUntil,
      freeAiChatsRemaining: freeAiChatsRemaining ?? this.freeAiChatsRemaining,
      freeLocationAnalysisRemaining: freeLocationAnalysisRemaining ?? this.freeLocationAnalysisRemaining,
      coins: coins ?? this.coins,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      referralCode: referralCode ?? this.referralCode,
      premiumFeatureAccess: premiumFeatureAccess ?? this.premiumFeatureAccess,
      usageStatistics: usageStatistics ?? this.usageStatistics,
      purchaseHistory: purchaseHistory ?? this.purchaseHistory,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountExpiryDate: discountExpiryDate ?? this.discountExpiryDate,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      serverVerificationToken: serverVerificationToken ?? this.serverVerificationToken,
      securityMetadata: securityMetadata ?? this.securityMetadata,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      mogiPoints: mogiPoints ?? this.mogiPoints,
      coinUsageHistory: coinUsageHistory ?? this.coinUsageHistory,
      coinAdditionHistory: coinAdditionHistory ?? this.coinAdditionHistory,
      transactionHistory: transactionHistory ?? this.transactionHistory,
      deviceFingerprint: deviceFingerprint ?? this.deviceFingerprint,
      lastModified: lastModified ?? this.lastModified,
      securityHashes: securityHashes ?? this.securityHashes,
    );
  }
  
  // Güvenlik doğrulama metodu
  bool verifyIntegrity(String expectedChecksum) {
    // Basit bir bütünlük kontrolü
    if (securityMetadata['integrityChecksum'] == null) {
      return false;
    }
    return securityMetadata['integrityChecksum'] == expectedChecksum;
  }
  
  // Sunucu doğrulama kontrolü
  bool isServerVerified() {
    if (lastSyncedAt == null || serverVerificationToken == null) {
      return false;
    }
    
    // Son 24 saat içinde doğrulanmış mı kontrol et
    final now = DateTime.now();
    final difference = now.difference(lastSyncedAt!);
    return difference.inHours < 24 && serverVerificationToken!.isNotEmpty;
  }
  
  // Varsayılan model oluştur
  static PremiumModel defaultModel() {
    return PremiumModel(
      isPremium: false,
      freeAiChatsRemaining: 0,
      freeLocationAnalysisRemaining: 0,
      coins: 0,
      mogiPoints: 6,
      lastSyncedAt: DateTime.now(),
    );
  }
} 