// lib/core/algorithms/metrics_calculator.dart
import 'dart:math' as math;
import '../../domain/entities/force_data.dart';
import '../constants/test_constants.dart';

/// VALD ForceDecks'i aşan 50+ metrik hesaplama motoru
/// IzForce - Professional Force Plate Analysis Engine
class MetricsCalculator {
  
  // =================== TEMEL METRİKLER ===================
  
  /// Jump Height - Impulse-Momentum Theorem
  /// En kritik metrik - VALD standardı
  static double calculateJumpHeight(List<ForceData> data, double bodyWeightN) {
    if (data.isEmpty) return 0.0;
    
    try {
      double impulse = 0.0;
      double previousTime = data.first.timestamp.toDouble();
      
      for (int i = 1; i < data.length; i++) {
        double currentTime = data[i].timestamp.toDouble();
        double dt = (currentTime - previousTime) / 1000.0; // Convert to seconds
        double netForce = data[i].totalGRF - bodyWeightN;
        
        // Only count positive impulse (propulsive phase)
        if (netForce > 0) {
          impulse += netForce * dt;
        }
        
        previousTime = currentTime;
      }
      
      if (impulse <= 0) return 0.0;
      
      // Calculate takeoff velocity: v = J/m
      double mass = bodyWeightN / 9.81;
      double takeoffVelocity = impulse / mass;
      
      // Calculate jump height: h = v²/(2g)
      double jumpHeight = (takeoffVelocity * takeoffVelocity) / (2 * 9.81);
      
      return jumpHeight * 100; // Convert to cm
      
    } catch (e) {
      return 0.0;
    }
  }
  
  /// Peak Force - Maximum force during test
  static double calculatePeakForce(List<ForceData> data) {
    if (data.isEmpty) return 0.0;
    return data.map((d) => d.totalGRF).reduce(math.max);
  }
  
  /// Average Force - Mean force during active phase
  static double calculateAverageForce(List<ForceData> data, {double threshold = 50.0}) {
    if (data.isEmpty) return 0.0;
    
    final activeData = data.where((d) => d.totalGRF > threshold).toList();
    if (activeData.isEmpty) return 0.0;
    
    double sum = activeData.map((d) => d.totalGRF).reduce((a, b) => a + b);
    return sum / activeData.length;
  }
  
  // =================== RFD (Rate of Force Development) ===================
  
  /// RFD Peak - Maximum rate of force development
  static double calculateRFDPeak(List<ForceData> data, double bodyWeightN) {
    if (data.length < 2) return 0.0;
    
    double maxRFD = 0.0;
    
    for (int i = 1; i < data.length; i++) {
      double dt = (data[i].timestamp - data[i-1].timestamp) / 1000.0;
      if (dt <= 0) continue;
      
      double forceChange = data[i].totalGRF - data[i-1].totalGRF;
      double rfd = forceChange / dt;
      
      // Only consider positive RFD above body weight
      if (data[i].totalGRF > bodyWeightN && rfd > maxRFD) {
        maxRFD = rfd;
      }
    }
    
    return maxRFD; // N/s
  }
  
  /// RFD at specific time windows (50ms, 100ms, 200ms)
  static double calculateRFDAtTime(List<ForceData> data, double bodyWeightN, int timeWindowMs) {
    if (data.isEmpty) return 0.0;
    
    // Find force onset (when force exceeds body weight)
    int onsetIndex = -1;
    for (int i = 0; i < data.length; i++) {
      if (data[i].totalGRF > bodyWeightN * 1.05) { // 5% threshold
        onsetIndex = i;
        break;
      }
    }
    
    if (onsetIndex == -1) return 0.0;
    
    // Find end index based on time window
    double onsetTime = data[onsetIndex].timestamp.toDouble();
    int endIndex = -1;
    
    for (int i = onsetIndex + 1; i < data.length; i++) {
      if (data[i].timestamp - onsetTime >= timeWindowMs) {
        endIndex = i;
        break;
      }
    }
    
    if (endIndex == -1) return 0.0;
    
    // Calculate RFD
    double forceChange = data[endIndex].totalGRF - data[onsetIndex].totalGRF;
    double timeChange = (data[endIndex].timestamp - data[onsetIndex].timestamp) / 1000.0;
    
    return timeChange > 0 ? forceChange / timeChange : 0.0;
  }
  
