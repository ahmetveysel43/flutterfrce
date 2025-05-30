// lib/core/algorithms/real_time_analyzer.dart - FULLY FIXED
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import '../constants/enhanced_test_protocols.dart'; // ✅ FIXED: Import TestType from enhanced protocols
import '../../domain/entities/force_data.dart';
import 'metrics_calculator.dart';

/// Real-time veri analizi ve faz yönetimi için canlı analiz motoru
/// VALD ForceDecks benzeri gerçek zamanlı analiz sistemi
class RealTimeAnalyzer {
  // Test Configuration
  TestType? _currentTestType;
  double? _bodyWeight;
  bool _isRunning = false;

  // Phase Management - ✅ REMOVED: Unused _phaseDetector field
  JumpPhase _currentPhase = JumpPhase.quietStanding;

  // Data Storage
  final List<ForceData> _dataBuffer = [];
  final int _maxBufferSize = 5000; // 50 seconds at 100Hz

  // Real-time Metrics
  Map<String, double> _currentMetrics = {};
  
  // Live Analysis State
  double _peakForce = 0.0;
  double _currentRFD = 0.0;
  int _sampleCount = 0;
  DateTime? _testStartTime;

  // Callbacks - ✅ FIXED: Real-time analyzer callbacks
  void Function(JumpPhase phase)? onPhaseChanged;
  void Function(Map<String, double> metrics)? onMetricsUpdated;
  void Function(TestResult testResult)? onTestCompleted;

  // Quality Control
  bool _dataQualityGood = true;
  List<String> _qualityIssues = [];

  // =================== PUBLIC METHODS ===================

  /// Test başlatma metodu
  void startTest(TestType testType, double bodyWeight) {
    _currentTestType = testType;
    _bodyWeight = bodyWeight;
    _isRunning = true;
    _testStartTime = DateTime.now();
    
    // Reset state
    _dataBuffer.clear();
    _currentMetrics.clear();
    _peakForce = 0.0;
    _currentRFD = 0.0;
    _sampleCount = 0;
    _currentPhase = JumpPhase.quietStanding;
    _qualityIssues.clear();
    
    // Initialize phase detector for this test type
    // Note: PhaseDetector will be initialized as needed
    
    debugPrint('🚀 Real-time analyzer started for ${testType.name}');
  }

  /// Test durdurma metodu
  TestResult stopTest() {
    _isRunning = false;
    final testResult = _generateTestResult();
    debugPrint('⏹️ Real-time analyzer stopped');
    return testResult;
  }

  /// Yeni veri noktası işleme ana metod
  void processNewData(ForceData data) {
    if (!_isRunning) return;

    // Add to buffer
    _dataBuffer.add(data);
    _sampleCount++;
    
    // Maintain buffer size
    if (_dataBuffer.length > _maxBufferSize) {
      _dataBuffer.removeAt(0);
    }

    // Quality control
    _checkDataQuality(data);

    if (_dataBuffer.length < 10) return; // Wait for sufficient data

    debugPrint('📊 Processing sample $_sampleCount: ${data.totalGRF.toStringAsFixed(1)}N');

    // =================== PHASE DETECTION ===================
    
    /// Mevcut canlı metrikleri döndürür
    final previousPhase = _currentPhase;
    
    // Simplified phase detection - use basic force thresholds
    _currentPhase = _detectPhaseSimple(data, _dataBuffer);

    /// Mevcut faz bilgisi
    if (_currentPhase != previousPhase) {
      onPhaseChanged?.call(_currentPhase);
      _handlePhaseTransition(previousPhase, _currentPhase);
    }

    // =================== REAL-TIME METRICS ===================
    
    /// Kalite sorunları listesi
    _updateLiveMetrics(data);

    /// Tespit edilen fazlar
    if (_sampleCount % 10 == 0) { // Update UI every 100ms
      onMetricsUpdated?.call(Map.from(_currentMetrics));
    }

    // =================== TEST COMPLETION CHECK ===================
    
    /// Ana veri ekleme noktası
    _checkTestCompletion();
  }

