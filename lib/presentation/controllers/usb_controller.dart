// lib/presentation/controllers/usb_controller.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../domain/entities/force_data.dart';
import '../../core/constants/test_constants.dart';

/// VALD ForceDecks benzeri USB dongle bağlantısını simulate eden controller
class UsbController extends ChangeNotifier {
  // Connection state
  bool _isConnected = false;
  String? _connectedDeviceId;
  List<String> _availableDevices = [];
  String? _errorMessage;
  bool _isScanning = false;
  
  // Data streaming
  StreamController<ForceData>? _forceDataController;
  Timer? _dataStreamTimer;
  ForceData? _latestForceData;
  
  // Mock data generation
  final math.Random _random = math.Random();
  double _mockBodyWeight = 700.0; // N (≈70kg)
  double _mockAsymmetry = 0.05; // 5% asymmetry
  bool _mockPersonOnPlatform = false;
  DateTime? _mockJumpStartTime;
  
  // Connection parameters
  static const Duration _scanTimeout = Duration(seconds: 5);
  static const Duration _connectionTimeout = Duration(seconds: 10);
  static const Duration _heartbeatInterval = Duration(seconds: 5);
  static const int _dataStreamRate = 100; // Hz (10ms intervals)

  // Getters
  bool get isConnected => _isConnected;
  String? get connectedDeviceId => _connectedDeviceId;
  List<String> get availableDevices => List.unmodifiable(_availableDevices);
  String? get errorMessage => _errorMessage;
  bool get isScanning => _isScanning;
  ForceData? get latestForceData => _latestForceData;
  
  /// Force data stream - VALD ForceDecks benzeri 1000Hz data stream
  Stream<ForceData>? get forceDataStream => _forceDataController?.stream;

  /// Cihaz tarama - Mock USB dongle'ları bul
  Future<void> refreshDevices() async {
    _setScanning(true);
    _clearError();
    
    try {
      debugPrint('🔍 USB cihazları taranıyor...');
      
      // Mock scanning delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock available devices
      _availableDevices = [
        'IzForce Platform #001',
        'IzForce Platform #002', 
        'VALD ForceDecks Compatible #003',
      ];
      
      debugPrint('✅ ${_availableDevices.length} cihaz bulundu');
      
    } catch (e) {
      _setError('Cihaz tarama hatası: $e');
      debugPrint('❌ Cihaz tarama hatası: $e');
    } finally {
      _setScanning(false);
    }
  }

  /// Cihaza bağlan
  Future<bool> connectToDevice(String deviceId) async {
    if (_isConnected) {
      await disconnect();
    }
    
    _clearError();
    debugPrint('🔌 Cihaza bağlanılıyor: $deviceId');
    
    try {
      // Mock connection delay
      await Future.delayed(const Duration(seconds: 3));
      
      // Simulate connection success/failure
      if (_random.nextDouble() > 0.1) { // 90% success rate
        _isConnected = true;
        _connectedDeviceId = deviceId;
        
        // Start data streaming
        _startDataStream();
        
        // Start heartbeat monitoring
        _startHeartbeatMonitoring();
        
        debugPrint('✅ Cihaza başarıyla bağlandı: $deviceId');
        notifyListeners();
        return true;
      } else {
        throw Exception('Cihaz yanıt vermiyor');
      }
      
    } catch (e) {
      _setError('Bağlantı hatası: $e');
      debugPrint('❌ Bağlantı hatası: $e');
      return false;
    }
  }

  /// Bağlantıyı kes
  Future<void> disconnect() async {
    if (!_isConnected) return;
    
    debugPrint('🔌 Bağlantı kesiliyor...');
    
    _stopDataStream();
    _isConnected = false;
    _connectedDeviceId = null;
    _latestForceData = null;
    
    debugPrint('✅ Bağlantı kesildi');
    notifyListeners();
  }

  /// Force data stream'ini başlat (VALD ForceDecks benzeri)
  void _startDataStream() {
    _forceDataController = StreamController<ForceData>.broadcast();
    
    // 100Hz data stream (10ms intervals) - gerçekte 1000Hz olur
    _dataStreamTimer = Timer.periodic(
      Duration(milliseconds: 1000 ~/ _dataStreamRate),
      (timer) => _generateAndEmitForceData(),
    );
    
    debugPrint('📊 Force data stream başlatıldı (${_dataStreamRate}Hz)');
  }

