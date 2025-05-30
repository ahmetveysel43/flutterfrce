// lib/core/constants/test_constants.dart
import 'package:flutter/material.dart';

/// VALD ForceDecks test constants and standards
class TestConstants {
  
  // Test Types (VALD ForceDecks standard tests)
  static const Map<TestType, String> testNames = {
    TestType.counterMovementJump: 'Counter Movement Jump',
    TestType.squatJump: 'Squat Jump', 
    TestType.dropJump: 'Drop Jump',
    TestType.landing: 'Landing',
    TestType.balance: 'Balance',
    TestType.isometric: 'Isometric',
  };
  
  static const Map<TestType, String> testDescriptions = {
    TestType.counterMovementJump: 'Jump with counter movement for maximum height',
    TestType.squatJump: 'Jump from static squat position',
    TestType.dropJump: 'Drop from height and immediately jump',
    TestType.landing: 'Land and stabilize from drop',
    TestType.balance: 'Static balance assessment',
    TestType.isometric: 'Maximum voluntary contraction',
  };
  
  static const Map<TestType, Duration> testDurations = {
    TestType.counterMovementJump: Duration(seconds: 8),
    TestType.squatJump: Duration(seconds: 6),
    TestType.dropJump: Duration(seconds: 10),
    TestType.landing: Duration(seconds: 8),
    TestType.balance: Duration(seconds: 30),
    TestType.isometric: Duration(seconds: 5),
  };
  
  // VALD Standards for Calibration
  static const double zeroCalibrationDuration = 3.0; // seconds
  static const double zeroStabilityThreshold = 5.0; // Newtons
  static const int zeroSampleRate = 1000; // Hz
  
  // Weight Measurement Standards  
  static const double weightStabilityThreshold = 0.5; // kg
  static const int weightStableDuration = 3; // seconds
  static const double minimumBodyWeight = 30.0; // kg
  static const double maximumBodyWeight = 200.0; // kg
  
  // Force Platform Specifications (VALD ForceDecks)
  static const double platformWidth = 40.0; // cm
  static const double platformHeight = 60.0; // cm
  static const int loadCellsPerPlatform = 4;
  static const double maxForceCapacity = 10000.0; // Newtons
  static const int samplingRate = 1000; // Hz
  
  // Test Performance Thresholds
  static const double asymmetryThreshold = 15.0; // percent (VALD standard)
  static const double goodAsymmetryThreshold = 10.0; // percent
  static const double excellentAsymmetryThreshold = 5.0; // percent
  
  // Jump Test Norms (example values - should be sport/age specific)
  static const Map<String, JumpNorms> jumpNorms = {
    'male_adult': JumpNorms(
      poor: 25.0,
      belowAverage: 30.0, 
      average: 35.0,
      aboveAverage: 40.0,
      excellent: 45.0,
    ),
    'female_adult': JumpNorms(
      poor: 20.0,
      belowAverage: 25.0,
      average: 30.0, 
      aboveAverage: 35.0,
      excellent: 40.0,
    ),
  };
  
  // Force Test Norms (Newtons)
  static const Map<String, ForceNorms> forceNorms = {
    'male_adult': ForceNorms(
      poor: 1500.0,
      belowAverage: 2000.0,
      average: 2500.0,
      aboveAverage: 3000.0, 
      excellent: 3500.0,
    ),
    'female_adult': ForceNorms(
      poor: 1200.0,
      belowAverage: 1600.0,
      average: 2000.0,
      aboveAverage: 2400.0,
      excellent: 2800.0,
    ),
  };
  
  // RFD Norms (N/s)
  static const Map<String, RFDNorms> rfdNorms = {
    'male_adult': RFDNorms(
      poor: 2000.0,
      belowAverage: 3000.0,
      average: 4000.0,
      aboveAverage: 5000.0,
      excellent: 6000.0,
    ),
    'female_adult': RFDNorms(
      poor: 1500.0,
      belowAverage: 2500.0,
      average: 3500.0,
      aboveAverage: 4500.0,
      excellent: 5500.0,
    ),
  };
  
