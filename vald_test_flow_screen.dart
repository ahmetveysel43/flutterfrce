// lib/presentation/screens/vald_test_flow_screen.dart
import 'package:flutter/material.dart';
import 'package:izforce/app/injection_container.dart';
import 'package:izforce/presentation/controllers/athlete_controller.dart';
import 'package:izforce/presentation/controllers/usb_controller.dart';
import 'package:izforce/presentation/controllers/vald_test_flow_controller.dart';
import 'package:izforce/presentation/widgets/vald_flow_widgets/connection_step_widget.dart';
import 'package:izforce/presentation/widgets/vald_flow_widgets/profile_selection_widget.dart';
import 'package:izforce/presentation/widgets/vald_flow_widgets/results_widget.dart';
import 'package:izforce/presentation/widgets/vald_flow_widgets/test_type_selection_widget.dart';
import 'package:izforce/presentation/widgets/vald_flow_widgets/testing_widget.dart';
import 'package:izforce/presentation/widgets/vald_flow_widgets/weight_measurement_widget.dart';
import 'package:izforce/presentation/widgets/vald_flow_widgets/zero_calibration_widget.dart';
import 'package:provider/provider.dart';

class ValdTestFlowScreen extends StatefulWidget {
  const ValdTestFlowScreen({super.key});

  @override
  State<ValdTestFlowScreen> createState() => _ValdTestFlowScreenState();
}

class _ValdTestFlowScreenState extends State<ValdTestFlowScreen> {
  late ValdTestFlowController _flowController;
  late UsbController _usbController;
  late AthleteController _athleteController;

  @override
  void initState() {
    super.initState();
    _flowController = ValdTestFlowController();
    _usbController = sl<UsbController>();
    _athleteController = sl<AthleteController>();
    
    // Load athletes for profile selection
    _athleteController.loadAthletes();
    
    // Listen to USB connection changes
    _usbController.addListener(_onUsbStatusChanged);
    
    // Listen to force data for real-time testing
    _startForceDataListening();
  }

  void _onUsbStatusChanged() {
    if (_usbController.isConnected && !_flowController.isConnected) {
      _flowController.connectToDevice(_usbController.connectedDeviceId ?? 'Unknown');
    } else if (!_usbController.isConnected && _flowController.isConnected) {
      _flowController.disconnect();
    }
  }

  void _startForceDataListening() {
    _usbController.forceDataStream?.listen((forceData) {
      _flowController.addTestData(forceData);
    });
  }