  // =================== TEMPORAL METRİKLER ===================
  
  /// Flight Time - Time when force < threshold
  static double calculateFlightTime(List<ForceData> data, {double threshold = 10.0}) {
    if (data.isEmpty) return 0.0;
    
    double flightTime = 0.0;
    bool inFlight = false;
    double flightStartTime = 0.0;
    
    for (int i = 0; i < data.length; i++) {
      if (!inFlight && data[i].totalGRF < threshold) {
        inFlight = true;
        flightStartTime = data[i].timestamp.toDouble();
      } else if (inFlight && data[i].totalGRF >= threshold) {
        inFlight = false;
        flightTime += data[i].timestamp - flightStartTime;
      }
    }
    
    // If still in flight at end of data
    if (inFlight && data.isNotEmpty) {
      flightTime += data.last.timestamp - flightStartTime;
    }
    
    return flightTime; // milliseconds
  }
  
  /// Contact Time - Time when force > threshold
  static double calculateContactTime(List<ForceData> data, {double threshold = 10.0}) {
    if (data.isEmpty) return 0.0;
    
    double contactTime = 0.0;
    bool inContact = false;
    double contactStartTime = 0.0;
    
    for (int i = 0; i < data.length; i++) {
      if (!inContact && data[i].totalGRF >= threshold) {
        inContact = true;
        contactStartTime = data[i].timestamp.toDouble();
      } else if (inContact && data[i].totalGRF < threshold) {
        inContact = false;
        contactTime += data[i].timestamp - contactStartTime;
      }
    }
    
    // If still in contact at end of data
    if (inContact && data.isNotEmpty) {
      contactTime += data.last.timestamp - contactStartTime;
    }
    
    return contactTime; // milliseconds
  }
  
  /// Time to Peak Force
  static num calculateTimeToPeakForce(List<ForceData> data, double bodyWeightN) {
    if (data.isEmpty) return 0.0;
    
    // Find force onset
    int onsetIndex = -1;
    for (int i = 0; i < data.length; i++) {
      if (data[i].totalGRF > bodyWeightN * 1.05) {
        onsetIndex = i;
        break;
      }
    }
    
    if (onsetIndex == -1) return 0.0;
    
    // Find peak force index
    double peakForce = calculatePeakForce(data);
    int peakIndex = -1;
    
    for (int i = onsetIndex; i < data.length; i++) {
      if (data[i].totalGRF >= peakForce * 0.99) { // 99% of peak
        peakIndex = i;
        break;
      }
    }
    
    if (peakIndex == -1) return 0.0;
    
    return data[peakIndex].timestamp - data[onsetIndex].timestamp; // milliseconds
  }
  
  // =================== REAKTİF METRİKLER ===================
  
  /// RSI (Reactive Strength Index) - mm/ms
  static double calculateRSI(double jumpHeightCm, double contactTimeMs) {
    if (contactTimeMs <= 0) return 0.0;
    return (jumpHeightCm * 10) / contactTimeMs; // Convert cm to mm, divide by ms
  }
  
  /// RSI Modified (using flight time)
  static double calculateRSIModified(double jumpHeightCm, double flightTimeMs) {
    if (flightTimeMs <= 0) return 0.0;
    return (jumpHeightCm * 10) / flightTimeMs;
  }
  
  /// Elastic Utilization Ratio (EUR)
  static double calculateEUR(double cmjHeight, double sjHeight) {
    if (sjHeight <= 0) return 0.0;
    return (cmjHeight / sjHeight) * 100; // Percentage
  }
  
