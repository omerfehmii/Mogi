import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/premium_service.dart';
import '../../../../core/network/network_connectivity_service.dart';
import '../../../../core/widgets/no_internet_connection_widget.dart';

// Renk paleti tanımlamaları
// Color palette definitions
const Color kPrimaryColor = Color(0xFF6339F9);
const Color kPrimaryLightColor = Color(0xFF8B6AFE);
const Color kPrimaryDarkColor = Color(0xFF4B2CD6);
const Color kAccentColor = Color(0xFFFF781F);
const Color kAccentLightColor = Color(0xFFFF9B5A);
const Color kBackgroundColor = Color(0xFFF8F9FF);
const Color kTextDarkColor = Color(0xFF08104F);
const Color kTextLightColor = Color(0xFF6B7280);
const Color kCardColor = Colors.white;
const Color kSuccessColor = Color(0xFF34D399);
const Color kErrorColor = Color(0xFFEF4444);

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> with SingleTickerProviderStateMixin {
  final _premiumService = PremiumService();
  final _connectivityService = NetworkConnectivityService();
  bool _isLoading = false;
  String? _selectedPackage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isInitialized = false;
  final List<dynamic> _premiumPlans = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
    
    // Listen for connectivity changes
    _connectivityService.isConnected.addListener(_onConnectivityChanged);
    
    // Initialize services
    _initServices();
  }
  
  Future<void> _initServices() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Check connectivity first
      await _connectivityService.checkConnectivity();
      
      if (_connectivityService.isConnected.value) {
        await _premiumService.initialize();
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _onConnectivityChanged() {
    if (mounted) {
      setState(() {
        // If connection is restored and not initialized yet, initialize services
        if (_connectivityService.isConnected.value) {
          print("Premium Page: Internet connection restored");
          // Sadece gerekli durumlarda servisleri yeniden başlatalım
          if (_premiumPlans.isEmpty || _errorMessage != null) {
            _initServices();
          }
        } else {
          print("Premium Page: Internet connection lost");
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _connectivityService.isConnected.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      bottomNavigationBar: !_connectivityService.isConnected.value ? null : Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: BoxDecoration(
          color: kCardColor,
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _selectedPackage == null || _isLoading || !_connectivityService.isConnected.value
                ? null
                : () => _handlePurchase(_selectedPackage!),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: kCardColor,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 5,
              shadowColor: kPrimaryColor.withOpacity(0.5),
              disabledBackgroundColor: kPrimaryColor.withOpacity(0.5),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: kCardColor,
                      strokeWidth: 3,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedPackage != null && (_selectedPackage == 'monthly_premium' || _selectedPackage == 'weekly_premium')
                          ? Icons.star
                          : Icons.star_outline, 
                        size: 20,
                        color: kCardColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedPackage != null && (_selectedPackage == 'monthly_premium' || _selectedPackage == 'weekly_premium')
                          ? 'Purchase Premium'
                          : 'Purchase Mogi Points',
                        style: GoogleFonts.nunitoSans(
                          color: kCardColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
      body: !_connectivityService.isConnected.value
          ? NoInternetConnectionWidget(
              onRetry: () async {
                print("Premium Page: Retry button pressed, checking connectivity...");
                // Bağlantıyı kontrol et
                await _connectivityService.checkConnectivity();
                
                // Kısa bir bekleme ekleyelim
                await Future.delayed(const Duration(milliseconds: 500));
                
                print("Premium Page: Connection status after retry: ${_connectivityService.isConnected.value}");
                
                // Her durumda servisleri yeniden başlatmayı deneyelim
                _initServices();
              },
              message: 'Internet connection is required to view premium options. Please check your connection and try again.',
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
                gradient: RadialGradient(
                  colors: [
                    kPrimaryLightColor.withOpacity(0.2),
                    kPrimaryLightColor.withOpacity(0.0),
                  ],
                ),
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
                gradient: RadialGradient(
                  colors: [
                    kAccentLightColor.withOpacity(0.15),
                    kAccentLightColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Ana içerik
          // Main content
          SafeArea(
            bottom: false,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Üst bar
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: kCardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimaryColor.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.arrow_back_rounded, color: kTextDarkColor),
                              tooltip: 'Back',
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: kCardColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimaryColor.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: kAccentColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.star,
                                    color: kAccentColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_premiumService.mogiPoints} Mogi',
                                  style: TextStyle(
                                    color: kTextDarkColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Başlık
                          // Title
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'MOGI ',
                                  style: GoogleFonts.nunitoSans(
                                    color: kPrimaryColor,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Premium',
                                  style: GoogleFonts.nunitoSans(
                                    color: kTextDarkColor,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedPackage != null && (_selectedPackage == 'monthly_premium' || _selectedPackage == 'weekly_premium')
                              ? 'Subscribe to premium to unlock all features and enhance your experience'
                              : 'Purchase Mogi points to use premium features and enhance your experience',
                            style: GoogleFonts.nunitoSans(
                              color: kTextLightColor,
                              fontSize: 16,
                              height: 1.5,
                              letterSpacing: 0.15,
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Özellikler
                          // Features
                          _buildFeaturesList(),
                          const SizedBox(height: 40),
                          // Mogi paketleri
                          _buildMogiPackages(),
                          const SizedBox(height: 40),
                          // Kullanıcı yorumları
                          // User testimonials
                          _buildTestimonials(),
                          const SizedBox(height: 24),
                          // Güvenlik notu
                          // Security note
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: kCardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: kPrimaryColor.withOpacity(0.1),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: kPrimaryColor.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_rounded,
                                    color: kPrimaryColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Secure payment',
                                    style: TextStyle(
                                      color: kTextLightColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {
        'icon': Icons.chat_bubble_outline_rounded,
        'title': 'AI Chat',
        'description': 'AI assistant available 24/7',
      },
      {
        'icon': Icons.location_on_outlined,
        'title': 'Location Analysis',
        'description': 'Detailed insights for your dream city',
      },
      {
        'icon': Icons.compare_arrows_rounded,
        'title': 'Location Comparison',
        'description': 'Compare multiple locations side by side',
      },
      {
        'icon': Icons.timer_outlined,
        'title': 'Time Saving',
        'description': 'Reduce research time by 70%',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kPrimaryColor,
                    kPrimaryLightColor,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFD700),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                'What You Get',
                    style: GoogleFonts.nunitoSans(
                      color: Colors.white,
                  fontWeight: FontWeight.bold,
                      fontSize: 22,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Premium Features',
                    style: GoogleFonts.nunitoSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.15,
                ),
              ),
            ],
          ),
            ),
          ),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6339F9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: const Color(0xFF6339F9),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'] as String,
                        style: GoogleFonts.nunitoSans(
                          color: const Color(0xFF08104F),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature['description'] as String,
                        style: GoogleFonts.nunitoSans(
                          color: const Color(0xFF08104F).withOpacity(0.7),
                          fontSize: 14,
                          letterSpacing: 0.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildTestimonials() {
    final testimonials = [
      {
        'name': 'Henry P.',
        'rating': 5,
        'text': 'Great👏👏',
        'city': 'Texas',
      },
      {
        'name': 'Michael T.',
        'rating': 5,
        'text': 'The AI chat saved me hours of research. Totally worth it!',
        'city': 'San Francisco',
      },
      {
        'name': 'Emma L.',
        'rating': 4,
        'text': 'Great insights on housing prices and neighborhood safety.',
        'city': 'Chicago',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6339F9).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.people_alt_outlined,
                color: Color(0xFF6339F9),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'What Users Say',
              style: TextStyle(
                color: Color(0xFF08104F),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: testimonials.length,
            itemBuilder: (context, index) {
              final testimonial = testimonials[index];
              return Container(
                width: 280,
                margin: EdgeInsets.only(
                  left: index == 0 ? 0 : 16,
                  right: index == testimonials.length - 1 ? 0 : 0,
                ),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Color(0xFF6339F9).withOpacity(0.1),
                          child: Text(
                            testimonial['name'].toString()[0],
                            style: const TextStyle(
                              color: Color(0xFF6339F9),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              testimonial['name'] as String,
                              style: const TextStyle(
                                color: Color(0xFF08104F),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              testimonial['city'] as String,
                              style: TextStyle(
                                color: Color(0xFF08104F).withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < (testimonial['rating'] as int)
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFFF781F),
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Text(
                        testimonial['text'] as String,
                        style: TextStyle(
                          color: Color(0xFF08104F).withOpacity(0.8),
                          fontSize: 14,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMogiPackages() {
    final packages = [
      {
        'id': 'monthly_premium',
        'isPremium': true,
        'name': 'Premium Monthly',
        'description': 'Monthly Premium Subscription',
        'premium_days': 30,
        'price': 14.99,
        'popular': true,
        'features': ['Unlimited Location Analysis', 'Unlimited AI Chat', 'Detailed Reports', 'Priority Support'],
      },
      {
        'id': 'weekly_premium',
        'isPremium': true,
        'name': 'Premium Weekly',
        'description': 'Weekly Premium Subscription',
        'premium_days': 7,
        'price': 4.99,
        'popular': false,
        'features': ['Unlimited Location Analysis', 'Unlimited AI Chat', 'Detailed Reports', 'Priority Support'],
      },
      {
        'id': 'small',
        'isPremium': false,
        'name': 'Basic Package',
        'coins': 50.0,
        'bonus': 10.0,
        'price': 4.99,
        'popular': false,
      },
      {
        'id': 'medium',
        'isPremium': false,
        'name': 'Value Package',
        'coins': 150.0,
        'bonus': 50.0,
        'price': 9.99,
        'popular': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6339F9).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.star_outline,
                color: Color(0xFF6339F9),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Packages',
              style: GoogleFonts.nunitoSans(
                color: const Color(0xFF08104F),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.25,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Select a package to access premium features',
          style: GoogleFonts.nunitoSans(
            color: Color(0xFF08104F).withOpacity(0.8),
            fontSize: 16,
            letterSpacing: 0.15,
          ),
        ),
        const SizedBox(height: 24),
        
        // Premium paketleri
        ...packages.where((package) => package['isPremium'] == true).map((package) => GestureDetector(
          onTap: () => setState(() {
            _selectedPackage = package['id'] as String;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            transform: Matrix4.identity()..scale(_selectedPackage == package['id'] ? 1.02 : 1.0),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: _selectedPackage == package['id']
                  ? Border.all(color: const Color(0xFFFF781F), width: 2)
                  : Border.all(color: Colors.transparent),
              boxShadow: [
                BoxShadow(
                  color: _selectedPackage == package['id']
                      ? const Color(0xFFFF781F).withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6339F9).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Color(0xFF6339F9),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'PREMIUM',
                                          style: TextStyle(
                                            color: Color(0xFF6339F9),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                package['name'] as String,
                                style: GoogleFonts.nunitoSans(
                                  color: const Color(0xFF08104F),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.25,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                package['id'] == 'monthly_premium' 
                                  ? 'Monthly subscription' 
                                  : 'Weekly subscription',
                                style: GoogleFonts.nunitoSans(
                                  color: const Color(0xFF08104F).withOpacity(0.6),
                                  fontSize: 14,
                                  letterSpacing: 0.25,
                                ),
                              ),
                              if (package['features'] != null) ...[
                                const SizedBox(height: 12),
                                ...((package['features'] as List).map((feature) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF34D399),
                                        size: 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        feature as String,
                                        style: TextStyle(
                                          color: Color(0xFF08104F).withOpacity(0.7),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))).toList(),
                              ],
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(
                                      '\$',
                                      style: TextStyle(
                                        color: Color(0xFF6339F9),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    (package['price'] as num).toInt().toString(),
                                    style: const TextStyle(
                                      color: Color(0xFF6339F9),
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      height: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '.${((package['price'] as num) % 1 * 100).toInt().toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: Color(0xFF6339F9),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  package['id'] == 'monthly_premium' ? '/ monthly' : '/ weekly',
                                  style: const TextStyle(
                                    color: Color(0xFF6339F9),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_selectedPackage == package['id'])
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF781F).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Color(0xFFFF781F),
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Selected',
                                        style: TextStyle(
                                          color: Color(0xFFFF781F),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (package['popular'] as bool)
                  Positioned(
                    top: 0,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF781F),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'MOST POPULAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        )).toList(),
        
        // Ayırıcı
        Container(
          margin: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: const Color(0xFF6339F9).withOpacity(0.1),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6339F9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: const Color(0xFF6339F9),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Mogi Points',
                          style: GoogleFonts.nunitoSans(
                            color: const Color(0xFF6339F9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: const Color(0xFF6339F9).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'One-time purchases for specific features',
                style: GoogleFonts.nunitoSans(
                  color: Color(0xFF08104F).withOpacity(0.7),
                  fontSize: 14,
                  letterSpacing: 0.25,
                ),
              ),
            ],
          ),
        ),
        
        // Mogi puanı paketleri
        ...packages.where((package) => package['isPremium'] != true).map((package) => GestureDetector(
          onTap: () => setState(() {
            _selectedPackage = package['id'] as String;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            transform: Matrix4.identity()..scale(_selectedPackage == package['id'] ? 1.02 : 1.0),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: _selectedPackage == package['id']
                  ? Border.all(color: const Color(0xFFFF781F), width: 2)
                  : Border.all(color: Colors.transparent),
              boxShadow: [
                BoxShadow(
                  color: _selectedPackage == package['id']
                      ? const Color(0xFFFF781F).withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6339F9).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Color(0xFF6339F9),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${(package['coins'] as num).toInt()}',
                                          style: const TextStyle(
                                            color: Color(0xFF6339F9),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (package['bonus'] != null && (package['bonus'] as num) > 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF781F),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '+${(package['bonus'] as num).toInt()}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                package['name'] as String,
                                style: GoogleFonts.nunitoSans(
                                  color: const Color(0xFF08104F),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.25,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'One-time purchase',
                                style: GoogleFonts.nunitoSans(
                                  color: const Color(0xFF08104F).withOpacity(0.6),
                                  fontSize: 14,
                                  letterSpacing: 0.25,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(
                                      '\$',
                                      style: TextStyle(
                                        color: Color(0xFF6339F9),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    (package['price'] as num).toInt().toString(),
                                    style: const TextStyle(
                                      color: Color(0xFF6339F9),
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      height: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '.${((package['price'] as num) % 1 * 100).toInt().toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: Color(0xFF6339F9),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_selectedPackage == package['id'])
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF781F).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Color(0xFFFF781F),
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Selected',
                                        style: TextStyle(
                                          color: Color(0xFFFF781F),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (package['popular'] as bool)
                  Positioned(
                    top: 0,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF781F),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'BEST VALUE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        )).toList(),
      ],
    );
  }

  Future<void> _handlePurchase(String packageId) async {
    // Check internet connection first
    await _connectivityService.checkConnectivity();
    if (!_connectivityService.isConnected.value) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection. Please check your connection and try again.'),
            backgroundColor: kErrorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      bool result;
      
      // Premium paket satın alınacaksa
      // For premium package purchase
      if (packageId == 'weekly_premium' || packageId == 'monthly_premium') {
        String subscriptionType = packageId == 'weekly_premium' ? 'weekly' : 'monthly';
        result = await _premiumService.startSubscription(subscriptionType);
        
        if (mounted && result) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Premium subscription successfully purchased! You can now use all premium features.'),
              backgroundColor: kSuccessColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          
          // Başarılı satın alma sonrası sayfayı kapat
          // Close the page after successful purchase
          if (result) {
            Navigator.pop(context);
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to purchase premium subscription. Please try again.'),
              backgroundColor: kErrorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } 
      // Mogi Points paketi satın alınacaksa
      // For Mogi Points package purchase
      else {
        result = await _premiumService.purchaseMogiPoints(packageId);
        
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result 
                  ? 'Mogi points purchased! You now have ${_premiumService.mogiPoints} Mogi points.'
                : 'Failed to purchase Mogi points. Please try again.'),
              backgroundColor: result ? kSuccessColor : kErrorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
            
            // Başarılı satın alma sonrası sayfayı kapat
            // Close the page after successful purchase
          if (result) {
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: kErrorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
} 