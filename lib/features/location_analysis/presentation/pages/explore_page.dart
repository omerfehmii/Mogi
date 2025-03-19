import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/location_card.dart';
import '../widgets/border_light_effect.dart';
import 'location_details_page.dart';
import 'map_page.dart';
import '../../../ai_assistant/presentation/pages/ai_assistant_page.dart';
import '../../data/services/places_service.dart';
import '../../data/services/location_recommendations_service.dart';
import '../../data/services/profile_service.dart';
import 'all_recommendations_page.dart';
import '../../data/services/premium_service.dart';
import 'premium_page.dart';
import 'location_comparison_page.dart';
import '../widgets/latest_comparison_widget.dart';
import '../widgets/explore_comparison_widget.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late MapController mapController;
  final PlacesService _placesService = PlacesService();
  final LocationRecommendationsService _recommendationsService = LocationRecommendationsService();
  final ProfileService _profileService = ProfileService();
  final List<Map<String, dynamic>> _locations = [];
  final List<Map<String, dynamic>> _recommendedLocations = [];
  bool _isLoading = false;
  int _currentPage = 0;
  static const int _locationsPerPage = 6;
  String _userCity = 'İstanbul';
  LatLng _center = const LatLng(41.0082, 28.9784); // Varsayılan olarak İstanbul
  final _mapController = MapController();
  final _premiumService = PremiumService();
  bool _isSearching = false;
  String _searchQuery = '';
  List<dynamic> _searchResults = [];

  final Map<String, LatLng> _cityCoordinates = {
    'İstanbul': const LatLng(41.0082, 28.9784),
    'Ankara': const LatLng(39.9334, 32.8597),
    'İzmir': const LatLng(38.4237, 27.1428),
    'Bursa': const LatLng(40.1885, 29.0610),
    'Antalya': const LatLng(36.8969, 30.7133),
  };

  bool _isLoadingRecommendations = false;
  String? _recommendationsError;

  @override
  void initState() {
    super.initState();
    _initProfile();
    _loadLocations();
    _loadRecommendedLocations();
    mapController = MapController();
    _initServices();
  }

  Future<void> _initProfile() async {
    try {
      await _profileService.init();
      final profile = await _profileService.getProfile();
      if (profile != null && mounted) {
        setState(() {
          _userCity = profile.city;
          _center = _cityCoordinates[profile.city] ?? _center;
        });
      }
    } catch (e) {
      print('Profil yüklenirken hata: $e');
    }
  }

  Future<void> _loadLocations() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _placesService.init();
      final localities = await _placesService.getLocalities(
        _center.latitude,
        _center.longitude,
        page: _currentPage,
      );

      final newLocations = localities.map((locality) {
        return {
          'name': locality['name'],
          'description': locality['formattedAddress'] ?? locality['vicinity'] ?? '',
          'imageUrl': 'assets/images/default_location.png',
          'securityScore': locality['rating'] ?? 4.0,
          'transportScore': (locality['rating'] ?? 4.0) * 0.8,
          'location': LatLng(
            locality['location']['lat'],
            locality['location']['lng'],
          ),
          'type': locality['type'],
        };
      }).toList();

      if (mounted) {
        setState(() {
          _locations.addAll(newLocations);
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Bölgeler yüklenirken hata: $e');
    }
  }

  Future<void> _loadRecommendedLocations() async {
    if (!mounted || _isLoadingRecommendations) return;
    
    setState(() {
      _isLoadingRecommendations = true;
      _recommendationsError = null;
    });

    try {
      print('Kişiselleştirilmiş öneriler yükleniyor...');
      
      // Servisin başlatıldığından emin ol
      await _recommendationsService.init();
      
      // Önerileri al
      final recommendations = await _recommendationsService.getPersonalizedRecommendations();
      
      print('Alınan öneri sayısı: ${recommendations.length}');
      
      if (!mounted) return;
      
      setState(() {
        _recommendedLocations.clear();
        
        // Önerileri dönüştür ve ekle
        for (final location in recommendations) {
          try {
            _recommendedLocations.add({
              'id': location.id,
              'name': location.name,
              'description': location.description,
              'imageUrl': location.imageUrl,
              'location': {
                'latitude': location.latitude,
                'longitude': location.longitude,
              },
              'type': location.type,
              'scores': location.scores,
            });
          } catch (e) {
            print('Öneri dönüştürülürken hata: $e');
            // Hatalı öneriyi atla
            continue;
          }
        }
        
        _isLoadingRecommendations = false;
        _recommendationsError = null;
      });
      
      print('State\'te güncellenen öneri sayısı: ${_recommendedLocations.length}');
    } catch (e, stackTrace) {
      print('Öneriler yüklenirken hata: $e');
      print('Stack trace: $stackTrace');
      
      if (!mounted) return;
      
      setState(() {
        _recommendationsError = 'Önerilen bölgeler yüklenirken bir hata oluştu. Lütfen tekrar deneyin.';
        _isLoadingRecommendations = false;
      });
    }
  }

  Future<void> _initServices() async {
    try {
      await _premiumService.init();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Premium servis başlatılamadı: $e');
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: const Color(0xFFF9F5F1),
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 0,
                pinned: true,
                floating: true,
                elevation: 0,
                expandedHeight: 80,
                toolbarHeight: 80,
                flexibleSpace: FlexibleSpaceBar(
                  expandedTitleScale: 1.0,
                  background: SafeArea(
                    child: Container(
                      color: const Color(0xFFF9F5F1),
                      padding: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).colorScheme.primary,
                                  letterSpacing: 2,
                                  fontFamily: 'Satoshi',
                                ),
                                children: const [
                                  TextSpan(text: 'MOGI'),
                                  TextSpan(
                                    text: 'AI',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFFF781F),
                                      fontFamily: 'Satoshi',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PremiumPage(),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: Ink(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF6B2C),
                                        Color(0xFFFF8F4C),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${_premiumService.isInitialized ? _premiumService.mogiPoints : 0} Mogi',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          letterSpacing: 0.2,
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
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    width: double.infinity,
                    height: 1,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // AI Assistant Card
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: BorderLightEffect(
                    lightColor: Colors.white,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6339F9),
                            Color(0xFF8B6DFA),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6339F9).withOpacity(0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AIAssistantPage(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.assistant,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ask AI Assistant',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'You can ask me anything about the area',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Hızlı Sorular
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Questions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF08104F),
                            ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildQuickQuestion(
                              question: 'Safest neighborhoods',
                              icon: Icons.security,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AIAssistantPage(
                                      initialMessage: 'What are the safest neighborhoods in $_userCity? Can you provide detailed information?',
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildQuickQuestion(
                              question: 'Ideal areas for students',
                              icon: Icons.school,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AIAssistantPage(
                                      initialMessage: 'What are the most ideal neighborhoods for students in $_userCity? Can you evaluate them in terms of transportation, social amenities, and economics?',
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildQuickQuestion(
                              question: 'Investment area recommendations',
                              icon: Icons.trending_up,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AIAssistantPage(
                                      initialMessage: 'Which areas in $_userCity show promise for future investment? Can you evaluate them in terms of real estate investment?',
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildQuickQuestion(
                              question: 'Areas with easy transportation',
                              icon: Icons.directions_subway,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AIAssistantPage(
                                      initialMessage: 'Which areas in $_userCity have well-developed public transportation networks and central locations? Can you explain in detail the transportation options like metro, metrobus, and bus services?',
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildQuickQuestion(
                              question: 'Best areas for families',
                              icon: Icons.family_restroom,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AIAssistantPage(
                                      initialMessage: 'Which areas in $_userCity are most suitable for families? Can you evaluate them in terms of schools, parks, healthcare services, and safety?',
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildQuickQuestion(
                              question: 'Social life and entertainment',
                              icon: Icons.local_activity,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AIAssistantPage(
                                      initialMessage: 'Which areas in $_userCity have the richest social life and entertainment options? Can you provide information about restaurants, cafes, shopping centers, and cultural activities?',
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildQuickQuestion(
                              question: 'Nature and green spaces',
                              icon: Icons.park,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AIAssistantPage(
                                      initialMessage: 'Which areas in $_userCity offer life close to nature with plenty of green spaces and parks? Can you provide information about walking trails and recreational areas?',
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildQuickQuestion(
                              question: 'Affordable housing areas',
                              icon: Icons.house,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AIAssistantPage(
                                      initialMessage: 'Which areas in $_userCity offer more affordable rent and house prices? Can you evaluate them in terms of living costs and price/performance ratio?',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Latest Comparison Widget
              SliverPadding(
                padding: const EdgeInsets.only(top: 16),
                sliver: SliverToBoxAdapter(
                  child: ExploreComparisonWidget(),
                ),
              ),
              
              // Mini Harita
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MapPage(),
                        ),
                      );
                    },
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: mapController,
                              options: MapOptions(
                                center: _center,
                                zoom: 11.0,
                                interactiveFlags: InteractiveFlag.none,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                                  subdomains: const ['a', 'b', 'c', 'd'],
                                  userAgentPackageName: 'com.mogi.app',
                                  retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.6),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 16,
                              left: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Explore on Map',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    'Click to go to detailed map',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Öneriler Bölümü
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _buildRecommendationsSection(),
                ),
              ),
              // Add bottom padding
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 80),
                sliver: const SliverToBoxAdapter(child: SizedBox()),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ... existing code ...
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Personalized Areas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF08104F),
                  ),
            ),
            if (_recommendedLocations.length > 4)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllRecommendationsPage(
                        recommendations: _recommendedLocations,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF7E5BED),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        if (_recommendationsError != null)
          _buildRecommendationsErrorView()
        else if (_recommendedLocations.isEmpty)
          _buildEmptyRecommendationsView()
        else
          GridView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.only(top: 8),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.65,
            ),
            itemCount: _recommendedLocations.length > 4 ? 4 : _recommendedLocations.length,
            itemBuilder: (context, index) {
              final location = _recommendedLocations[index];
              return LocationCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationDetailsPage(
                        location: LatLng(
                          location['location']['latitude'],
                          location['location']['longitude'],
                        ),
                        locationName: location['name'],
                        description: location['description'],
                        imageUrl: location['imageUrl'],
                        type: location['type'],
                        locationId: location['id'],
                        securityScore: location['scores']?['security'],
                        transportScore: location['scores']?['transport'],
                        educationScore: location['scores']?['education'],
                        healthScore: location['scores']?['health'],
                        socialScore: location['scores']?['social'],
                      ),
                    ),
                  ).then((_) => _loadRecommendedLocations());
                },
                locationName: location['name'],
                description: location['description'],
                imageUrl: location['imageUrl'],
                type: location['type'],
                isGridView: true,
                location: LatLng(
                  location['location']['latitude'],
                  location['location']['longitude'],
                ),
                mapStyle: MapStyle.voyager,
                locationId: location['id'],
                securityScore: location['scores']?['security'],
                transportScore: location['scores']?['transport'],
                educationScore: location['scores']?['education'],
                healthScore: location['scores']?['health'],
                socialScore: location['scores']?['social'],
              );
            },
          ),
      ],
    );
  }

  Widget _buildRecommendationsErrorView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _recommendationsError!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadRecommendedLocations,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecommendationsView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5F1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_searching,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No recommended areas yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF08104F),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Recommendations will appear here as you explore areas',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
          ),
          const SizedBox(height: 16),
          if (!_isLoadingRecommendations)
            ElevatedButton.icon(
              onPressed: _loadRecommendedLocations,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            )
          else
            const CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildQuickQuestion({
    required String question,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF6B2C),
                  Color(0xFFFF8F4C),
                ],
                stops: [0.0, 1.0],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFF6B2C).withOpacity(0.25),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  question,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 