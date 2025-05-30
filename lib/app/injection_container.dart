// lib/app/injection_container.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../presentation/controllers/usb_controller.dart';
import '../presentation/controllers/athlete_controller.dart';
import '../presentation/controllers/vald_test_flow_controller.dart';
import '../services/database_service.dart';

/// Global service locator instance
/// VALD ForceDecks benzeri dependency injection sistemi
final GetIt sl = GetIt.instance;

/// Dependency injection setup
/// Tüm controller'ları ve service'leri tek yerden yönet
class InjectionContainer {
  
  /// Initialize all dependencies
  static Future<void> init() async {
    await _initControllers();
    await _initServices();
    await _initRepositories();
    await _initUseCases();
    
    print('✅ Dependency injection initialized');
  }

  /// Reset all dependencies (test için)
  static Future<void> reset() async {
    await sl.reset();
    print('🔄 Dependencies reset');
  }

  /// Initialize controllers (Presentation Layer)
  static Future<void> _initControllers() async {
    // USB Controller - Singleton (tek instance)
    sl.registerSingleton<UsbController>(UsbController());
    
    // Athlete Controller - Singleton
    sl.registerSingleton<AthleteController>(AthleteController());
    
    // VALD Test Flow Controller - Factory (her kullanımda yeni instance)
    sl.registerFactory<ValdTestFlowController>(() => ValdTestFlowController());
    
    print('📱 Controllers registered');
  }

  /// Initialize services (Data Layer)
  static Future<void> _initServices() async {
    try {
      // Database Service - Singleton
      sl.registerSingleton<DatabaseService>(DatabaseService());
      
      debugPrint('🔧 Services registered successfully');
    } catch (e) {
      debugPrint('❌ Services registration failed: $e');
      // Don't rethrow - let app continue
    }
  }

  /// Initialize repositories (Domain Layer)
  static Future<void> _initRepositories() async {
    // Athlete Repository - Singleton
    // sl.registerSingleton<AthleteRepository>(
    //   AthleteRepositoryImpl(sl<DatabaseService>())
    // );
    
    // Test Results Repository - Singleton
    // sl.registerSingleton<TestResultsRepository>(
    //   TestResultsRepositoryImpl(sl<DatabaseService>())
    // );
    
    print('🗃️ Repositories registered');
  }

  /// Initialize use cases (Domain Layer)
  static Future<void> _initUseCases() async {
    // Athlete Use Cases
    // sl.registerFactory<GetAthletesUseCase>(
    //   () => GetAthletesUseCase(sl<AthleteRepository>())
    // );
    
    // Test Use Cases
    // sl.registerFactory<RunTestUseCase>(
    //   () => RunTestUseCase(sl<TestResultsRepository>())
    // );
    
    print('⚙️ Use cases registered');
  }
}

/// Service locator extensions for easy access
extension ServiceLocatorExtensions on GetIt {
  
  /// Get Database Service
  DatabaseService get databaseService => get<DatabaseService>();
  
  /// Get USB Controller
  UsbController get usbController => get<UsbController>();
  
  /// Get Athlete Controller
  AthleteController get athleteController => get<AthleteController>();
  
  /// Get new VALD Test Flow Controller
  ValdTestFlowController get valdTestFlowController => get<ValdTestFlowController>();
  
  /// Check if service is registered
  bool isRegistered<T extends Object>() {
    return isRegistered<T>();
  }
  
  /// Register singleton if not already registered
  void registerSingletonIfNotExists<T extends Object>(T instance) {
    if (!isRegistered<T>()) {
      registerSingleton<T>(instance);
    }
  }
  
  /// Register factory if not already registered
  void registerFactoryIfNotExists<T extends Object>(T Function() factory) {
    if (!isRegistered<T>()) {
      registerFactory<T>(factory);
    }
  }
}

/// Dependency manager for advanced operations
class DependencyManager {
  
  /// Initialize with custom configuration
  static Future<void> initWithConfig(DependencyConfig config) async {
    if (config.resetFirst) {
      await InjectionContainer.reset();
    }
    
    await InjectionContainer.init();
    
    // Apply custom configurations
    if (config.enableMockData) {
      _enableMockData();
    }
    
    if (config.enableDebugMode) {
      _enableDebugMode();
    }
    
    print('🎛️ Dependencies initialized with custom config');
  }
  
  /// Enable mock data for development
  static void _enableMockData() {
    // USB Controller mock mode
    sl<UsbController>().setMockPersonOnPlatform(false);
    
    // Load mock athletes
    sl<AthleteController>().loadAthletes();
    
    print('🎭 Mock data enabled');
  }
  
  /// Enable debug mode
  static void _enableDebugMode() {
    // Enable debug logging
    print('🐛 Debug mode enabled');
  }
  