  /// Analiz penceresi güncelleme metodu
  void _updateLiveMetrics(ForceData currentData) {
    /// Ana metrik güncelleme lojiği
    if (_dataBuffer.length < 20) return;

    final recent = _dataBuffer.sublist(_dataBuffer.length - 20); // Last 200ms
    
    // =================== PHASE-BASED METRICS ===================
    
    /// Faz değişimi kaydı
    switch (_currentPhase) {
      case JumpPhase.quietStanding:
        _updateQuietStandingMetrics(recent);
        break;
      case JumpPhase.unweighting: // ✅ FIXED: Add missing enum case
        _updateUnweightingMetrics(recent);
        break;
      case JumpPhase.braking: // ✅ FIXED: Use only existing enum values
        _updateBrakingMetrics(recent);
        break;
      case JumpPhase.propulsion:
        _updatePropulsionMetrics(recent);
        break;
      case JumpPhase.flight:
        _updateFlightMetrics(recent);
        break;
      case JumpPhase.landing:
        _updateLandingMetrics(recent);
        break;
    }

    // =================== SPECIALIZED HANDLING ===================
    
    /// Özel faz geçiş işlemleri
    if (_requiresSpecialHandling()) {
      _handleSpecialMetrics();
    }

    // =================== LIVE METRIC CALCULATIONS ===================
    
    /// Canlı metrik güncelleme
    _calculateLiveMetrics(recent);

    // =================== COMMON METRICS ===================
    
    /// Temel metrikler (tüm test türlerinde ortak)
    _currentMetrics['currentForce'] = currentData.totalGRF;
    _currentMetrics['peakForce'] = _peakForce;
    _currentMetrics['testDuration'] = _getElapsedSeconds();

    // =================== TEST-SPECIFIC METRICS ===================
    
    /// Test türüne göre özel metrikler
    switch (_currentTestType!) {
      case TestType.counterMovementJump:
      case TestType.squatJump:
      case TestType.dropJump:
        _updateJumpMetrics(recent);
        break;
      case TestType.balance:
      case TestType.singleLegBalance:
        _updateBalanceMetrics(recent);
        break;
      case TestType.isometricMidThigh:
      case TestType.isometricSquat:
        _updateIsometricMetrics(recent);
        break;
      case TestType.landing:
      case TestType.landAndHold:
        _updateLandingMetrics(recent);
        break;
      case TestType.reactiveDynamic:
      case TestType.hopping:
        _updateReactiveMetrics(recent);
        break;
      case TestType.changeOfDirection:
      case TestType.powerClean:
        _updatePowerMetrics(recent);
        break;
      case TestType.fatigue:
      case TestType.recovery:
        _updateEnduranceMetrics(recent);
        break;
      case TestType.returnToSport:
      case TestType.injuryRisk:
        _updateRehabilitationMetrics(recent);
        break;
    }

    // =================== AUTO-COMPLETION LOGIC ===================
    
    /// Test tetikleme metrikleri
    if (_shouldAutoComplete()) {
      /// Canlı metrikleri güncelleme
      _completeTest();
    }

    /// Anlık RFD hesaplama
    _updateRFD(currentData);
  }

  // =================== PHASE DETECTION HELPER ===================
  
  JumpPhase _detectPhaseSimple(ForceData currentData, List<ForceData> buffer) {
    if (buffer.length < 10) return JumpPhase.quietStanding;
    
    final bodyWeightN = (_bodyWeight ?? 70.0) * 9.81;
    final currentForce = currentData.totalGRF;
    final threshold = bodyWeightN * 0.1; // 10% of body weight
    
    // Simple threshold-based phase detection
    if (currentForce < bodyWeightN - threshold) {
      return JumpPhase.braking; // Unloading/countermovement
    } else if (currentForce > bodyWeightN + threshold) {
      return _peakForce > bodyWeightN * 1.5 ? JumpPhase.propulsion : JumpPhase.braking;
    } else if (currentForce < threshold) {
      return JumpPhase.flight;
    } else if (currentForce > bodyWeightN * 1.2) {
      return JumpPhase.landing;
    }
    
    return JumpPhase.quietStanding;
  }

  // =================== PHASE-SPECIFIC UPDATES ===================

  void _updateQuietStandingMetrics(List<ForceData> data) {
    final forces = data.map((d) => d.totalGRF).toList();
    final mean = forces.reduce((a, b) => a + b) / forces.length;
    final variance = forces.map((f) => (f - mean) * (f - mean)).reduce((a, b) => a + b) / forces.length;
    
    _currentMetrics['bodyWeight'] = mean;
    _currentMetrics['stability'] = math.sqrt(variance);
    
    // Check if stable enough for baseline, eğer test tamamlandıysa
    if (variance < 100) { // 100N² variance threshold
      _currentMetrics['baselineStable'] = 1.0;
    }
  }