  // UI Colors (VALD-inspired)
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color secondaryBlue = Color(0xFF42A5F5);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFE53935);
  static const Color neutralGrey = Color(0xFF757575);
  
  // Test Status Colors
  static const Map<TestStatus, Color> statusColors = {
    TestStatus.notStarted: neutralGrey,
    TestStatus.inProgress: primaryBlue,
    TestStatus.completed: successGreen,
    TestStatus.failed: errorRed,
    TestStatus.cancelled: warningOrange,
  };
  
  // Connection Settings
  static const int usbConnectionTimeout = 10; // seconds
  static const int usbReconnectAttempts = 3;
  static const Duration usbHeartbeatInterval = Duration(seconds: 5);
  
  // Data Processing
  static const int maxDataPoints = 10000; // Limit for performance
  static const double gravityConstant = 9.81; // m/s²
  static const double forceToWeightRatio = 9.81; // N to kg conversion
  
  // File Export Settings
  static const String exportDateFormat = 'yyyy-MM-dd_HH-mm-ss';
  static const String csvSeparator = ',';
  static const List<String> exportHeaders = [
    'Time', 'TotalForce', 'LeftForce', 'RightForce', 
    'LeftCoPX', 'LeftCoPY', 'RightCoPX', 'RightCoPY',
    'AsymmetryIndex', 'LoadRate'
  ];
}

// Enums
enum TestType {
  counterMovementJump,
  squatJump,
  dropJump,
  landing,
  balance,
  isometric,
}

enum TestStatus {
  notStarted,
  inProgress, 
  completed,
  failed,
  cancelled,
}

// Normative Data Classes
class JumpNorms {
  final double poor;
  final double belowAverage;
  final double average;
  final double aboveAverage;
  final double excellent;
  
  const JumpNorms({
    required this.poor,
    required this.belowAverage,
    required this.average,
    required this.aboveAverage,
    required this.excellent,
  });
  
  PerformanceLevel getLevel(double value) {
    if (value >= excellent) return PerformanceLevel.excellent;
    if (value >= aboveAverage) return PerformanceLevel.aboveAverage;
    if (value >= average) return PerformanceLevel.average;
    if (value >= belowAverage) return PerformanceLevel.belowAverage;
    return PerformanceLevel.poor;
  }
}

class ForceNorms {
  final double poor;
  final double belowAverage;
  final double average;
  final double aboveAverage;
  final double excellent;
  
  const ForceNorms({
    required this.poor,
    required this.belowAverage,
    required this.average,
    required this.aboveAverage,
    required this.excellent,
  });
  
  PerformanceLevel getLevel(double value) {
    if (value >= excellent) return PerformanceLevel.excellent;
    if (value >= aboveAverage) return PerformanceLevel.aboveAverage;
    if (value >= average) return PerformanceLevel.average;
    if (value >= belowAverage) return PerformanceLevel.belowAverage;
    return PerformanceLevel.poor;
  }
}

class RFDNorms {
  final double poor;
  final double belowAverage;
  final double average;
  final double aboveAverage;
  final double excellent;
  
  const RFDNorms({
    required this.poor,
    required this.belowAverage,
    required this.average,
    required this.aboveAverage,
    required this.excellent,
  });
  
  PerformanceLevel getLevel(double value) {
    if (value >= excellent) return PerformanceLevel.excellent;
    if (value >= aboveAverage) return PerformanceLevel.aboveAverage;
    if (value >= average) return PerformanceLevel.average;
    if (value >= belowAverage) return PerformanceLevel.belowAverage;
    return PerformanceLevel.poor;
  }

  
}

enum PerformanceLevel {
  poor,
  belowAverage,
  average,
  aboveAverage,
  excellent,
}

// Extensions for better UX
extension PerformanceLevelExtension on PerformanceLevel {
  String get displayName {
    switch (this) {
      case PerformanceLevel.poor:
        return 'Poor';
      case PerformanceLevel.belowAverage:
        return 'Below Average';
      case PerformanceLevel.average:
        return 'Average';
      case PerformanceLevel.aboveAverage:
        return 'Above Average';
      case PerformanceLevel.excellent:
        return 'Excellent';
    }
  }
  
  Color get color {
    switch (this) {
      case PerformanceLevel.poor:
        return TestConstants.errorRed;
      case PerformanceLevel.belowAverage:
        return TestConstants.warningOrange;
      case PerformanceLevel.average:
        return TestConstants.neutralGrey;
      case PerformanceLevel.aboveAverage:
        return TestConstants.successGreen;
      case PerformanceLevel.excellent:
        return const Color(0xFF2E7D32); // Dark green
    }
  }
  
  IconData get icon {
    switch (this) {
      case PerformanceLevel.poor:
        return Icons.trending_down;
      case PerformanceLevel.belowAverage:
        return Icons.remove;
      case PerformanceLevel.average:
        return Icons.trending_flat;
      case PerformanceLevel.aboveAverage:
        return Icons.trending_up;
      case PerformanceLevel.excellent:
        return Icons.star;
    }
  }

  
}