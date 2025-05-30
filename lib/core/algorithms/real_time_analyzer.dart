// lib/core/algorithms/real_time_analyzer.dart
import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import '../../domain/entities/force_data.dart';
import '../constants/test_constants.dart';
import 'metrics_calculator.dart';
import 'phase_detector.dart';

/// Real-time force plate veri analizi ve test yönetimi
/// VALD ForceDecks benzeri canlı analiz motoru
class RealTimeAnalyzer {
  
  // Test state
  TestType? _currentTestType;
  bool _isTestActive = false;
  DateTime? _testStartTime;
  double _bodyWeightN = 0.0;
  
  // Data buffers
  final Queue<ForceData> _dataBuffer = Queue<ForceData>();
  final Queue<ForceData> _analysisWindow = Queue<ForceData>();
  final int _maxBufferSize = 10000; // ~10 seconds at 1000Hz
  final int _analysisWindowSize = 100; // ~100ms window
  
  // Current analysis state
  JumpPhase _currentPhase = JumpPhase.quietStanding;
  JumpPhase? _previousPhase;
  final Map<String, double> _liveMetrics = {};
  final List<PhaseMarker> _detectedPhases = [];
  
  // Test completion detection
  bool _hasJumpOccurred = false;
  bool _hasLandingOccurred = false;
  DateTime? _lastLandingTime;
  final Duration _stabilizationWaitTime = const Duration(seconds: 2);
  
  // Quality assessment
  TestQuality _testQuality = TestQuality.unknown;
  final List<String> _qualityIssues = [];
  
  // Callbacks
  Function(JumpPhase)? onPhaseChanged;
  Function(Map<String, double>)? onMetricsUpdated;
  Function(TestResult)? onTestCompleted;
  Function(String)? onQualityIssue;
  
  // =================== PUBLIC INTERFACE ===================
  
  /// Test başlatma
  void startTest(TestType testType, double bodyWeightKg) {
    _currentTestType = testType;
    _bodyWeightN = bodyWeightKg * 9.81;
    _isTestActive = true;
    _testStartTime = DateTime.now();
    
    // Reset state
    _dataBuffer.clear();
    _analysisWindow.clear();
    _currentPhase = JumpPhase.quietStanding;
    _previousPhase = null;
    _liveMetrics.clear();
    _detectedPhases.clear();
    _hasJumpOccurred = false;
    _hasLandingOccurred = false;
    _lastLandingTime = null;
    _testQuality = TestQuality.unknown;
    _qualityIssues.clear();
    
    print('🚀 Real-time analysis started: $testType');
  }
  
  /// Test durdurma
  TestResult? stopTest() {
    if (!_isTestActive) return null;
    
    _isTestActive = false;
    final testResult = _generateTestResult();
    
    print('⏹️ Real-time analysis stopped');
    onTestCompleted?.call(testResult);
    
    return testResult;
  }
  
  /// Yeni veri noktası işleme (ana metod)
  void processNewData(ForceData data) {
    if (!_isTestActive) return;
    
    try {
      // Add to buffers
      _addToBuffers(data);
      
      // Phase detection
      _updateCurrentPhase(data);
      
      // Calculate live metrics
      _updateLiveMetrics();
      
      // Test completion detection
      _checkTestCompletion();
      
      // Quality assessment
      _assessTestQuality(data);
      
    } catch (e) {
      print('❌ Real-time analysis error: $e');
    }
  }
  
  /// Mevcut canlı metrikleri al
  Map<String, double> getLiveMetrics() => Map.from(_liveMetrics);
  
  /// Mevcut faz bilgisi
  JumpPhase getCurrentPhase() => _currentPhase;
  
  /// Test durumu
  bool get isTestActive => _isTestActive;
  
  /// Test kalitesi
  TestQuality get testQuality => _testQuality;
  
  /// Kalite sorunları
  List<String> get qualityIssues => List.from(_qualityIssues);
  
  /// Tespit edilen fazlar
  List<PhaseMarker> get detectedPhases => List.from(_detectedPhases);
  
  // =================== PRIVATE METHODS ===================
  
  /// Buffer'lara veri ekleme
  void _addToBuffers(ForceData data) {
    // Ana buffer
    _dataBuffer.add(data);
    if (_dataBuffer.length > _maxBufferSize) {
      _dataBuffer.removeFirst();
    }
    
    // Analiz penceresi
    _analysisWindow.add(data);
    if (_analysisWindow.length > _analysisWindowSize) {
      _analysisWindow.removeFirst();
    }
  }
  
