// lib/presentation/controllers/vald_test_flow_controller.dart - FULLY FIXED & ENHANCED
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/extensions/list_extensions.dart';
import '../../domain/entities/athlete.dart';
import '../../domain/entities/force_data.dart';
import '../../core/constants/test_constants.dart' hide TestResult; // ✅ FIXED: Hide conflicting TestResult
import '../../core/constants/enhanced_test_protocols.dart';
import '../../core/algorithms/metrics_calculator.dart';
import '../../core/algorithms/phase_detector.dart';
import '../../core/algorithms/real_time_analyzer.dart';

/// VALD ForceDecks benzeri test akışını yöneten controller - Enhanced with 18 Test Protocols
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

  // Step 3: Test Type Selection - ✅ FIXED: Using Enhanced TestType
  TestType? _selectedTestType;
  TestCategory? _selectedCategory;

  // Step 4: Zero Calibration
  bool _isZeroCalibrated = false;
  double _zeroOffsetLeft = 0.0;
  double _zeroOffsetRight = 0.0;
  final List<double> _zeroCalibrationSamples = [];

  // Step 5: Weight Measurement
  double? _measuredWeight;
  bool _isWeightStable = false;
  final List<double> _weightSamples = [];
  Timer? _weightTimer;

  // Step 6: Real-time Test
  bool _isTestRunning = false;
  DateTime? _testStartTime;
  final List<ForceData> _testData = [];
  Duration _testDuration = Duration.zero;
  Timer? _testTimer;

  // Step 7: Results
  Map<String, double>? _testResults;

  // ✅ Enhanced: Real-time analyzer integration
  final RealTimeAnalyzer _realTimeAnalyzer = RealTimeAnalyzer();
  JumpPhase _currentPhase = JumpPhase.quietStanding;
  Map<String, double> _liveMetrics = {};

  // ✅ Enhanced: Protocol-specific data
  TestProtocol? _currentProtocol;
  List<String> _currentInstructions = [];
  bool _showTurkish = true;

  // ✅ Constructor with proper initialization
  ValdTestFlowController() {
    _initializeRealTimeAnalyzer();
  }

  void _initializeRealTimeAnalyzer() {
    _realTimeAnalyzer.onPhaseChanged = _onPhaseChanged;
    _realTimeAnalyzer.onMetricsUpdated = _onMetricsUpdated;
    _realTimeAnalyzer.onTestCompleted = _onTestCompleted;
  }

  // =================== GETTERS ===================
  
  ValdTestStep get currentStep => _currentStep;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  
  // Connection
  bool get isConnected => _isConnected;
  String? get connectedDevice => _connectedDevice;
  
  // Profile
  Athlete? get selectedAthlete => _selectedAthlete;
  List<Athlete> get availableAthletes => _availableAthletes;
  
  // Test Type - ✅ Enhanced getters
  TestType? get selectedTestType => _selectedTestType;
  TestCategory? get selectedCategory => _selectedCategory;
  TestProtocol? get currentProtocol => _currentProtocol;
  List<String> get currentInstructions => _currentInstructions;
  bool get showTurkish => _showTurkish;
  
  // ✅ Enhanced: Get available test types by category
  List<TestType> getTestTypesByCategory(TestCategory category) {
    return TestType.values.where((type) => type.category == category).toList();
  }
  
  // ✅ Enhanced: Get filtered test types by athlete characteristics
  List<TestType> getRecommendedTestTypes() {
    if (_selectedAthlete?.sport == null) return TestType.values;
    
    final sport = _selectedAthlete!.sport!;
    return TestType.values.where((type) {
      final protocol = EnhancedTestProtocols.protocols[type];
      return protocol?.sportRecommendations.any((rec) => 
        rec.toLowerCase().contains(sport.toLowerCase())) ?? false;
    }).toList();
  }
  
  // Zero Calibration
  bool get isZeroCalibrated => _isZeroCalibrated;
  double get zeroOffsetLeft => _zeroOffsetLeft;
  double get zeroOffsetRight => _zeroOffsetRight;
  
  // Weight Measurement
  double? get measuredWeight => _measuredWeight;
  bool get isWeightStable => _isWeightStable;
  String get weightStatus {
    if (_measuredWeight == null) return _showTurkish ? 'Platformlara çıkın' : 'Stand on platforms';
    if (!_isWeightStable) return _showTurkish ? 'Sabit durun...' : 'Hold still...';
    return '${_showTurkish ? 'Ağırlık' : 'Weight'}: ${_measuredWeight!.toStringAsFixed(1)} kg';
  }
  
  // Test
  bool get isTestRunning => _isTestRunning;
  Duration get testDuration => _testDuration;
  List<ForceData> get testData => _testData;
  
  // Real-time data getters
  JumpPhase get currentPhase => _currentPhase;
  Map<String, double> get liveMetrics => Map.from(_liveMetrics);
  
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

  // =================== ENHANCED: LANGUAGE TOGGLE ===================
  
  void toggleLanguage() {
    _showTurkish = !_showTurkish;
    _updateCurrentInstructions();
    notifyListeners();
  }

  // =================== STEP 1: CONNECTION MANAGEMENT ===================
  
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
      _setError(_showTurkish ? 'Bağlantı hatası: $e' : 'Connection failed: $e');
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

  // =================== STEP 2: PROFILE MANAGEMENT ===================
  
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
      _setError(_showTurkish ? 'Lütfen bir sporcu profili seçin' : 'Please select an athlete profile');
      return;
    }
    _goToStep(ValdTestStep.testTypeSelection);
  }

  // =================== STEP 3: ENHANCED TEST TYPE SELECTION ===================
  
  void selectTestCategory(TestCategory category) {
    _selectedCategory = category;
    _selectedTestType = null; // Reset test type when category changes
    _currentProtocol = null;
    _clearError();
    notifyListeners();
  }

  void selectTestType(TestType testType) {
    _selectedTestType = testType;
    _selectedCategory = testType.category;
    
    // ✅ Enhanced: Load protocol details
    _currentProtocol = EnhancedTestProtocols.protocols[testType];
    _updateCurrentInstructions();
    
    _clearError();
    notifyListeners();
  }

  void _updateCurrentInstructions() {
    if (_currentProtocol == null) {
      _currentInstructions = [];
      return;
    }
    
    _currentInstructions = _showTurkish 
        ? _currentProtocol!.turkishInstructions
        : _currentProtocol!.instructions;
  }

  void proceedToZeroCalibration() {
    if (_selectedTestType == null) {
      _setError(_showTurkish ? 'Lütfen bir test türü seçin' : 'Please select a test type');
      return;
    }
    _goToStep(ValdTestStep.zeroCalibration);
  }

  // =================== STEP 4: ZERO CALIBRATION ===================
  
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
      final samples = _zeroCalibrationSamples;
      if (samples.isNotEmpty) {
        final half = samples.length ~/ 2;
        _zeroOffsetLeft = samples.take(half).reduce((a, b) => a + b) / half;
        _zeroOffsetRight = samples.skip(half).reduce((a, b) => a + b) / (samples.length - half);
      }
      
      _isZeroCalibrated = true;
      _clearError();
      
      return true;
    } catch (e) {
      _setError(_showTurkish ? 'Sıfır kalibrasyonu başarısız: $e' : 'Zero calibration failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void proceedToWeightMeasurement() {
    if (!_isZeroCalibrated) {
      _setError(_showTurkish ? 'Sıfır kalibrasyonu gerekli' : 'Zero calibration required');
      return;
    }
    _goToStep(ValdTestStep.weightMeasurement);
  }

  // =================== STEP 5: WEIGHT MEASUREMENT ===================
  
  void startWeightMeasurement() {
    _weightSamples.clear();
    _measuredWeight = null;
    _isWeightStable = false;
    
    _weightTimer?.cancel();
    _weightTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
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
      final recent = _weightSamples.sublist(_weightSamples.length - 20); // ✅ FIXED: Use sublist instead of takeLast
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
      _setError(_showTurkish ? 'Stabil ağırlık ölçümü gerekli' : 'Stable weight measurement required');
      return;
    }
    
    _weightTimer?.cancel();
    _goToStep(ValdTestStep.testing);
  }

  // =================== STEP 6: ENHANCED REAL-TIME TESTING ===================
  
  void startTest() {
    if (_currentStep != ValdTestStep.testing || _selectedTestType == null || _measuredWeight == null) {
      _setError(_showTurkish ? 'Test başlatılamıyor' : 'Test cannot be started');
      return;
    }
    
    _isTestRunning = true;
    _testStartTime = DateTime.now();
    _testData.clear();
    _testDuration = Duration.zero;
    
    // ✅ Enhanced: Start real-time analyzer with protocol
    _realTimeAnalyzer.startTest(_selectedTestType!, _measuredWeight!);
    
    // Start test timer with protocol-specific duration
    _testTimer?.cancel();
    _testTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isTestRunning) {
        timer.cancel();
        return;
      }
      
      _testDuration = DateTime.now().difference(_testStartTime!);
      
      // ✅ Enhanced: Use protocol-specific duration
      final maxDuration = _currentProtocol?.duration ?? const Duration(seconds: 10);
      if (_testDuration >= maxDuration) {
        _stopTest();
        timer.cancel();
      }
      
      notifyListeners();
    });
    
    debugPrint('🚀 Enhanced Test started: ${_currentProtocol?.name ?? _selectedTestType.toString()}');
  }

  void _stopTest() {
    _isTestRunning = false;
    _testTimer?.cancel();
    
    // ✅ FIXED: Remove unused variable
    _realTimeAnalyzer.stopTest();
    
    _calculateResults();
    _goToStep(ValdTestStep.results);
    
    debugPrint('⏹️ Enhanced Test stopped');
  }

  void addTestData(ForceData data) {
    if (_isTestRunning) {
      // Process with real-time analyzer first
      _realTimeAnalyzer.processNewData(data);
      
      // Apply zero calibration
      final correctedLeft = math.max(0, data.leftGRF - _zeroOffsetLeft);
      final correctedRight = math.max(0, data.rightGRF - _zeroOffsetRight);
      
      final correctedData = data.copyWith(
        leftGRF: correctedLeft.toDouble(),
        rightGRF: correctedRight.toDouble(),
        totalGRF: (correctedLeft + correctedRight).toDouble(),
      );
      
      _testData.add(correctedData);
      
      // Limit data size for performance
      if (_testData.length > 10000) {
        _testData.removeAt(0);
      }
    }
  }

  // =================== STEP 7: ENHANCED RESULTS CALCULATION ===================
  
  void _calculateResults() {
    if (_testData.isEmpty) {
      _testResults = {
        'jumpHeight': 0.0,
        'peakForce': 0.0,
        'averageForce': 0.0,
        'bodyWeight': _measuredWeight ?? 0.0,
        'asymmetryIndex': 0.0,
      };
      return;
    }
    
    final bodyWeightN = (_measuredWeight ?? 70.0) * 9.81;
    
    // ✅ Enhanced: Use MetricsCalculator for comprehensive analysis
    _testResults = MetricsCalculator.calculateAllMetrics(_testData, bodyWeightN);
    
    // ✅ Enhanced: Add protocol-specific validations
    if (_currentProtocol != null) {
      _validateResultsAgainstProtocol();
    }
    
    debugPrint('📊 Enhanced Results calculated: ${_testResults!.keys.length} metrics');
  }

  void _validateResultsAgainstProtocol() {
    if (_testResults == null || _currentProtocol == null) return;
    
    final rules = _currentProtocol!.validationRules;
    final results = _testResults!;
    
    // Validate against protocol rules
    if (rules.minPeakForce != null && (results['peakForce'] ?? 0) < rules.minPeakForce!) {
      debugPrint('⚠️ Peak force below protocol minimum');
    }
    
    if (rules.maxAsymmetry != null && (results['asymmetryIndex'] ?? 0) > rules.maxAsymmetry!) {
      debugPrint('⚠️ Asymmetry above protocol maximum');
    }
    
    if (rules.minFlightTime != null && (results['flightTime'] ?? 0) < rules.minFlightTime!) {
      debugPrint('⚠️ Flight time below protocol minimum');
    }
    
    if (rules.maxContactTime != null && (results['contactTime'] ?? 0) > rules.maxContactTime!) {
      debugPrint('⚠️ Contact time above protocol maximum');
    }
  }

  // =================== REAL-TIME ANALYZER CALLBACKS ===================
  
  void _onPhaseChanged(JumpPhase newPhase) {
    _currentPhase = newPhase;
    notifyListeners();
    debugPrint('📊 Phase changed to: ${newPhase.turkishName}');
  }

  void _onMetricsUpdated(Map<String, double> metrics) {
    _liveMetrics = Map.from(metrics);
    notifyListeners();
  }

  void _onTestCompleted(TestResult testResult) {
    // Log completion but don't use the variable to avoid unused warning
    debugPrint('✅ Test completed automatically by analyzer');
    if (_isTestRunning) {
      _stopTest();
    }
  }

  // =================== FLOW NAVIGATION ===================
  
  void _goToStep(ValdTestStep step) {
    _currentStep = step;
    _clearError();
    
    // Auto-start certain steps
    switch (step) {
      case ValdTestStep.weightMeasurement:
        startWeightMeasurement();
        break;
      case ValdTestStep.testing:
        // Test is started manually by user action
        break;
      default:
        break;
    }
    
    notifyListeners();
  }

  void goToPreviousStep() {
    _cancelActiveTimers();
    
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
    _cancelActiveTimers();
    
    _currentStep = ValdTestStep.connection;
    _selectedAthlete = null;
    _selectedTestType = null;
    _selectedCategory = null;
    _currentProtocol = null;
    _currentInstructions.clear();
    _isZeroCalibrated = false;
    _zeroOffsetLeft = 0.0;
    _zeroOffsetRight = 0.0;
    _measuredWeight = null;
    _isWeightStable = false;
    _isTestRunning = false;
    _testData.clear();
    _testResults = null;
    _currentPhase = JumpPhase.quietStanding;
    _liveMetrics.clear();
    _clearError();
  }

  // =================== HELPER METHODS ===================
  
  void _cancelActiveTimers() {
    _testTimer?.cancel();
    _weightTimer?.cancel();
  }

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

  // =================== ENHANCED PUBLIC METHODS FOR UI ===================
  
  /// Get current live metrics for UI display
  Map<String, double> getLiveMetrics() => Map.from(_liveMetrics);
  
  /// Get current phase for UI display
  JumpPhase getCurrentPhase() => _currentPhase;
  
  /// Check if test can be started
  bool canStartTest() {
    return _currentStep == ValdTestStep.testing && 
           _selectedTestType != null && 
           _measuredWeight != null && 
           !_isTestRunning;
  }
  
  /// Manual test stop (for emergency)
  void stopTestManually() {
    if (_isTestRunning) {
      debugPrint('🛑 Test stopped manually');
      _stopTest();
    }
  }
  
  /// Get test progress as percentage
  double getTestProgress() {
    if (!_isTestRunning || _currentProtocol == null) return 0.0;
    
    final maxDuration = _currentProtocol!.duration;
    final progress = _testDuration.inMilliseconds / maxDuration.inMilliseconds;
    return progress.clamp(0.0, 1.0);
  }

  /// ✅ Enhanced: Get protocol-specific metrics
  Map<String, dynamic> getProtocolMetrics() {
    if (_currentProtocol == null || _testResults == null) {
      return {};
    }
    
    return {
      'protocol': _currentProtocol!.name,
      'turkishName': _currentProtocol!.turkishName,
      'category': _currentProtocol!.category.turkishName,
      'difficulty': _currentProtocol!.difficulty.turkishName,
      'duration': _currentProtocol!.duration.inSeconds,
      'results': _testResults!,
      'validationPassed': _validateResults(),
    };
  }

  /// ✅ Enhanced: Validate results against protocol
  bool _validateResults() {
    if (_testResults == null || _currentProtocol == null) return false;
    
    final rules = _currentProtocol!.validationRules;
    final results = _testResults!;
    
    if (rules.minPeakForce != null && (results['peakForce'] ?? 0) < rules.minPeakForce!) {
      return false;
    }
    
    if (rules.maxAsymmetry != null && (results['asymmetryIndex'] ?? 0) > rules.maxAsymmetry!) {
      return false;
    }
    
    return true;
  }

  /// ✅ Enhanced: Get sport-specific recommendations
  List<String> getSportRecommendations() {
    return _currentProtocol?.sportRecommendations ?? [];
  }

  @override
  void dispose() {
    _cancelActiveTimers();
    _realTimeAnalyzer.dispose();
    super.dispose();
  }
}

