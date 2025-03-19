import 'package:flutter/material.dart';
import 'package:mogi/features/ai_assistant/presentation/pages/ai_assistant_page.dart';
import 'package:mogi/features/location_analysis/presentation/pages/location_comparison_page.dart';
import '../../../../core/network/network_connectivity_service.dart';
import '../../../../core/widgets/no_internet_connection_widget.dart';
import '../../../location_analysis/data/services/premium_service.dart';
import '../../../location_analysis/presentation/pages/premium_page.dart';
import '../../../location_analysis/data/services/profile_service.dart';
import '../../data/services/chat_history_service.dart';
import '../../domain/models/message_model.dart';

class AIHubPage extends StatefulWidget {
  const AIHubPage({Key? key}) : super(key: key);

  @override
  State<AIHubPage> createState() => _AIHubPageState();
}

class _AIHubPageState extends State<AIHubPage> with SingleTickerProviderStateMixin {
  final NetworkConnectivityService _connectivityService = NetworkConnectivityService();
  final PremiumService _premiumService = PremiumService();
  final ChatHistoryService _chatHistoryService = ChatHistoryService();
  final ProfileService _profileService = ProfileService();
  late AnimationController _animationController;
  List<MessageModel> _recentMessages = [];
  bool _isLoading = true;
  int _totalAIInteractions = 0;
  String _userCity = '';
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initServices();
    
