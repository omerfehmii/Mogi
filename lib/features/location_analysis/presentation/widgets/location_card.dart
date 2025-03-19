import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

enum MapStyle {
  standard,
  terrain,
  toner,
  positron,
  darkMatter,
  voyager,
  mapTiler3d,
}

class LocationCard extends StatefulWidget {
  final VoidCallback onTap;
  final String locationName;
  final String description;
  final String imageUrl;
  final bool isGridView;
  final String type;
  final LatLng location;
  final MapStyle mapStyle;
  final String? locationId;
  final double? securityScore;
  final double? transportScore;
  final double? educationScore;
  final double? healthScore;
  final double? socialScore;
  final bool isSaved;

  const LocationCard({
    super.key,
    required this.onTap,
    required this.locationName,
    required this.description,
    required this.imageUrl,
    required this.type,
    required this.location,
    this.isGridView = false,
    this.mapStyle = MapStyle.voyager,
    this.locationId,
    this.securityScore,
    this.transportScore,
    this.educationScore,
    this.healthScore,
    this.socialScore,
    this.isSaved = false,
  });

  @override
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  String get _mapUrlTemplate {
    switch (widget.mapStyle) {
      case MapStyle.standard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapStyle.terrain:
        return 'https://tile.stamen.com/terrain/{z}/{x}/{y}.jpg';
      case MapStyle.toner:
        return 'https://tile.stamen.com/toner/{z}/{x}/{y}.png';
      case MapStyle.positron:
        return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
      case MapStyle.darkMatter:
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
      case MapStyle.voyager:
        return 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
      case MapStyle.mapTiler3d:
        return 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=YOUR_MAPTILER_KEY';
    }
  }

  List<String> get _subdomains {
    switch (widget.mapStyle) {
      case MapStyle.standard:
        return const ['a', 'b', 'c'];
      case MapStyle.terrain:
      case MapStyle.toner:
        return const ['a', 'b', 'c', 'd'];
      case MapStyle.positron:
      case MapStyle.darkMatter:
      case MapStyle.voyager:
      case MapStyle.mapTiler3d:
        return const ['a', 'b', 'c', 'd'];
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: MouseRegion(
              onEnter: (_) {
                setState(() => _isHovered = true);
                _controller.forward();
              },
              onExit: (_) {
                setState(() => _isHovered = false);
                _controller.reverse();
              },
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _isHovered
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: _isHovered ? 20 : 10,
                      offset: const Offset(0, 4),
                      spreadRadius: _isHovered ? 2 : 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: AspectRatio(
                          aspectRatio: widget.isGridView ? 1 : 16 / 9,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: FlutterMap(
                                  options: MapOptions(
                                    center: widget.location,
                                    zoom: 14.0,
                                    interactiveFlags: InteractiveFlag.none,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate: _mapUrlTemplate,
                                      subdomains: _subdomains,
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
                              Positioned.fill(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: widget.onTap,
                                    splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    highlightColor: Colors.transparent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Area',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              if (widget.isSaved)
                                Icon(
                                  Icons.favorite,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.locationName,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF08104F),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward,
                                color: Color(0xFF7E5BED),
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (widget.type) {
      case 'district':
        return Icons.location_city;
      case 'residential':
        return Icons.home;
      case 'commercial':
        return Icons.store;
      case 'park':
        return Icons.park;
      case 'education':
        return Icons.school;
      default:
        return Icons.place;
    }
  }

  String _getTypeText() {
    switch (widget.type) {
      case 'district':
        return 'District';
      case 'residential':
        return 'Residential Area';
      case 'commercial':
        return 'Commercial Area';
      case 'park':
        return 'Park';
      case 'education':
        return 'Education';
      default:
        return 'Area';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
} 