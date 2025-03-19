import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mogi/features/location_analysis/presentation/bloc/location_analysis_bloc.dart';
import 'package:mogi/features/location_analysis/presentation/bloc/location_analysis_event.dart';
import 'package:mogi/features/location_analysis/presentation/bloc/location_analysis_state.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(41.0082, 28.9784); // İstanbul koordinatları
  final TextEditingController _searchController = TextEditingController();
  LatLng? _selectedLocation;
  bool isMapView = true;
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;
  bool _isSearchFocused = false;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _searchAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _searchAnimationController, curve: Curves.easeInOut),
    );

    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
      if (_searchFocusNode.hasFocus) {
        _searchAnimationController.forward();
      } else {
        _searchAnimationController.reverse();
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Row(
          children: [
            // Sol Panel - Explore
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
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
                    _buildAppBar(),
                    _buildSearchBar(),
                    _buildViewToggle(),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: isMapView
                              ? GoogleMap(
                                  onMapCreated: _onMapCreated,
                                  initialCameraPosition: CameraPosition(
                                    target: _center,
                                    zoom: 14.0,
                                  ),
                                  myLocationButtonEnabled: true,
                                  myLocationEnabled: true,
                                  onTap: _onMapTap,
                                  markers: _selectedLocation != null
                                      ? {
                                          Marker(
                                            markerId: const MarkerId('selected_location'),
                                            position: _selectedLocation!,
                                            icon: BitmapDescriptor.defaultMarkerWithHue(
                                              BitmapDescriptor.hueViolet,
                                            ),
                                          ),
                                        }
                                      : {},
                                )
                              : const Center(child: Text('List View')),
                        ),
                      ),
                    ),
                    _buildAIAssistantCard(),
                  ],
                ),
              ),
            ),
            // Orta Panel - Location Details
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    // Başlık
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Location Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // İstatistik Kartları
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '92',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: const Color(0xFF0A0F2C),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Safety Score',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '85',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: const Color(0xFF0A0F2C),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Transport',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Özellikler Listesi
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Area Features',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: const Color(0xFF0A0F2C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Buraya özellikler listesi eklenecek
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Sağ Panel - Profile
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    // Başlık
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Profile',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Profil Bilgileri
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.person, color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'John Doe',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF0A0F2C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // İstatistikler
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saved Locations',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '12',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: const Color(0xFF0A0F2C),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Favori Lokasyonlar
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Favorite Locations',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: const Color(0xFF0A0F2C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Buraya favori lokasyonlar listesi eklenecek
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchAnimationController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _buildAppBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            'Explore',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Search ve Favori butonları
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F3C),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.search, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F3C),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.favorite_border, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return ScaleTransition(
      scale: _searchAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isSearchFocused ? 0.1 : 0.05),
              blurRadius: _isSearchFocused ? 15 : 10,
              offset: Offset(0, _isSearchFocused ? 5 : 3),
            ),
          ],
        ),
        child: TextField(
          focusNode: _searchFocusNode,
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Konum ara...',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => setState(() => isMapView = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isMapView ? Theme.of(context).colorScheme.primary : const Color(0xFFF3F4F6),
                foregroundColor: isMapView ? Colors.white : const Color(0xFF6B7280),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Map View'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => setState(() => isMapView = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: !isMapView ? Theme.of(context).colorScheme.primary : const Color(0xFFF3F4F6),
                foregroundColor: !isMapView ? Colors.white : const Color(0xFF6B7280),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('List View'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAssistantCard() {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7E5BED).withOpacity(0.9),
            const Color(0xFFAB92F8).withOpacity(0.9),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7E5BED).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.assistant,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'AI Asistan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Bu konum hakkında\nher şeyi sorabilirsiniz',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sohbeti Başlat',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
    );
  }
} 