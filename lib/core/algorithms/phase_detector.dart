// lib/core/algorithms/phase_detector.dart
import 'dart:math' as math;
import '../../domain/entities/force_data.dart';
import 'metrics_calculator.dart';

/// VALD ForceDecks benzeri otomatik faz tespit algoritması
/// Sıçrama hareketinin farklı fazlarını gerçek zamanlı tespit eder
class PhaseDetector {
  
  // Faz tespit parametreleri
  static const double _quietStandingThreshold = 1.2; // BW multiplier
  static const double _unweightingThreshold = 0.8;   // BW multiplier
  static const double _flightThreshold = 50.0;       // Newtons
  static const double _landingThreshold = 100.0;     // Newtons
  static const int _minimumPhaseDuration = 50;       // milliseconds
  
  /// Gerçek zamanlı faz tespit - her yeni data point için
  static JumpPhase detectCurrentPhase(
    ForceData current, 
    ForceData? previous, 
    double bodyWeightN,
    {JumpPhase? previousPhase}
  ) {
    final currentPhase = previousPhase ?? JumpPhase.quietStanding;
    
    // Phase transition logic based on current state
    switch (currentPhase) {
      case JumpPhase.quietStanding:
        return _detectFromQuietStanding(current, bodyWeightN);
        
      case JumpPhase.unweighting:
        return _detectFromUnweighting(current, previous, bodyWeightN);
        
      case JumpPhase.braking:
        return _detectFromBraking(current, previous, bodyWeightN);
        
      case JumpPhase.propulsion:
        return _detectFromPropulsion(current, previous, bodyWeightN);
        
      case JumpPhase.flight:
        return _detectFromFlight(current, bodyWeightN);
        
      case JumpPhase.landing:
        return _detectFromLanding(current, bodyWeightN);
    }
  }
  
  /// Tüm test verisi için kapsamlı faz analizi
  static List<PhaseMarker> detectAllPhases(List<ForceData> data, double bodyWeightN) {
    if (data.length < 10) return [];
    
    final phases = <PhaseMarker>[];
    final velocities = _calculateVelocities(data, bodyWeightN);
    
    JumpPhase currentPhase = JumpPhase.quietStanding;
    int phaseStartIndex = 0;
    double phaseStartTime = data.first.timestamp.toDouble();
    
    for (int i = 1; i < data.length; i++) {
      final newPhase = _detectPhaseAtIndex(
        data, velocities, i, bodyWeightN, currentPhase
      );
      
      // Phase transition detected
      if (newPhase != currentPhase) {
        // Add completed phase if it meets minimum duration
        final phaseDuration = data[i-1].timestamp - phaseStartTime;
        if (phaseDuration >= _minimumPhaseDuration) {
          phases.add(PhaseMarker(
            phase: currentPhase,
            startIndex: phaseStartIndex,
            endIndex: i - 1,
            startTime: phaseStartTime,
            endTime: data[i-1].timestamp.toDouble(),
          ));
        }
        
        // Start new phase
        currentPhase = newPhase;
        phaseStartIndex = i;
        phaseStartTime = data[i].timestamp.toDouble();
      }
    }
    
    // Add final phase
    if (data.isNotEmpty) {
      phases.add(PhaseMarker(
        phase: currentPhase,
        startIndex: phaseStartIndex,
        endIndex: data.length - 1,
        startTime: phaseStartTime,
        endTime: data.last.timestamp.toDouble(),
      ));
    }
    
    return _validateAndCleanPhases(phases);
  }
  
