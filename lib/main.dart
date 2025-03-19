import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dart_openai/dart_openai.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'features/location_analysis/presentation/pages/explore_page.dart';
import 'features/location_analysis/presentation/pages/profile_page.dart';
import 'features/location_analysis/presentation/pages/location_comparison_page.dart';
import 'features/ai_assistant/presentation/pages/ai_assistant_page.dart';
import 'features/ai_assistant/presentation/pages/ai_hub_page.dart';
import 'features/location_analysis/domain/models/saved_location_model.dart';
import 'features/location_analysis/domain/models/recently_viewed_location_model.dart';
import 'features/ai_assistant/domain/models/message_model.dart';
import 'features/location_analysis/domain/models/premium_model.dart';
import 'features/location_analysis/domain/models/profile_model.dart';
import 'features/location_analysis/data/services/premium_service.dart';
import 'features/location_analysis/data/models/comparison_history_model.dart';
import 'features/location_analysis/data/services/comparison_history_service.dart';
import 'core/services/supabase_service.dart';
import 'core/network/network_connectivity_service.dart';
import 'core/di/service_locator.dart';

void main() async {
  // Start benchmark
  final stopwatch = Stopwatch()..start();
  
  // Initialize Flutter framework
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kDebugMode) {
    print('Main initializing... ${stopwatch.elapsedMilliseconds}ms');
  }
  
  // Run all initialization tasks in parallel
  await Future.wait([
    dotenv.load(),
    Hive.initFlutter(),
  ]);
  
  if (kDebugMode) {
    print('Parallel initializations completed: ${stopwatch.elapsedMilliseconds}ms');
  }
  
  // Register Hive adapters
  _registerHiveAdapters();
  if (kDebugMode) {
    print('Hive adapters registered: ${stopwatch.elapsedMilliseconds}ms');
  }
  
  // Initialize service locator
  await setupServiceLocator();
  if (kDebugMode) {
    print('Service locator initialized: ${stopwatch.elapsedMilliseconds}ms');
  }
  
  // Check connectivity status periodically
  Timer.periodic(const Duration(seconds: 30), (_) {
    serviceLocator<NetworkConnectivityService>().checkConnectivity();
  });
  
  try {
    if (kDebugMode) {
      print('Services initialized: ${stopwatch.elapsedMilliseconds}ms');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Service initialization error: $e');
    }
  }
  
  final openAiKey = dotenv.env['OPENAI_API_KEY'];
  if (openAiKey == null || openAiKey.isEmpty) {
    throw Exception('OPENAI_API_KEY environment variable is not set');
  }
  
  // OpenAI configuration
  OpenAI.apiKey = openAiKey;
  OpenAI.requestsTimeOut = const Duration(minutes: 2); // 2 minutes timeout
  
  // Open Hive boxes
  try {
    await _openHiveBoxes();
    if (kDebugMode) {
      print('Hive boxes opened: ${stopwatch.elapsedMilliseconds}ms');
    }
  } catch (e) {
    print('Error opening Hive boxes: $e');
    // Delete Hive database
    await Hive.deleteFromDisk();
    await Hive.initFlutter();
    
    // Register Hive adapters again
    _registerHiveAdapters();
    
    // Open Hive boxes again
    try {
      await _openHiveBoxes();
      if (kDebugMode) {
        print('Hive boxes reset and opened: ${stopwatch.elapsedMilliseconds}ms');
      }
    } catch (e) {
      print('Error opening Hive boxes on reset: $e');
      throw Exception('Hive database initialization failed: $e');
    }
  }
  
  // Initialize premium service
  final premiumService = PremiumService();
  await premiumService.initialize();
  
  if (kDebugMode) {
    print('Initialization completed: ${stopwatch.elapsedMilliseconds}ms');
  }
  stopwatch.stop();
  
  runApp(const MyApp());
}

