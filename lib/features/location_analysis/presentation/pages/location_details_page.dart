import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart';
import '../../data/services/saved_locations_service.dart';
import '../../data/services/location_recommendations_service.dart';
import 'location_insights_page.dart';
import '../../../ai_assistant/presentation/pages/ai_assistant_page.dart';
import 'real_estate_listings_page.dart';

class LocationDetailsPage extends StatefulWidget {
  final LatLng location;
  final String? locationName;
  final String? description;
  final String? imageUrl;
  final double? securityScore;
  final String? type;
  final String? locationId;
  final double? transportScore;
  final double? educationScore;
  final double? healthScore;
  final double? socialScore;

  const LocationDetailsPage({
    super.key,
    required this.location,
    this.locationName,
    this.description,
    this.imageUrl,
    this.securityScore,
    this.type,
    this.locationId,
    this.transportScore,
    this.educationScore,
    this.healthScore,
    this.socialScore,
  });

  @override
  State<LocationDetailsPage> createState() => _LocationDetailsPageState();
}

class _LocationDetailsPageState extends State<LocationDetailsPage> {
  final _savedLocationsService = SavedLocationsService();
  final _recommendationsService = LocationRecommendationsService();
  bool _isLocationSaved = false;
  bool _isLoading = false;
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initServices();
  }

  Future<void> _initServices() async {
    await _savedLocationsService.init();
    await _recommendationsService.init();
    if (widget.locationId != null) {
      final isSaved = await _savedLocationsService.isLocationSaved(widget.locationId!);
      if (mounted) {
        setState(() => _isLocationSaved = isSaved);
      }
    }
    // Konumu son görüntülenenlere ekle
    await _addToRecentlyViewed();
  }

  Future<void> _addToRecentlyViewed() async {
    await _recommendationsService.addRecentlyViewedLocation(
      name: widget.locationName ?? '',
      description: widget.description ?? '',
      imageUrl: widget.imageUrl ?? 'assets/images/default_location.png',
      latitude: widget.location.latitude,
      longitude: widget.location.longitude,
      type: widget.type ?? 'unknown',
      scores: {
        'security': widget.securityScore ?? 4.0,
        'transport': widget.transportScore ?? 3.5,
        'education': widget.educationScore ?? 3.0,
        'health': widget.healthScore ?? 3.0,
        'social': widget.socialScore ?? 3.0,
      },
    );
  }

  Future<void> _toggleSaveLocation() async {
    setState(() => _isLoading = true);

    try {
      if (_isLocationSaved) {
        await _savedLocationsService.removeLocationById(widget.locationId!);
      } else {
        await _savedLocationsService.saveLocation(
          name: widget.locationName ?? '',
          description: widget.description ?? '',
          imageUrl: widget.imageUrl ?? 'assets/images/default_location.png',
          latitude: widget.location.latitude,
          longitude: widget.location.longitude,
          securityScore: widget.securityScore ?? 4.0,
          transportScore: widget.transportScore ?? 3.5,
          type: widget.type ?? 'unknown',
          additionalScores: {
            'education': widget.educationScore ?? 3.0,
            'health': widget.healthScore ?? 3.0,
            'social': widget.socialScore ?? 3.0,
          },
        );
      }

      if (mounted) {
        setState(() => _isLocationSaved = !_isLocationSaved);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLocationSaved ? 'Location saved' : 'Location removed from favorites'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
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
    // Durum çubuğunu şeffaf yap
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          Container(
            height: 300 + topPadding,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(28)),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: widget.location,
                      zoom: 14,
                      interactiveFlags: InteractiveFlag.none,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.mogi.app',
                        retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: widget.location,
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFF7E5BED),
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: topPadding + 16,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: const Color(0xFF08104F),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.locationName ?? 'Location Details',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF08104F),
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      IconButton(
                        onPressed: _isLoading ? null : _toggleSaveLocation,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _isLocationSaved ? Icons.favorite : Icons.favorite_border,
                                color: _isLocationSaved
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.primary,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    context,
                    icon: Icons.location_city,
                    label: 'Area Characteristics',
                    description: widget.type == 'district' ? 'Central residential area' :
                               widget.type == 'residential' ? 'Residential area' :
                               widget.type == 'commercial' ? 'Commercial area' :
                               widget.type == 'mixed' ? 'Mixed-use area' : 'General residential area',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Features',
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
                    childAspectRatio: 1.2,
                    padding: EdgeInsets.zero,
                    children: [
                      _buildFeatureButton(
                        context,
                        icon: Icons.assistant,
                        title: 'AI Assistant',
                        description: 'Ask anything\nabout the area',
                        color: const Color(0xFF6339F9),
                        onTap: () {
                          String initialQuestion = 'Can I get detailed information about the ${widget.locationName} area? ';
                          
                          // If area scores are available, add them to the question
                          if (widget.securityScore != null || widget.transportScore != null) {
                            initialQuestion += 'Especially in terms of ';
                            if (widget.securityScore != null) {
                              initialQuestion += 'security, ';
                            }
                            if (widget.transportScore != null) {
                              initialQuestion += 'transportation, ';
                            }
                            if (widget.educationScore != null) {
                              initialQuestion += 'education, ';
                            }
                            if (widget.healthScore != null) {
                              initialQuestion += 'healthcare, ';
                            }
                            if (widget.socialScore != null) {
                              initialQuestion += 'social life, ';
                            }
                            // Remove last comma and space
                            initialQuestion = initialQuestion.substring(0, initialQuestion.length - 2);
                            initialQuestion += '?';
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AIAssistantPage(
                                initialMessage: initialQuestion,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildFeatureButton(
                        context,
                        icon: Icons.info_outline,
                        title: 'General Features',
                        description: 'Basic features\nof the area',
                        color: const Color(0xFFFF781F),
                        onTap: () {
                          LocationInsightsPage.open(
                            context,
                            widget.location,
                            widget.locationName ?? 'Selected Location',
                          );
                        },
                      ),
                      _buildFeatureButton(
                        context,
                        icon: Icons.home_work,
                        title: 'Real Estate',
                        description: 'Property prices\nand listings',
                        color: const Color(0xFFFF781F),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RealEstateListingsPage(
                                location: widget.location,
                                locationName: widget.locationName ?? 'Selected Location',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6339F9)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF08104F),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
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

  Widget _buildFeatureButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF08104F),
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                    height: 1.1,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }
} 