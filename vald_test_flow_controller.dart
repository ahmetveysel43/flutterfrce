// lib/presentation/controllers/vald_test_flow_controller.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:izforce/core/extensions/list_extensions.dart';
import '../../domain/entities/athlete.dart';
import '../../domain/entities/force_data.dart';
import '../../core/constants/test_constants.dart';

/// VALD ForceDecks benzeri 7 adımlı test akışını yöneten controller
class ValdTestFlowController extends ChangeNotifier {
  // VALD Test Flow Steps
  ValdTestStep _currentStep = ValdTestStep.connection;
  String? _errorMessage;
  bool _isLoading = false;

  // Step 1: Connection
  bool _isConnected = false;
  String? _connectedDevice;

  // Step 2: Profile Selection  
  Athlete? _selectedAthlete;
  List<Athlete> _availableAthletes = [];

  // Step 3: Test Type Selection
  TestType? _selectedTestType;

  // Step 4: Zero Calibration
  bool _isZeroCalibrated = false;
  double _zeroOffsetLeft = 0.0;
  double _zeroOffsetRight = 0.0;
  List<double> _zeroCalibrationSamples = [];

  // Step 5: Weight Measurement
  double? _measuredWeight;
  bool _isWeightStable = false;
  List<double> _weightSamples = [];

  // Step 6: Real-time Test
  bool _isTestRunning = false;
  DateTime? _testStartTime;
  List<ForceData> _testData = [];
  Duration _testDuration = Duration.zero;

  // Step 7: Results
  Map<String, double>? _testResults;

  // Getters
  ValdTestStep get currentStep => _currentStep;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  
  // Connection
  bool get isConnected => _isConnected;
  String? get connectedDevice => _connectedDevice;
  
  // Profile
  Athlete? get selectedAthlete => _selectedAthlete;
  List<Athlete> get availableAthletes => _availableAthletes;
  
  // Test Type
  TestType? get selectedTestType => _selectedTestType;
  
  // Zero Calibration
  bool get isZeroCalibrated => _isZeroCalibrated;
  double get zeroOffsetLeft => _zeroOffsetLeft;
  double get zeroOffsetRight => _zeroOffsetRight;
  
  // Weight Measurement
  double? get measuredWeight => _measuredWeight;
  bool get isWeightStable => _isWeightStable;
  String get weightStatus {
    if (_measuredWeight == null) return 'Stand on platforms';
    if (!_isWeightStable) return 'Hold still...';
    return 'Weight: ${_measuredWeight!.toStringAsFixed(1)} kg';
  }
  
  // Test
  bool get isTestRunning => _isTestRunning;
  Duration get testDuration => _testDuration;
  List<ForceData> get testData => _testData;
  
  // Results
  Map<String, double>? get testResults => _testResults;

  // Progress calculation
  double get overallProgress {
    switch (_currentStep) {
      case ValdTestStep.connection:
        return _isConnected ? 0.14 : 0.0;
      case ValdTestStep.profileSelection:
        return _selectedAthlete != null ? 0.28 : 0.14;
      case ValdTestStep.testTypeSelection:
        return _selectedTestType != null ? 0.42 : 0.28;
      case ValdTestStep.zeroCalibration:
        return _isZeroCalibrated ? 0.56 : 0.42;
      case ValdTestStep.weightMeasurement:
        return _measuredWeight != null ? 0.70 : 0.56;
      case ValdTestStep.testing:
        return 0.85;
      case ValdTestStep.results:
        return 1.0;
    }
  }