  @override
  void dispose() {
    _usbController.removeListener(_onUsbStatusChanged);
    _flowController.dispose();
    super.dispose();
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
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // Progress Header
            _buildProgressHeader(),
            
            // Step Content
            Expanded(
              child: _buildStepContent(),
            ),
            
            // Navigation Footer
            _buildNavigationFooter(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Consumer<ValdTestFlowController>(
        builder: (context, controller, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'IzForce Test',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
              Text(
                controller.currentStep.title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          );
        },
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        Consumer<ValdTestFlowController>(
          builder: (context, controller, child) {
            return IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _showRestartDialog(),
              tooltip: 'Restart Flow',
            );
          },
        ),
      ],
    );
  }

  Widget _buildProgressHeader() {
    return Consumer<ValdTestFlowController>(
      builder: (context, controller, child) {
        return Container(
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
          child: Column(
            children: [
              // Step Indicators
              Row(
                children: ValdTestStep.values.map((step) {
                  final index = ValdTestStep.values.indexOf(step);
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
                                ? const Color(0xFF1565C0)
                                : isCompleted 
                                    ? Colors.green
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
                                      fontSize: 12,
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
                              color: isCompleted ? Colors.green : Colors.grey[300],
                              margin: const EdgeInsets.symmetric(horizontal: 4),
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
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
                minHeight: 4,
              ),
              
              const SizedBox(height: 12),
              
              // Step Title & Description
              Row(
                children: [
                  Icon(
                    controller.currentStep.icon,
                    color: const Color(0xFF1565C0),
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
                            color: Color(0xFF1565C0),
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
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepContent() {
    return Consumer<ValdTestFlowController>(
      builder: (context, controller, child) {
        // Error Display
        if (controller.errorMessage != null) {
          return _buildErrorWidget(controller.errorMessage!);
        }
        
        // Loading Overlay
        if (controller.isLoading) {
          return _buildLoadingWidget();
        }
        
        // Step Content
        switch (controller.currentStep) {
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
      },
    );
  }

  Widget _buildNavigationFooter() {
    return Consumer<ValdTestFlowController>(
      builder: (context, controller, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Back Button
              if (controller.currentStep != ValdTestStep.connection)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.isLoading ? null : () => controller.goToPreviousStep(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF1565C0)),
                      foregroundColor: const Color(0xFF1565C0),
                    ),
                  ),
                ),
              
              if (controller.currentStep != ValdTestStep.connection)
                const SizedBox(width: 16),
              
              // Next/Action Button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: controller.isLoading ? null : () => _handleNextAction(controller),
                  icon: _getNextActionIcon(controller.currentStep),
                  label: Text(_getNextActionText(controller.currentStep)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
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
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
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
            ElevatedButton(
              onPressed: () => _flowController.restartFlow(),
              child: const Text('Restart'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
          ),
          SizedBox(height: 16),
          Text(
            'Processing...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNextAction(ValdTestFlowController controller) {
    switch (controller.currentStep) {
      case ValdTestStep.connection:
        _connectToDevice();
        break;
      case ValdTestStep.profileSelection:
        controller.proceedToTestSelection();
        break;
      case ValdTestStep.testTypeSelection:
        controller.proceedToZeroCalibration();
        break;
      case ValdTestStep.zeroCalibration:
        controller.startZeroCalibration();
        break;
      case ValdTestStep.weightMeasurement:
        controller.proceedToTesting();
        break;
      case ValdTestStep.testing:
        if (controller.isTestRunning) {
          // Stop test manually if needed
        } else {
          controller.startTest();
        }
        break;
      case ValdTestStep.results:
        controller.restartFlow();
        break;
    }
  }

  void _connectToDevice() async {
    // Try to connect USB first
    if (!_usbController.isConnected) {
      await _usbController.refreshDevices();
      if (_usbController.availableDevices.isNotEmpty) {
        await _usbController.connectToDevice(_usbController.availableDevices.first);
      }
    }
    
    if (_usbController.isConnected) {
      _flowController.connectToDevice(_usbController.connectedDeviceId ?? 'Unknown');
    } else {
      
    }
  }

  Icon _getNextActionIcon(ValdTestStep step) {
    switch (step) {
      case ValdTestStep.connection:
        return const Icon(Icons.link);
      case ValdTestStep.profileSelection:
        return const Icon(Icons.arrow_forward);
      case ValdTestStep.testTypeSelection:
        return const Icon(Icons.arrow_forward);
      case ValdTestStep.zeroCalibration:
        return const Icon(Icons.balance);
      case ValdTestStep.weightMeasurement:
        return const Icon(Icons.arrow_forward);
      case ValdTestStep.testing:
        return const Icon(Icons.play_arrow);
      case ValdTestStep.results:
        return const Icon(Icons.refresh);
    }
  }

  String _getNextActionText(ValdTestStep step) {
    switch (step) {
      case ValdTestStep.connection:
        return 'Connect Platform';
      case ValdTestStep.profileSelection:
        return 'Continue';
      case ValdTestStep.testTypeSelection:
        return 'Continue';
      case ValdTestStep.zeroCalibration:
        return 'Start Zero Calibration';
      case ValdTestStep.weightMeasurement:
        return 'Continue to Test';
      case ValdTestStep.testing:
        return 'Start Test';
      case ValdTestStep.results:
        return 'New Test';
    }
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restart Test Flow'),
        content: const Text(
          'Are you sure you want to restart the test flow? All progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _flowController.restartFlow();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Restart', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}