import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shimmer/shimmer.dart';
import '../../data/services/area_analysis_service.dart';
import '../../data/services/premium_service.dart';
import '../pages/premium_page.dart';
import '../../../../core/network/network_connectivity_service.dart';
import '../../../../core/widgets/no_internet_connection_widget.dart';

class LocationInsightsPage extends StatefulWidget {
  final LatLng location;
  final String locationName;

  const LocationInsightsPage({
    super.key,
    required this.location,
    required this.locationName,
  });

  static Future<void> open(BuildContext context, LatLng location, String locationName) async {
    final premiumService = PremiumService();
    final connectivityService = NetworkConnectivityService();
    await premiumService.init();
    await connectivityService.checkConnectivity();

    // Check internet connection
    if (!connectivityService.isConnected.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection. Please check your connection and try again.')),
      );
      return;
    }

    print('Lokasyon Analizi açılıyor - Başlangıç durumu:');
    print('Premium: ${premiumService.isPremium}');
    print('Premium Kontrol: isPremium = ${premiumService.status.isPremium}, premiumUntil = ${premiumService.status.premiumUntil}');
    print('Mogi Puanları: ${premiumService.mogiPoints}');

    // Premium kontrolü
    bool canAccessPage = false;
    
    if (premiumService.isPremium) {
      print('Kullanıcı premium olduğu için doğrudan erişim sağlanıyor');
      canAccessPage = true;
    } else {
      print('Kullanıcı premium DEĞİL, Mogi puanları kontrol ediliyor');
      // Premium olmayan kullanıcılar için Mogi puanı kontrolü
      if (premiumService.mogiPoints > 0) {
        print('Mogi puanları kullanılıyor: ${premiumService.mogiPoints}');
        final success = await premiumService.useMogiPointsForLocationAnalysis();
        print('Mogi puanı kullanımı sonucu: $success, Kalan puan: ${premiumService.mogiPoints}');
        
        if (success) {
          print('Lokasyon analizi için Mogi puanı kullanıldı. Kalan: ${premiumService.mogiPoints}');
          canAccessPage = true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mogi puanları kullanılamadı. Lütfen daha sonra tekrar deneyin.')),
          );
        }
      } else {
        print('Mogi puanı yetersiz, premium sayfasına yönlendiriliyor');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yetersiz Mogi puanı. Lütfen daha fazla Mogi puanı satın alın.')),
        );
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const PremiumPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 200),
          ),
        );
      }
    }
    
    // Sayfaya erişim izni varsa yönlendir
    if (canAccessPage) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationInsightsPage(
            location: location,
            locationName: locationName,
          ),
        ),
      );
    }
  }

  @override
  State<LocationInsightsPage> createState() => _LocationInsightsPageState();
}

class _LocationInsightsPageState extends State<LocationInsightsPage> {
  final _areaAnalysisService = AreaAnalysisService();
  final _premiumService = PremiumService();
  final _connectivityService = NetworkConnectivityService();
  Map<String, dynamic>? _analysisData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initServices();
    