  // Step 1: Connection Management
  Future<bool> connectToDevice(String deviceId) async {
    _setLoading(true);
    try {
      // Simulate connection delay
      await Future.delayed(const Duration(seconds: 2));
      
      _isConnected = true;
      _connectedDevice = deviceId;
      _clearError();
      
      // Auto advance to next step
      _goToStep(ValdTestStep.profileSelection);
      return true;
    } catch (e) {
      _setError('Connection failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void disconnect() {
    _isConnected = false;
    _connectedDevice = null;
    _resetFlow();
  }

  // Step 2: Profile Management
  void loadAthletes(List<Athlete> athletes) {
    _availableAthletes = athletes;
    notifyListeners();
  }

  void selectAthlete(Athlete athlete) {
    _selectedAthlete = athlete;
    _clearError();
    notifyListeners();
  }

  void proceedToTestSelection() {
    if (_selectedAthlete == null) {
      _setError('Please select an athlete profile');
      return;
    }
    _goToStep(ValdTestStep.testTypeSelection);
  }

  // Step 3: Test Type Selection
  void selectTestType(TestType testType) {
    _selectedTestType = testType;
    _clearError();
    notifyListeners();
  }

  void proceedToZeroCalibration() {
    if (_selectedTestType == null) {
      _setError('Please select a test type');
      return;
    }
    _goToStep(ValdTestStep.zeroCalibration);
  }

  // Step 4: Zero Calibration (VALD'ın en önemli özelliği)
  Future<bool> startZeroCalibration() async {
    _setLoading(true);
    _zeroCalibrationSamples.clear();
    
    try {
      // 3 saniye boyunca platform boşken örnekleme
      for (int i = 0; i < 300; i++) { // 100Hz x 3 saniye
        await Future.delayed(const Duration(milliseconds: 10));
        
        // Mock zero calibration data
        _zeroCalibrationSamples.add(5.0 + (math.Random().nextDouble() - 0.5) * 2);
        
        // Progress feedback
        if (i % 30 == 0) {
          notifyListeners();
        }
      }
      
      // Calculate zero offsets
      _zeroOffsetLeft = _zeroCalibrationSamples.take(150).reduce((a, b) => a + b) / 150;
      _zeroOffsetRight = _zeroCalibrationSamples.skip(150).reduce((a, b) => a + b) / 150;
      
      _isZeroCalibrated = true;
      _clearError();
      
      return true;
    } catch (e) {
      _setError('Zero calibration failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void proceedToWeightMeasurement() {
    if (!_isZeroCalibrated) {
      _setError('Zero calibration required');
      return;
    }
    _goToStep(ValdTestStep.weightMeasurement);
  }

  // Step 5: Weight Measurement (VALD'ın diğer önemli özelliği)
  void startWeightMeasurement() {
    _weightSamples.clear();
    _measuredWeight = null;
    _isWeightStable = false;
    
    // Start continuous weight monitoring
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_currentStep != ValdTestStep.weightMeasurement) {
        timer.cancel();
        return;
      }
      
      _updateWeightMeasurement();
    });
  }

  void _updateWeightMeasurement() {
    // Mock weight measurement - gerçekte force data'dan hesaplanacak
    final mockWeight = 75.0 + (math.Random().nextDouble() - 0.5) * 2;
    _weightSamples.add(mockWeight);
    
    // Keep last 50 samples (5 seconds)
    if (_weightSamples.length > 50) {
      _weightSamples.removeAt(0);
    }
    
    // Calculate stability
    if (_weightSamples.length >= 20) {
      final recent = _weightSamples.takeLast(20);
      final mean = recent.reduce((a, b) => a + b) / recent.length;
      final variance = recent.map((w) => (w - mean) * (w - mean)).reduce((a, b) => a + b) / recent.length;
      final stdDev = math.sqrt(variance);
      
      _measuredWeight = mean;
      _isWeightStable = stdDev < 0.5; // 0.5kg stability threshold
      
      notifyListeners();
    }
  }

  void proceedToTesting() {
    if (_measuredWeight == null || !_isWeightStable) {
      _setError('Stable weight measurement required');
      return;
    }
    _goToStep(ValdTestStep.testing);
  }

  // Step 6: Real-time Testing
  void startTest() {
    if (_currentStep != ValdTestStep.testing) return;
    
    _isTestRunning = true;
    _testStartTime = DateTime.now();
    _testData.clear();
    _testDuration = Duration.zero;
    
    // Start test timer
    Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (!_isTestRunning) {
        timer.cancel();
        return;
      }
      
      _testDuration = DateTime.now().difference(_testStartTime!);
      
      // Auto-stop test based on test type
      final maxDuration = TestConstants.testDurations[_selectedTestType!] ?? const Duration(seconds: 10);
      if (_testDuration >= maxDuration) {
        _stopTest();
        timer.cancel();
      }
      
      notifyListeners();
    });
  }

  void _stopTest() {
    _isTestRunning = false;
    _calculateResults();
    _goToStep(ValdTestStep.results);
  }

  void addTestData(ForceData data) {
    if (_isTestRunning) {
      // Apply zero calibration
      final correctedLeft = data.leftGRF - _zeroOffsetLeft;
      final correctedRight = data.rightGRF - _zeroOffsetRight;
      
      final correctedData = data.copyWith(
        leftGRF: correctedLeft,
        rightGRF: correctedRight,
        totalGRF: correctedLeft + correctedRight,
      );
      
      _testData.add(correctedData);
      
      // Limit data size for performance
      if (_testData.length > 10000) {
        _testData.removeAt(0);
      }
    }
  }

  // Step 7: Results Calculation
  void _calculateResults() {
    if (_testData.isEmpty) return;
    
    // Basic VALD-style metrics
    final forces = _testData.map((d) => d.totalGRF).toList();
    final peakForce = forces.isNotEmpty ? forces.reduce(math.max) : 0.0;
    final averageForce = forces.isNotEmpty ? forces.reduce((a, b) => a + b) / forces.length : 0.0;
    
    // Jump height calculation (simplified)
    final bodyWeightN = (_measuredWeight ?? 70.0) * 9.81;
    final impulse = forces.fold(0.0, (sum, f) => sum + (f - bodyWeightN)) / 1000; // Simplified
    final jumpHeight = (impulse * impulse) / (2 * bodyWeightN * 9.81) * 100; // cm
    
    _testResults = {
      'jumpHeight': jumpHeight.clamp(0, 100),
      'peakForce': peakForce,
      'averageForce': averageForce,
      'bodyWeight': _measuredWeight ?? 0.0,
      'asymmetryIndex': _testData.isNotEmpty ? _testData.last.asymmetryIndex * 100 : 0.0,
    };
  }

  // Flow Navigation
  void _goToStep(ValdTestStep step) {
    _currentStep = step;
    _clearError();
    
    // Auto-start certain steps
    switch (step) {
      case ValdTestStep.weightMeasurement:
        startWeightMeasurement();
        break;
      default:
        break;
    }
    
    notifyListeners();
  }

  void goToPreviousStep() {
    switch (_currentStep) {
      case ValdTestStep.profileSelection:
        _goToStep(ValdTestStep.connection);
        break;
      case ValdTestStep.testTypeSelection:
        _goToStep(ValdTestStep.profileSelection);
        break;
      case ValdTestStep.zeroCalibration:
        _goToStep(ValdTestStep.testTypeSelection);
        break;
      case ValdTestStep.weightMeasurement:
        _goToStep(ValdTestStep.zeroCalibration);
        break;
      case ValdTestStep.testing:
        _goToStep(ValdTestStep.weightMeasurement);
        break;
      case ValdTestStep.results:
        _goToStep(ValdTestStep.testing);
        break;
      default:
        break;
    }
  }

  void restartFlow() {
    _resetFlow();
    _goToStep(ValdTestStep.connection);
  }

  void _resetFlow() {
    _currentStep = ValdTestStep.connection;
    _selectedAthlete = null;
    _selectedTestType = null;
    _isZeroCalibrated = false;
    _zeroOffsetLeft = 0.0;
    _zeroOffsetRight = 0.0;
    _measuredWeight = null;
    _isWeightStable = false;
    _isTestRunning = false;
    _testData.clear();
    _testResults = null;
    _clearError();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up any active timers or streams
    super.dispose();
  }
}