  /// Faz bazlı metrik hesaplamaları
  static Map<JumpPhase, Map<String, double>> calculatePhaseMetrics(
    List<ForceData> data, 
    List<PhaseMarker> phases, 
    double bodyWeightN
  ) {
    final phaseMetrics = <JumpPhase, Map<String, double>>{};
    
    for (final phase in phases) {
      final phaseData = data.sublist(phase.startIndex, phase.endIndex + 1);
      final metrics = <String, double>{};
      
      switch (phase.phase) {
        case JumpPhase.quietStanding:
          metrics.addAll(_calculateQuietStandingMetrics(phaseData));
          break;
          
        case JumpPhase.unweighting:
          metrics.addAll(_calculateUnweightingMetrics(phaseData, bodyWeightN));
          break;
          
        case JumpPhase.braking:
          metrics.addAll(_calculateBrakingMetrics(phaseData, bodyWeightN));
          break;
          
        case JumpPhase.propulsion:
          metrics.addAll(_calculatePropulsionMetrics(phaseData, bodyWeightN));
          break;
          
        case JumpPhase.flight:
          metrics.addAll(_calculateFlightMetrics(phaseData, phase));
          break;
          
        case JumpPhase.landing:
          metrics.addAll(_calculateLandingMetrics(phaseData, bodyWeightN));
          break;
      }
      
      phaseMetrics[phase.phase] = metrics;
    }
    
    return phaseMetrics;
  }
  
  // =================== PRİVATE HELPER METHODS ===================
  
  /// Quiet Standing fazından çıkış tespiti
  static JumpPhase _detectFromQuietStanding(ForceData current, double bodyWeightN) {
    if (current.totalGRF < bodyWeightN * _unweightingThreshold) {
      return JumpPhase.unweighting;
    }
    return JumpPhase.quietStanding;
  }
  
  /// Unweighting fazından çıkış tespiti
  static JumpPhase _detectFromUnweighting(ForceData current, ForceData? previous, double bodyWeightN) {
    if (previous == null) return JumpPhase.unweighting;
    
    // Return to quiet standing if force increases back to BW
    if (current.totalGRF > bodyWeightN * _quietStandingThreshold) {
      return JumpPhase.quietStanding;
    }
    
    // Transition to braking if force starts increasing above BW
    if (current.totalGRF > bodyWeightN && 
        current.totalGRF > previous.totalGRF) {
      return JumpPhase.braking;
    }
    
    return JumpPhase.unweighting;
  }
  
  /// Braking fazından çıkış tespiti (velocity based)
  static JumpPhase _detectFromBraking(ForceData current, ForceData? previous, double bodyWeightN) {
    if (previous == null) return JumpPhase.braking;
    
    // Calculate simple velocity direction
    final dt = (current.timestamp - previous.timestamp) / 1000.0;
    if (dt <= 0) return JumpPhase.braking;
    
    final mass = bodyWeightN / 9.81;
    final avgForce = (current.totalGRF + previous.totalGRF) / 2;
    final acceleration = (avgForce - bodyWeightN) / mass;
    
    // Transition to propulsion when acceleration becomes positive
    // (velocity stops decreasing and starts increasing)
    if (acceleration > 0.5 && current.totalGRF > bodyWeightN) {
      return JumpPhase.propulsion;
    }
    
    return JumpPhase.braking;
  }
  
  /// Propulsion fazından çıkış tespiti
  static JumpPhase _detectFromPropulsion(ForceData current, ForceData? previous, double bodyWeightN) {
    // Takeoff when force drops below threshold
    if (current.totalGRF < _flightThreshold) {
      return JumpPhase.flight;
    }
    
    return JumpPhase.propulsion;
  }
  
  /// Flight fazından çıkış tespiti
  static JumpPhase _detectFromFlight(ForceData current, double bodyWeightN) {
    // Landing when force exceeds threshold
    if (current.totalGRF > _landingThreshold) {
      return JumpPhase.landing;
    }
    
    return JumpPhase.flight;
  }
  
  /// Landing fazından çıkış tespiti
  static JumpPhase _detectFromLanding(ForceData current, double bodyWeightN) {
    // Return to quiet standing when force stabilizes around body weight
    if (current.totalGRF > bodyWeightN * 0.9 && 
        current.totalGRF < bodyWeightN * 1.1) {
      return JumpPhase.quietStanding;
    }
    
    return JumpPhase.landing;
  }
  
