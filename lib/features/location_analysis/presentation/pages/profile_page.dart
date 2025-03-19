import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../ai_assistant/data/services/chat_history_service.dart';
import '../../../ai_assistant/domain/models/message_model.dart';
import '../../../ai_assistant/presentation/pages/ai_assistant_page.dart';
import '../../data/services/saved_locations_service.dart';
import '../../domain/models/saved_location_model.dart';
import '../widgets/location_card.dart';
import 'location_details_page.dart';
import 'edit_profile_page.dart';
import '../../data/services/profile_service.dart';
import '../../data/services/location_recommendations_service.dart';
import '../../domain/models/recently_viewed_location_model.dart';
import '../../data/services/premium_service.dart';
import '../../data/services/comparison_history_service.dart';
import '../../data/models/comparison_history_model.dart';
import 'chat_history_page.dart';
import 'all_locations_page.dart';
import '../widgets/profile_header_widget.dart';
import '../widgets/saved_locations_widget.dart';
import '../widgets/chat_history_widget.dart';
import '../widgets/comparison_history_widget.dart';
import '../widgets/admin_actions_widget.dart';
import '../widgets/loading_indicator_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Services
  final SavedLocationsService _savedLocationsService = SavedLocationsService();
  final ProfileService _profileService = ProfileService();
  final LocationRecommendationsService _recommendationsService = LocationRecommendationsService();
  final PremiumService _premiumService = PremiumService();
  final ChatHistoryService _chatHistoryService = ChatHistoryService();
  final ComparisonHistoryService _comparisonHistoryService = ComparisonHistoryService();
  
  // State variables
  late String _userName = '';
  late String _userCity = '';
  List<SavedLocationModel> _savedLocations = [];
  List<MessageModel> _chatHistory = [];
  List<ComparisonHistoryModel> _comparisonHistory = [];
  List<RecentlyViewedLocationModel> _recentlyViewedLocations = [];
  bool _isLoading = true;
  String confirmText = '';
  String resetConfirmText = '';
  String mogiConfirmText = '';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('en_US');
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    
    try {
      // PremiumService'i ayrıca başlat
      await _premiumService.init();
      
      await Future.wait([
        _initChatHistory(),
        _initComparisonHistory(),
        _initSavedLocations(),
        _initProfile(),
        _initRecentlyViewedLocations(),
      ]);
      
      // Son mogi puanı durumunu logla
      print('Profil sayfası - Güncel Mogi puanları: ${_premiumService.mogiPoints}');
    } catch (e) {
      print('Profil verilerini yükleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler yüklenirken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initChatHistory() async {
    await _chatHistoryService.init();
    final allThreads = _chatHistoryService.getAllThreads();
    
    setState(() {
      _chatHistory = allThreads
          .where((thread) => thread.isNotEmpty)
          .map((thread) {
            final (message, threadId) = _chatHistoryService.getLastUserMessageAndThreadId(thread);
            return message;
          })
          .where((msg) => msg != null)
          .map((msg) => msg!)
          .toList();
    });
  }

  Future<void> _initComparisonHistory() async {
    await _comparisonHistoryService.init();
    final comparisons = _comparisonHistoryService.getAllComparisons();
    print('COMPARISON HISTORY: Found ${comparisons.length} items');
    if (comparisons.isNotEmpty) {
      print('COMPARISON HISTORY: First item title: ${comparisons.first.title}');
    } else {
      print('COMPARISON HISTORY: No items found');
    }
    setState(() {
      _comparisonHistory = comparisons;
    });
  }

  Future<void> _initSavedLocations() async {
    await _savedLocationsService.init();
    final locations = await _savedLocationsService.getSavedLocations();
    setState(() {
      _savedLocations = locations;
    });
  }

  Future<void> _initProfile() async {
    await _profileService.init();
    final profile = await _profileService.getProfile();
    if (profile != null && mounted) {
      setState(() {
        // Çok uzun değerleri kırp
        if (profile.name.length > 30) {
          _userName = '${profile.name.substring(0, 30)}...';
        } else {
          _userName = profile.name;
        }
        
        if (profile.city.length > 20) {
          _userCity = '${profile.city.substring(0, 20)}...';
        } else {
          _userCity = profile.city;
        }
      });
    }
  }

  Future<void> _initRecentlyViewedLocations() async {
    await _recommendationsService.init();
    final locations = await _recommendationsService.getRecentlyViewedLocations();
    setState(() {
      _recentlyViewedLocations = locations;
    });
  }

  Future<void> _clearChatHistory() async {
    await _chatHistoryService.clearHistory();
    setState(() {
      _chatHistory = [];
    });
  }

  Future<void> _clearComparisonHistory() async {
    await _comparisonHistoryService.clearAllComparisons();
    setState(() {
      _comparisonHistory = [];
    });
  }

  Future<void> _resetPremiumStatus() async {
    // Onay diyalogu göster
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Premium Durumunu Sıfırla', 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF08104F),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Premium durumunu sıfırlamak istediğinizden emin misiniz?',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bu işlem tüm premium özelliklerinizi ve limitlerinizi sıfırlayacaktır.',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              // Güvenlik doğrulama kodu
              const SizedBox(height: 20),
              const Text(
                'Güvenlik doğrulaması için "SIFIRLA" yazın:',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'SIFIRLA',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
                onChanged: (value) {
                  resetConfirmText = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'İptal',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Doğrulama kontrolü
                if (resetConfirmText == 'SIFIRLA') {
                  Navigator.of(context).pop(true);
                } else {
                  // Hatalı doğrulama
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Güvenlik doğrulaması başarısız oldu!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  Navigator.of(context).pop(false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Limitleri Sıfırla'),
            ),
          ],
        );
      },
    );
    
    // Kullanıcı onayladı mı?
    if (confirm != true) {
      return; // Kullanıcı onaylamadı, işlemi iptal et
    }
    
    // Onaydan sonra premium durumunu sıfırla
    try {
      setState(() => _isLoading = true);
      await _premiumService.init();
      
      // İşlemi gerçekleştir ve logla
      print('Premium durumu sıfırlama işlemi başlatılıyor...');
      await _premiumService.resetLimits();
      print('Premium durumu sıfırlama işlemi tamamlandı');
      
      // Kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premium durumu sıfırlandı'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Sayfayı yenile
        await _initData();
      }
    } catch (e) {
      print('Premium durumu sıfırlama hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetMogiPoints() async {
    // Onay diyalogu göster
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mogi Puanlarını Sıfırla', 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF08104F),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mogi puanlarınızı 5\'e sıfırlamak istediğinizden emin misiniz?',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bu işlem geri alınamaz ve mevcut tüm Mogi puanlarınızı kaybedeceksiniz.',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              // Güvenlik doğrulama kodu
              const SizedBox(height: 20),
              const Text(
                'Güvenlik doğrulaması için "PUANISIFIRLA" yazın:',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'PUANISIFIRLA',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.orange),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.orange),
                  ),
                ),
                onChanged: (value) {
                  mogiConfirmText = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'İptal',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Doğrulama kontrolü
                if (mogiConfirmText == 'PUANISIFIRLA') {
                  Navigator.of(context).pop(true);
                } else {
                  // Hatalı doğrulama
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Güvenlik doğrulaması başarısız oldu!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  Navigator.of(context).pop(false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Puanları Sıfırla'),
            ),
          ],
        );
      },
    );
    
    // Kullanıcı onayladı mı?
    if (confirm != true) {
      return; // Kullanıcı onaylamadı, işlemi iptal et
    }
    
    // Onaydan sonra Mogi puanlarını sıfırla
    try {
      setState(() => _isLoading = true);
      await _premiumService.init();
      
      // İşlemi gerçekleştir ve logla
      print('Mogi puanlarını sıfırlama işlemi başlatılıyor...');
      await _premiumService.resetMogiPoints();
      print('Mogi puanlarını sıfırlama işlemi tamamlandı');
      
      // Kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mogi puanları 5\'e sıfırlandı'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Sayfayı yenile
        await _initData();
      }
    } catch (e) {
      print('Mogi puanlarını sıfırlama hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removePremiumStatus() async {
    // Onay diyalogu göster
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Premium Statüsünü Kaldır', 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF08104F),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Premium statüsünü kaldırmak istediğinizden emin misiniz?',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bu işlem geri alınamaz ve premium özelliklerinizi kaybedeceksiniz.',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              // Güvenlik doğrulama kodu
              const SizedBox(height: 20),
              const Text(
                'Güvenlik doğrulaması için "KALDIR" yazın:',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'KALDIR',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.purple),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.purple),
                  ),
                ),
                onChanged: (value) {
                  // Değeri bir değişkende saklayabiliriz ama bu örnek için gerek yok
                  // Doğrulama "OK" düğmesine basıldığında yapılacak
                  confirmText = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'İptal',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Doğrulama kontrolü
                if (confirmText == 'KALDIR') {
                  Navigator.of(context).pop(true);
                } else {
                  // Hatalı doğrulama
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Güvenlik doğrulaması başarısız oldu!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  Navigator.of(context).pop(false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Statüsü Kaldır'),
            ),
          ],
        );
      },
    );
    
    // Kullanıcı onayladı mı?
    if (confirm != true) {
      return; // Kullanıcı onaylamadı, işlemi iptal et
    }
    
    // Onaydan sonra premium statüsünü kaldır
    try {
      setState(() => _isLoading = true);
      await _premiumService.init();
      
      // İşlemi gerçekleştir ve logla
      print('Premium statüsü kaldırma işlemi başlatılıyor...');
      await _premiumService.removePremiumStatus();
      print('Premium statüsü kaldırma işlemi tamamlandı');
      
      // Kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premium statüsü kaldırıldı'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Sayfayı yenile
        await _initData();
      }
    } catch (e) {
      print('Premium statüsü kaldırma hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F1),
      body: SafeArea(
        child: _isLoading 
          ? const LoadingIndicatorWidget()
          : RefreshIndicator(
              onRefresh: _initData,
              child: ListView(
                children: [
                  // Profile Header
                  ProfileHeaderWidget(
                    userName: _userName,
                    userCity: _userCity,
                    savedLocationsCount: _savedLocations.length,
                    chatHistoryCount: _chatHistory.length + _comparisonHistory.length,
                    premiumService: _premiumService,
                    onEditProfile: () => _navigateToEditProfile(context),
                  ),
                  
                  // Saved Locations Section
                  if (_savedLocations.isNotEmpty)
                    SavedLocationsWidget(
                      savedLocations: _savedLocations,
                      onRefresh: _initData,
                    ),
                  
                  // Comparison History Section
                  if (_comparisonHistory.isNotEmpty)
                    ComparisonHistoryWidget(
                      comparisonHistory: _comparisonHistory,
                      onClearHistory: _clearComparisonHistory,
                      comparisonHistoryService: _comparisonHistoryService,
                      onRefresh: _initData,
                    ),
                  
                  // Chat History Section
                  if (_chatHistory.isNotEmpty)
                    ChatHistoryWidget(
                      chatHistory: _chatHistory,
                      onClearHistory: _clearChatHistory,
                      chatHistoryService: _chatHistoryService,
                      onRefresh: _initData,
                    ),
                    
                  const SizedBox(height: 32),
                  
                  // Admin Actions
                  AdminActionsWidget(
                    premiumService: _premiumService,
                    onPremiumStatusChanged: _initData,
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
      ),
    );
  }
  
  void _navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          onProfileUpdated: _initData,
        ),
      ),
    );
  }
} 