  /// Force data stream'ini durdur
  void _stopDataStream() {
    _dataStreamTimer?.cancel();
    _dataStreamTimer = null;
    
    _forceDataController?.close();
    _forceDataController = null;
    
    debugPrint('📊 Force data stream durduruldu');
  }

  /// Mock force data üret ve yayınla
  void _generateAndEmitForceData() {
    if (!_isConnected || _forceDataController == null) return;
    
    try {
      final forceData = _generateMockForceData();
      _latestForceData = forceData;
      
      _forceDataController!.add(forceData);
      
    } catch (e) {
      debugPrint('❌ Force data üretim hatası: $e');
    }
  }

  /// Gerçekçi mock force data üret
  ForceData _generateMockForceData() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Mock scenarios - platform üzerinde kimse yok, normal duruş, sıçrama
    double leftForce = 0;
    double rightForce = 0;
    
    if (_mockPersonOnPlatform) {
      // Person on platform - simulate body weight with small variations
      final baseWeight = _mockBodyWeight / 2; // Split between platforms
      final variation = 10.0; // ±10N variation
      
      leftForce = baseWeight * (1 + _mockAsymmetry) + 
                  ((_random.nextDouble() - 0.5) * variation);
      rightForce = baseWeight * (1 - _mockAsymmetry) + 
                   ((_random.nextDouble() - 0.5) * variation);
      
      // Simulate jump if jump started
      if (_mockJumpStartTime != null) {
        final jumpElapsed = DateTime.now().difference(_mockJumpStartTime!).inMilliseconds;
        leftForce = _simulateJumpForce(leftForce, jumpElapsed);
        rightForce = _simulateJumpForce(rightForce, jumpElapsed);
      }
      
    } else {
      // Empty platform - only sensor noise
      leftForce = (_random.nextDouble() - 0.5) * 10; // ±5N noise
      rightForce = (_random.nextDouble() - 0.5) * 10;
    }
    
    // Ensure non-negative forces
    leftForce = math.max(0, leftForce);
    rightForce = math.max(0, rightForce);
    
    // Generate mock load cell values
    final leftLoadCells = _generateLoadCellValues(leftForce);
    final rightLoadCells = _generateLoadCellValues(rightForce);
    
