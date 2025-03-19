import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';

class RealEstateListingsPage extends StatefulWidget {
  final LatLng location;
  final String locationName;

  const RealEstateListingsPage({
    Key? key,
    required this.location,
    required this.locationName,
  }) : super(key: key);

  @override
  State<RealEstateListingsPage> createState() => _RealEstateListingsPageState();
}

class _RealEstateListingsPageState extends State<RealEstateListingsPage> {
  String _countryCode = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCountryFromCoordinates();
  }

  Future<void> _getCountryFromCoordinates() async {
    try {
      final placemarks = await placemarkFromCoordinates(
        widget.location.latitude,
        widget.location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final countryCode = placemarks.first.isoCountryCode ?? '';
        setState(() {
          _countryCode = countryCode;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Could not get country code: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getRealEstateWebsites() {
    // Bölge adını URL için uygun formata çevir
    final encodedLocation = Uri.encodeComponent(widget.locationName);
    
    // Varsayılan olarak İngilizce terimler
    String rentTerm = 'rent';
    String saleTerm = 'buy';
    String propertyTerm = 'house apartment';
    String agentTerm = 'real estate agent';
    
    // Ülkeye göre arama terimlerini belirle
    switch (_countryCode.toUpperCase()) {
      case 'TR':
        rentTerm = 'kiralık';
        saleTerm = 'satılık';
        propertyTerm = 'ev daire konut';
        agentTerm = 'emlak ofisi emlakçı';
        break;
      case 'DE':
        rentTerm = 'mieten';
        saleTerm = 'kaufen';
        propertyTerm = 'haus wohnung immobilien';
        agentTerm = 'immobilienmakler';
        break;
      case 'FR':
        rentTerm = 'louer';
        saleTerm = 'acheter';
        propertyTerm = 'maison appartement';
        agentTerm = 'agence immobilière';
        break;
      case 'ES':
        rentTerm = 'alquilar';
        saleTerm = 'comprar';
        propertyTerm = 'casa piso';
        agentTerm = 'agencia inmobiliaria';
        break;
      case 'IT':
        rentTerm = 'affittare';
        saleTerm = 'comprare';
        propertyTerm = 'casa appartamento';
        agentTerm = 'agenzia immobiliare';
        break;
      case 'NL':
        rentTerm = 'huren';
        saleTerm = 'kopen';
        propertyTerm = 'huis appartement';
        agentTerm = 'makelaar';
        break;
      case 'PT':
        rentTerm = 'alugar';
        saleTerm = 'comprar';
        propertyTerm = 'casa apartamento';
        agentTerm = 'imobiliária';
        break;
      case 'RU':
        rentTerm = 'аренда';
        saleTerm = 'купить';
        propertyTerm = 'квартира дом';
        agentTerm = 'агентство недвижимости';
        break;
      case 'JP':
        rentTerm = '賃貸';
        saleTerm = '売買';
        propertyTerm = 'マンション 一戸建て';
        agentTerm = '不動産業者';
        break;
      case 'KR':
        rentTerm = '임대';
        saleTerm = '매매';
        propertyTerm = '아파트 주택';
        agentTerm = '부동산';
        break;
      case 'CN':
        rentTerm = '租房';
        saleTerm = '买房';
        propertyTerm = '公寓 住宅';
        agentTerm = '房地产中介';
        break;
    }

    // Her durumda hem yerel dilde hem de İngilizce arama yap
    final localSearch = '$encodedLocation $rentTerm $propertyTerm';
    final englishSearch = '$encodedLocation rent house apartment';

    return [
      {
        'name': 'Rental\nListings',
        'icon': Icons.home_outlined,
        'color': const Color(0xFFFF781F),
        'url': 'https://www.google.com/search?q=$localSearch OR $englishSearch',
      },
      {
        'name': 'Properties\nfor Sale',
        'icon': Icons.sell_outlined,
        'color': const Color(0xFFFF781F),
        'url': 'https://www.google.com/search?q=$encodedLocation $saleTerm $propertyTerm OR $encodedLocation buy house apartment',
      },
      {
        'name': 'Real Estate\nAgencies',
        'icon': Icons.business_outlined,
        'color': const Color(0xFFFF781F),
        'url': 'https://www.google.com/search?q=$encodedLocation $agentTerm OR $encodedLocation real estate agent property',
      },
      {
        'name': 'Show on\nMap',
        'icon': Icons.map_outlined,
        'color': const Color(0xFFFF781F),
        'url': 'https://www.google.com/maps/search/$encodedLocation+$agentTerm',
      },
    ];
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the website')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real Estate Listings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF08104F),
                fontSize: 18,
              ),
            ),
            Text(
              widget.locationName,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFF08104F),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Real Estate Websites',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF08104F),
                        ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: _getRealEstateWebsites().length,
                    itemBuilder: (context, index) {
                      final website = _getRealEstateWebsites()[index];
                      return _buildWebsiteCard(
                        name: website['name'],
                        icon: website['icon'],
                        color: website['color'],
                        onTap: () => _launchURL(website['url']),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Information',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF08104F),
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The real estate websites listed here are popular platforms in your area. Each site has its own terms of use, and Mogi is not responsible for the listings on these sites.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF6B7280),
                                height: 1.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildWebsiteCard({
    required String name,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF08104F),
                      fontSize: 14,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 