  void _updateUnweightingMetrics(List<ForceData> data) {
    /// Unweighting phase metrics (weight reduction phase)
    final forces = data.map((d) => d.totalGRF).toList();
    final minForce = forces.reduce(math.min);
    final bodyWeightN = (_bodyWeight ?? 70.0) * 9.81;
    
    _currentMetrics['minForce'] = minForce;
    _currentMetrics['unweightingDepth'] = bodyWeightN - minForce;
    _currentMetrics['unweightingPercent'] = ((bodyWeightN - minForce) / bodyWeightN * 100).clamp(0, 100);
  }

  void _updateBrakingMetrics(List<ForceData> data) {
    /// Braking phase metrics (previously loading metrics)
    final forces = data.map((d) => d.totalGRF).toList();
    final maxForce = forces.reduce(math.max);
    final minForce = forces.reduce(math.min);
    
    _peakForce = math.max(_peakForce, maxForce);
    _currentMetrics['brakingPeakForce'] = maxForce;
    _currentMetrics['minForce'] = minForce;
    _currentMetrics['unloadingDepth'] = (_bodyWeight ?? 700) - minForce;
  }

  void _updatePropulsionMetrics(List<ForceData> data) {
    final forces = data.map((d) => d.totalGRF).toList();
    final maxForce = forces.reduce(math.max);
    
    _peakForce = math.max(_peakForce, maxForce);
    _currentMetrics['propulsionPeakForce'] = maxForce;
    
    // Calculate impulse (simplified)
    final impulse = forces.reduce((a, b) => a + b) * 0.01; // 100Hz = 0.01s per sample
    _currentMetrics['propulsionImpulse'] = impulse;
    
    // Use currentForce for RFD calculation
    final currentForce = forces.last;
    if (forces.length >= 2) {
      final deltaForce = currentForce - forces[forces.length - 2];
      _currentMetrics['instantRFD'] = deltaForce / 0.01; // Per sample RFD
    }
  }

  void _updateFlightMetrics(List<ForceData> data) {
    // Platteau detection for sustained phases
    _currentMetrics['inFlight'] = 1.0;
    _currentMetrics['flightTime'] = _getPhaseElapsedTime(JumpPhase.flight);
  }

  void _updateLandingMetrics(List<ForceData> data) {
    /// İniş metrikleri güncelleme
    final forces = data.map((d) => d.totalGRF).toList();
    final maxForce = forces.reduce(math.max);
    _peakForce = math.max(_peakForce, maxForce);
    _currentMetrics['landingPeakForce'] = maxForce;
    
    // Calculate loading rate
    if (forces.length >= 2) {
      final loadingRate = (forces.last - forces.first) / (forces.length * 0.01);
      _currentMetrics['landingLoadingRate'] = loadingRate;
    }
  }

  // =================== TEST TYPE SPECIFIC METRICS ===================

  void _checkTestCompletion() {
    /// Test tamamlanma kontrolü
    if (_currentTestType == null || _bodyWeight == null) return;
    
    /// Maksimum süre kontrolü
    final elapsed = _getElapsedSeconds();
    
    // Get protocol-specific max duration
    final protocol = EnhancedTestProtocols.protocols[_currentTestType!];
    final maxDuration = protocol?.duration.inSeconds ?? 10;
    
    if (elapsed >= maxDuration) {
      debugPrint('⏰ Test completed due to maximum duration');
      _completeTest();
      return;
    }
    
    /// Test türüne göre tamamlanma kriterleri
    switch (_currentTestType!) {
      case TestType.counterMovementJump:
      case TestType.squatJump:
      case TestType.dropJump:
        // Jump testleri süre bazlı tamamlanır
        break;
        
      case TestType.balance:
      case TestType.singleLegBalance:
        // Balance tests complete after duration
        break;
        
      case TestType.isometricMidThigh:
      case TestType.isometricSquat:
        // Isometric tests complete after duration  
        break;
        
      case TestType.landing:
      case TestType.landAndHold:
        // Landing tests complete after stable landing
        break;
        
      case TestType.reactiveDynamic:
      case TestType.hopping:
        // Reactive tests complete after repetitions
        break;
        
      case TestType.changeOfDirection:
      case TestType.powerClean:
        // Power tests complete after movement
        break;
        
      case TestType.fatigue:
      case TestType.recovery:
        // Endurance tests complete after protocol
        break;
        
      case TestType.returnToSport:
      case TestType.injuryRisk:
        // Rehabilitation tests complete after assessment
        break;
    }
  }

