import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/models/saved_location_model.dart';
import '../widgets/location_card.dart';
import '../pages/location_details_page.dart';
import '../pages/all_locations_page.dart';

class SavedLocationsWidget extends StatelessWidget {
  final List<SavedLocationModel> savedLocations;
  final Function() onRefresh;

  const SavedLocationsWidget({
    Key? key,
    required this.savedLocations,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saved Locations',
                style: TextStyle(
                  color: Color(0xFF08104F),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _viewAllLocations(context),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF6339F9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: savedLocations.length > 5 ? 5 : savedLocations.length,
            itemBuilder: (context, index) {
              final location = savedLocations[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                child: LocationCard(
                  onTap: () => _viewLocationDetails(context, location),
                  locationName: location.name,
                  description: location.description,
                  imageUrl: location.imageUrl,
                  type: location.type,
                  locationId: location.id,
                  location: LatLng(
                    location.location.latitude,
                    location.location.longitude,
                  ),
                  mapStyle: MapStyle.voyager,
                  securityScore: location.scores['security'],
                  transportScore: location.scores['transport'],
                  educationScore: location.scores['education'],
                  healthScore: location.scores['health'],
                  socialScore: location.scores['social'],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _viewAllLocations(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllLocationsPage(
          locations: savedLocations,
        ),
      ),
    ).then((_) => onRefresh());
  }

  void _viewLocationDetails(BuildContext context, SavedLocationModel location) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationDetailsPage(
          location: LatLng(
            location.location.latitude,
            location.location.longitude,
          ),
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
    ).then((_) => onRefresh());
  }
} 