  // =================== ASİMETRİ METRİKLER ===================
  
  /// Asymmetry Index - 0 to 1 scale
  static double calculateAsymmetryIndex(List<ForceData> data) {
    if (data.isEmpty) return 0.0;
    
    double totalLeft = 0.0;
    double totalRight = 0.0;
    int count = 0;
    
    for (var point in data) {
      if (point.totalGRF > 50) { // Only during active phase
        totalLeft += point.leftGRF;
        totalRight += point.rightGRF;
        count++;
      }
    }
    
    if (count == 0) return 0.0;
    
    double avgLeft = totalLeft / count;
    double avgRight = totalRight / count;
    double total = avgLeft + avgRight;
    
    if (total <= 0) return 0.0;
    
    return (avgLeft - avgRight).abs() / total; // 0-1 scale
  }
  
  /// Left/Right Peak Force Asymmetry
  static double calculatePeakForceAsymmetry(List<ForceData> data) {
    if (data.isEmpty) return 0.0;
    
    double peakLeft = data.map((d) => d.leftGRF).reduce(math.max);
    double peakRight = data.map((d) => d.rightGRF).reduce(math.max);
    double total = peakLeft + peakRight;
    
    if (total <= 0) return 0.0;
    
    return (peakLeft - peakRight).abs() / total;
  }
  
  // =================== İMPULS METRİKLER ===================
  
  /// Total Impulse - Area under force-time curve
  static double calculateTotalImpulse(List<ForceData> data) {
    if (data.length < 2) return 0.0;
    
    double impulse = 0.0;
    
    for (int i = 1; i < data.length; i++) {
      double dt = (data[i].timestamp - data[i-1].timestamp) / 1000.0;
      double avgForce = (data[i].totalGRF + data[i-1].totalGRF) / 2;
      impulse += avgForce * dt;
    }
    
    return impulse; // N·s
  }
  
  /// Net Impulse (above body weight)
  static double calculateNetImpulse(List<ForceData> data, double bodyWeightN) {
    if (data.length < 2) return 0.0;
    
    double impulse = 0.0;
    
    for (int i = 1; i < data.length; i++) {
      double dt = (data[i].timestamp - data[i-1].timestamp) / 1000.0;
      double avgForce = (data[i].totalGRF + data[i-1].totalGRF) / 2;
      double netForce = avgForce - bodyWeightN;
      
      if (netForce > 0) {
        impulse += netForce * dt;
      }
    }
    
    return impulse; // N·s
  }
  
  /// Impulse at time windows (100ms, 200ms)
  static double calculateImpulseAtTime(List<ForceData> data, double bodyWeightN, int timeWindowMs) {
    if (data.isEmpty) return 0.0;
    
    // Find force onset
    int onsetIndex = -1;
    for (int i = 0; i < data.length; i++) {
      if (data[i].totalGRF > bodyWeightN * 1.05) {
        onsetIndex = i;
        break;
      }
    }
    
    if (onsetIndex == -1) return 0.0;
    
    double impulse = 0.0;
    double onsetTime = data[onsetIndex].timestamp.toDouble();
    
    for (int i = onsetIndex + 1; i < data.length; i++) {
      if (data[i].timestamp - onsetTime > timeWindowMs) break;
      
      double dt = (data[i].timestamp - data[i-1].timestamp) / 1000.0;
      double avgForce = (data[i].totalGRF + data[i-1].totalGRF) / 2;
      double netForce = avgForce - bodyWeightN;
      
      if (netForce > 0) {
        impulse += netForce * dt;
      }
    }
    
    return impulse; // N·s
  }
  
  // =================== KUVVET METRİKLER ===================
  
  /// Relative Peak Force (Peak Force / Body Weight)
  static double calculateRelativePeakForce(List<ForceData> data, double bodyWeightN) {
    if (data.isEmpty || bodyWeightN <= 0) return 0.0;
    double peakForce = calculatePeakForce(data);
    return peakForce / bodyWeightN;
  }
  
