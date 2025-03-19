import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../domain/models/saved_location_model.dart';
import '../widgets/location_card.dart';
import 'location_details_page.dart';

class AllLocationsPage extends StatefulWidget {
  final List<SavedLocationModel> locations;

  const AllLocationsPage({
    super.key,
    required this.locations,
  });

  @override
  State<AllLocationsPage> createState() => _AllLocationsPageState();
}

class _AllLocationsPageState extends State<AllLocationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text(
          'Saved Locations',
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
        itemCount: widget.locations.length,
        itemBuilder: (context, index) {
          final location = widget.locations[index];
          return LocationCard(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LocationDetailsPage(
                    location: location.location,
                    locationName: location.name,
                    description: location.description,
                    imageUrl: location.imageUrl,
                    type: location.type,
                    locationId: location.id,
                    securityScore: location.scores['security'],
                    transportScore: location.scores['transport'],
                    educationScore: location.scores['education'],
                    healthScore: location.scores['health'],
                    socialScore: location.scores['social'],
                  ),
                ),
              ).then((_) {
                // Return to the saved locations page when done
                Navigator.pop(context);
              });
            },
            locationName: location.name,
            description: location.description,
            imageUrl: location.imageUrl,
            type: location.type,
            isGridView: true,
            location: location.location,
            mapStyle: MapStyle.voyager,
          );
        },
      ),
    );
  }
} 