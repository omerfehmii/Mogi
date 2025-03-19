import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/location_card.dart';
import 'location_details_page.dart';
import '../../data/services/saved_locations_service.dart';

class AllRecommendationsPage extends StatefulWidget {
  final List<Map<String, dynamic>> recommendations;

  const AllRecommendationsPage({
    Key? key,
    required this.recommendations,
  }) : super(key: key);

  @override
  State<AllRecommendationsPage> createState() => _AllRecommendationsPageState();
}

class _AllRecommendationsPageState extends State<AllRecommendationsPage> {
  final SavedLocationsService _savedLocationsService = SavedLocationsService();
  Map<String, bool> _savedStates = {};

  @override
  void initState() {
    super.initState();
    _initSavedStates();
  }

  Future<void> _initSavedStates() async {
    await _savedLocationsService.init();
    for (var recommendation in widget.recommendations) {
      final locationId = recommendation['id'] as String;
      final isSaved = await _savedLocationsService.isLocationSaved(locationId);
      if (mounted) {
        setState(() {
          _savedStates[locationId] = isSaved;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text(
          'Recommended Areas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF08104F),
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFF08104F),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: const Color(0xFF08104F),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.65,
        ),
        itemCount: widget.recommendations.length,
        itemBuilder: (context, index) {
          final recommendation = widget.recommendations[index];
          final locationId = recommendation['id'] as String;
          return LocationCard(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LocationDetailsPage(
                    location: LatLng(
                      recommendation['location']['latitude'] as double,
                      recommendation['location']['longitude'] as double,
                    ),
                    locationName: recommendation['name'] as String,
                    description: recommendation['description'] as String,
                    imageUrl: recommendation['imageUrl'] as String,
                    type: recommendation['type'] as String,
                    locationId: locationId,
                    securityScore: recommendation['scores']['security'] as double?,
                    transportScore: recommendation['scores']['transport'] as double?,
                    educationScore: recommendation['scores']['education'] as double?,
                    healthScore: recommendation['scores']['health'] as double?,
                    socialScore: recommendation['scores']['social'] as double?,
                  ),
                ),
              );
              // Geri döndüğünde kaydedilme durumunu güncelle
              if (mounted) {
                final isSaved = await _savedLocationsService.isLocationSaved(locationId);
                setState(() {
                  _savedStates[locationId] = isSaved;
                });
              }
            },
            locationName: recommendation['name'] as String,
            description: recommendation['description'] as String,
            imageUrl: recommendation['imageUrl'] as String,
            type: recommendation['type'] as String,
            isGridView: true,
            location: LatLng(
              recommendation['location']['latitude'] as double,
              recommendation['location']['longitude'] as double,
            ),
            mapStyle: MapStyle.voyager,
            locationId: locationId,
            isSaved: _savedStates[locationId] ?? false,
          );
        },
      ),
    );
  }
} 