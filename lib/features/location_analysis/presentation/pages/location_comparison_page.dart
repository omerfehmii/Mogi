import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/premium_service.dart';
import '../../data/services/comparison_history_service.dart';
import '../../data/models/comparison_history_model.dart';
import '../../../ai_assistant/data/services/location_comparison_service.dart';
import '../widgets/comparison_result_card.dart';
import '../widgets/location_input_card.dart';
import 'premium_page.dart';
import '../../../../core/network/network_connectivity_service.dart';
import '../../../../core/widgets/no_internet_connection_widget.dart';

class LocationComparisonPage extends StatefulWidget {
  final bool fromNavBar;
  
  const LocationComparisonPage({
    Key? key, 
    this.fromNavBar = true,
  }) : super(key: key);

  @override
  State<LocationComparisonPage> createState() => _LocationComparisonPageState();
}

class _LocationComparisonPageState extends State<LocationComparisonPage> {
  final _premiumService = PremiumService();
  final _comparisonService = LocationComparisonService();
  final _historyService = ComparisonHistoryService();
  final _connectivityService = NetworkConnectivityService();
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _locationControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  
  bool _isLoading = false;
  String? _comparisonResult;
  String? _errorMessage;
  final _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
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
          print("Location Comparison: Internet connection restored");
          if (_errorMessage?.contains('İnternet bağlantısı bulunamadı') == true) {
            _errorMessage = null;
            // Sadece internet bağlantısı hatası varsa servisleri yeniden başlat
            _initServices();
          }
        } else {
          // İnternet bağlantısı kesildiğinde UI'ı güncelle
          print("Location Comparison: Internet connection lost");
        }
      });
    }
  }
  
  Future<void> _initServices() async {
    try {
      await _premiumService.init();
      await _comparisonService.init();
      await _historyService.init();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Servisler başlatılamadı: $e';
        });
      }
    }
  }
  
  @override
  void dispose() {
    for (var controller in _locationControllers) {
      controller.dispose();
    }
    _scrollController.dispose();
    _connectivityService.isConnected.removeListener(_onConnectivityChanged);
    super.dispose();
  }
  
  Future<void> _compareLocations() async {
    if (!_formKey.currentState!.validate()) return;
    
    // İnternet bağlantısını kontrol et
    if (!_connectivityService.isConnected.value) {
      setState(() {
        _errorMessage = 'İnternet bağlantısı bulunamadı. Lütfen bağlantınızı kontrol edin ve tekrar deneyin.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _comparisonResult = null;
    });

    try {
      // Premium durumunu kontrol et
      final hasPremiumAccess = await _checkPremiumStatus();
      if (!hasPremiumAccess) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final locations = _locationControllers
          .where((controller) => controller.text.isNotEmpty)
          .map((controller) => controller.text)
          .toList();

      final result = await _comparisonService.compareLocations(locations);

      // Karşılaştırma geçmişine kaydet
      await _historyService.addComparison(
        locations: locations,
        result: result,
      );

      setState(() {
        _comparisonResult = result;
        _isLoading = false;
      });

      // Scroll to the top after getting the result
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<bool> _checkPremiumStatus() async {
    // Premium kullanıcılar için doğrudan true döndür
    if (_premiumService.isPremium) {
      return true;
    }
    
    // Premium olmayan kullanıcılar için Mogi puanı kontrolü
    if (_premiumService.mogiPoints >= 2) { // Karşılaştırma için 2 Mogi puanı gerekiyor
      final success = await _premiumService.useMogiPointsForLocationComparison();
      
      if (success) {
        return true;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mogi puanları kullanılamadı. Lütfen daha sonra tekrar deneyin.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      // Mogi puanı yoksa Premium sayfasına yönlendir - doğrudan widget kullanarak
      if (mounted) {
        // Premium sayfasına yönlendir - animasyonsuz geçiş
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const PremiumPage(),
            transitionDuration: Duration.zero, // Animasyonsuz geçiş için
            reverseTransitionDuration: Duration.zero,
          ),
        );
      }
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: widget.fromNavBar ? null : IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF6339F9), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Location Comparison',
          style: TextStyle(
            color: Color(0xFF08104F),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: !_connectivityService.isConnected.value && _comparisonResult == null
          ? NoInternetConnectionWidget(
              onRetry: () async {
                print("Location Comparison: Retry button pressed, checking connectivity...");
                // Bağlantıyı kontrol et
                await _connectivityService.checkConnectivity();
                
                // Kısa bir bekleme ekleyelim
                await Future.delayed(const Duration(milliseconds: 500));
                
                print("Location Comparison: Connection status after retry: ${_connectivityService.isConnected.value}");
                
                // Her durumda hata mesajını temizleyelim ve servisleri yeniden başlatalım
                setState(() {
                  _errorMessage = null;
                });
                
                // Servisleri yeniden başlat
                _initServices();
              },
              message: 'Konum karşılaştırması için internet bağlantısı gereklidir. Lütfen bağlantınızı kontrol edin ve tekrar deneyin.',
            )
          : GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, widget.fromNavBar ? 16 : 20, 20, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Introduction card
                            _buildIntroductionCard(),
                            
                            const SizedBox(height: 24),
                            
                            // Location inputs
                            _buildLocationInputsSection(),
                            
                            const SizedBox(height: 24),
                            
                            // Comparison results or loading
                            if (_isLoading)
                              _buildLoadingIndicator()
                            else if (_errorMessage != null)
                              _buildErrorMessage()
                            else if (_comparisonResult != null)
                              ComparisonResultCard(result: _comparisonResult!),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_comparisonResult == null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFF9F5F1).withOpacity(0),
                          const Color(0xFFF9F5F1),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: ElevatedButton(
                      onPressed: _isLoading || !_connectivityService.isConnected.value ? null : _compareLocations,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6339F9),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        elevation: 4,
                        shadowColor: const Color(0xFF6339F9).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        minimumSize: const Size.fromHeight(60),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.compare_arrows_rounded),
                          const SizedBox(width: 12),
                          Text(
                            _isLoading 
                                ? "Comparing..." 
                                : !_connectivityService.isConnected.value 
                                    ? "No Internet Connection" 
                                    : "Compare Locations",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: _comparisonResult != null
          ? Container(
              margin: const EdgeInsets.only(bottom: 16, right: 16),
              child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _comparisonResult = null;
                    // Alanları temizle
                    for (var controller in _locationControllers) {
                      controller.clear();
                    }
                  });
                },
                backgroundColor: const Color(0xFF6339F9),
                foregroundColor: Colors.white,
                elevation: 4,
                tooltip: 'New Comparison',
                child: const Icon(Icons.refresh_rounded, size: 24),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
  
  Widget _buildIntroductionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6339F9), Color(0xFF8C6FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6339F9).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.compare_arrows_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                "AI-Powered Comparison",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Enter up to 3 locations to receive a detailed AI comparison across various factors including cost of living, safety, education, transportation, and more.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLocationInputsSection() {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter Locations",
              style: TextStyle(
                color: Color(0xFF08104F),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Provide specific locations for better results (e.g., 'Manhattan, New York' instead of just 'New York')",
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildLocationInput(
              controller: _locationControllers[0],
              hintText: "First location",
              prefixIcon: Icons.place_rounded,
              isRequired: true,
              index: 1,
            ),
            
            const SizedBox(height: 16),
            
            _buildLocationInput(
              controller: _locationControllers[1],
              hintText: "Second location",
              prefixIcon: Icons.place_rounded,
              isRequired: true,
              index: 2,
            ),
            
            const SizedBox(height: 16),
            
            _buildLocationInput(
              controller: _locationControllers[2],
              hintText: "Third location (optional)",
              prefixIcon: Icons.place_rounded,
              isRequired: false,
              index: 3,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLocationInput({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required bool isRequired,
    required int index,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(
          color: Color(0xFF2D3748),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: const Color(0xFF6B7280).withOpacity(0.8),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: const Color(0xFF6339F9),
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
                  onPressed: () {
                    controller.clear();
                    setState(() {});
                  },
                )
              : null,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 50,
            minHeight: 50,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        onChanged: (value) {
          setState(() {});
        },
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Please enter location $index';
          }
          return null;
        },
        textInputAction: index < 3 ? TextInputAction.next : TextInputAction.done,
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6339F9)),
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "Our AI is analyzing your locations",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF08104F),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "This usually takes 15-30 seconds. We're gathering data on living costs, safety, transportation and more.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE53E3E).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53E3E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFE53E3E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                "Error",
                style: TextStyle(
                  color: Color(0xFFE53E3E),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: Color(0xFF4A5568),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _compareLocations,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53E3E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Try Again",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}