  void _completeTest() {
    if (!_isRunning) return;
    
    /// Otomatik test tamamlanma kontrolü
    _isRunning = false;
    final testResult = _generateTestResult();
    onTestCompleted?.call(testResult);
    
    debugPrint('✅ Test completed automatically');
  }

  void _updateJumpMetrics(List<ForceData> data) {
    final forces = data.map((d) => d.totalGRF).toList();
    final maxForce = forces.reduce(math.max);
    _peakForce = math.max(_peakForce, maxForce);
    
    // Calculate jump height using impulse-momentum
    if (_currentPhase == JumpPhase.flight && _bodyWeight != null) {
      final bodyWeightN = _bodyWeight! * 9.81;
      final netImpulse = forces.map((f) => f - bodyWeightN).where((f) => f > 0).fold(0.0, (a, b) => a + b) * 0.01;
      final velocity = netImpulse / _bodyWeight!;
      final jumpHeight = (velocity * velocity) / (2 * 9.81) * 100; // Convert to cm
      
      _currentMetrics['estimatedJumpHeight'] = jumpHeight;
      debugPrint('📊 Estimated jump height: ${jumpHeight.toStringAsFixed(1)} cm');
    }
  }

  void _updateBalanceMetrics(List<ForceData> data) {
    /// İzometrik test tamamlanma kontrolü
    // Center of Pressure calculations
    final copX = data.map((d) => (d.rightGRF - d.leftGRF) / d.totalGRF).toList();
    final copXMean = copX.reduce((a, b) => a + b) / copX.length;
    final copXVariance = copX.map((x) => (x - copXMean) * (x - copXMean)).reduce((a, b) => a + b) / copX.length;
    
    _currentMetrics['copSway'] = math.sqrt(copXVariance);
    _currentMetrics['asymmetryIndex'] = (copXMean.abs() * 100).clamp(0, 100);
    
    // Platteau stability check
    if (copXVariance < 0.01) { // Very stable
      debugPrint('✅ Excellent balance stability detected');
    }
  }

  void _updateIsometricMetrics(List<ForceData> data) {
    /// İniş testi tamamlanma kontrolü
    final forces = data.map((d) => d.totalGRF).toList();
    final maxForce = forces.reduce(math.max);
    _peakForce = math.max(_peakForce, maxForce);
    
    // Check for force plateau (isometric hold)
    final recent10 = forces.sublist(math.max(0, forces.length - 10));
    final variance = _calculateVariance(recent10);
    
    if (variance < 100 && maxForce > (_bodyWeight ?? 700) * 1.5) {
      _currentMetrics['isometricPlateau'] = 1.0;
      debugPrint('🔄 Isometric plateau detected');
    }
  }

  void _updateReactiveMetrics(List<ForceData> data) {
    // Contact time and flight time for reactive tests
    final forces = data.map((d) => d.totalGRF).toList();
    final threshold = (_bodyWeight ?? 700) * 0.1; // 10% body weight
    
    final isContact = forces.last > threshold;
    _currentMetrics['contactPhase'] = isContact ? 1.0 : 0.0;
    
    // Track contact/flight transitions for RSI calculation
    if (_currentPhase == JumpPhase.flight) {
      _currentMetrics['reactiveStrengthIndex'] = _calculateRSI();
    }
  }

  void _updatePowerMetrics(List<ForceData> data) {
    // Power = Force × Velocity calculations
    final forces = data.map((d) => d.totalGRF).toList();
    
    if (forces.length >= 5) {
      final velocities = _calculateVelocities(forces);
      final powers = [];
      for (int i = 0; i < forces.length && i < velocities.length; i++) {
        powers.add((forces[i] * velocities[i]).toDouble()); // ✅ FIXED: Explicit double conversion
      }
      
      if (powers.isNotEmpty) {
        final maxPower = powers.reduce((a, b) => a > b ? a : b); // ✅ FIXED: Use comparison function
        _currentMetrics['peakPower'] = maxPower;
      }
    }
  }

  void _updateEnduranceMetrics(List<ForceData> data) {
    // Track performance degradation over time
    final forces = data.map((d) => d.totalGRF).toList();
    final currentMax = forces.reduce(math.max);
    
    if (!_currentMetrics.containsKey('initialPeakForce')) {
      _currentMetrics['initialPeakForce'] = currentMax;
    }
    
    final fatigueIndex = currentMax / (_currentMetrics['initialPeakForce'] ?? currentMax);
    _currentMetrics['fatigueIndex'] = fatigueIndex;
    _currentMetrics['performanceDecline'] = (1 - fatigueIndex) * 100;
  }