  /// Get dependency health status
  static DependencyHealthStatus getHealthStatus() {
    final status = DependencyHealthStatus();
    
    try {
      // Check critical dependencies
      status.databaseServiceOk = sl.isRegistered<DatabaseService>();
      status.usbControllerOk = sl.isRegistered<UsbController>();
      status.athleteControllerOk = sl.isRegistered<AthleteController>();
      status.valdTestFlowControllerOk = sl.isRegistered<ValdTestFlowController>();
      
      // Check connection status
      if (status.usbControllerOk) {
        status.usbConnected = sl<UsbController>().isConnected;
      }
      
      // Check data availability
      if (status.athleteControllerOk) {
        status.athletesLoaded = sl<AthleteController>().totalAthletes > 0;
      }
      
      status.overall = status.databaseServiceOk &&
                      status.usbControllerOk && 
                      status.athleteControllerOk && 
                      status.valdTestFlowControllerOk;
      
    } catch (e) {
      status.error = e.toString();
      status.overall = false;
    }
    
    return status;
  }
  
  /// Perform dependency health check
  static Future<bool> performHealthCheck() async {
    final status = getHealthStatus();
    
    if (!status.overall) {
      print('❌ Dependency health check failed: ${status.error}');
      return false;
    }
    
    // Perform functional tests
    try {
      // Test USB Controller
      await sl<UsbController>().refreshDevices();
      
      // Test Athlete Controller
      if (!status.athletesLoaded) {
        await sl<AthleteController>().loadAthletes();
      }
      
      print('✅ Dependency health check passed');
      return true;
      
    } catch (e) {
      print('❌ Functional health check failed: $e');
      return false;
    }
  }
}

/// Dependency configuration
class DependencyConfig {
  final bool resetFirst;
  final bool enableMockData;
  final bool enableDebugMode;
  final bool performHealthCheck;
  
  const DependencyConfig({
    this.resetFirst = false,
    this.enableMockData = true,
    this.enableDebugMode = false,
    this.performHealthCheck = true,
  });
  
  /// Development configuration
  static const DependencyConfig development = DependencyConfig(
    resetFirst: false,
    enableMockData: true,
    enableDebugMode: true,
    performHealthCheck: true,
  );
  
  /// Production configuration
  static const DependencyConfig production = DependencyConfig(
    resetFirst: false,
    enableMockData: false,
    enableDebugMode: false,
    performHealthCheck: false,
  );
  
  /// Test configuration
  static const DependencyConfig test = DependencyConfig(
    resetFirst: true,
    enableMockData: true,
    enableDebugMode: true,
    performHealthCheck: false,
  );
}

/// Dependency health status
class DependencyHealthStatus {
  bool overall = false;
  bool databaseServiceOk = false;
  bool usbControllerOk = false;
  bool athleteControllerOk = false;
  bool valdTestFlowControllerOk = false;
  bool usbConnected = false;
  bool athletesLoaded = false;
  String? error;
  
  @override
  String toString() {
    return '''
Dependency Health Status:
- Overall: ${overall ? '✅' : '❌'}
- Database Service: ${databaseServiceOk ? '✅' : '❌'}
- USB Controller: ${usbControllerOk ? '✅' : '❌'}
- Athlete Controller: ${athleteControllerOk ? '✅' : '❌'}  
- VALD Test Flow Controller: ${valdTestFlowControllerOk ? '✅' : '❌'}
- USB Connected: ${usbConnected ? '✅' : '❌'}
- Athletes Loaded: ${athletesLoaded ? '✅' : '❌'}
${error != null ? '- Error: $error' : ''}
''';
  }
}

/// Dependency scope management
class DependencyScopes {
  static const String global = 'global';
  static const String session = 'session';
  static const String test = 'test';
  
  /// Switch to different scope
  static Future<void> switchScope(String scope) async {
    switch (scope) {
      case global:
        await _initGlobalScope();
        break;
      case session:
        await _initSessionScope();
        break;
      case test:
        await _initTestScope();
        break;
    }
  }
  
  static Future<void> _initGlobalScope() async {
    await DependencyManager.initWithConfig(DependencyConfig.production);
  }
  
  static Future<void> _initSessionScope() async {
    await DependencyManager.initWithConfig(DependencyConfig.development);
  }
  
  static Future<void> _initTestScope() async {
    await DependencyManager.initWithConfig(DependencyConfig.test);
  }
}

/// Helper functions for common dependency operations
class DependencyHelpers {
  
  /// Quick setup for main app
  static Future<void> setupForApp() async {
    await InjectionContainer.init();
    await sl<AthleteController>().loadAthletes();
    print('🚀 App dependencies ready');
  }
  
  /// Quick setup for testing
  static Future<void> setupForTesting() async {
    await InjectionContainer.reset();
    await DependencyManager.initWithConfig(DependencyConfig.test);
    print('🧪 Test dependencies ready');
  }
  
  /// Emergency reset
  static Future<void> emergencyReset() async {
    try {
      await InjectionContainer.reset();
      await setupForApp();
      print('🆘 Emergency reset completed');
    } catch (e) {
      print('💥 Emergency reset failed: $e');
      rethrow;
    }
  }
  
  /// Get all registered services info
  static Map<String, bool> getRegisteredServicesInfo() {
    return {
      'DatabaseService': sl.isRegistered<DatabaseService>(),
      'UsbController': sl.isRegistered<UsbController>(),
      'AthleteController': sl.isRegistered<AthleteController>(), 
      'ValdTestFlowController': sl.isRegistered<ValdTestFlowController>(),
    };
  }
}