  /// Index bazlı faz tespiti (kapsamlı analiz için)
  static JumpPhase _detectPhaseAtIndex(
    List<ForceData> data, 
    List<double> velocities,
    int index, 
    double bodyWeightN, 
    JumpPhase currentPhase
  ) {
    final current = data[index];
    final velocity = velocities[index];
    
    // Force thresholds
    final isQuietForce = current.totalGRF > bodyWeightN * 0.9 && 
                        current.totalGRF < bodyWeightN * 1.1;
    final isUnweighting = current.totalGRF < bodyWeightN * _unweightingThreshold;
    final isAboveBW = current.totalGRF > bodyWeightN;
    final isFlight = current.totalGRF < _flightThreshold;
    final isLanding = current.totalGRF > _landingThreshold;
    
    // Phase detection logic
    switch (currentPhase) {
      case JumpPhase.quietStanding:
        if (isUnweighting) return JumpPhase.unweighting;
        break;
        
      case JumpPhase.unweighting:
        if (isQuietForce) return JumpPhase.quietStanding;
        if (isAboveBW && velocity < 0) return JumpPhase.braking;
        break;
        
      case JumpPhase.braking:
        if (velocity >= 0 && isAboveBW) return JumpPhase.propulsion;
        break;
        
      case JumpPhase.propulsion:
        if (isFlight) return JumpPhase.flight;
        break;
        
      case JumpPhase.flight:
        if (isLanding) return JumpPhase.landing;
        break;
        
      case JumpPhase.landing:
        if (isQuietForce) return JumpPhase.quietStanding;
        break;
    }
    
    return currentPhase;
  }
  
  /// Velocity hesaplama (faz tespiti için)
  static List<double> _calculateVelocities(List<ForceData> data, double bodyWeightN) {
    final velocities = <double>[];
    final mass = bodyWeightN / 9.81;
    double velocity = 0.0;
    
    velocities.add(0.0); // First point has zero velocity
    
    for (int i = 1; i < data.length; i++) {
      final dt = (data[i].timestamp - data[i-1].timestamp) / 1000.0;
      if (dt > 0) {
        final avgForce = (data[i].totalGRF + data[i-1].totalGRF) / 2;
        final acceleration = (avgForce - bodyWeightN) / mass;
        velocity += acceleration * dt;
      }
      velocities.add(velocity);
    }
    
    return velocities;
  }
  
  /// Fazları temizle ve validate et
  static List<PhaseMarker> _validateAndCleanPhases(List<PhaseMarker> phases) {
    final cleanedPhases = <PhaseMarker>[];
    
    for (final phase in phases) {
      // Minimum duration check
      final duration = phase.endTime - phase.startTime;
      if (duration >= _minimumPhaseDuration) {
        cleanedPhases.add(phase);
      }
    }
    
    return cleanedPhases;
  }
  
  // =================== PHASE-SPECIFIC METRICS ===================
  
  /// Quiet Standing metrikleri
  static Map<String, double> _calculateQuietStandingMetrics(List<ForceData> data) {
    if (data.isEmpty) return {};
    
    final forces = data.map((d) => d.totalGRF).toList();
    final mean = forces.reduce((a, b) => a + b) / forces.length;
    
    // Standard deviation
    final variance = forces.map((f) => math.pow(f - mean, 2)).reduce((a, b) => a + b) / forces.length;
    final stdDev = math.sqrt(variance);
    
    return {
      'duration': (data.last.timestamp - data.first.timestamp).toDouble(), // ✅ FIXED
      'meanForce': mean,
      'stdDevForce': stdDev,
      'bodyWeight': mean, // Estimate body weight from quiet standing
    };
  }
  
  /// Unweighting metrikleri
  static Map<String, double> _calculateUnweightingMetrics(List<ForceData> data, double bodyWeightN) {
    if (data.isEmpty) return {};
    
    final forces = data.map((d) => d.totalGRF).toList();
    final minForce = forces.reduce(math.min);
    final duration = (data.last.timestamp - data.first.timestamp).toDouble(); // ✅ FIXED
    
    return {
      'duration': duration,
      'minForce': minForce,
      'unweightingDepth': bodyWeightN - minForce,
      'unweightingRate': (bodyWeightN - minForce) / (duration / 1000.0), // N/s
    };
  }
  