// VALD Test Flow Steps
enum ValdTestStep {
  connection,        // Step 1: USB Connection
  profileSelection,  // Step 2: Athlete Profile  
  testTypeSelection, // Step 3: Test Type
  zeroCalibration,   // Step 4: Zero Calibration
  weightMeasurement, // Step 5: Weight Measurement
  testing,          // Step 6: Real-time Test
  results,          // Step 7: Results Display
}

extension ValdTestStepExtension on ValdTestStep {
  String get title {
    switch (this) {
      case ValdTestStep.connection:
        return 'Connect Platform';
      case ValdTestStep.profileSelection:
        return 'Select Athlete';
      case ValdTestStep.testTypeSelection:
        return 'Choose Test';
      case ValdTestStep.zeroCalibration:
        return 'Zero Calibration';
      case ValdTestStep.weightMeasurement:
        return 'Measure Weight';
      case ValdTestStep.testing:
        return 'Perform Test';
      case ValdTestStep.results:
        return 'View Results';
    }
  }

  String get description {
    switch (this) {
      case ValdTestStep.connection:
        return 'Connect to dual force platforms';
      case ValdTestStep.profileSelection:
        return 'Select athlete profile for testing';
      case ValdTestStep.testTypeSelection:
        return 'Choose the type of test to perform';
      case ValdTestStep.zeroCalibration:
        return 'Calibrate platforms with no load';
      case ValdTestStep.weightMeasurement:
        return 'Stand still to measure body weight';
      case ValdTestStep.testing:
        return 'Perform the selected test';
      case ValdTestStep.results:
        return 'Review your test results';
    }
  }

  IconData get icon {
    switch (this) {
      case ValdTestStep.connection:
        return Icons.link;
      case ValdTestStep.profileSelection:
        return Icons.person;
      case ValdTestStep.testTypeSelection:
        return Icons.assignment;
      case ValdTestStep.zeroCalibration:
        return Icons.balance;
      case ValdTestStep.testTypeSelection:
        return Icons.monitor_weight;
      case ValdTestStep.testing:
        return Icons.play_circle;
      case ValdTestStep.results:
        return Icons.analytics;
      case ValdTestStep.weightMeasurement:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}