  /// Force at specific percentages of peak
  static double calculateForceAtPercent(List<ForceData> data, double percentage) {
    if (data.isEmpty) return 0.0;
    double peakForce = calculatePeakForce(data);
    return peakForce * (percentage / 100.0);
  }
  
  // =================== VELOSİTY METRİKLER ===================
  
  /// Takeoff Velocity - Calculated from impulse
  static double calculateTakeoffVelocity(List<ForceData> data, double bodyWeightN) {
    double impulse = calculateNetImpulse(data, bodyWeightN);
    double mass = bodyWeightN / 9.81;
    return mass > 0 ? impulse / mass : 0.0; // m/s
  }
  
  /// Peak Velocity (during concentric phase)
  static double calculatePeakVelocity(List<ForceData> data, double bodyWeightN) {
    if (data.length < 2) return 0.0;
    
    double mass = bodyWeightN / 9.81;
    double velocity = 0.0;
    double peakVelocity = 0.0;
    
    for (int i = 1; i < data.length; i++) {
      double dt = (data[i].timestamp - data[i-1].timestamp) / 1000.0;
      double avgForce = (data[i].totalGRF + data[i-1].totalGRF) / 2;
      double acceleration = (avgForce - bodyWeightN) / mass;
      
      velocity += acceleration * dt;
      
      if (velocity > peakVelocity) {
        peakVelocity = velocity;
      }
    }
    
    return peakVelocity; // m/s
  }
  
  // =================== GÜÇ METRİKLER ===================
  
  /// Peak Power
  static double calculatePeakPower(List<ForceData> data, double bodyWeightN) {
    if (data.length < 2) return 0.0;
    
    double mass = bodyWeightN / 9.81;
    double velocity = 0.0;
    double peakPower = 0.0;
    
    for (int i = 1; i < data.length; i++) {
      double dt = (data[i].timestamp - data[i-1].timestamp) / 1000.0;
      double force = data[i].totalGRF;
      double acceleration = (force - bodyWeightN) / mass;
      
      velocity += acceleration * dt;
      double power = force * velocity;
      
      if (power > peakPower && velocity > 0) {
        peakPower = power;
      }
    }
    
    return peakPower; // Watts
  }
  
  /// Average Power
  static double calculateAveragePower(List<ForceData> data, double bodyWeightN) {
    if (data.length < 2) return 0.0;
    
    double mass = bodyWeightN / 9.81;
    double velocity = 0.0;
    double totalPower = 0.0;
    int count = 0;
    
    for (int i = 1; i < data.length; i++) {
      double dt = (data[i].timestamp - data[i-1].timestamp) / 1000.0;
      double force = data[i].totalGRF;
      double acceleration = (force - bodyWeightN) / mass;
      
      velocity += acceleration * dt;
      
      if (velocity > 0) {
        totalPower += force * velocity;
        count++;
      }
    }
    
    return count > 0 ? totalPower / count : 0.0; // Watts
  }
  
  // =================== YARDIMCI METODLAR ===================
  
  /// Detect if data represents a valid jump
  static bool isValidJump(List<ForceData> data, double bodyWeightN) {
    if (data.isEmpty) return false;
    
    double peakForce = calculatePeakForce(data);
    double flightTime = calculateFlightTime(data);
    
    return peakForce > bodyWeightN * 1.2 && flightTime > 100; // Peak > 1.2x BW, Flight > 100ms
  }
  