  void _updateRehabilitationMetrics(List<ForceData> data) {
    // Comprehensive assessment combining multiple metrics
    _updateJumpMetrics(data);
    _updateBalanceMetrics(data);
    
    // Risk assessment based on asymmetry and force patterns
    final asymmetry = _currentMetrics['asymmetryIndex'] ?? 0;
    // Store asymmetry value directly instead of unused string
    _currentMetrics['injuryRiskLevel'] = asymmetry;
  }

  // =================== HELPER METHODS ===================

  bool _requiresSpecialHandling() {
    return _currentTestType == TestType.dropJump || 
           _currentTestType == TestType.reactiveDynamic ||
           _currentTestType == TestType.fatigue;
  }

  void _handleSpecialMetrics() {
    // Special handling for complex test types
    switch (_currentTestType!) {
      case TestType.dropJump:
        _updateDropJumpSpecialMetrics();
        break;
      case TestType.reactiveDynamic:
        _updateReactiveDynamicSpecialMetrics();
        break;
      case TestType.fatigue:
        _updateFatigueSpecialMetrics();
        break;
      default:
        break;
    }
  }

  void _updateDropJumpSpecialMetrics() {
    // Contact time minimization focus
    if (_currentPhase == JumpPhase.propulsion) {
      final contactTime = _getPhaseElapsedTime(JumpPhase.braking) + _getPhaseElapsedTime(JumpPhase.propulsion);
      _currentMetrics['contactTime'] = contactTime;
      
      if (contactTime > 0 && _currentMetrics['estimatedJumpHeight'] != null) {
        final rsi = _currentMetrics['estimatedJumpHeight']! / contactTime;
        _currentMetrics['reactiveStrengthIndex'] = rsi;
      }
    }
  }

  void _updateReactiveDynamicSpecialMetrics() {
    // Multiple jump consistency
    // Track jump-to-jump variability
    _currentMetrics['jumpConsistency'] = _calculateJumpConsistency();
  }

  void _updateFatigueSpecialMetrics() {
    // Progressive performance decline tracking
    final jumpNumber = (_currentMetrics['jumpCount'] ?? 0) + 1;
    _currentMetrics['jumpCount'] = jumpNumber;
    
    if (jumpNumber > 1) {
      final performanceDecline = _calculatePerformanceDecline();
      _currentMetrics['fatigueRate'] = performanceDecline;
    }
  }

  void _calculateLiveMetrics(List<ForceData> data) {
    if (data.isEmpty) return;
    
    final forces = data.map((d) => d.totalGRF).toList();
    
    // Basic statistics
    final mean = forces.reduce((a, b) => a + b) / forces.length;
    final maxForce = forces.reduce(math.max);
    final minForce = forces.reduce(math.min);
    
    _currentMetrics['averageForce'] = mean;
    _currentMetrics['forceRange'] = maxForce - minForce;
    
    // Update global peak
    _peakForce = math.max(_peakForce, maxForce);
  }

  void _updateRFD(ForceData currentData) {
    if (_dataBuffer.length < 10) return;
    
    // Calculate RFD over last 50ms (5 samples at 100Hz)
    final recentCount = math.min(5, _dataBuffer.length);
    final recent = _dataBuffer.sublist(_dataBuffer.length - recentCount);
    
    if (recent.length >= 2) {
      final deltaForce = recent.last.totalGRF - recent.first.totalGRF;
      final deltaTime = (recent.length - 1) * 0.01; // 100Hz = 0.01s
      _currentRFD = deltaForce / deltaTime;
      _currentMetrics['currentRFD'] = _currentRFD;
    }
  }

  bool _shouldAutoComplete() {
    // Auto-completion logic based on test type and current metrics
    final elapsed = _getElapsedSeconds();
    
    switch (_currentTestType!) {
      case TestType.counterMovementJump:
      case TestType.squatJump:
        // Complete after landing phase stabilizes
        return _currentPhase == JumpPhase.landing && elapsed > 3;
        
      case TestType.dropJump:
        return _currentPhase == JumpPhase.landing && elapsed > 2;
        
      case TestType.balance:
        return elapsed >= 30; // 30 second balance test
        
      case TestType.isometricMidThigh:
        return elapsed >= 5 && (_currentMetrics['isometricPlateau'] ?? 0) > 0;
        
      default:
        return false;
    }
  }