    return ForceData.fromSensorData(
      timestamp: timestamp,
      leftLoadCells: leftLoadCells,
      rightLoadCells: rightLoadCells,
      previousTotalForce: _latestForceData?.totalGRF,
      timeDelta: 10, // 10ms intervals
    );
  }

  /// Sıçrama force profilini simulate et
  double _simulateJumpForce(double baseForce, int jumpElapsedMs) {
    final jumpPhase = jumpElapsedMs / 1000.0; // seconds
    
    if (jumpPhase < 0.2) {
      // Countermovement phase (0-200ms): Force decreases
      final factor = 1.0 - (jumpPhase / 0.2) * 0.3; // 30% decrease
      return baseForce * factor;
    } else if (jumpPhase < 0.8) {
      // Propulsion phase (200-800ms): Force increases dramatically
      final propulsionPhase = (jumpPhase - 0.2) / 0.6;
      final forceFactor = 1.0 + propulsionPhase * 2.5; // Up to 2.5x body weight
      return baseForce * forceFactor;
    } else if (jumpPhase < 1.0) {
      // Takeoff phase (800-1000ms): Force decreases to zero
      final takeoffPhase = (jumpPhase - 0.8) / 0.2;
      final forceFactor = 1.0 - takeoffPhase;
      return baseForce * forceFactor;
    } else if (jumpPhase < 1.5) {
      // Flight phase (1000-1500ms): Zero force
      return 0.0;
    } else if (jumpPhase < 2.0) {
      // Landing phase (1500-2000ms): Force increases rapidly
      final landingPhase = (jumpPhase - 1.5) / 0.5;
      final forceFactor = landingPhase * 1.5; // Up to 1.5x body weight
      return baseForce * forceFactor;
    } else {
      // Stabilization phase (2000ms+): Return to body weight
      _mockJumpStartTime = null; // End jump simulation
      return baseForce;
    }
  }

  /// Load cell değerlerini generate et
  List<double> _generateLoadCellValues(double totalForce) {
    // 4 load cell per platform - distribute force with some variation
    final baseForce = totalForce / 4;
    return List.generate(4, (i) {
      final variation = (_random.nextDouble() - 0.5) * 0.2; // ±10% variation
      return math.max(0, baseForce * (1 + variation));
    });
  }

  /// Heartbeat monitoring başlat
  void _startHeartbeatMonitoring() {
    Timer.periodic(_heartbeatInterval, (timer) {
      if (!_isConnected) {
        timer.cancel();
        return;
      }
      
      // Simulate occasional connection drops
      if (_random.nextDouble() < 0.01) { // 1% chance per heartbeat
        debugPrint('💔 Heartbeat kaybedildi - bağlantı koptu');
        _handleConnectionLoss();
        timer.cancel();
      }
    });
  }

  /// Bağlantı kaybını handle et
  void _handleConnectionLoss() {
    _isConnected = false;
    _connectedDeviceId = null;
    _stopDataStream();
    _setError('Cihaz bağlantısı koptu');
    notifyListeners();
  }

  // Mock control methods (test UI için)
  
  /// Mock person on platform
  void setMockPersonOnPlatform(bool onPlatform) {
    _mockPersonOnPlatform = onPlatform;
    if (!onPlatform) {
      _mockJumpStartTime = null;
    }
    debugPrint('👤 Mock person on platform: $onPlatform');
  }

  /// Mock body weight ayarla
  void setMockBodyWeight(double weightKg) {
    _mockBodyWeight = weightKg * 9.81; // Convert to Newtons
    debugPrint('⚖️ Mock body weight: ${weightKg}kg');
  }

  /// Mock asymmetry ayarla
  void setMockAsymmetry(double asymmetryPercent) {
    _mockAsymmetry = asymmetryPercent / 100.0;
    debugPrint('⚖️ Mock asymmetry: ${asymmetryPercent}%');
  }

  /// Mock jump simülasyonu başlat
  void triggerMockJump() {
    if (_mockPersonOnPlatform) {
      _mockJumpStartTime = DateTime.now();
      debugPrint('🦘 Mock jump başlatıldı');
    }
  }

  /// Zero calibration için static noise data
  void setZeroCalibrationMode(bool enabled) {
    if (enabled) {
      _mockPersonOnPlatform = false;
      _mockJumpStartTime = null;
      debugPrint('⚖️ Zero calibration mode aktif');
    }
  }

  // Helper methods
  void _setScanning(bool scanning) {
    _isScanning = scanning;
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
    _dataStreamTimer?.cancel();
    _forceDataController?.close();
    super.dispose();
  }
}

/// USB Connection status
enum UsbConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

/// USB Device info
class UsbDevice {
  final String id;
  final String name;
  final String manufacturer;
  final String serialNumber;
  final bool isCompatible;

  const UsbDevice({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.serialNumber,
    this.isCompatible = true,
  });

  @override
  String toString() => '$name ($id)';
}

/// USB Controller extensions
extension UsbControllerExtensions on UsbController {
  /// Get connection status
  UsbConnectionStatus get connectionStatus {
    if (errorMessage != null) return UsbConnectionStatus.error;
    if (isScanning) return UsbConnectionStatus.scanning;
    if (isConnected) return UsbConnectionStatus.connected;
    return UsbConnectionStatus.disconnected;
  }

  /// Get connection status text
  String get connectionStatusText {
    switch (connectionStatus) {
      case UsbConnectionStatus.disconnected:
        return 'Bağlantı yok';
      case UsbConnectionStatus.scanning:
        return 'Cihazlar taranıyor...';
      case UsbConnectionStatus.connecting:
        return 'Bağlanıyor...';
      case UsbConnectionStatus.connected:
        return 'Bağlı: ${connectedDeviceId ?? 'Bilinmeyen'}';
      case UsbConnectionStatus.error:
        return 'Hata: ${errorMessage ?? 'Bilinmeyen hata'}';
    }
  }

  /// Get signal strength (mock)
  int get signalStrength {
    if (!isConnected) return 0;
    // Mock signal strength based on latest data
    return latestForceData != null ? 4 : 2; // 0-4 bars
  }

  /// Get data rate (samples per second)
  double get dataRate => isConnected ? UsbController._dataStreamRate.toDouble() : 0.0;
}