Future<void> _openHiveBoxes() async {
  final boxNames = [
    'places_cache',
    'saved_locations',
    'chat_history',
    'recently_viewed_locations',
    'premium_status',
    'comparison_history'
  ];
  
  for (var boxName in boxNames) {
    try {
      switch(boxName) {
        case 'places_cache':
          await Hive.openBox(boxName);
          break;
        case 'saved_locations':
          await Hive.openBox<SavedLocationModel>(boxName);
          break;
        case 'chat_history':
          await Hive.openBox<MessageModel>(boxName);
          break;
        case 'recently_viewed_locations':
          await Hive.openBox<RecentlyViewedLocationModel>(boxName);
          break;
        case 'premium_status':
          await Hive.openBox<PremiumModel>(boxName);
          break;
        case 'comparison_history':
          await Hive.openBox<ComparisonHistoryModel>(boxName);
          break;
      }
    } catch (e) {
      print('$boxName opening error: $e');
      // Delete box and reopen
      await Hive.deleteBoxFromDisk(boxName);
      switch(boxName) {
        case 'places_cache':
          await Hive.openBox(boxName);
          break;
        case 'saved_locations':
          await Hive.openBox<SavedLocationModel>(boxName);
          break;
        case 'chat_history':
          await Hive.openBox<MessageModel>(boxName);
          break;
        case 'recently_viewed_locations':
          await Hive.openBox<RecentlyViewedLocationModel>(boxName);
          break;
        case 'premium_status':
          await Hive.openBox<PremiumModel>(boxName);
          break;
        case 'comparison_history':
          await Hive.openBox<ComparisonHistoryModel>(boxName);
          break;
      }
      print('$boxName deleted and reopened.');
    }
  }
}

/// Register all Hive adapters
void _registerHiveAdapters() {
  // Register adapters if not already registered
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(SavedLocationModelAdapter());
  }
  
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(MessageModelAdapter());
  }
  
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(RecentlyViewedLocationModelAdapter());
  }
  
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(ProfileModelAdapter());
  }
  
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(PremiumModelAdapter());
  }
  
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(ComparisonHistoryModelAdapter());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOGI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Satoshi',
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF6339F9),
          secondary: const Color(0xFF8B6DFA),
          tertiary: const Color(0xFFFF781F),
          brightness: Brightness.light,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: const Color(0xFF08104F),
          error: Colors.red,
          onError: Colors.white,
          background: const Color(0xFFF9F5F1),
          onBackground: const Color(0xFF08104F),
          surface: const Color(0xFF08104F),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF9F5F1),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color(0xFFCDBEFF),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7E5BED),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF7E5BED),
        ),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final List<Widget> _pages = [
    const ExplorePage(key: PageStorageKey('explore')),
    const AIHubPage(key: PageStorageKey('ai_hub')),
    const ProfilePage(key: PageStorageKey('profile')),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuint),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6339F9).withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 5),
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    icon: Icons.explore,
                    activeIcon: Icons.explore_rounded,
                    isSelected: _selectedIndex == 0,
                    index: 0,
                  ),
                  const SizedBox(width: 60), // Space for center button
                  _buildNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    isSelected: _selectedIndex == 2,
                    index: 2,
                  ),
                ],
              ),
              Positioned.fill(
                child: Center(
                  child: _buildCenterButton(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    final isSelected = _selectedIndex == 1;
    
    return GestureDetector(
      onTap: () {
        if (_selectedIndex != 1) {
          setState(() => _selectedIndex = 1);
          _animationController.reset();
          _animationController.forward();
        }
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected 
              ? [const Color(0xFF6339F9), const Color(0xFF8C6FFF)]
              : [const Color(0xFFF1ECFF), const Color(0xFFF1ECFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6339F9).withOpacity(isSelected ? 0.4 : 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isSelected && _selectedIndex == 1 ? _scaleAnimation.value : 1.0,
                child: Icon(
                  Icons.auto_awesome,
                  color: isSelected ? Colors.white : const Color(0xFF6339F9),
                  size: 26,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required bool isSelected,
    required int index,
  }) {
    return InkWell(
      onTap: () {
        if (_selectedIndex != index) {
          setState(() => _selectedIndex = index);
          _animationController.reset();
          _animationController.forward();
        }
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        width: 60,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.all(isSelected ? 12 : 0),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF6339F9) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: const Color(0xFF6339F9).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ] : null,
            ),
            child: isSelected 
              ? AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _selectedIndex == index ? _scaleAnimation.value : 1.0,
                      child: Icon(
                        activeIcon,
                        color: Colors.white,
                        size: 24,
                      ),
                    );
                  },
                )
              : Icon(
                  icon,
                  color: const Color(0xFF9CA3AF),
                  size: 24,
                ),
          ),
        ),
      ),
    );
  }
}