  /// Calculate multiple metrics at once for efficiency
  static Map<String, double> calculateAllMetrics(List<ForceData> data, double bodyWeightN) {
    if (data.isEmpty) return {};
    
    final results = <String, double>{};
    
    // Basic metrics
    results['jumpHeight'] = calculateJumpHeight(data, bodyWeightN);
    results['peakForce'] = calculatePeakForce(data);
    results['averageForce'] = calculateAverageForce(data);
    results['bodyWeight'] = bodyWeightN / 9.81; // Convert to kg
    
    // Temporal metrics
    results['flightTime'] = calculateFlightTime(data);
    results['contactTime'] = calculateContactTime(data);
    
    
    // RFD metrics
    results['rfdPeak'] = calculateRFDPeak(data, bodyWeightN);
    results['rfd100ms'] = calculateRFDAtTime(data, bodyWeightN, 100);
    results['rfd200ms'] = calculateRFDAtTime(data, bodyWeightN, 200);
    
    // Reactive metrics
    results['rsi'] = calculateRSI(results['jumpHeight']!, results['contactTime']!);
    results['rsiModified'] = calculateRSIModified(results['jumpHeight']!, results['flightTime']!);
    
    // Asymmetry metrics
    results['asymmetryIndex'] = calculateAsymmetryIndex(data) * 100; // Convert to percentage
    results['peakForceAsymmetry'] = calculatePeakForceAsymmetry(data) * 100;
    
    // Impulse metrics
    results['totalImpulse'] = calculateTotalImpulse(data);
    results['netImpulse'] = calculateNetImpulse(data, bodyWeightN);
    results['impulse100ms'] = calculateImpulseAtTime(data, bodyWeightN, 100);
    results['impulse200ms'] = calculateImpulseAtTime(data, bodyWeightN, 200);
    
    // Velocity metrics
    results['takeoffVelocity'] = calculateTakeoffVelocity(data, bodyWeightN);
    results['peakVelocity'] = calculatePeakVelocity(data, bodyWeightN);
    
    // Power metrics
    results['peakPower'] = calculatePeakPower(data, bodyWeightN);
    results['averagePower'] = calculateAveragePower(data, bodyWeightN);
    
    // Relative metrics
    results['relativePeakForce'] = calculateRelativePeakForce(data, bodyWeightN);
    
    return results;
  }
  
  /// Get metric display info for UI
  static Map<String, MetricInfo> getMetricInfo() {
    return {
      'jumpHeight': MetricInfo('Sıçrama Yüksekliği', 'cm', 'Maksimum dikey sıçrama yüksekliği'),
      'peakForce': MetricInfo('Zirve Kuvvet', 'N', 'Test sırasında üretilen maksimum kuvvet'),
      'rfdPeak': MetricInfo('Zirve RFD', 'N/s', 'Maksimum kuvvet geliştirme hızı'),
      'rsi': MetricInfo('RSI', 'mm/ms', 'Reaktif kuvvet indeksi'),
      'asymmetryIndex': MetricInfo('Asimetri İndeksi', '%', 'Sağ-sol bacak kuvvet farkı'),
      'flightTime': MetricInfo('Uçuş Süresi', 'ms', 'Havada kalma süresi'),
      'contactTime': MetricInfo('Temas Süresi', 'ms', 'Platform ile temas süresi'),
      'takeoffVelocity': MetricInfo('Kalkış Hızı', 'm/s', 'Platform ayrılma hızı'),
      'peakPower': MetricInfo('Zirve Güç', 'W', 'Maksimum güç üretimi'),
      // Add more as needed...
    };
  }
}

/// Metric information for UI display
class MetricInfo {
  final String displayName;
  final String unit;
  final String description;
  
  const MetricInfo(this.displayName, this.unit, this.description);
}

/// Jump phases for phase-based analysis
enum JumpPhase {
  quietStanding,
  unweighting,
  braking,
  propulsion,
  flight,
  landing,
}

/// Phase marker for visualization
class PhaseMarker {
  final JumpPhase phase;
  final int startIndex;
  final int endIndex;
  final double startTime;
  final double endTime;
  
  const PhaseMarker({
    required this.phase,
    required this.startIndex,
    required this.endIndex,
    required this.startTime,
    required this.endTime,
  });
}