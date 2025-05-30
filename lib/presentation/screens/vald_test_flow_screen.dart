// lib/presentation/screens/vald_test_flow_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/vald_test_flow_controller.dart';
import '../controllers/usb_controller.dart';
import '../controllers/athlete_controller.dart';
import '../widgets/vald_flow_widgets/connection_step_widget.dart';
import '../widgets/vald_flow_widgets/profile_selection_widget.dart';
import '../widgets/vald_flow_widgets/test_type_selection_widget.dart';
import '../widgets/vald_flow_widgets/zero_calibration_widget.dart';
import '../widgets/vald_flow_widgets/weight_measurement_widget.dart';
import '../widgets/vald_flow_widgets/testing_widget.dart';
import '../widgets/vald_flow_widgets/results_widget.dart';
import '../../core/constants/test_constants.dart';
import '../../app/injection_container.dart';

class ValdTestFlowScreen extends StatefulWidget {
  const ValdTestFlowScreen({super.key});

  @override
  State<ValdTestFlowScreen> createState() => _ValdTestFlowScreenState();
}

class _ValdTestFlowScreenState extends State<ValdTestFlowScreen>
    with TickerProviderStateMixin {
  
  late ValdTestFlowController _flowController;
  late UsbController _usbController;
  late AthleteController _athleteController;
  
  // Animations
  late AnimationController _headerAnimationController;
  late AnimationController _stepAnimationController;
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _stepFadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _setupListeners();
    _performInitialSetup();
  }

  void _initializeControllers() {
    // Get controllers from dependency injection
    _flowController = ValdTestFlowController();
    _usbController = sl<UsbController>();
    _athleteController = sl<AthleteController>();
  }

  void _initializeAnimations() {
    // Header animation
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerSlideAnimation = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOutCubic),
    );

    // Step content animation
    _stepAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _stepFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _stepAnimationController, curve: Curves.easeIn),
    );

    // Start animations
    _headerAnimationController.forward();
    _stepAnimationController.forward();
  }

  void _setupListeners() {
    // Listen to USB connection changes
    _usbController.addListener(_onUsbStatusChanged);
    
    // Listen to flow controller changes
    _flowController.addListener(_onFlowControllerChanged);
    
    // Listen to force data for real-time processing
    _startForceDataListening();
  }

  void _onUsbStatusChanged() {
    // Auto-connect when USB device is available
    if (_usbController.isConnected && !_flowController.isConnected) {
      _flowController.connectToDevice(
        _usbController.connectedDeviceId ?? 'Unknown Device'
      );
    } else if (!_usbController.isConnected && _flowController.isConnected) {
      _flowController.disconnect();
    }
  }

  void _onFlowControllerChanged() {
    // Trigger step animation when step changes
    _stepAnimationController.reset();
    _stepAnimationController.forward();
  }

  void _startForceDataListening() {
    _usbController.forceDataStream?.listen((forceData) {
      // Forward force data to flow controller for processing
      _flowController.addTestData(forceData);
    });
  }

  Future<void> _performInitialSetup() async {
    // Load athletes if not already loaded
    if (_athleteController.totalAthletes == 0) {
      await _athleteController.loadAthletes();
    }

    // Auto-scan for USB devices
    if (_usbController.availableDevices.isEmpty) {
      await _usbController.refreshDevices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _flowController),
        ChangeNotifierProvider.value(value: _usbController),
        ChangeNotifierProvider.value(value: _athleteController),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Column(
            children: [
              // Animated Header
              _buildAnimatedHeader(),
              
              // Main Content Area
              Expanded(
                child: _buildMainContent(),
              ),
            ],
          ),
        ),
        
        // Floating Action Button for emergency actions
        floatingActionButton: _buildFloatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: _headerSlideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _headerSlideAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Consumer<ValdTestFlowController>(
              builder: (context, controller, child) {
                return Column(
                  children: [
                    // App Title and Status
                    Row(
                      children: [
                        // App Icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: TestConstants.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.analytics,
                            color: TestConstants.primaryBlue,
                            size: 28,
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Title and Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'IzForce Test System',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: TestConstants.primaryBlue,
                                ),
                              ),
                              Text(
                                controller.currentStep.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Connection Status
                        _buildConnectionStatus(),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Progress Indicator
                    _buildProgressIndicator(controller),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionStatus() {
    return Consumer<UsbController>(
      builder: (context, usbController, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: usbController.isConnected 
                ? TestConstants.successGreen.withOpacity(0.1)
                : TestConstants.warningOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: usbController.isConnected 
                  ? TestConstants.successGreen
                  : TestConstants.warningOrange,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                usbController.isConnected ? Icons.wifi : Icons.wifi_off,
                size: 16,
                color: usbController.isConnected 
                    ? TestConstants.successGreen
                    : TestConstants.warningOrange,
              ),
              const SizedBox(width: 6),
              Text(
                usbController.isConnected ? 'Connected' : 'Disconnected',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: usbController.isConnected 
                      ? TestConstants.successGreen
                      : TestConstants.warningOrange,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator(ValdTestFlowController controller) {
    return Column(
      children: [
        // Step Dots
        Row(
          children: ValdTestStep.values.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isActive = step == controller.currentStep;
            final isCompleted = ValdTestStep.values.indexOf(controller.currentStep) > index;
            
            return Expanded(
              child: Row(
                children: [
                  // Step Circle
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive 
                          ? TestConstants.primaryBlue
                          : isCompleted 
                              ? TestConstants.successGreen
                              : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isActive ? Colors.white : Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  
                  // Connector Line
                  if (index < ValdTestStep.values.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted ? TestConstants.successGreen : Colors.grey[300],
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 16),
        
        // Progress Bar
        LinearProgressIndicator(
          value: controller.overallProgress,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(TestConstants.primaryBlue),
          minHeight: 4,
        ),
        
        const SizedBox(height: 12),
        
        // Step Description
        Row(
          children: [
            Icon(
              controller.currentStep.icon,
              color: TestConstants.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.currentStep.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: TestConstants.primaryBlue,
                    ),
                  ),
                  Text(
                    controller.currentStep.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${(controller.overallProgress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: TestConstants.primaryBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Consumer<ValdTestFlowController>(
      builder: (context, controller, child) {
        // Error State
        if (controller.errorMessage != null) {
          return _buildErrorState(controller.errorMessage!);
        }
        
        // Loading State
        if (controller.isLoading) {
          return _buildLoadingState();
        }
        
        // Step Content with Animation
        return AnimatedBuilder(
          animation: _stepFadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _stepFadeAnimation,
              child: _buildStepContent(controller.currentStep),
            );
          },
        );
      },
    );
  }

  Widget _buildStepContent(ValdTestStep step) {
    switch (step) {
      case ValdTestStep.connection:
        return const ConnectionStepWidget();
      case ValdTestStep.profileSelection:
        return const ProfileSelectionWidget();
      case ValdTestStep.testTypeSelection:
        return const TestTypeSelectionWidget();
      case ValdTestStep.zeroCalibration:
        return const ZeroCalibrationWidget();
      case ValdTestStep.weightMeasurement:
        return const WeightMeasurementWidget();
      case ValdTestStep.testing:
        return const TestingWidget();
      case ValdTestStep.results:
        return const ResultsWidget();
    }
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: TestConstants.errorRed,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Test Flow Error',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: TestConstants.errorRed,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _flowController.goToPreviousStep(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _flowController.restartFlow(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restart Flow'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(TestConstants.primaryBlue),
              strokeWidth: 4,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Processing...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<ValdTestFlowController>(
      builder: (context, controller, child) {
        return FloatingActionButton(
          onPressed: () => _showQuickActionsMenu(context),
          backgroundColor: TestConstants.primaryBlue,
          child: const Icon(Icons.more_vert, color: Colors.white),
        );
      },
    );
  }

  void _showQuickActionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: TestConstants.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            
            // Restart Flow
            ListTile(
              leading: const Icon(Icons.refresh, color: TestConstants.primaryBlue),
              title: const Text('Restart Test Flow'),
              subtitle: const Text('Start over from connection step'),
              onTap: () {
                Navigator.pop(context);
                _showRestartConfirmation();
              },
            ),
            
            // USB Controls
            ListTile(
              leading: const Icon(Icons.usb, color: TestConstants.primaryBlue),
              title: const Text('USB Connection'),
              subtitle: Text(_usbController.connectionStatusText),
              onTap: () {
                Navigator.pop(context);
                _showUsbControlsDialog();
              },
            ),
            
            // Mock Controls (Development)
            if (_flowController.currentStep == ValdTestStep.testing)
              ListTile(
                leading: const Icon(Icons.sports, color: TestConstants.warningOrange),
                title: const Text('Simulate Jump'),
                subtitle: const Text('Trigger mock jump for testing'),
                onTap: () {
                  Navigator.pop(context);
                  _usbController.triggerMockJump();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showRestartConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restart Test Flow'),
        content: const Text(
          'Are you sure you want to restart the test flow? All progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _flowController.restartFlow();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TestConstants.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  void _showUsbControlsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('USB Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${_usbController.connectionStatusText}'),
            const SizedBox(height: 8),
            Text('Available Devices: ${_usbController.availableDevices.length}'),
            if (_usbController.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${_usbController.errorMessage}',
                style: const TextStyle(color: TestConstants.errorRed),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!_usbController.isConnected)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _usbController.refreshDevices();
                if (_usbController.availableDevices.isNotEmpty) {
                  await _usbController.connectToDevice(
                    _usbController.availableDevices.first
                  );
                }
              },
              child: const Text('Reconnect'),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usbController.removeListener(_onUsbStatusChanged);
    _flowController.removeListener(_onFlowControllerChanged);
    _flowController.dispose();
    _headerAnimationController.dispose();
    _stepAnimationController.dispose();
    super.dispose();
  }
}

/// Custom app bar for better UX
class ValdTestFlowAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ValdTestFlowController flowController;

  const ValdTestFlowAppBar({
    super.key,
    required this.flowController,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'IzForce Test',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            flowController.currentStep.title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showStepInfo(context),
          tooltip: 'Step Information',
        ),
      ],
    );
  }

  void _showStepInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(flowController.currentStep.title),
        content: Text(flowController.currentStep.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}