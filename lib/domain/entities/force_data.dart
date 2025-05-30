// lib/domain/entities/force_data.dart
import 'dart:math' as math;

/// VALD ForceDecks benzeri dual platform force data entity
/// Her sample için sol ve sağ platform verilerini içerir
class ForceData {
  /// Timestamp (milliseconds since epoch)
  final int timestamp;
  
  /// Sol platform Ground Reaction Force (N)
  final double leftGRF;
  
  /// Sağ platform Ground Reaction Force (N) 
  final double rightGRF;
  
  /// Toplam Ground Reaction Force (N)
  final double totalGRF;
  
  /// Sol platform Center of Pressure X koordinatı (cm)
  final double leftCoPX;
  
  /// Sol platform Center of Pressure Y koordinatı (cm)
  final double leftCoPY;
  
  /// Sağ platform Center of Pressure X koordinatı (cm)
  final double rightCoPX;
  
  /// Sağ platform Center of Pressure Y koordinatı (cm)
  final double rightCoPY;
  
  /// Asimetri indeksi (0.0-1.0, 0 = mükemmel simetri)
  final double asymmetryIndex;
  
  /// Load rate / Rate of Force Development (N/s)
  final double loadRate;
  
  /// Sol platform load cell değerleri (4 adet)
  final List<double> leftLoadCells;
  
  /// Sağ platform load cell değerleri (4 adet)
  final List<double> rightLoadCells;

  const ForceData({
    required this.timestamp,
    required this.leftGRF,
    required this.rightGRF,
    required this.totalGRF,
    required this.leftCoPX,
    required this.leftCoPY,
    required this.rightCoPX,
    required this.rightCoPY,
    required this.asymmetryIndex,
    required this.loadRate,
    this.leftLoadCells = const [0, 0, 0, 0],
    this.rightLoadCells = const [0, 0, 0, 0],
  });

  /// Factory constructor for creating from raw sensor data
  factory ForceData.fromSensorData({
    required int timestamp,
    required List<double> leftLoadCells,
    required List<double> rightLoadCells,
    double? previousTotalForce,
    int? timeDelta,
  }) {
    // Sol platform toplam kuvvet
    final leftGRF = leftLoadCells.fold(0.0, (sum, cell) => sum + cell);
    
    // Sağ platform toplam kuvvet
    final rightGRF = rightLoadCells.fold(0.0, (sum, cell) => sum + cell);
    
    // Toplam kuvvet
    final totalGRF = leftGRF + rightGRF;
    
    // Center of Pressure hesaplama (basitleştirilmiş)
    final leftCoPX = _calculateCoPX(leftLoadCells);
    final leftCoPY = _calculateCoPY(leftLoadCells);
    final rightCoPX = _calculateCoPX(rightLoadCells);
    final rightCoPY = _calculateCoPY(rightLoadCells);
    
    // Asimetri indeksi (VALD standartı)
    final asymmetryIndex = _calculateAsymmetryIndex(leftGRF, rightGRF);
    
    // Load rate hesaplama
    final loadRate = _calculateLoadRate(totalGRF, previousTotalForce, timeDelta);
    
    return ForceData(
      timestamp: timestamp,
      leftGRF: leftGRF,
      rightGRF: rightGRF,
      totalGRF: totalGRF,
      leftCoPX: leftCoPX,
      leftCoPY: leftCoPY,
      rightCoPX: rightCoPX,
      rightCoPY: rightCoPY,
      asymmetryIndex: asymmetryIndex,
      loadRate: loadRate,
      leftLoadCells: List.from(leftLoadCells),
      rightLoadCells: List.from(rightLoadCells),
    );
  }

  /// Mock data factory (development için)
  factory ForceData.mock({
    int? timestamp,
    double? baseForce,
    double? asymmetry,
  }) {
    final now = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    final base = baseForce ?? 800.0;
    final asym = asymmetry ?? 0.05;
    
    // Mock asimetri ile sol/sağ dağılım
    final leftGRF = base * (0.5 + asym);
    final rightGRF = base * (0.5 - asym);
    final totalGRF = leftGRF + rightGRF;
    
    // Mock CoP değerleri
    final leftCoPX = (math.Random().nextDouble() - 0.5) * 4; // ±2cm
    final leftCoPY = (math.Random().nextDouble() - 0.5) * 6; // ±3cm
    final rightCoPX = (math.Random().nextDouble() - 0.5) * 4;
    final rightCoPY = (math.Random().nextDouble() - 0.5) * 6;
    
    // Mock load cells (4 per platform)
    final leftLoadCells = List.generate(4, (i) => leftGRF / 4 + (math.Random().nextDouble() - 0.5) * 10);
    final rightLoadCells = List.generate(4, (i) => rightGRF / 4 + (math.Random().nextDouble() - 0.5) * 10);
    
    return ForceData(
      timestamp: now,
      leftGRF: leftGRF,
      rightGRF: rightGRF,
      totalGRF: totalGRF,
      leftCoPX: leftCoPX,
      leftCoPY: leftCoPY,
      rightCoPX: rightCoPX,
      rightCoPY: rightCoPY,
      asymmetryIndex: asym.abs(),
      loadRate: 0.0, // Mock için 0
      leftLoadCells: leftLoadCells,
      rightLoadCells: rightLoadCells,
    );
  }