// =================== ENUMS & EXTENSIONS ===================

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

  String get turkishTitle {
    switch (this) {
      case ValdTestStep.connection:
        return 'Platform Bağlantısı';
      case ValdTestStep.profileSelection:
        return 'Sporcu Seçimi';
      case ValdTestStep.testTypeSelection:
        return 'Test Seçimi';
      case ValdTestStep.zeroCalibration:
        return 'Sıfır Kalibrasyonu';
      case ValdTestStep.weightMeasurement:
        return 'Ağırlık Ölçümü';
      case ValdTestStep.testing:
        return 'Test Uygulama';
      case ValdTestStep.results:
        return 'Sonuçlar';
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

  String get turkishDescription {
    switch (this) {
      case ValdTestStep.connection:
        return 'Çift kuvvet platformuna bağlan';
      case ValdTestStep.profileSelection:
        return 'Test için sporcu profili seç';
      case ValdTestStep.testTypeSelection:
        return 'Yapılacak test türünü seç';
      case ValdTestStep.zeroCalibration:
        return 'Platformları yüksüz kalibre et';
      case ValdTestStep.weightMeasurement:
        return 'Vücut ağırlığını ölçmek için sabit dur';
      case ValdTestStep.testing:
        return 'Seçilen testi uygula';
      case ValdTestStep.results:
        return 'Test sonuçlarını incele';
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
      case ValdTestStep.weightMeasurement:
        return Icons.monitor_weight;
      case ValdTestStep.testing:
        return Icons.play_circle;
      case ValdTestStep.results:
        return Icons.analytics;
    }
  }
}