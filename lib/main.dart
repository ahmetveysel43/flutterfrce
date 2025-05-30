// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:izLab/services/database_service.dart';
import 'package:provider/provider.dart';
import 'app/injection_container.dart';
import 'presentation/screens/vald_test_flow_screen.dart';
import 'presentation/controllers/usb_controller.dart';
import 'presentation/controllers/athlete_controller.dart';
import 'core/constants/test_constants.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await _initializeDependencies();
  
  // Configure system UI
  _configureSystemUI();
  
  // Run the app
  runApp(const IzForceApp());
}

/// Initialize all dependencies
Future<void> _initializeDependencies() async {
  try {
    debugPrint('🔄 Starting dependency initialization...');
    
    // Initialize core dependencies only
    await InjectionContainer.init();
    
    debugPrint('✅ Core dependencies initialized');
    
    // Try to initialize database separately with error handling
    try {
      if (sl.isRegistered<DatabaseService>()) {
        debugPrint('📊 Database service found, generating mock data...');
        // Don't await this - do it in background
        sl<DatabaseService>().generateMockData().catchError((e) {
          debugPrint('❌ Mock data generation failed: $e');
        });
      }
    } catch (e) {
      debugPrint('❌ Database initialization failed: $e');
      // Continue without database - app should still work
    }
    
    debugPrint('✅ IzForce App dependencies initialized successfully');
    
  } catch (e) {
    debugPrint('❌ Critical dependency initialization failed: $e');
    // Don't rethrow - let app continue with minimal functionality
  }
}

/// Configure system UI appearance
void _configureSystemUI() {
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);
  
  // Configure status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}

class IzForceApp extends StatelessWidget {
  const IzForceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Global providers using dependency injection
        ChangeNotifierProvider<UsbController>.value(
          value: sl<UsbController>(),
        ),
        ChangeNotifierProvider<AthleteController>.value(
          value: sl<AthleteController>(),
        ),
      ],
      child: MaterialApp(
        title: 'IzForce - VALD ForceDecks Clone',
        debugShowCheckedModeBanner: false,
        
        // Theme configuration
        theme: _buildAppTheme(),
        
        // Home screen
        home: const AppLoadingScreen(),
        
        // Error handling
        builder: (context, widget) {
          // Handle layout errors
          ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
            return _buildErrorWidget(errorDetails);
          };
          
          return widget ?? const SizedBox.shrink();
        },
      ),
    );
  }

  /// Build app theme with VALD-inspired colors
  ThemeData _buildAppTheme() {
    return ThemeData(
      // Primary colors
      primarySwatch: Colors.blue,
      primaryColor: TestConstants.primaryBlue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: TestConstants.primaryBlue,
        brightness: Brightness.light,
      ),
      
      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: TestConstants.primaryBlue,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: TestConstants.primaryBlue),
      ),
      
      // Card theme
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        shadowColor: Colors.black26,
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TestConstants.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TestConstants.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // Text theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: TestConstants.primaryBlue,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: TestConstants.primaryBlue,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.black54,
        ),
      ),
      
      // Use Material 3
      useMaterial3: true,
    );
  }

  /// Build error widget for debugging
  Widget _buildErrorWidget(FlutterErrorDetails errorDetails) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Uygulama Hatası',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorDetails.exception.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Restart app
                  runApp(const IzForceApp());
                },
                child: const Text('Uygulamayı Yeniden Başlat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// App loading screen - dependency initialization sırasında gösterilir
class AppLoadingScreen extends StatefulWidget {
  const AppLoadingScreen({super.key});

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _performAppInitialization();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  Future<void> _performAppInitialization() async {
    try {
      // Wait for animations to settle
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Perform health check
      final healthCheckPassed = await DependencyManager.performHealthCheck();
      
      if (!healthCheckPassed) {
        throw Exception('Health check failed');
      }
      
      // Navigate to main screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ValdTestFlowScreen(),
          ),
        );
      }
      
    } catch (e) {
      debugPrint('❌ App initialization failed: $e');
      
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Başlatma Hatası'),
        content: Text('Uygulama başlatılırken hata oluştu:\n\n$error'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Try emergency reset
              try {
                await DependencyHelpers.emergencyReset();
                _performAppInitialization();
              } catch (e) {
                debugPrint('Emergency reset failed: $e');
              }
            },
            child: const Text('Yeniden Dene'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo/icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: TestConstants.primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.show_chart,
                        size: 64,
                        color: TestConstants.primaryBlue,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // App title
                    const Text(
                      'IzForce',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: TestConstants.primaryBlue,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Subtitle
                    Text(
                      'Force Platform Analysis System',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Loading indicator
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          TestConstants.primaryBlue,
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Loading text
                    Text(
                      'Sistem başlatılıyor...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

/// App lifecycle management
class AppLifecycleManager extends StatefulWidget {
  final Widget child;

  const AppLifecycleManager({
    super.key,
    required this.child,
  });

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('📱 App resumed');
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        debugPrint('📱 App paused');
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        debugPrint('📱 App detached');
        _handleAppDetached();
        break;
      default:
        break;
    }
  }

  void _handleAppResumed() {
    // Reconnect USB if needed
    if (sl.isRegistered<UsbController>()) {
      final usbController = sl<UsbController>();
      if (!usbController.isConnected) {
        usbController.refreshDevices();
      }
    }
  }

  void _handleAppPaused() {
    // Pause data streaming to save battery
    if (sl.isRegistered<UsbController>()) {
      // Could implement pause mechanism
    }
  }

  void _handleAppDetached() {
    // Cleanup resources
    if (sl.isRegistered<UsbController>()) {
      sl<UsbController>().disconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}