  /// Faz güncelleme
  void _updateCurrentPhase(ForceData data) {
    final previousData = _dataBuffer.length > 1 ? _dataBuffer.elementAt(_dataBuffer.length - 2) : null;
    
    final newPhase = PhaseDetector.detectCurrentPhase(
      data, 
      previousData, 
      _bodyWeightN,
      previousPhase: _currentPhase
    );
    
    if (newPhase != _currentPhase) {
      _previousPhase = _currentPhase;
      _currentPhase = newPhase;
      
      // Phase değişimi kaydı
      if (_testStartTime != null) {
        _detectedPhases.add(PhaseMarker(
          phase: _previousPhase!,
          startIndex: _dataBuffer.length - _analysisWindowSize,
          endIndex: _dataBuffer.length - 1,
          startTime: (_testStartTime!.millisecondsSinceEpoch + 
                     (_dataBuffer.length - _analysisWindowSize) * 10).toDouble(),
          endTime: data.timestamp.toDouble(),
        ));
      }
      
      print('📊 Phase changed: ${_previousPhase?.turkishName} → ${_currentPhase.turkishName}');
      onPhaseChanged?.call(_currentPhase);
      
      // Özel faz geçiş işlemleri
      _handlePhaseTransition(newPhase);
    }
  }
  
  /// Canlı metrik güncelleme
  void _updateLiveMetrics() {
    if (_dataBuffer.length < 10) return;
    
    final recentData = _dataBuffer.toList();
    
    // Temel metrikler
    _liveMetrics['currentForce'] = recentData.last.totalGRF;
    _liveMetrics['peakForce'] = recentData.map((d) => d.totalGRF).reduce(math.max);
    _liveMetrics['currentAsymmetry'] = recentData.last.asymmetryIndex * 100;
    
    // Test süresine bağlı metrikler
    if (_testStartTime != null) {
      final elapsedMs = DateTime.now().difference(_testStartTime!).inMilliseconds;
      _liveMetrics['testDuration'] = elapsedMs.toDouble();
      
      // Test türüne göre özel metrikler
      switch (_currentTestType!) {
        case TestType.counterMovementJump:
        case TestType.squatJump:
        case TestType.dropJump:
          _updateJumpMetrics(recentData);
          break;
          
        case TestType.balance:
        case TestType.singleLegBalance:
          _updateBalanceMetrics(recentData);
          break;
          
        case TestType.isometricMidThigh:
        case TestType.isometricSquat:
          _updateIsometricMetrics(recentData);
          break;
          
        case TestType.landing:
        case TestType.landAndHold:
          _updateLandingMetrics(recentData);
          break;
          
        default:
          break;
      }
    }
    
    // Callback tetikleme
    onMetricsUpdated?.call(Map.from(_liveMetrics));
  }
  
  /// Sıçrama metrikleri güncelleme
  void _updateJumpMetrics(List<ForceData> data) {
    // Anlık RFD hesaplama
    if (data.length >= 2) {
      final latest = data.last;
      final previous = data[data.length - 2];
      final dt = (latest.timestamp - previous.timestamp) / 1000.0;
      
      if (dt > 0) {
        final rfd = (latest.totalGRF - previous.totalGRF) / dt;
        _liveMetrics['currentRFD'] = rfd;
        
        // Peak RFD tracking
        final currentPeakRFD = _liveMetrics['peakRFD'] ?? 0.0;
        if (rfd > currentPeakRFD && latest.totalGRF > _bodyWeightN) {
          _liveMetrics['peakRFD'] = rfd;
        }
      }
    }
    
    // Jump height estimation (eğer jump tamamlandıysa)
    if (_hasJumpOccurred && _currentPhase == JumpPhase.landing) {
      final jumpHeight = MetricsCalculator.calculateJumpHeight(data, _bodyWeightN);
      _liveMetrics['estimatedJumpHeight'] = jumpHeight;
    }
    
    // Flight time tracking
    if (_currentPhase == JumpPhase.flight) {
      final flightStart = _detectedPhases
          .where((p) => p.phase == JumpPhase.flight)
          .lastOrNull?.startTime ?? data.last.timestamp.toDouble();
      _liveMetrics['currentFlightTime'] = data.last.timestamp - flightStart;
    }
  }
  
