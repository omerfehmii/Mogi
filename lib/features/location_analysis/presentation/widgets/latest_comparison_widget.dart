import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import '../../data/models/comparison_history_model.dart';
import '../../data/services/comparison_history_service.dart';
import '../pages/comparison_details_page.dart';

class LatestComparisonWidget extends StatefulWidget {
  const LatestComparisonWidget({Key? key}) : super(key: key);

  @override
  State<LatestComparisonWidget> createState() => _LatestComparisonWidgetState();
}

class _LatestComparisonWidgetState extends State<LatestComparisonWidget> with SingleTickerProviderStateMixin {
  final ComparisonHistoryService _historyService = ComparisonHistoryService();
  ComparisonHistoryModel? _latestComparison;
  bool _isLoading = true;
  bool _hasError = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // Sample data categories for visualization
  final List<String> _categories = [
    'Cost of Living',
    'Safety',
    'Education',
    'Transportation',
  ];
  
  // Generated scores for visualization
  List<Map<String, double>> _locationScores = [];
  
  // Animation state
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    
    _loadLatestComparison();
    
    // Set up animation completion listener
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestComparison() async {
    try {
      await _historyService.init();
      final comparisons = _historyService.getAllComparisons();
      
      setState(() {
        _isLoading = false;
        if (comparisons.isNotEmpty) {
          _latestComparison = comparisons.first;
          _generateVisualizationData();
          
          // Otomatik olarak animasyonu başlat
          _isAnimating = true;
          _animationController.reset();
          _animationController.forward();
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }
  
  void _generateVisualizationData() {
    if (_latestComparison == null) return;
    
    final random = math.Random(42); // Fixed seed for consistent random values
    _locationScores = [];
    
    // Generate random scores for each location
    for (var location in _latestComparison!.locations) {
      final scores = <String, double>{};
      for (var category in _categories) {
        scores[category] = 0.3 + random.nextDouble() * 0.7; // Score between 0.3 and 1.0
      }
      _locationScores.add(scores);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_hasError || _latestComparison == null) {
      return _buildEmptyState();
    }
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ComparisonDetailsPage(
              comparison: _latestComparison!,
              onDelete: () {
                _loadLatestComparison();
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6339F9), Color(0xFF8C6FFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Latest Comparison',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _latestComparison!.title,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
            
            // Visualization
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Comparison Overview',
                        style: TextStyle(
                          color: Color(0xFF08104F),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildLegend(),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return _buildBarChartVisualization();
                      },
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
  
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEAE4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_latestComparison!.locations.length, (index) {
          final colors = [
            const Color(0xFF6339F9),
            const Color(0xFFFF781F),
            const Color(0xFF00C48C),
          ];
          
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _latestComparison!.locations[index],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF08104F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildBarChartVisualization() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Row(
                          children: List.generate(_locationScores.length, (locationIndex) {
                            final score = _locationScores[locationIndex][category] ?? 0.5;
                            final colors = [
                              const Color(0xFF6339F9),
                              const Color(0xFFFF781F),
                              const Color(0xFF00C48C),
                            ];
                            
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                '${(score * 100).toInt()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: colors[locationIndex % colors.length],
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(_locationScores.length, (locationIndex) {
                        final score = _locationScores[locationIndex][category] ?? 0.5;
                        final animatedScore = score * _animation.value;
                        
                        final colors = [
                          const Color(0xFF6339F9),
                          const Color(0xFFFF781F),
                          const Color(0xFF00C48C),
                        ];
                        
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: locationIndex < _locationScores.length - 1 ? 4 : 0,
                            ),
                            child: Stack(
                              children: [
                                Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: animatedScore,
                                  child: Container(
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: colors[locationIndex % colors.length],
                                      borderRadius: BorderRadius.circular(5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colors[locationIndex % colors.length].withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.compare_arrows_rounded,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No comparisons yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Compare locations to see visualization',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
} 