  /// Braking (Eccentric) metrikleri
  static Map<String, double> _calculateBrakingMetrics(List<ForceData> data, double bodyWeightN) {
    if (data.isEmpty) return {};
    
    final duration = (data.last.timestamp - data.first.timestamp).toDouble(); // ✅ FIXED
    final impulse = MetricsCalculator.calculateTotalImpulse(data);
    final peakForce = data.map((d) => d.totalGRF).reduce(math.max);
    
    // Eccentric RFD
    double maxRFD = 0.0;
    for (int i = 1; i < data.length; i++) {
      final dt = (data[i].timestamp - data[i-1].timestamp) / 1000.0;
      if (dt > 0) {
        final rfd = (data[i].totalGRF - data[i-1].totalGRF) / dt;
        if (rfd > maxRFD) maxRFD = rfd;
      }
    }
    
    return {
      'duration': duration,
      'peakForce': peakForce,
      'impulse': impulse,
      'eccentricRFD': maxRFD,
      'meanForce': data.map((d) => d.totalGRF).reduce((a, b) => a + b) / data.length,
    };
  }
  
  /// Propulsion (Concentric) metrikleri
  static Map<String, double> _calculatePropulsionMetrics(List<ForceData> data, double bodyWeightN) {
    if (data.isEmpty) return {};
    
    final duration = (data.last.timestamp - data.first.timestamp).toDouble(); // ✅ FIXED
    final netImpulse = MetricsCalculator.calculateNetImpulse(data, bodyWeightN);
    final peakForce = data.map((d) => d.totalGRF).reduce(math.max);
    
    // Concentric RFD
    double maxRFD = 0.0;
    for (int i = 1; i < data.length; i++) {
      final dt = (data[i].timestamp - data[i-1].timestamp) / 1000.0;
      if (dt > 0) {
        final rfd = (data[i].totalGRF - data[i-1].totalGRF) / dt;
        if (rfd > maxRFD) maxRFD = rfd;
      }
    }
    
    return {
      'duration': duration,
      'peakForce': peakForce,
      'netImpulse': netImpulse,
      'concentricRFD': maxRFD,
      'meanForce': data.map((d) => d.totalGRF).reduce((a, b) => a + b) / data.length,
    };
  }
  
  /// Flight metrikleri
  static Map<String, double> _calculateFlightMetrics(List<ForceData> data, PhaseMarker phase) {
    final duration = phase.endTime - phase.startTime;
    
    return {
      'flightTime': duration,
      'meanForce': data.isNotEmpty ? data.map((d) => d.totalGRF).reduce((a, b) => a + b) / data.length : 0.0,
    };
  }
  
  /// Landing metrikleri
  static Map<String, double> _calculateLandingMetrics(List<ForceData> data, double bodyWeightN) {
    if (data.isEmpty) return {};
    
    final duration = (data.last.timestamp - data.first.timestamp).toDouble(); // ✅ FIXED
    final peakForce = data.map((d) => d.totalGRF).reduce(math.max);
    final impulse = MetricsCalculator.calculateTotalImpulse(data);
    
    // Time to stabilization (when force returns to ~body weight)
    double timeToStabilization = duration;
    for (int i = 0; i < data.length; i++) {
      if (data[i].totalGRF <= bodyWeightN * 1.1) {
        timeToStabilization = (data[i].timestamp - data.first.timestamp).toDouble(); // ✅ FIXED
        break;
      }
    }
    
    // Landing RFD
    double maxRFD = 0.0;
    for (int i = 1; i < data.length; i++) {
      final dt = (data[i].timestamp - data[i-1].timestamp) / 1000.0;
      if (dt > 0) {
        final rfd = (data[i].totalGRF - data[i-1].totalGRF) / dt;
        if (rfd > maxRFD) maxRFD = rfd;
      }
    }
    
    return {
      'duration': duration,
      'peakLandingForce': peakForce,
      'landingImpulse': impulse,
      'timeToStabilization': timeToStabilization,
      'landingRFD': maxRFD,
      'landingForceRatio': peakForce / bodyWeightN,
    };
  }
  
