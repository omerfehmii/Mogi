import 'package:get_it/get_it.dart';
import '../../features/location_analysis/data/services/profile_service.dart';
import '../../features/location_analysis/data/services/premium_service.dart';
import '../network/network_connectivity_service.dart';
import '../services/supabase_service.dart';

final GetIt serviceLocator = GetIt.instance;

/// Uygulama başlangıcında çağrılacak servis locator başlatma fonksiyonu
Future<void> setupServiceLocator() async {
  // Singleton servisler
  serviceLocator.registerLazySingleton<ProfileService>(() => ProfileService());
  serviceLocator.registerLazySingleton<PremiumService>(() => PremiumService());
  serviceLocator.registerLazySingleton<NetworkConnectivityService>(() => NetworkConnectivityService());
  serviceLocator.registerLazySingleton<SupabaseService>(() => SupabaseService());
  
  // Servisleri başlat
  await _initializeServices();
}

/// Kayıtlı servisleri başlat
Future<void> _initializeServices() async {
  // Önce network servisini başlat
  await serviceLocator<NetworkConnectivityService>().init();
  
  // Sonra diğer servisleri başlat
  await serviceLocator<SupabaseService>().init();
  await serviceLocator<ProfileService>().init();
  await serviceLocator<PremiumService>().init();
}

/// Uygulama kapanırken çağrılacak temizleme fonksiyonu
Future<void> resetServiceLocator() async {
  await serviceLocator.reset();
} 