import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../data/models/comparison_history_model.dart';
import '../../data/services/comparison_history_service.dart';
import '../pages/comparison_details_page.dart';
import '../pages/location_comparison_page.dart';

class ExploreComparisonWidget extends StatefulWidget {
  const ExploreComparisonWidget({Key? key}) : super(key: key);

  @override
  State<ExploreComparisonWidget> createState() => _ExploreComparisonWidgetState();
}

class _ExploreComparisonWidgetState extends State<ExploreComparisonWidget> with SingleTickerProviderStateMixin {
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    );
    
    _loadLatestComparison();
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
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (comparisons.isNotEmpty) {
            _latestComparison = comparisons.first;
            _generateVisualizationData();
            
            // Animasyonu başlat
            _animationController.reset();
            _animationController.forward();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
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
    
    return Container(
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
            decoration: const BoxDecoration(
              color: Color(0xFFF0EDFF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6339F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.compare_arrows_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location Comparisons',
                        style: TextStyle(
                          color: Color(0xFF08104F),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Compare cities with AI analysis',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Latest comparison or create new
                if (_latestComparison != null) ...[
                  _buildLatestComparisonPreview(),
                  const SizedBox(height: 16),
                ],
                
                // Create new comparison button
                _buildCreateComparisonButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLatestComparisonPreview() {
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comparison Title Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _latestComparison!.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF08104F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Color(0xFF6339F9),
                  ),
                ],
              ),
            ),
            
            // Locations Legend
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: List.generate(_latestComparison!.locations.length, (index) {
                  final colors = [
                    const Color(0xFF6339F9),
                    const Color(0xFFFF781F),
                    const Color(0xFF00C48C),
                  ];
                  
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index < _latestComparison!.locations.length - 1 ? 8 : 0,
                      ),
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
                          const SizedBox(width: 6),
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
            ),
            
            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                color: Colors.grey.shade200,
                height: 1,
              ),
            ),
            
            // Chart
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildComparisonPreviewChart(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildComparisonPreviewChart() {
    if (_locationScores.isEmpty) return const SizedBox();
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(_categories.length, (index) {
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
                          color: Color(0xFF08104F),
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
                  const SizedBox(height: 8),
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
                            right: locationIndex < _locationScores.length - 1 ? 8 : 0,
                          ),
                          child: Stack(
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: animatedScore,
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: colors[locationIndex % colors.length],
                                    borderRadius: BorderRadius.circular(4),
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
          }),
        );
      },
    );
  }
  
  Widget _buildCreateComparisonButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LocationComparisonPage(fromNavBar: false),
          ),
        ).then((_) {
          _loadLatestComparison();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6339F9), Color(0xFF8C6FFF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6339F9).withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              'Create New Comparison',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 200,
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
            decoration: const BoxDecoration(
              color: Color(0xFFF0EDFF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6339F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.compare_arrows_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location Comparisons',
                        style: TextStyle(
                          color: Color(0xFF08104F),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Compare cities with AI analysis',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.compare_arrows_rounded,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No comparisons yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF08104F),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first location comparison',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                _buildCreateComparisonButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 