  /// Denge metrikleri güncelleme
  void _updateBalanceMetrics(List<ForceData> data) {
    if (data.length < 10) return;
    
    // Center of Pressure velocity
    final copVelocities = <double>[];
    for (int i = 1; i < data.length; i++) {
      final dx = data[i].leftCoPX - data[i-1].leftCoPX; // Simplified CoP calc
      final dy = data[i].leftCoPY - data[i-1].leftCoPY;
      final dt = (data[i].timestamp - data[i-1].timestamp) / 1000.0;
      
      if (dt > 0) {
        final velocity = math.sqrt(dx * dx + dy * dy) / dt;
        copVelocities.add(velocity);
      }
    }
    
    if (copVelocities.isNotEmpty) {
      _liveMetrics['copVelocity'] = copVelocities.last;
      _liveMetrics['avgCopVelocity'] = copVelocities.reduce((a, b) => a + b) / copVelocities.length;
    }
    
    // Sway area estimation
    final forces = data.map((d) => d.totalGRF).toList();
    final variance = _calculateVariance(forces);
    _liveMetrics['swayVariance'] = variance;
  }
  
  /// İzometrik metrikler güncelleme
  void _updateIsometricMetrics(List<ForceData> data) {
    if (data.length < 10) return;
    
    final forces = data.map((d) => d.totalGRF).toList();
    final currentForce = forces.last;
    
    // Plateau detection
    final recentForces = forces.takeLast(math.min(50, forces.length));
    final isStable = _isForceStable(recentForces, threshold: 50.0); // 50N threshold
    
    _liveMetrics['isPlatteau'] = isStable ? 1.0 : 0.0;
    _liveMetrics['plateauForce'] = isStable ? recentForces.reduce((a, b) => a + b) / recentForces.length : 0.0;
    
    // Force consistency
    final consistency = _calculateConsistency(recentForces);
    _liveMetrics['forceConsistency'] = consistency;
  }
  
  /// İniş metrikleri güncelleme
  void _updateLandingMetrics(List<ForceData> data) {
    if (_currentPhase == JumpPhase.landing && data.isNotEmpty) {
      final currentForce = data.last.totalGRF;
      
      // Landing impact force
      final currentPeakLanding = _liveMetrics['peakLandingForce'] ?? 0.0;
      if (currentForce > currentPeakLanding) {
        _liveMetrics['peakLandingForce'] = currentForce;
      }
      
      // Stabilization progress
      final stabilizationThreshold = _bodyWeightN * 1.1;
      _liveMetrics['isStabilizing'] = currentForce <= stabilizationThreshold ? 1.0 : 0.0;
    }
  }
  
  /// Test tamamlanma kontrolü
  void _checkTestCompletion() {
    if (!_isTestActive || _testStartTime == null) return;
    
    final elapsedTime = DateTime.now().difference(_testStartTime!);
    final maxDuration = TestConstants.testDurations[_currentTestType!] ?? const Duration(seconds: 10);
    
    // Maksimum süre kontrolü
    if (elapsedTime >= maxDuration) {
      print('⏰ Test completed: Maximum duration reached');
      stopTest();
      return;
    }
    
    // Test türüne göre tamamlanma kriterleri
    switch (_currentTestType!) {
      case TestType.counterMovementJump:
      case TestType.squatJump:
      case TestType.dropJump:
        _checkJumpTestCompletion();
        break;
        
      case TestType.balance:
      case TestType.singleLegBalance:
        // Balance testleri süre bazlı tamamlanır
        break;
        
      case TestType.isometricMidThigh:
      case TestType.isometricSquat:
        _checkIsometricTestCompletion();
        break;
        
      case TestType.landing:
      case TestType.landAndHold:
        _checkLandingTestCompletion();
        break;
        
      default:
        break;
    }
  }
  
  /// Sıçrama testi tamamlanma kontrolü
  void _checkJumpTestCompletion() {
    // Jump occurred detection
    if (!_hasJumpOccurred && _currentPhase == JumpPhase.flight) {
      _hasJumpOccurred = true;
      print('🦘 Jump detected');
    }
    
    // Landing occurred detection
    if (_hasJumpOccurred && !_hasLandingOccurred && _currentPhase == JumpPhase.landing) {
      _hasLandingOccurred = true;
      _lastLandingTime = DateTime.now();
      print('🛬 Landing detected');
    }
    
    // Stabilization check
    if (_hasLandingOccurred && _lastLandingTime != null) {
      final timeSinceLanding = DateTime.now().difference(_lastLandingTime!);
      
      if (timeSinceLanding >= _stabilizationWaitTime && 
          _currentPhase == JumpPhase.quietStanding) {
        print('✅ Jump test completed: Stabilization achieved');
        stopTest();
      }
    }
  }
  
