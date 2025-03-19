import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/services/area_analysis_service.dart';

class AreaAnalysisPage extends StatefulWidget {
  final LatLng location;
  final String locationName;

  const AreaAnalysisPage({
    super.key,
    required this.location,
    required this.locationName,
  });

  @override
  State<AreaAnalysisPage> createState() => _AreaAnalysisPageState();
}

class _AreaAnalysisPageState extends State<AreaAnalysisPage> {
  final _analysisService = AreaAnalysisService();
  bool _isLoading = true;
  Map<String, dynamic>? _analysisData;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    try {
      final data = await _analysisService.getAreaAnalysis(widget.location);
      setState(() {
        _analysisData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analiz yüklenirken hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.locationName} Analizi',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPotentialScoreCard(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Genel Analiz'),
                    const SizedBox(height: 16),
                    _buildGeneralAnalysis(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Gelişim Faktörleri'),
                    const SizedBox(height: 16),
                    _buildGrowthFactors(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Rekabet Analizi'),
                    const SizedBox(height: 16),
                    _buildCompetitionAnalysis(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Öneriler'),
                    const SizedBox(height: 16),
                    _buildRecommendations(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPotentialScoreCard() {
    final score = _analysisData?['development_potential']['potential_score'] ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7E5BED),
            const Color(0xFFAB92F8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7E5BED).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gelişim Potansiyeli',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                score.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '/10',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      score >= 7 ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      score >= 7 ? 'Yüksek' : 'Orta',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralAnalysis() {
    final analysis = _analysisData?['general_analysis'];
    if (analysis == null) return const SizedBox();

    return Column(
      children: [
        _buildAnalysisCard(
          'İşletme Yoğunluğu',
          Icons.business,
          '${analysis['business_density']['total_businesses']} işletme',
          [
            _buildDistributionBar(
              'Perakende',
              analysis['business_density']['per_category']['retail'],
            ),
            _buildDistributionBar(
              'Yeme-İçme',
              analysis['business_density']['per_category']['food_beverage'],
            ),
            _buildDistributionBar(
              'Hizmet',
              analysis['business_density']['per_category']['services'],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildAnalysisCard(
          'Demografik Yapı',
          Icons.people,
          '${analysis['demographic_match']['population_density']} kişi/km²',
          [
            _buildDistributionBar(
              'Genç',
              analysis['demographic_match']['age_distribution']['young'].toDouble(),
            ),
            _buildDistributionBar(
              'Yetişkin',
              analysis['demographic_match']['age_distribution']['adult'].toDouble(),
            ),
            _buildDistributionBar(
              'Yaşlı',
              analysis['demographic_match']['age_distribution']['elderly'].toDouble(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGrowthFactors() {
    final factors = _analysisData?['development_potential']['growth_factors'];
    if (factors == null) return const SizedBox();

    return Column(
      children: [
        _buildFactorCard(
          'Yeni İşletmeler',
          Icons.trending_up,
          '${factors['new_businesses']['total_new_businesses']} yeni işletme',
          'Son 6 ayda açılan',
          factors['new_businesses']['growth_rate'],
        ),
        const SizedBox(height: 16),
        _buildFactorCard(
          'Emlak Fırsatları',
          Icons.apartment,
          '${factors['real_estate_opportunities']['available_commercial_space']}m²',
          'Kullanılabilir alan',
          null,
        ),
        const SizedBox(height: 16),
        _buildFactorCard(
          'Altyapı Gelişimi',
          Icons.engineering,
          factors['infrastructure_development']['planned_improvements'][0],
          'Planlanan proje',
          factors['infrastructure_development']['public_transport_score'],
        ),
      ],
    );
  }

  Widget _buildCompetitionAnalysis() {
    final competition = _analysisData?['competition_analysis'];
    if (competition == null) return const SizedBox();

    return Column(
      children: [
        _buildAnalysisCard(
          'Rekabet Seviyesi',
          Icons.compare_arrows,
          'Orta-Yüksek Seviye',
          [
            _buildDistributionBar(
              'Düşük Segment',
              competition['competition_level']['by_price_level']['low'].toDouble(),
            ),
            _buildDistributionBar(
              'Orta Segment',
              competition['competition_level']['by_price_level']['medium'].toDouble(),
            ),
            _buildDistributionBar(
              'Yüksek Segment',
              competition['competition_level']['by_price_level']['high'].toDouble(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMarketGapsCard(competition['market_gaps']),
      ],
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _analysisData?['development_potential']['recommendations'] as List?;
    if (recommendations == null) return const SizedBox();

    return Column(
      children: recommendations.map((recommendation) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF7E5BED),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recommendation,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF08104D),
      ),
    );
  }

  Widget _buildAnalysisCard(
    String title,
    IconData icon,
    String value,
    List<Widget> charts,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7E5BED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF7E5BED),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF08104D),
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...charts,
        ],
      ),
    );
  }

  Widget _buildDistributionBar(String label, double percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '%${percentage.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF08104D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7E5BED)),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorCard(
    String title,
    IconData icon,
    String value,
    String subtitle,
    double? score,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF7E5BED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF7E5BED),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF08104D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (score != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _getScoreColor(score).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                score.toString(),
                style: TextStyle(
                  color: _getScoreColor(score),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMarketGapsCard(List<String> gaps) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pazar Fırsatları',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF08104D),
            ),
          ),
          const SizedBox(height: 12),
          ...gaps.map((gap) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7E5BED),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    gap,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.orange;
    return Colors.red;
  }
} 