// lib/core/extensions/list_extensions.dart
import 'dart:math' as math;

/// List extensions for data processing and analysis
extension ListExtensions<T> on List<T> {
  /// Take last N elements from list
  /// Mevcut kodlarınızda kullanılan takeLast() metodu
  List<T> takeLast(int count) {
    if (count <= 0) return [];
    if (count >= length) return List.from(this);
    return sublist(length - count);
  }

  /// Take first N elements from list
  List<T> takeFirst(int count) {
    if (count <= 0) return [];
    if (count >= length) return List.from(this);
    return sublist(0, count);
  }

  /// Skip last N elements
  List<T> skipLast(int count) {
    if (count <= 0) return List.from(this);
    if (count >= length) return [];
    return sublist(0, length - count);
  }

  /// Chunk list into smaller lists of specified size
  List<List<T>> chunk(int size) {
    if (size <= 0) throw ArgumentError('Chunk size must be positive');
    
    final chunks = <List<T>>[];
    for (int i = 0; i < length; i += size) {
      final end = math.min(i + size, length);
      chunks.add(sublist(i, end));
    }
    return chunks;
  }

  /// Get element at index or return null if out of bounds
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Get first element or null if empty
  T? get firstOrNull => isEmpty ? null : first;

  /// Get last element or null if empty
  T? get lastOrNull => isEmpty ? null : last;

  /// Remove duplicates while preserving order
  List<T> distinct() {
    final seen = <T>{};
    return where((element) => seen.add(element)).toList();
  }

  /// Group elements by a key function
  Map<K, List<T>> groupBy<K>(K Function(T) keyFunction) {
    final groups = <K, List<T>>{};
    for (final element in this) {
      final key = keyFunction(element);
      groups.putIfAbsent(key, () => []).add(element);
    }
    return groups;
  }
}

/// Numeric list extensions for force data analysis
extension NumericListExtensions on List<num> {
  /// Calculate mean/average
  double get mean {
    if (isEmpty) return 0.0;
    return sum / length;
  }

  /// Calculate sum
  double get sum => fold(0.0, (prev, element) => prev + element.toDouble());

  /// Calculate standard deviation
  double get standardDeviation {
    if (isEmpty) return 0.0;
    if (length == 1) return 0.0;
    
    final meanValue = mean;
    final variance = map((x) => math.pow(x - meanValue, 2))
        .reduce((a, b) => a + b) / (length - 1);
    return math.sqrt(variance);
  }

  /// Calculate variance
  double get variance {
    if (isEmpty) return 0.0;
    if (length == 1) return 0.0;
    
    final meanValue = mean;
    return map((x) => math.pow(x - meanValue, 2))
        .reduce((a, b) => a + b) / (length - 1);
  }

  /// Get minimum value
  double get min => isEmpty ? 0.0 : reduce(math.min).toDouble();

  /// Get maximum value  
  double get max => isEmpty ? 0.0 : reduce(math.max).toDouble();

  /// Get range (max - min)
  double get range => max - min;

  /// Calculate median
  double get median {
    if (isEmpty) return 0.0;
    
    final sorted = map((x) => x.toDouble()).toList()..sort();
    final mid = sorted.length ~/ 2;
    
    if (sorted.length.isOdd) {
      return sorted[mid];
    } else {
      return (sorted[mid - 1] + sorted[mid]) / 2;
    }
  }

  /// Calculate percentile (0.0 to 1.0)
  double percentile(double p) {
    if (isEmpty) return 0.0;
    if (p < 0.0 || p > 1.0) throw ArgumentError('Percentile must be between 0.0 and 1.0');
    
    final sorted = map((x) => x.toDouble()).toList()..sort();
    if (p == 0.0) return sorted.first;
    if (p == 1.0) return sorted.last;
    
    final index = p * (sorted.length - 1);
    final lower = index.floor();
    final upper = index.ceil();
    
    if (lower == upper) {
      return sorted[lower];
    } else {
      final weight = index - lower;
      return sorted[lower] * (1 - weight) + sorted[upper] * weight;
    }
  }

  /// Calculate quartiles (Q1, Q2/Median, Q3)
  List<double> get quartiles => [percentile(0.25), median, percentile(0.75)];

  /// Calculate IQR (Interquartile Range)
  double get iqr {
    final q = quartiles;
    return q[2] - q[0]; // Q3 - Q1
  }