  /// İzometrik test tamamlanma kontrolü
  void _checkIsometricTestCompletion() {
    final isPlateau = (_liveMetrics['isPlatteau'] ?? 0.0) > 0.5;
    
    if (isPlateau) {
      final elapsedTime = DateTime.now().difference(_testStartTime!);
      final minPlateauTime = const Duration(seconds: 3); // Minimum 3 saniye plateau
      
      if (elapsedTime >= minPlateauTime) {
        print('💪 Isometric test completed: Plateau maintained');
        stopTest();
      }
    }
  }
  
  /// İniş testi tamamlanma kontrolü
  void _checkLandingTestCompletion() {
    final isStabilizing = (_liveMetrics['isStabilizing'] ?? 0.0) > 0.5;
    
    if (isStabilizing && _lastLandingTime != null) {
      final timeSinceLanding = DateTime.now().difference(_lastLandingTime!);
      
      if (timeSinceLanding >= _stabilizationWaitTime) {
        print('🎯 Landing test completed: Stabilization achieved');
        stopTest();
      }
    }
  }
  
  /// Faz geçiş işlemleri
  void _handlePhaseTransition(JumpPhase newPhase) {
    switch (newPhase) {
      case JumpPhase.flight:
        _hasJumpOccurred = true;
        break;
        
      case JumpPhase.landing:
        if (_hasJumpOccurred) {
          _hasLandingOccurred = true;
          _lastLandingTime = DateTime.now();
        }
        break;
        
      default:
        break;
    }
  }
  
  /// Test kalitesi değerlendirmesi
  void _assessTestQuality(ForceData data) {
    _qualityIssues.clear();
    
    // Signal quality checks
    if (data.totalGRF < 0) {
      _qualityIssues.add('Negatif kuvvet değeri tespit edildi');
    }
    
    if (data.asymmetryIndex > 0.3) { // 30% threshold
      _qualityIssues.add('Yüksek asimetri tespit edildi (>${(data.asymmetryIndex * 100).toInt()}%)');
    }
    
    // Test-specific quality checks
    switch (_currentTestType!) {
      case TestType.counterMovementJump:
      case TestType.squatJump:
        _assessJumpQuality();
        break;
        
      case TestType.balance:
        _assessBalanceQuality();
        break;
        
      default:
        break;
    }
    
    // Overall quality assessment
    if (_qualityIssues.isEmpty) {
      _testQuality = TestQuality.excellent;
    } else if (_qualityIssues.length <= 2) {
      _testQuality = TestQuality.good;
    } else {
      _testQuality = TestQuality.poor;
    }
    
    // Notify about quality issues
    for (final issue in _qualityIssues) {
      onQualityIssue?.call(issue);
    }
  }
  
  /// Sıçrama kalitesi değerlendirmesi
  void _assessJumpQuality() {
    final peakForce = _liveMetrics['peakForce'] ?? 0.0;
    final rfd = _liveMetrics['peakRFD'] ?? 0.0;
    
    if (peakForce < _bodyWeightN * 1.5) {
      _qualityIssues.add('Düşük zirve kuvvet (${(peakForce / _bodyWeightN).toStringAsFixed(1)}x BW)');
    }
    
    if (rfd < 2000) {
      _qualityIssues.add('Düşük RFD (${rfd.toInt()} N/s)');
    }
    
    // Phase duration checks
    final propulsionPhases = _detectedPhases.where((p) => p.phase == JumpPhase.propulsion);
    if (propulsionPhases.isNotEmpty) {
      final propulsionDuration = propulsionPhases.last.endTime - propulsionPhases.last.startTime;
      if (propulsionDuration > 500) { // 500ms threshold
        _qualityIssues.add('Uzun propulsiyon fazı (${propulsionDuration.toInt()}ms)');
      }
    }
  }
  