  void _handlePhaseTransition(JumpPhase from, JumpPhase to) {
    /// Faz geçiş işlemleri
    debugPrint('🔄 Phase transition: ${from.name} → ${to.name}');
    
    // Record phase transition timestamp
    _currentMetrics['phase${to.name}StartTime'] = _getElapsedSeconds();
    
    // Phase-specific transition actions
    switch (to) {
      case JumpPhase.propulsion:
        _currentMetrics['unloadingCompleted'] = 1.0;
        break;
      case JumpPhase.flight:
        _currentMetrics['takeoffCompleted'] = 1.0;
        break;
      case JumpPhase.landing:
        _currentMetrics['flightCompleted'] = 1.0;
        break;
      default:
        break;
    }
  }

  void _checkDataQuality(ForceData data) {
    /// Data kalitesi değerlendirmesi
    _qualityIssues.clear();
    _dataQualityGood = true;
    
    // Check for negative forces
    if (data.leftGRF < 0 || data.rightGRF < 0) {
      _qualityIssues.add('Negatif force değeri tespit edildi');
      _dataQualityGood = false;
    }
    
    // Check for high asymmetry (> 80%)
    if (data.totalGRF > 0) {
      final asymmetry = (data.leftGRF - data.rightGRF).abs() / data.totalGRF * 100;
      if (asymmetry > 80) {
        _qualityIssues.add('Yüksek asimetri tespit edildi: ${asymmetry.toStringAsFixed(1)}%');
        _dataQualityGood = false;
      }
    }
    
    _currentMetrics['dataQuality'] = _dataQualityGood ? 1.0 : 0.0;
  }

  // =================== CALCULATION HELPERS ===================

  double _getElapsedSeconds() {
    if (_testStartTime == null) return 0.0;
    return DateTime.now().difference(_testStartTime!).inMilliseconds / 1000.0;
  }

  double _getPhaseElapsedTime(JumpPhase phase) {
    // Simplified phase time calculation
    return _currentMetrics['phase${phase.name}StartTime'] ?? 0.0;
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    return values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
  }

  double _calculateRSI() {
    final jumpHeight = _currentMetrics['estimatedJumpHeight'] ?? 0;
    final contactTime = _currentMetrics['contactTime'] ?? 1;
    return contactTime > 0 ? jumpHeight / contactTime : 0;
  }

  List<double> _calculateVelocities(List<double> forces) {
    // Simplified velocity calculation from force using impulse-momentum
    final velocities = <double>[];
    double velocity = 0.0;
    
    for (final force in forces) {
      final acceleration = (force - (_bodyWeight ?? 700) * 9.81) / (_bodyWeight ?? 70);
      velocity += acceleration * 0.01; // 100Hz sample rate
      velocities.add(velocity);
    }
    
    return velocities;
  }

  double _calculateJumpConsistency() {
    // Placeholder for jump-to-jump consistency calculation
    return 0.8; // 80% consistency placeholder
  }

  double _calculatePerformanceDecline() {
    // Placeholder for fatigue-based performance decline
    final jumpCount = _currentMetrics['jumpCount'] ?? 1;
    return jumpCount > 1 ? (jumpCount - 1) * 2 : 0; // 2% decline per jump
  }

  TestResult _generateTestResult() {
    return TestResult(
      testType: _currentTestType!,
      duration: _getElapsedSeconds(),
      phases: [_currentPhase], // Simplified
      metrics: Map.from(_currentMetrics),
      dataQuality: _dataQualityGood,
      qualityIssues: List.from(_qualityIssues),
      rawData: List.from(_dataBuffer),
    );
  }

  // =================== GETTERS ===================

  Map<String, double> get currentMetrics => Map.from(_currentMetrics);
  JumpPhase get currentPhase => _currentPhase;
  bool get isRunning => _isRunning;
  bool get dataQuality => _dataQualityGood;
  List<String> get qualityIssues => List.from(_qualityIssues);

  void dispose() {
    _isRunning = false;
    _dataBuffer.clear();
    _currentMetrics.clear();
  }
}

// =================== TEST RESULT CLASS ===================

class TestResult {
  final TestType testType;
  final double duration;
  final List<JumpPhase> phases;
  final Map<String, double> metrics;
  final bool dataQuality;
  final List<String> qualityIssues;
  final List<ForceData> rawData;

  const TestResult({
    required this.testType,
    required this.duration,
    required this.phases,
    required this.metrics,
    required this.dataQuality,
    required this.qualityIssues,
    required this.rawData,
  });

  @override
  String toString() {
    return 'TestResult(type: $testType, duration: ${duration.toStringAsFixed(1)}s, quality: $dataQuality)';
  }
}