  /// Detect outliers using IQR method
  List<int> get outlierIndices {
    if (length < 4) return []; // Need at least 4 points for quartiles
    
    final q = quartiles;
    final q1 = q[0];
    final q3 = q[2];
    final iqrValue = q3 - q1;
    final lowerBound = q1 - 1.5 * iqrValue;
    final upperBound = q3 + 1.5 * iqrValue;
    
    final outliers = <int>[];
    for (int i = 0; i < length; i++) {
      final value = this[i].toDouble();
      if (value < lowerBound || value > upperBound) {
        outliers.add(i);
      }
    }
    return outliers;
  }

  /// Remove outliers using IQR method
  List<num> removeOutliers() {
    final outliers = outlierIndices.toSet();
    final cleaned = <num>[];
    for (int i = 0; i < length; i++) {
      if (!outliers.contains(i)) {
        cleaned.add(this[i]);
      }
    }
    return cleaned;
  }

  /// Calculate coefficient of variation (CV) as percentage
  double get coefficientOfVariation {
    final meanValue = mean;
    if (meanValue == 0.0) return 0.0;
    return (standardDeviation / meanValue) * 100;
  }

  /// Calculate RMS (Root Mean Square)
  double get rms {
    if (isEmpty) return 0.0;
    final sumOfSquares = fold(0.0, (prev, element) => prev + (element.toDouble() * element.toDouble()));
    return math.sqrt(sumOfSquares / length);
  }

  /// Calculate moving average with specified window size
  List<double> movingAverage(int windowSize) {
    if (windowSize <= 0) throw ArgumentError('Window size must be positive');
    if (windowSize > length) return [mean];
    
    final result = <double>[];
    for (int i = windowSize - 1; i < length; i++) {
      final window = sublist(i - windowSize + 1, i + 1);
      result.add(window.map((x) => x.toDouble()).reduce((a, b) => a + b) / windowSize);
    }
    return result;
  }

  /// Find peaks in data (local maxima)
  List<int> findPeaks({double minHeight = double.negativeInfinity, int minDistance = 1}) {
    if (length < 3) return [];
    
    final peaks = <int>[];
    for (int i = 1; i < length - 1; i++) {
      final current = this[i].toDouble();
      final prev = this[i - 1].toDouble();
      final next = this[i + 1].toDouble();
      
      if (current > prev && current > next && current >= minHeight) {
        // Check minimum distance from previous peak
        if (peaks.isEmpty || i - peaks.last >= minDistance) {
          peaks.add(i);
        }
      }
    }
    return peaks;
  }

  /// Calculate rate of change between consecutive points
  List<double> rateOfChange() {
    if (length < 2) return [];
    
    final rates = <double>[];
    for (int i = 1; i < length; i++) {
      rates.add(this[i].toDouble() - this[i - 1].toDouble());
    }
    return rates;
  }

  /// Smooth data using simple moving average
  List<double> smooth(int windowSize) {
    return movingAverage(windowSize);
  }

  /// Normalize data to 0-1 range
  List<double> normalize() {
    if (isEmpty) return [];
    
    final minVal = min;
    final maxVal = max;
    final range = maxVal - minVal;
    
    if (range == 0.0) return map((x) => 0.5).toList(); // All values same
    
    return map((x) => (x.toDouble() - minVal) / range).toList();
  }

  /// Calculate z-scores (standardize)
  List<double> zScores() {
    if (isEmpty) return [];
    
    final meanValue = mean;
    final stdDev = standardDeviation;
    
    if (stdDev == 0.0) return map((x) => 0.0).toList(); // No variation
    
    return map((x) => (x.toDouble() - meanValue) / stdDev).toList();
  }
}

/// Double list specific extensions for force analysis
extension DoubleListExtensions on List<double> {
  /// Calculate sum for double lists
  double get sum => fold(0.0, (prev, element) => prev + element);

  /// Calculate area under curve using trapezoidal rule
  double areaUnderCurve({List<double>? xValues}) {
    if (length < 2) return 0.0;
    
    xValues ??= List.generate(length, (i) => i.toDouble());
    if (xValues.length != length) throw ArgumentError('X and Y lists must have same length');
    
    double area = 0.0;
    for (int i = 1; i < length; i++) {
      final dx = xValues[i] - xValues[i - 1];
      final avgY = (this[i] + this[i - 1]) / 2;
      area += dx * avgY;
    }
    return area;
  }

  /// Calculate impulse (area above baseline)
  double impulse({double baseline = 0.0, List<double>? timeValues}) {
    final adjustedValues = map((y) => math.max(0.0, y - baseline)).toList();
    return adjustedValues.areaUnderCurve(xValues: timeValues);
  }