  /// Denge kalitesi değerlendirmesi
  void _assessBalanceQuality() {
    final copVelocity = _liveMetrics['avgCopVelocity'] ?? 0.0;
    final swayVariance = _liveMetrics['swayVariance'] ?? 0.0;
    
    if (copVelocity > 20.0) { // mm/s threshold
      _qualityIssues.add('Yüksek CoP hızı (${copVelocity.toStringAsFixed(1)} mm/s)');
    }
    
    if (swayVariance > 1000) { // N² threshold
      _qualityIssues.add('Yüksek salınım varyansı');
    }
  }
  
  /// Test sonucu oluşturma
  TestResult _generateTestResult() {
    final allData = _dataBuffer.toList();
    final allMetrics = MetricsCalculator.calculateAllMetrics(allData, _bodyWeightN);
    
    // Phase metrics
    final phaseMetrics = PhaseDetector.calculatePhaseMetrics(
      allData, _detectedPhases, _bodyWeightN
    );
    
    final testDuration = _testStartTime != null 
        ? DateTime.now().difference(_testStartTime!).inMilliseconds.toDouble()
        : 0.0;
    
    return TestResult(
      testType: _currentTestType!,
      testDuration: testDuration,
      bodyWeight: _bodyWeightN / 9.81,
      allMetrics: allMetrics,
      phaseMetrics: phaseMetrics,
      detectedPhases: _detectedPhases,
      testQuality: _testQuality,
      qualityIssues: List.from(_qualityIssues),
      rawData: allData,
    );
  }
  
  // =================== UTILITY METHODS ===================
  
  /// Variance hesaplama
  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => math.pow(v - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }
  
  /// Kuvvet stabilite kontrolü
  bool _isForceStable(List<double> forces, {required double threshold}) {
    if (forces.length < 10) return false;
    
    final mean = forces.reduce((a, b) => a + b) / forces.length;
    final deviations = forces.map((f) => (f - mean).abs());
    final maxDeviation = deviations.reduce(math.max);
    
    return maxDeviation <= threshold;
  }
  
  /// Consistency hesaplama
  double _calculateConsistency(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final variance = _calculateVariance(values);
    final mean = values.reduce((a, b) => a + b) / values.length;
    
    if (mean == 0) return 0.0;
    
    final cv = math.sqrt(variance) / mean; // Coefficient of variation
    return math.max(0.0, 1.0 - cv); // 1 = perfect consistency, 0 = no consistency
  }
  
  /// Cleanup
  void dispose() {
    _dataBuffer.clear();
    _analysisWindow.clear();
    _detectedPhases.clear();
    _qualityIssues.clear();
    _liveMetrics.clear();
  }
}

/// Test kalite enum
enum TestQuality {
  unknown,
  poor,
  good,
  excellent,
}

/// Test sonucu sınıfı
class TestResult {
  final TestType testType;
  final double testDuration;
  final double bodyWeight;
  final Map<String, double> allMetrics;
  final Map<JumpPhase, Map<String, double>> phaseMetrics;
  final List<PhaseMarker> detectedPhases;
  final TestQuality testQuality;
  final List<String> qualityIssues;
  final List<ForceData> rawData;
  
  const TestResult({
    required this.testType,
    required this.testDuration,
    required this.bodyWeight,
    required this.allMetrics,
    required this.phaseMetrics,
    required this.detectedPhases,
    required this.testQuality,
    required this.qualityIssues,
    required this.rawData,
  });
  
  /// Test başarı durumu
  bool get isSuccessful => testQuality != TestQuality.poor && qualityIssues.length <= 2;
  
  /// Özet rapor
  String get summaryReport {
    final jumpHeight = allMetrics['jumpHeight']?.toStringAsFixed(1) ?? '--';
    final peakForce = allMetrics['peakForce']?.toStringAsFixed(0) ?? '--';
    final asymmetry = allMetrics['asymmetryIndex']?.toStringAsFixed(1) ?? '--';
    
    return '''
Test: ${testType.toString().split('.').last}
Süre: ${(testDuration / 1000).toStringAsFixed(1)}s
Sıçrama: ${jumpHeight}cm
Zirve Kuvvet: ${peakForce}N
Asimetri: ${asymmetry}%
Kalite: ${testQuality.toString().split('.').last}
''';
  }
}

/// Extension for List takeLast
extension ListExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (count >= length) return this;
    return sublist(length - count);
  }
  
  T? get lastOrNull => isEmpty ? null : last;
}