  // =================== UTILITY METHODS ===================
  
  /// Faz geçiş noktalarını bul
  static List<PhaseTransition> findPhaseTransitions(List<PhaseMarker> phases) {
    final transitions = <PhaseTransition>[];
    
    for (int i = 1; i < phases.length; i++) {
      transitions.add(PhaseTransition(
        fromPhase: phases[i-1].phase,
        toPhase: phases[i].phase,
        transitionTime: phases[i].startTime,
        transitionIndex: phases[i].startIndex,
      ));
    }
    
    return transitions;
  }
  
  /// Faz sürelerini analiz et
  static Map<JumpPhase, double> analyzePhaseDurations(List<PhaseMarker> phases) {
    final durations = <JumpPhase, double>{};
    
    for (final phase in phases) {
      durations[phase.phase] = phase.endTime - phase.startTime;
    }
    
    return durations;
  }
  
  /// Faz kalitesini değerlendir
  static Map<JumpPhase, PhaseQuality> evaluatePhaseQuality(
    List<PhaseMarker> phases,
    Map<JumpPhase, Map<String, double>> phaseMetrics
  ) {
    final quality = <JumpPhase, PhaseQuality>{};
    
    for (final phase in phases) {
      final metrics = phaseMetrics[phase.phase] ?? {};
      quality[phase.phase] = _assessPhaseQuality(phase.phase, metrics);
    }
    
    return quality;
  }
  
  /// Faz kalitesi değerlendirmesi
  static PhaseQuality _assessPhaseQuality(JumpPhase phase, Map<String, double> metrics) {
    switch (phase) {
      case JumpPhase.propulsion:
        final duration = metrics['duration'] ?? 0.0;
        final rfd = metrics['concentricRFD'] ?? 0.0;
        
        if (duration > 200 && duration < 400 && rfd > 3000) {
          return PhaseQuality.excellent;
        } else if (duration > 150 && duration < 500 && rfd > 2000) {
          return PhaseQuality.good;
        } else {
          return PhaseQuality.poor;
        }
        
      case JumpPhase.flight:
        final flightTime = metrics['flightTime'] ?? 0.0;
        
        if (flightTime > 400) {
          return PhaseQuality.excellent;
        } else if (flightTime > 250) {
          return PhaseQuality.good;
        } else {
          return PhaseQuality.poor;
        }
        
      default:
        return PhaseQuality.good;
    }
  }
}

/// Faz geçiş bilgisi
class PhaseTransition {
  final JumpPhase fromPhase;
  final JumpPhase toPhase;
  final double transitionTime;
  final int transitionIndex;
  
  const PhaseTransition({
    required this.fromPhase,
    required this.toPhase,
    required this.transitionTime,
    required this.transitionIndex,
  });
}

/// Faz kalite değerlendirmesi
enum PhaseQuality {
  excellent,
  good,
  poor,
}

/// Extension for phase display
extension JumpPhaseExtension on JumpPhase {
  String get turkishName {
    switch (this) {
      case JumpPhase.quietStanding:
        return 'Sakin Duruş';
      case JumpPhase.unweighting:
        return 'Yükten Çıkma';
      case JumpPhase.braking:
        return 'Fren (Eksantrik)';
      case JumpPhase.propulsion:
        return 'İtme (Konsantrik)';
      case JumpPhase.flight:
        return 'Uçuş';
      case JumpPhase.landing:
        return 'İniş';
    }
  }
  
  String get description {
    switch (this) {
      case JumpPhase.quietStanding:
        return 'Sporcu platformda sakin duruyor';
      case JumpPhase.unweighting:
        return 'Çömelerek vücut ağırlığını azaltma';
      case JumpPhase.braking:
        return 'Eksantrik kasılma ile enerji depolama';
      case JumpPhase.propulsion:
        return 'Konsantrik kasılma ile itme';
      case JumpPhase.flight:
        return 'Havada kalma süresi';
      case JumpPhase.landing:
        return 'Zemine geri dönüş ve stabilizasyon';
    }
  }
}