  /// Find zero crossings
  List<int> findZeroCrossings() {
    final crossings = <int>[];
    for (int i = 1; i < length; i++) {
      if ((this[i - 1] >= 0 && this[i] < 0) || (this[i - 1] < 0 && this[i] >= 0)) {
        crossings.add(i);
      }
    }
    return crossings;
  }

 /// Calculate linear trend (slope)
double linearTrendSlope() {
  if (length < 2) return 0.0;
  
  final n = length.toDouble();
  final xValues = List.generate(length, (i) => i.toDouble());
  
  final sumX = xValues.fold(0.0, (a, b) => a + b);
  final sumY = fold(0.0, (a, b) => a + b);
  final sumXY = () {
    double sum = 0.0;
    for (int i = 0; i < length; i++) {
      sum += xValues[i] * this[i];
    }
    return sum;
  }();
  final sumX2 = xValues.fold(0.0, (a, b) => a + (b * b));
  
  final denominator = n * sumX2 - sumX * sumX;
  if (denominator == 0.0) return 0.0;
  
  return (n * sumXY - sumX * sumY) / denominator;
}

  /// Calculate R-squared for linear trend
  double linearTrendRSquared() {
    if (length < 2) return 0.0;
    
    final meanY = fold(0.0, (a, b) => a + b) / length; // Use fold instead of mean
    final slope = linearTrendSlope();
    final intercept = meanY - slope * (length - 1) / 2;
    
    double ssRes = 0.0; // Sum of squares of residuals
    double ssTot = 0.0; // Total sum of squares
    
    for (int i = 0; i < length; i++) {
      final predicted = slope * i + intercept;
      ssRes += math.pow(this[i] - predicted, 2);
      ssTot += math.pow(this[i] - meanY, 2);
    }
    
    if (ssTot == 0.0) return 1.0; // Perfect fit
    return 1.0 - (ssRes / ssTot);
  }
}

/// Extensions for Force Data specific analysis
extension ForceDataListExtensions on List<double> {
  /// Calculate Rate of Force Development (RFD) over time window
  double rfdOverWindow(List<double> timeValues, double windowStart, double windowEnd) {
    if (length != timeValues.length) throw ArgumentError('Force and time lists must have same length');
    
    final startIndex = timeValues.indexWhere((t) => t >= windowStart);
    final endIndex = timeValues.lastIndexWhere((t) => t <= windowEnd);
    
    if (startIndex == -1 || endIndex == -1 || startIndex >= endIndex) return 0.0;
    
    final forceChange = this[endIndex] - this[startIndex];
    final timeChange = timeValues[endIndex] - timeValues[startIndex];
    
    return timeChange > 0 ? forceChange / timeChange : 0.0;
  }

  /// Detect jump phases from force data
  JumpPhases detectJumpPhases(double bodyWeight, {double threshold = 0.1}) {
    final bodyWeightThreshold = bodyWeight * threshold;
    
    // Find takeoff (force drops below threshold)
    int? takeoffIndex;
    for (int i = 0; i < length; i++) {
      if (this[i] < bodyWeightThreshold) {
        takeoffIndex = i;
        break;
      }
    }
    
    // Find landing (force rises above threshold after takeoff)
    int? landingIndex;
    if (takeoffIndex != null) {
      for (int i = takeoffIndex + 1; i < length; i++) {
        if (this[i] > bodyWeightThreshold) {
          landingIndex = i;
          break;
        }
      }
    }
    
    return JumpPhases(
      takeoffIndex: takeoffIndex,
      landingIndex: landingIndex,
      flightTime: (takeoffIndex != null && landingIndex != null) 
          ? landingIndex - takeoffIndex 
          : null,
    );
  }

  /// Calculate stability index (coefficient of variation)
  double stabilityIndex() {
    final meanValue = fold(0.0, (a, b) => a + b) / length;
    if (meanValue == 0.0) return 0.0;
    
    final variance = map((x) => math.pow(x - meanValue, 2))
        .fold(0.0, (a, b) => a + b) / (length - 1);
    final standardDeviation = math.sqrt(variance);
    
    return (standardDeviation / meanValue) * 100;
  }
}

/// Jump phase detection result
class JumpPhases {
  final int? takeoffIndex;
  final int? landingIndex;
  final int? flightTime; // in samples

  const JumpPhases({
    this.takeoffIndex,
    this.landingIndex,
    this.flightTime,
  });

  bool get hasValidJump => takeoffIndex != null && landingIndex != null;
  
  double flightTimeSeconds(double sampleRate) {
    return flightTime != null ? flightTime! / sampleRate : 0.0;
  }
}