    // Listen for connectivity changes
    _connectivityService.isConnected.addListener(_onConnectivityChanged);
  }
  
  void _onConnectivityChanged() {
    if (mounted) {
      setState(() {});
    }
  }
  
  Future<void> _initServices() async {
    setState(() => _isLoading = true);
    try {
      await _premiumService.init();
      await _connectivityService.checkConnectivity();
      await _chatHistoryService.init();
      await _profileService.init();
      
      // Kullanıcı profilinden şehir bilgisini al
      final profile = await _profileService.getProfile();
      _userCity = profile?.city ?? 'Paris';
      
      // Get recent conversations
      final messages = await _chatHistoryService.getMessages();
      
      // Calculate total AI interactions
      if (messages.isNotEmpty) {
        // Count user messages only for total questions
        _totalAIInteractions = messages.where((msg) => !msg.isAIMessage).length;
      }
      
      if (mounted) {
        setState(() {
          _recentMessages = messages.take(3).toList(); // Take last 3 messages
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _connectivityService.isConnected.removeListener(_onConnectivityChanged);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F1),
      body: !_connectivityService.isConnected.value
        ? NoInternetConnectionWidget(
            onRetry: () async {
              await _connectivityService.checkConnectivity();
              _initServices();
            },
            message: 'Internet connection is required for AI features. Please check your connection and try again.',
          )
        : SafeArea(
            child: RefreshIndicator(
              onRefresh: _initServices,
              color: Theme.of(context).colorScheme.primary,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverAppBar(
                    backgroundColor: const Color(0xFFF9F5F1),
                    surfaceTintColor: Colors.transparent,
                    scrolledUnderElevation: 0,
                    pinned: true,
                    floating: true,
                    elevation: 0,
                    expandedHeight: 80,
                    toolbarHeight: 80,
                    flexibleSpace: FlexibleSpaceBar(
                      expandedTitleScale: 1.0,
                      background: Container(
                        color: const Color(0xFFF9F5F1),
                        padding: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 26,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'AI Features',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF08104F),
                                ),
                              ),
                              const Spacer(),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const PremiumPage(),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(24),
                                  child: Ink(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF6B2C),
                                          Color(0xFFFF8F4C),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${_premiumService.isInitialized ? _premiumService.mogiPoints : 0} Mogi',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // AI Statistics
                  if (!_isLoading) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: _buildAIStats(),
                      ),
                    ),
                  ],

                  // Main AI Features
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Artificial Intelligence Features',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildFeatureCard(
                            icon: Icons.chat_bubble_outline_rounded,
                            title: 'AI Chat Assistant',
                            description: 'Get information about locations and ask questions with MOGI AI assistant.',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6339F9), Color(0xFF8C6FFF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AIAssistantPage(),
                                ),
                              ).then((_) => _initServices());
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureCard(
                            icon: Icons.compare_arrows_rounded,
                            title: 'Location Comparison',
                            description: 'Analyze and compare two or more locations with AI assistance.',
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B2C), Color(0xFFFF8F4C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LocationComparisonPage(fromNavBar: false),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Popular Questions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Popular Questions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverToBoxAdapter(
                      child: _buildPopularQuestions(),
                    ),
                  ),
                  
                  // AI Tips
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'AI Chat Tips',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverToBoxAdapter(
                      child: _buildAITips(),
                    ),
                  ),
                  
                  // Categories
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ask About These Topics',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverToBoxAdapter(
                      child: _buildCategoryCards(),
                    ),
                  ),
                  
                  // Recent Conversations
                  if (_recentMessages.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Recent Conversations',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(
                                    builder: (context) => const AIAssistantPage()
                                  )
                                ).then((_) => _initServices());
                              },
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final message = _recentMessages[index];
                            if (!message.isAIMessage) {
                              return _buildRecentMessageItem(message);
                            }
                            return const SizedBox.shrink();
                          },
                          childCount: _recentMessages.length,
                        ),
                      ),
                    ),
                  ],
                  
                  // Coming Soon Features
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Coming Soon Features',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildComingSoonCard(
                            icon: Icons.home_work_outlined,
                            title: 'AI Real Estate Recommendations',
                            description: 'Find the most suitable properties with AI based on your preferences.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildAIStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.9),
            Theme.of(context).colorScheme.secondary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your AI Statistics',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.star_border_rounded,
                  value: (_premiumService.isPremium ? 'Premium' : 'Free'),
                  label: 'Account Type',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.diamond_outlined,
                  value: '${_premiumService.isInitialized ? _premiumService.mogiPoints : 0}',
                  label: 'Mogi Points',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPopularQuestions() {
    final questions = [
      'How is the quality of schools in the area?',
      'Which neighborhood is safer to live in?',
      'What are the transportation options?',
      'How much are the real estate prices?',
    ];

    // Şehir ismini eklemek için her soru için şehirli versiyonu oluştur
    final questionsWithCity = [
      'How is the quality of schools in $_userCity?',
      'Which neighborhood is safer to live in $_userCity?',
      'What are the transportation options in $_userCity?',
      'How much are the real estate prices in $_userCity?',
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 12,
      children: questions.asMap().entries.map((entry) {
        final index = entry.key;
        final question = entry.value;
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AIAssistantPage(initialMessage: questionsWithCity[index]),
                ),
                ).then((_) => _initServices());
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  question,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentMessageItem(MessageModel message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.question_answer_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message.text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios,
            color: Theme.of(context).colorScheme.primary,
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.grey[400],
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Coming Soon',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
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

  Widget _buildAITips() {
    final tips = [
      'Be specific about locations for better results',
      'Ask follow-up questions to get deeper insights',
      'Compare multiple aspects of a location',
      'Ask for local recommendations',
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'How to get the most out of AI Chat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AIAssistantPage(
                    initialMessage: "How can I get the most out of MOGI AI?",
                  ),
                ),
              ).then((_) => _initServices());
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Learn More About AI Features',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCards() {
    final categories = [
      {
        'icon': Icons.home_outlined,
        'title': 'Housing',
        'questions': [
          'What are housing prices in this area?',
          'Are there any new developments?',
          "What's the rental market like?"
        ],
        'questionsWithCity': [
          'What are housing prices in $_userCity?',
          'Are there any new developments in $_userCity?',
          "What's the rental market like in $_userCity?"
        ],
      },
      {
        'icon': Icons.family_restroom,
        'title': 'Family Life',
        'questions': [
          'How are the schools rated?',
          'What family activities are available?',
          'Are there good parks and playgrounds?'
        ],
        'questionsWithCity': [
          'How are the schools rated in $_userCity?',
          'What family activities are available in $_userCity?',
          'Are there good parks and playgrounds in $_userCity?'
        ],
      },
      {
        'icon': Icons.directions_bus_outlined,
        'title': 'Transportation',
        'questions': [
          'How is public transportation?',
          "What's the average commute time?",
          'Are there bike lanes?'
        ],
        'questionsWithCity': [
          'How is public transportation in $_userCity?',
          "What's the average commute time in $_userCity?",
          'Are there bike lanes in $_userCity?'
        ],
      },
      {
        'icon': Icons.local_police_outlined,
        'title': 'Safety',
        'questions': [
          'What are crime rates in this area?',
          'Are there neighborhood watch programs?',
          'How safe is it at night?'
        ],
        'questionsWithCity': [
          'What are crime rates in $_userCity?',
          'Are there neighborhood watch programs in $_userCity?',
          'How safe is it at night in $_userCity?'
        ],
      },
    ];
    
    return Column(
      children: categories.map((category) => _buildCategoryCard(
        icon: category['icon'] as IconData,
        title: category['title'] as String,
        questions: category['questions'] as List<String>,
        questionsWithCity: category['questionsWithCity'] as List<String>,
      )).toList(),
    );
  }
  
  Widget _buildCategoryCard({
    required IconData icon,
    required String title,
    required List<String> questions,
    required List<String> questionsWithCity,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ExpansionTile(
        key: PageStorageKey<String>(title),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.transparent),
        ),
        collapsedShape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.transparent),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF08104F),
          ),
        ),
        subtitle: Text(
          '${questions.length} example questions',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AIAssistantPage(initialMessage: questionsWithCity[index]),
                  ),
                ).then((_) => _initServices());
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
} 