// lib/presentation/widgets/vald_flow_widgets/testing_widget.dart - COMPLETELY FIXED
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/vald_test_flow_controller.dart';
import '../../controllers/usb_controller.dart';
import '../../../domain/entities/force_data.dart';
import '../../../core/constants/test_constants.dart';
import '../../../core/algorithms/phase_detector.dart';

class TestingWidget extends StatefulWidget {
  const TestingWidget({super.key});

  @override
  State<TestingWidget> createState() => _TestingWidgetState();
}

class _TestingWidgetState extends State<TestingWidget>
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _countdownController;
  late AnimationController _testingController;
  late AnimationController _metricsController;
  
  // Animations
  late Animation<double> _countdownScale;
  late Animation<double> _testingPulse;
  late Animation<double> _metricsOpacity;
  
  // Test state
  bool _isCountingDown = false;
  bool _isTestActive = false;
  int _countdownValue = 3;
  Timer? _countdownTimer;
  
  // Real-time data for charts
  final List<FlSpot> _totalForceData = [];
  final List<FlSpot> _leftForceData = [];
  final List<FlSpot> _rightForceData = [];
  double _chartTimeWindow = 10.0; // seconds
  DateTime? _testStartTime;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeTestParameters();
  }

  void _initializeAnimations() {
    // Countdown animation
    _countdownController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _countdownScale = Tween<double>(begin: 2.0, end: 0.5).animate(
      CurvedAnimation(parent: _countdownController, curve: Curves.elasticOut),
    );
    
    // Testing pulse animation
    _testingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _testingPulse = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _testingController, curve: Curves.easeInOut),
    );
    
    // Metrics fade animation
    _metricsController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _metricsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _metricsController, curve: Curves.easeIn),
    );
  }

  void _initializeTestParameters() {
    final flowController = context.read<ValdTestFlowController>();
    
    // Set chart window based on test type
    switch (flowController.selectedTestType!) {
      case TestType.counterMovementJump:
        _chartTimeWindow = 8.0;
        break;
      case TestType.squatJump:
        _chartTimeWindow = 6.0;
        break;
      case TestType.dropJump:
        _chartTimeWindow = 10.0;
        break;
      case TestType.balance:
        _chartTimeWindow = 30.0;
        break;
      case TestType.isometricMidThigh:
      case TestType.isometricSquat:
        _chartTimeWindow = 5.0;
        break;
      case TestType.landing:
      case TestType.landAndHold:
        _chartTimeWindow = 8.0;
        break;
      default:
        _chartTimeWindow = 10.0;
    }
  }

  void _startCountdown() {
    setState(() {
      _isCountingDown = true;
      _countdownValue = 3;
    });
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownController.forward().then((_) {
        _countdownController.reset();
      });
      
      setState(() {
        _countdownValue--;
      });
      
      if (_countdownValue <= 0) {
        timer.cancel();
        _startTest();
      }
    });
  }

  void _startTest() {
    setState(() {
      _isCountingDown = false;
      _isTestActive = true;
      _testStartTime = DateTime.now();
    });
    
    // Clear previous data
    _totalForceData.clear();
    _leftForceData.clear();
    _rightForceData.clear();
    
    // Start animations
    _testingController.repeat(reverse: true);
    _metricsController.forward();
    
    // Start the actual test in flow controller
    final flowController = context.read<ValdTestFlowController>();
    flowController.startTest();
    
    // Listen to force data
    _startForceDataListening();
  }

  void _startForceDataListening() {
    final usbController = context.read<UsbController>();
    usbController.forceDataStream?.listen((forceData) {
      if (_isTestActive && _testStartTime != null) {
        _processForceData(forceData);
      }
    });
  }

  void _processForceData(ForceData data) {
    if (!_isTestActive || _testStartTime == null) return;
    
    final elapsedTime = DateTime.now().difference(_testStartTime!).inMilliseconds / 1000.0;
    
    // Add data points to charts
    setState(() {
      _totalForceData.add(FlSpot(elapsedTime, data.totalGRF));
      _leftForceData.add(FlSpot(elapsedTime, data.leftGRF));
      _rightForceData.add(FlSpot(elapsedTime, data.rightGRF));
      
      // Keep data within time window
      _trimDataToWindow();
    });
  }

  void _trimDataToWindow() {
    final currentTime = _totalForceData.isNotEmpty ? _totalForceData.last.x : 0;
    final cutoffTime = currentTime - _chartTimeWindow;
    
    _totalForceData.removeWhere((spot) => spot.x < cutoffTime);
    _leftForceData.removeWhere((spot) => spot.x < cutoffTime);
    _rightForceData.removeWhere((spot) => spot.x < cutoffTime);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ValdTestFlowController, UsbController>(
      builder: (context, flowController, usbController, child) {
        // Get real-time data from controller
        final currentPhase = flowController.getCurrentPhase();
        final liveMetrics = flowController.getLiveMetrics();
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Test Header
              _buildTestHeader(flowController),
              
              const SizedBox(height: 12),
              
              // Main Content - Responsive layout
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 800) {
                    return Column(
                      children: [
                        // Charts Panel (full width on small screens)
                        SizedBox(
                          height: 300,
                          child: _buildChartsPanel(flowController),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Metrics Panel (full width on small screens)
                        SizedBox(
                          height: 400,
                          child: _buildMetricsPanel(currentPhase, liveMetrics),
                        ),
                      ],
                    );
                  } else {
                    // Side-by-side layout for larger screens
                    return SizedBox(
                      height: 450,
                      child: Row(
                        children: [
                          // Left Panel - Charts
                          Expanded(
                            flex: 3,
                            child: _buildChartsPanel(flowController),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Right Panel - Live Metrics
                          Expanded(
                            flex: 2,
                            child: _buildMetricsPanel(currentPhase, liveMetrics),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              
              const SizedBox(height: 12),
              
              // Control Panel
              _buildControlPanel(flowController),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTestHeader(ValdTestFlowController flowController) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Test Type Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getTestTypeIcon(flowController.selectedTestType!),
                  color: const Color(0xFF1565C0),
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Test Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TestConstants.testNames[flowController.selectedTestType!] ?? 'Test',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Athlete: ${flowController.selectedAthlete?.fullName ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Status Indicator
              _buildStatusIndicator(),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Body weight info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Body Weight: ${flowController.measuredWeight?.toStringAsFixed(1) ?? '--'} kg',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (_isCountingDown) {
      statusColor = Colors.orange;
      statusText = 'Preparing';
      statusIcon = Icons.hourglass_empty;
    } else if (_isTestActive) {
      statusColor = Colors.green;
      statusText = 'Testing';
      statusIcon = Icons.play_circle;
    } else {
      statusColor = Colors.blue;
      statusText = 'Ready';
      statusIcon = Icons.play_arrow;
    }
    
    return AnimatedBuilder(
      animation: _testingPulse,
      builder: (context, child) {
        return Transform.scale(
          scale: _isTestActive ? _testingPulse.value : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: statusColor, size: 14),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChartsPanel(ValdTestFlowController flowController) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart Header
          Row(
            children: [
              const Icon(
                Icons.show_chart,
                color: Color(0xFF1565C0),
                size: 18,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Real-time Force Analysis',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Compact legend
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendItem('Total', const Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  _buildLegendItem('L', Colors.green),
                  const SizedBox(width: 8),
                  _buildLegendItem('R', Colors.red),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Countdown Overlay or Force Chart
          Expanded(
            child: _isCountingDown 
                ? _buildCountdownOverlay()
                : _buildForceChart(flowController),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    return AnimatedBuilder(
      animation: _countdownScale,
      builder: (context, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: _countdownScale.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1565C0),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _countdownValue > 0 ? _countdownValue.toString() : 'GO!',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Get ready to perform the test',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildForceChart(ValdTestFlowController flowController) {
    if (_totalForceData.isEmpty) {
      return const Center(
        child: Text(
          'Waiting for force data...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    // Get peak force from live metrics
    final liveMetrics = flowController.getLiveMetrics();
    final peakForce = liveMetrics['peakForce'] ?? 2000.0;
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          verticalInterval: 1,
          horizontalInterval: 500,
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 0.5,
          ),
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: 500,
              getTitlesWidget: (value, meta) => Text(
                '${(value / 1000).toStringAsFixed(1)}k',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              interval: 1,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}s',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        lineBarsData: [
          // Total Force Line (Blue)
          LineChartBarData(
            spots: _totalForceData,
            color: const Color(0xFF1565C0),
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF1565C0).withValues(alpha: 0.1),
            ),
          ),
          // Left Force Line (Green)
          LineChartBarData(
            spots: _leftForceData,
            color: Colors.green,
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // Right Force Line (Red)
          LineChartBarData(
            spots: _rightForceData,
            color: Colors.red,
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        minX: _totalForceData.isNotEmpty 
            ? math.max(0, _totalForceData.last.x - _chartTimeWindow)
            : 0,
        maxX: _totalForceData.isNotEmpty ? _totalForceData.last.x : _chartTimeWindow,
        minY: 0,
        maxY: peakForce > 0 ? peakForce * 1.1 : 2000,
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsPanel(JumpPhase currentPhase, Map<String, double> liveMetrics) {
    return AnimatedBuilder(
      animation: _metricsOpacity,
      builder: (context, child) {
        return Opacity(
          opacity: _metricsOpacity.value,
          child: Column(
            children: [
              // Live Metrics
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Metrics',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Live metrics from controller
                      Expanded(
                        child: ListView(
                          children: [
                            // Jump Height
                            _buildMetricCard(
                              'Jump Height',
                              '${(liveMetrics['estimatedJumpHeight'] ?? 0.0).toStringAsFixed(1)} cm',
                              Icons.height,
                              Colors.green,
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Peak Force
                            _buildMetricCard(
                              'Peak Force',
                              '${(liveMetrics['peakForce'] ?? 0.0).toStringAsFixed(0)} N',
                              Icons.trending_up,
                              const Color(0xFF1565C0),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Current RFD
                            _buildMetricCard(
                              'Current RFD',
                              '${(liveMetrics['currentRFD'] ?? 0.0).toStringAsFixed(0)} N/s',
                              Icons.speed,
                              Colors.orange,
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Asymmetry
                            _buildMetricCard(
                              'Asymmetry',
                              '${(liveMetrics['currentAsymmetry'] ?? 0.0).toStringAsFixed(1)}%',
                              Icons.balance,
                              (liveMetrics['currentAsymmetry'] ?? 0.0) > 15 ? Colors.red : Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Test Phase Indicator
              _buildPhaseIndicator(currentPhase),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator(JumpPhase currentPhase) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Test Phase',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getPhaseIcon(currentPhase),
                color: _getPhaseColor(currentPhase),
                size: 18,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  currentPhase.turkishName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getPhaseColor(currentPhase),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(ValdTestFlowController flowController) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Test Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Test Progress',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: flowController.getTestProgress(),
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
                minHeight: 6,
              ),
              const SizedBox(height: 4),
              Text(
                '${flowController.testDuration.inSeconds}s / ${TestConstants.testDurations[flowController.selectedTestType!]?.inSeconds ?? 10}s',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Start/Stop Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: flowController.canStartTest() && !_isCountingDown && !_isTestActive
                  ? _startCountdown
                  : _isTestActive 
                      ? () => flowController.stopTestManually()
                      : null,
              icon: Icon(
                _isCountingDown 
                    ? Icons.hourglass_empty 
                    : _isTestActive 
                        ? Icons.stop
                        : Icons.play_arrow,
                size: 18,
              ),
              label: Text(
                _isCountingDown 
                    ? 'Starting...' 
                    : _isTestActive 
                        ? 'Stop Test'
                        : 'Start Test',
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTestActive 
                    ? Colors.red 
                    : const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTestTypeIcon(TestType testType) {
    switch (testType) {
      case TestType.counterMovementJump:
        return Icons.trending_up;
      case TestType.squatJump:
        return Icons.arrow_upward;
      case TestType.dropJump:
        return Icons.arrow_downward;
      case TestType.balance:
        return Icons.balance;
      case TestType.isometricMidThigh:
      case TestType.isometricSquat:
        return Icons.fitness_center;
      case TestType.landing:
      case TestType.landAndHold:
        return Icons.flight_land;
      default:
        return Icons.analytics;
    }
  }

  IconData _getPhaseIcon(JumpPhase phase) {
    switch (phase) {
      case JumpPhase.quietStanding:
        return Icons.accessibility_new;
      case JumpPhase.preparatory:
        return Icons.hourglass_empty;
      case JumpPhase.braking:
        return Icons.arrow_downward;
      case JumpPhase.propulsive:
        return Icons.arrow_upward;
      case JumpPhase.flight:
        return Icons.flight;
      case JumpPhase.landing:
        return Icons.flight_land;
      case JumpPhase.stabilization:
        return Icons.balance;
      default:
        return Icons.help_outline;
    }
  }

  Color _getPhaseColor(JumpPhase phase) {
    switch (phase) {
      case JumpPhase.quietStanding:
        return Colors.grey;
      case JumpPhase.preparatory:
        return Colors.blue;
      case JumpPhase.braking:
        return Colors.orange;
      case JumpPhase.propulsive:
        return Colors.green;
      case JumpPhase.flight:
        return Colors.purple;
      case JumpPhase.landing:
        return Colors.red;
      case JumpPhase.stabilization:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _countdownController.dispose();
    _testingController.dispose();
    _metricsController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }
}

// Extension for List to get last N elements
extension ListExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (count >= length) return this;
    return sublist(length - count);
  }
}