    // Listen for connectivity changes
    _connectivityService.isConnected.addListener(_onConnectivityChanged);
  }
  
  void _onConnectivityChanged() {
    if (mounted) {
      setState(() {
        // Update UI when connectivity status changes
        if (_connectivityService.isConnected.value) {
          // Internet connection restored
          print("Location Insights: Internet connection restored");
          if (_error == 'No internet connection. Please check your connection and try again.') {
            _error = null;
            // Reload analysis if we have no data yet
            if (_analysisData == null && !_isLoading) {
              _loadAnalysis();
            }
          }
        } else {
          // Internet connection lost
          print("Location Insights: Internet connection lost");
          if (_error == null && !_isLoading) {
            _error = 'No internet connection. Please check your connection and try again.';
          }
        }
      });
    }
  }

  Future<void> _initServices() async {
    try {
      await _premiumService.init();
      
      // Check internet connection
      await _connectivityService.checkConnectivity();
      if (!_connectivityService.isConnected.value) {
        setState(() {
          _error = 'No internet connection. Please check your connection and try again.';
          _isLoading = false;
        });
        return;
      }
      
      _loadAnalysis();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAnalysis() async {
    try {
      // Check internet connection
      if (!_connectivityService.isConnected.value) {
        setState(() {
          _error = 'No internet connection. Please check your connection and try again.';
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('Analiz yükleniyor - Başlangıç durumu:');
      print('Premium: ${_premiumService.isPremium}');
      print('Mogi Puanları: ${_premiumService.mogiPoints}');

      final data = await _areaAnalysisService.getAreaAnalysis(widget.location);
      
      print('Analiz yüklendi - Son durum:');
      print('Premium: ${_premiumService.isPremium}');
      print('Mogi Puanları: ${_premiumService.mogiPoints}');

      setState(() {
        _analysisData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showPremiumDialog() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const PremiumPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF08104F),
        foregroundColor: Colors.white,
        title: Text(
          widget.locationName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Satoshi',
          ),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: !_connectivityService.isConnected.value && _analysisData == null
          ? NoInternetConnectionWidget(
              onRetry: () async {
                print("Location Insights: Retry button pressed, checking connectivity...");
                // Bağlantıyı kontrol et
                await _connectivityService.checkConnectivity();
                
                // Kısa bir bekleme ekleyelim
                await Future.delayed(const Duration(milliseconds: 500));
                
                print("Location Insights: Connection status after retry: ${_connectivityService.isConnected.value}");
                
                // Her durumda analizi yeniden yüklemeyi deneyelim
                _loadAnalysis();
              },
              message: 'Internet connection is required for location analysis. Please check your connection and try again.',
            )
          : _isLoading
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSkeletonOverallScore(),
                      const SizedBox(height: 24),
                      _buildSkeletonAreaInfo(),
                      const SizedBox(height: 24),
                      _buildSkeletonDetailedScores(),
                      const SizedBox(height: 24),
                      _buildSkeletonFeatures(),
                    ],
                  ),
                )
              : _error != null
                  ? _buildErrorView()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOverallScore(),
                          const SizedBox(height: 24),
                          _buildAreaInfo(),
                          const SizedBox(height: 24),
                          _buildDetailedScores(),
                          const SizedBox(height: 24),
                          _buildFeatures(),
                          if (_analysisData?['air_quality'] != null) ...[
                            const SizedBox(height: 24),
                            _buildAirQuality(),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Occurred',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: !_connectivityService.isConnected.value ? null : _loadAnalysis,
              icon: const Icon(Icons.refresh),
              label: Text(!_connectivityService.isConnected.value ? 'No Internet Connection' : 'Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallScore() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Score',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF08104F),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7E5BED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  (_analysisData?['scores']?['overall'] ?? 0.0).toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7E5BED),
                      ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'This area has a good score in terms of overall quality of life.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAreaInfo() {
    final areaInfo = _analysisData?['area_info'];
    if (areaInfo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Area Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF08104F),
                ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Type', _getAreaTypeText(areaInfo['type'])),
          _buildInfoRow('District', areaInfo['district'] ?? ''),
          _buildInfoRow('City', areaInfo['city'] ?? ''),
          const SizedBox(height: 16),
          if (areaInfo['descriptions']?.isNotEmpty == true) ...[
            Text(
              'Highlighted Features',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF08104F),
                  ),
            ),
            const SizedBox(height: 8),
            ...List<Widget>.from(
              (areaInfo['descriptions'] as List).map(
                (description) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7E5BED),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF6B7280),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedScores() {
    final scores = _analysisData?['scores'];
    if (scores == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Scores',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF08104F),
                ),
          ),
          const SizedBox(height: 16),
          _buildScoreRow('Green Areas', scores['green_areas'] ?? 0, Icons.park),
          _buildScoreRow('Basic Needs', scores['basic_needs'] ?? 0, Icons.shopping_bag),
          _buildScoreRow('Air Quality', scores['air_quality'] ?? 0, Icons.air),
        ],
      ),
    );
  }

  Widget _buildFeatures() {
    final features = _analysisData?['area_info']?['features'];
    if (features == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nearby Places',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF08104F),
                ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2,
            children: [
              _buildFeatureItem('park', 'Park', Icons.park),
              _buildFeatureItem('school', 'School', Icons.school),
              _buildFeatureItem('hospital', 'Hospital', Icons.local_hospital),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String key, String label, IconData icon) {
    final count = _analysisData?['area_info']?['features']?[key] ?? 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7E5BED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF7E5BED),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                ),
                Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF08104F),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirQuality() {
    final airQuality = _analysisData?['air_quality'];
    if (airQuality == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Air Quality',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF08104F),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getAqiColor(airQuality['aqi'] as double).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  (airQuality['aqi'] as double).toStringAsFixed(1),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getAqiColor(airQuality['aqi'] as double),
                      ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      airQuality['category'] ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF08104F),
                          ),
                    ),
                    if (airQuality['dominantPollutant'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Dominant Pollutant: ${airQuality['dominantPollutant']}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (airQuality['healthRecommendations'] != null) ...[
            const SizedBox(height: 24),
            Text(
              'Health Recommendations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF08104F),
                  ),
            ),
            const SizedBox(height: 12),
            _buildHealthRecommendation(
              'General',
              airQuality['healthRecommendations']['general'] ?? '',
              Icons.people,
            ),
            _buildHealthRecommendation(
              'Elderly',
              airQuality['healthRecommendations']['elderly'] ?? '',
              Icons.elderly,
            ),
            _buildHealthRecommendation(
              'Children',
              airQuality['healthRecommendations']['children'] ?? '',
              Icons.child_care,
            ),
            _buildHealthRecommendation(
              'Athletes',
              airQuality['healthRecommendations']['athletes'] ?? '',
              Icons.directions_run,
            ),
          ],
          if (airQuality['pollutants']?.isNotEmpty == true) ...[
            const SizedBox(height: 24),
            Text(
              'Pollutants',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF08104F),
                  ),
            ),
            const SizedBox(height: 12),
            ...List<Widget>.from(
              (airQuality['pollutants'] as List).map(
                (pollutant) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            pollutant['name'],
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF08104F),
                                ),
                          ),
                          Text(
                            '${pollutant['value']} ${pollutant['unit']}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF6B7280),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pollutant['description'] ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF08104F),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, double score, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getScoreColor(score).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: _getScoreColor(score),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF08104F),
                          ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: score / 10,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getScoreColor(score),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getScoreColor(score).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  score.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _getScoreColor(score),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAreaType(String type) {
    switch (type) {
      case 'mahalle':
        return 'Neighborhood';
      case 'ilçe':
        return 'District';
      case 'il':
        return 'City';
      default:
        return type;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.orange;
    return Colors.red;
  }

  String _getScoreText(double score) {
    if (score >= 8) return 'Very Good';
    if (score >= 6) return 'Good';
    if (score >= 4) return 'Moderate';
    return 'Needs Improvement';
  }

  Color _getAqiColor(double aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.brown;
  }

  String _getAQICategory(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Sensitive';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  String _getAreaTypeText(String type) {
    switch (type) {
      case 'mahalle':
        return 'Neighborhood';
      case 'ilçe':
        return 'District';
      case 'il':
        return 'City';
      default:
        return type;
    }
  }

  Widget _buildHealthRecommendation(String title, String recommendation, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7E5BED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF7E5BED),
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF08104F),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  recommendation,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonOverallScore() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonAreaInfo() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 150,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(3, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 80,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonDetailedScores() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 130,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(3, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonFeatures() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2,
              children: List.generate(3, (index) => Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _connectivityService.isConnected.removeListener(_onConnectivityChanged);
    super.dispose();
  }
} 