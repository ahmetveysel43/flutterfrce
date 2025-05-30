// lib/presentation/widgets/vald_flow_widgets/zero_calibration_widget.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/vald_test_flow_controller.dart';
import '../../controllers/usb_controller.dart';

class ZeroCalibrationWidget extends StatefulWidget {
  const ZeroCalibrationWidget({super.key});

  @override
  State<ZeroCalibrationWidget> createState() => _ZeroCalibrationWidgetState();
}

class _ZeroCalibrationWidgetState extends State<ZeroCalibrationWidget>
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _platformAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _progressAnimationController;
  
  // Animations
  late Animation<double> _platformScale;
  late Animation<double> _pulseScale;
  late Animation<double> _progressAnimation;
  
  // Calibration state
  bool _isCalibrating = false;
  double _calibrationProgress = 0.0;
  List<double> _leftSamples = [];
  List<double> _rightSamples = [];
  Timer? _calibrationTimer;
  Timer? _dataTimer;
  
  // Platform stability indicators
  double _leftStability = 0.0;
  double _rightStability = 0.0;
  bool _isPlatformStable = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStabilityMonitoring();
  }

  void _initializeAnimations() {
    // Platform scale animation
    _platformAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _platformScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _platformAnimationController, curve: Curves.elasticOut),
    );
    
    // Pulse animation for active state
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseAnimationController, curve: Curves.easeInOut),
    );
    
    // Progress animation
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 3000), // 3 second calibration
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressAnimationController, curve: Curves.easeInOut),
    );

    // Start entrance animation
    _platformAnimationController.forward();
    
    // Start pulse animation loop
    _pulseAnimationController.repeat(reverse: true);
  }

  void _startStabilityMonitoring() {
    // Monitor platform stability before calibration
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final usbController = context.read<UsbController>();
      final latestData = usbController.latestForceData;
      
      if (latestData != null) {
        _updateStabilityIndicators(latestData.leftGRF, latestData.rightGRF);
      }
    });
  }

  void _updateStabilityIndicators(double leftForce, double rightForce) {
    setState(() {
      // Simple stability calculation - in real app would use running average
      _leftStability = (leftForce / 1000).clamp(0.0, 1.0);
      _rightStability = (rightForce / 1000).clamp(0.0, 1.0);
      
      // Platform is stable when both forces are low (< 50N)
      _isPlatformStable = leftForce < 50 && rightForce < 50;
    });
  }

  Future<void> _startZeroCalibration() async {
    if (_isCalibrating) return;
    
    setState(() {
      _isCalibrating = true;
      _calibrationProgress = 0.0;
      _leftSamples.clear();
      _rightSamples.clear();
    });

    // Start progress animation
    _progressAnimationController.forward();
    
    // Start calibration data collection
    final flowController = context.read<ValdTestFlowController>();
    
    _calibrationTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      _calibrationProgress += 0.01 / 3.0; // 3 seconds total
      
      // Collect mock calibration samples
      final usbController = context.read<UsbController>();
      final latestData = usbController.latestForceData;
      
      if (latestData != null) {
        _leftSamples.add(latestData.leftGRF);
        _rightSamples.add(latestData.rightGRF);
      } else {
        // Add noise for empty platform
        _leftSamples.add(2.0 + (math.Random().nextDouble() - 0.5) * 4);
        _rightSamples.add(2.0 + (math.Random().nextDouble() - 0.5) * 4);
      }
      
      if (mounted) {
        setState(() {});
      }
      
      // Complete calibration after 3 seconds
      if (_calibrationProgress >= 1.0) {
        timer.cancel();
        _completeCalibration(flowController);
      }
    });
  }

  void _completeCalibration(ValdTestFlowController flowController) async {
    // Calculate zero offsets
    final leftOffset = _leftSamples.isNotEmpty 
        ? _leftSamples.reduce((a, b) => a + b) / _leftSamples.length 
        : 0.0;
    final rightOffset = _rightSamples.isNotEmpty 
        ? _rightSamples.reduce((a, b) => a + b) / _rightSamples.length 
        : 0.0;
    
    // Simulate successful calibration
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _isCalibrating = false;
    });
    
    // Proceed to next step automatically
    await Future.delayed(const Duration(milliseconds: 1000));
    flowController.proceedToWeightMeasurement();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ValdTestFlowController, UsbController>(
      builder: (context, flowController, usbController, child) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Instructions Header
              _buildInstructionsHeader(),
              
              const SizedBox(height: 32),
              
              // Platform Visualization
              Expanded(
                child: _buildPlatformVisualization(),
              ),
              
              const SizedBox(height: 32),
              
              // Calibration Controls
              _buildCalibrationControls(flowController),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstructionsHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Warning Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.balance,
              color: Colors.orange,
              size: 32,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Title
          const Text(
            'Zero Calibration',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Instructions
          const Text(
            'Ensure both platforms are completely empty',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Requirements List
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                _buildRequirementItem(
                  Icons.clear,
                  'Remove all objects from platforms',
                  _isPlatformStable,
                ),
                const SizedBox(height: 8),
                _buildRequirementItem(
                  Icons.pets,
                  'Ensure no one is standing on platforms',
                  _isPlatformStable,
                ),
                const SizedBox(height: 8),
                _buildRequirementItem(
                  Icons.vibration,
                  'Minimize vibrations and movement',
                  _isPlatformStable,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(IconData icon, String text, bool isCompleted) {
    return Row(
      children: [
        Icon(
          icon,
          color: isCompleted ? Colors.green : Colors.orange,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isCompleted ? Colors.green : Colors.grey[700],
              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        if (isCompleted)
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 16,
          ),
      ],
    );
  }

  Widget _buildPlatformVisualization() {
    return AnimatedBuilder(
      animation: Listenable.merge([_platformScale, _pulseScale, _progressAnimation]),
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Platform Status
              Text(
                _isCalibrating ? 'Calibrating...' : (_isPlatformStable ? 'Platforms Ready' : 'Clear Platforms'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isCalibrating 
                      ? const Color(0xFF1565C0)
                      : _isPlatformStable 
                          ? Colors.green 
                          : Colors.orange,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Dual Platform Visual
              Row(
                children: [
                  // Left Platform
                  Expanded(
                    child: _buildPlatformVisual(
                      'Left Platform',
                      _leftStability,
                      _isCalibrating,
                      const Color(0xFF1565C0),
                    ),
                  ),
                  
                  const SizedBox(width: 32),
                  
                  // Right Platform  
                  Expanded(
                    child: _buildPlatformVisual(
                      'Right Platform',
                      _rightStability,
                      _isCalibrating,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Calibration Progress
              if (_isCalibrating) ...[
                Text(
                  'Collecting calibration data...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _progressAnimation.value,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_progressAnimation.value * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlatformVisual(String title, double stability, bool isCalibrating, Color color) {
    return Transform.scale(
      scale: _platformScale.value * (isCalibrating ? _pulseScale.value : 1.0),
      child: Column(
        children: [
          // Platform Title
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Platform Rectangle
          Container(
            width: 120,
            height: 180,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(isCalibrating ? 0.8 : 0.3),
                width: isCalibrating ? 3 : 2,
              ),
            ),
            child: Stack(
              children: [
                // Grid Pattern
                CustomPaint(
                  size: const Size(120, 180),
                  painter: PlatformGridPainter(color: color.withOpacity(0.2)),
                ),
                
                // Stability Indicator
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        stability < 0.1 ? Icons.check_circle : Icons.warning,
                        color: stability < 0.1 ? Colors.green : Colors.orange,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stability < 0.1 ? 'Empty' : 'Clear',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: stability < 0.1 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Calibration Animation Overlay
                if (isCalibrating)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Force Value Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${(stability * 100).toStringAsFixed(1)}N',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationControls(ValdTestFlowController flowController) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isPlatformStable 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isPlatformStable 
                    ? Colors.green.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isPlatformStable ? Icons.check_circle : Icons.warning,
                  color: _isPlatformStable ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isPlatformStable 
                        ? 'Platforms are ready for calibration'
                        : 'Please clear all objects from platforms',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isPlatformStable ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Calibration Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_isPlatformStable && !_isCalibrating) ? _startZeroCalibration : null,
              icon: _isCalibrating 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.balance),
              label: Text(_isCalibrating ? 'Calibrating...' : 'Start Zero Calibration'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _platformAnimationController.dispose();
    _pulseAnimationController.dispose();
    _progressAnimationController.dispose();
    _calibrationTimer?.cancel();
    _dataTimer?.cancel();
    super.dispose();
  }
}

// Custom painter for platform grid pattern
class PlatformGridPainter extends CustomPainter {
  final Color color;

  PlatformGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    // Draw grid lines
    for (int i = 1; i < 4; i++) {
      // Vertical lines
      canvas.drawLine(
        Offset(size.width * i / 4, 0),
        Offset(size.width * i / 4, size.height),
        paint,
      );
      
      // Horizontal lines
      canvas.drawLine(
        Offset(0, size.height * i / 4),
        Offset(size.width, size.height * i / 4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}