  /// Zero calibration uygulanmış kopyasını döndür
  ForceData applyZeroCalibration({
    required double leftZeroOffset,
    required double rightZeroOffset,
  }) {
    return copyWith(
      leftGRF: math.max(0, leftGRF - leftZeroOffset),
      rightGRF: math.max(0, rightGRF - rightZeroOffset),
      totalGRF: math.max(0, totalGRF - leftZeroOffset - rightZeroOffset),
    );
  }

  /// Body weight normalize edilmiş değerleri döndür
  ForceData normalizeToBodyWeight(double bodyWeightN) {
    if (bodyWeightN <= 0) return this;
    
    return copyWith(
      leftGRF: leftGRF / bodyWeightN,
      rightGRF: rightGRF / bodyWeightN,
      totalGRF: totalGRF / bodyWeightN,
    );
  }

  /// Copy with method
  ForceData copyWith({
    int? timestamp,
    double? leftGRF,
    double? rightGRF,
    double? totalGRF,
    double? leftCoPX,
    double? leftCoPY,
    double? rightCoPX,
    double? rightCoPY,
    double? asymmetryIndex,
    double? loadRate,
    List<double>? leftLoadCells,
    List<double>? rightLoadCells,
  }) {
    return ForceData(
      timestamp: timestamp ?? this.timestamp,
      leftGRF: leftGRF ?? this.leftGRF,
      rightGRF: rightGRF ?? this.rightGRF,
      totalGRF: totalGRF ?? this.totalGRF,
      leftCoPX: leftCoPX ?? this.leftCoPX,
      leftCoPY: leftCoPY ?? this.leftCoPY,
      rightCoPX: rightCoPX ?? this.rightCoPX,
      rightCoPY: rightCoPY ?? this.rightCoPY,
      asymmetryIndex: asymmetryIndex ?? this.asymmetryIndex,
      loadRate: loadRate ?? this.loadRate,
      leftLoadCells: leftLoadCells ?? this.leftLoadCells,
      rightLoadCells: rightLoadCells ?? this.rightLoadCells,
    );
  }

  /// JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'leftGRF': leftGRF,
      'rightGRF': rightGRF,
      'totalGRF': totalGRF,
      'leftCoPX': leftCoPX,
      'leftCoPY': leftCoPY,
      'rightCoPX': rightCoPX,
      'rightCoPY': rightCoPY,
      'asymmetryIndex': asymmetryIndex,
      'loadRate': loadRate,
      'leftLoadCells': leftLoadCells,
      'rightLoadCells': rightLoadCells,
    };
  }

  /// JSON deserialization
  factory ForceData.fromJson(Map<String, dynamic> json) {
    return ForceData(
      timestamp: json['timestamp'] as int,
      leftGRF: (json['leftGRF'] as num).toDouble(),
      rightGRF: (json['rightGRF'] as num).toDouble(),
      totalGRF: (json['totalGRF'] as num).toDouble(),
      leftCoPX: (json['leftCoPX'] as num).toDouble(),
      leftCoPY: (json['leftCoPY'] as num).toDouble(),
      rightCoPX: (json['rightCoPX'] as num).toDouble(),
      rightCoPY: (json['rightCoPY'] as num).toDouble(),
      asymmetryIndex: (json['asymmetryIndex'] as num).toDouble(),
      loadRate: (json['loadRate'] as num).toDouble(),
      leftLoadCells: (json['leftLoadCells'] as List).cast<double>(),
      rightLoadCells: (json['rightLoadCells'] as List).cast<double>(),
    );
  }

  /// CSV export için string
  String toCsvRow() {
    return [
      timestamp,
      totalGRF.toStringAsFixed(2),
      leftGRF.toStringAsFixed(2),
      rightGRF.toStringAsFixed(2),
      leftCoPX.toStringAsFixed(3),
      leftCoPY.toStringAsFixed(3),
      rightCoPX.toStringAsFixed(3),
      rightCoPY.toStringAsFixed(3),
      asymmetryIndex.toStringAsFixed(4),
      loadRate.toStringAsFixed(1),
    ].join(',');
  }

  @override
  String toString() {
    return 'ForceData(timestamp: $timestamp, total: ${totalGRF.toStringAsFixed(1)}N, '
           'left: ${leftGRF.toStringAsFixed(1)}N, right: ${rightGRF.toStringAsFixed(1)}N, '
           'asymmetry: ${(asymmetryIndex * 100).toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForceData &&
           other.timestamp == timestamp &&
           other.leftGRF == leftGRF &&
           other.rightGRF == rightGRF &&
           other.totalGRF == totalGRF;
  }

  @override
  int get hashCode {
    return Object.hash(timestamp, leftGRF, rightGRF, totalGRF);
  }

  // Private helper methods
  static double _calculateCoPX(List<double> loadCells) {
    if (loadCells.length != 4) return 0.0;
    
    // Basitleştirilmiş CoP hesaplama
    // Gerçekte platform geometrisine göre hesaplanır
    final total = loadCells.fold(0.0, (sum, cell) => sum + cell);
    if (total <= 0) return 0.0;
    
    // Load cell pozisyonları: TL, TR, BL, BR
    final coPX = ((loadCells[1] + loadCells[3]) - (loadCells[0] + loadCells[2])) / total * 10; // cm
    return coPX.clamp(-20.0, 20.0); // Platform width sınırları
  }

  static double _calculateCoPY(List<double> loadCells) {
    if (loadCells.length != 4) return 0.0;
    
    final total = loadCells.fold(0.0, (sum, cell) => sum + cell);
    if (total <= 0) return 0.0;
    
    // Load cell pozisyonları: TL, TR, BL, BR
    final coPY = ((loadCells[0] + loadCells[1]) - (loadCells[2] + loadCells[3])) / total * 15; // cm
    return coPY.clamp(-30.0, 30.0); // Platform height sınırları
  }

  static double _calculateAsymmetryIndex(double leftGRF, double rightGRF) {
    final total = leftGRF + rightGRF;
    if (total <= 0) return 0.0;
    
    // VALD ForceDecks asimetri formülü
    final asymmetry = (leftGRF - rightGRF).abs() / total;
    return asymmetry.clamp(0.0, 1.0);
  }

  static double _calculateLoadRate(double currentForce, double? previousForce, int? timeDelta) {
    if (previousForce == null || timeDelta == null || timeDelta <= 0) {
      return 0.0;
    }
    
    final forceChange = currentForce - previousForce;
    final timeChangeSeconds = timeDelta / 1000.0; // ms to seconds
    
    return forceChange / timeChangeSeconds; // N/s
  }
}

/// Force data analysis helper methods
extension ForceDataAnalysis on ForceData {
  /// Bu sample'da kişi platform üzerinde mi?
  bool get isPersonOnPlatform => totalGRF > 100.0; // 100N threshold
  
  /// Bu sample'da kişi havada mı? (jump test için)
  bool get isInFlight => totalGRF < 50.0; // 50N threshold
  
  /// Asimetri VALD standardına göre normal mi?
  bool get isAsymmetryNormal => asymmetryIndex <= 0.15; // %15
  
  /// Asimetri seviyesi
  AsymmetryLevel get asymmetryLevel {
    if (asymmetryIndex <= 0.05) return AsymmetryLevel.excellent;
    if (asymmetryIndex <= 0.10) return AsymmetryLevel.good;
    if (asymmetryIndex <= 0.15) return AsymmetryLevel.acceptable;
    if (asymmetryIndex <= 0.25) return AsymmetryLevel.attention;
    return AsymmetryLevel.intervention;
  }
  
  /// Body weight olarak kg cinsinden değer
  double get bodyWeightKg => totalGRF / 9.81;
  
  /// Dominant side (sol mu sağ mı daha güçlü)
  PlatformSide get dominantSide {
    if (leftGRF > rightGRF) return PlatformSide.left;
    if (rightGRF > leftGRF) return PlatformSide.right;
    return PlatformSide.balanced;
  }
}

/// Asimetri seviyeleri (VALD standartları)
enum AsymmetryLevel {
  excellent,    // ≤ 5%
  good,         // 5-10%
  acceptable,   // 10-15%
  attention,    // 15-25%
  intervention, // > 25%
}

enum PlatformSide {
  left,
  right,
  balanced,
}

extension AsymmetryLevelExtension on AsymmetryLevel {
  String get displayName {
    switch (this) {
      case AsymmetryLevel.excellent:
        return 'Excellent';
      case AsymmetryLevel.good:
        return 'Good';
      case AsymmetryLevel.acceptable:
        return 'Acceptable';
      case AsymmetryLevel.attention:
        return 'Needs Attention';
      case AsymmetryLevel.intervention:
        return 'Requires Intervention';
    }
  }
  
  String get description {
    switch (this) {
      case AsymmetryLevel.excellent:
        return 'Outstanding bilateral balance';
      case AsymmetryLevel.good:
        return 'Good bilateral balance';
      case AsymmetryLevel.acceptable:
        return 'Within normal limits';
      case AsymmetryLevel.attention:
        return 'Monitor and consider training';
      case AsymmetryLevel.intervention:
        return 'Address significant imbalance';
    }
  }
}