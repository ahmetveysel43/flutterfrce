// lib/presentation/widgets/vald_flow_widgets/enhanced_testing_widget.dart
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

class EnhancedTestingWidget extends StatefulWidget {
  const EnhancedTestingWidget({super.key});

  @override
  State<EnhancedTestingWidget> createState() => _EnhancedTestingWidgetState();
}

class _EnhancedTestingWidgetState extends State<EnhancedTestingWidget>
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _countdownController;
  late AnimationController _testingController;
  late AnimationController _metricsController;
  late AnimationController _performanceController;
  
  // Animations
  late Animation<double> _countdownScale;
  late Animation<double> _testingPulse;
  late Animation<double> _metricsOpacity;
  late Animation<double> _performanceBounce;
  
  // Test state
  bool _isCountingDown = false;
  bool _isTestActive = false;
  int _countdownValue = 3;
  Timer? _countdownTimer;
  
  // Real-time data for charts
  final List<FlSpot> _totalForceData = [];
  final List<FlSpot> _leftForceData = [];
  final List<FlSpot> _rightForceData = [];
  double _chartTimeWindow = 10.0;
  DateTime? _testStartTime;
  
  // Enhanced performance tracking
  PerformanceLevel? _currentPerformanceLevel;
  String? _normKey;
  bool _showTurkishUI = true;
  
  // Real-time feedback
  List<String> _realTimeFeedback = [];
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeTestParameters();
    _setupRealTimeFeedback();
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
    
    // Performance level animation
    _performanceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _performanceBounce = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _performanceController, curve: Curves.elasticOut),
    );
  }

  void _initializeTestParameters() {
    final flowController = context.read<ValdTestFlowController>();
    final protocol = TestConstants.getProtocol(flowController.selectedTestType!);
    
    if (protocol != null) {
      _chartTimeWindow = protocol.duration.inSeconds.toDouble();
    }
    
    // Setup Turkish norms for athlete
    final athlete = flowController.selectedAthlete;
    if (athlete != null) {
      _normKey = TestConstants.getTurkishNormKey(
        athlete.gender, 
        athlete.age, 
        athlete.sport,
      );
    }
  }
  
  void _setupRealTimeFeedback() {
    _feedbackTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_isTestActive) {
        _updateRealTimeFeedback();
      }
    });
  }
  
  void _updateRealTimeFeedback() {
    final flowController = context.read<ValdTestFlowController>();
    final liveMetrics = flowController.getLiveMetrics();
    final currentPhase = flowController.getCurrentPhase();
    
    setState(() {
      _realTimeFeedback.clear();
      
      // Phase-specific feedback
      switch (currentPhase) {
        case JumpPhase.quietStanding:
          _realTimeFeedback.add(_showTurkishUI ? 'Sakin durun' : 'Stay still');
          break;
        case JumpPhase.preparatory:
          _realTimeFeedback.add(_showTurkishUI ? 'Hazırlanın' : 'Get ready');
          break;
        case JumpPhase.braking:
          _realTimeFeedback.add(_showTurkishUI ? 'Çömelin' : 'Squat down');
          break;
        case JumpPhase.propulsive:
          _realTimeFeedback.add(_showTurkishUI ? 'Sıçrayın!' : 'Jump!');
          break;
        case JumpPhase.flight:
          _realTimeFeedback.add(_showTurkishUI ? 'Uçuş!' : 'Flight!');
          break;
        case JumpPhase.landing:
          _realTimeFeedback.add(_showTurkishUI ? 'İniş' : 'Landing');
          break;
        case JumpPhase.stabilization:
          _realTimeFeedback.add(_showTurkishUI ? 'Dengede kalın' : 'Stabilize');
          break;
      }
      
      // Performance feedback
      final asymmetry = liveMetrics['currentAsymmetry'] ?? 0.0;
      if (asymmetry > TestConstants.asymmetryThreshold) {
        _realTimeFeedback.add(_showTurkishUI 
            ? 'Daha dengeli!' 
            : 'More balanced!');
      }
      
      // Jump height feedback for jump tests
      final estimatedHeight = liveMetrics['estimatedJumpHeight'] ?? 0.0;
      if (estimatedHeight > 0 && _normKey != null) {
        final level = TestConstants.getJumpPerformanceLevel(estimatedHeight, _normKey!);
        if (level != _currentPerformanceLevel) {
          _currentPerformanceLevel = level;
          _performanceController.forward().then((_) => _performanceController.reverse());
        }
      }
      
      // Keep feedback list manageable
      if (_realTimeFeedback.length > 3) {
        _realTimeFeedback = _realTimeFeedback.take(3).toList();
      }
    });
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
      _realTimeFeedback.clear();
      _currentPerformanceLevel = null;
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
    
    setState(() {
      _totalForceData.add(FlSpot(elapsedTime, data.totalGRF));
      _leftForceData.add(FlSpot(elapsedTime, data.leftGRF));
      _rightForceData.add(FlSpot(elapsedTime, data.rightGRF));
      
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
        final protocol = TestConstants.getProtocol(flowController.selectedTestType!);
        final currentPhase = flowController.getCurrentPhase();
        final liveMetrics = flowController.getLiveMetrics();
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Enhanced Test Header
              _buildEnhancedTestHeader(flowController, protocol!),
              
              const SizedBox(height: 12),
              
              // Real-time Feedback Bar
              _buildRealTimeFeedbackBar(),
              
              const SizedBox(height: 12),
              
              // Main Content
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 900) {
                    return Column(
                      children: [
                        // Charts Panel
                        SizedBox(
                          height: 320,
                          child: _buildEnhancedChartsPanel(flowController, protocol),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Metrics Panel
                        SizedBox(
                          height: 450,
                          child: _buildEnhancedMetricsPanel(currentPhase, liveMetrics, protocol),
                        ),
                      ],
                    );
                  } else {
                    return SizedBox(
                      height: 480,
                      child: Row(
                        children: [
                          // Left Panel - Charts
                          Expanded(
                            flex: 3,
                            child: _buildEnhancedChartsPanel(flowController, protocol),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Right Panel - Metrics
                          Expanded(
                            flex: 2,
                            child: _buildEnhancedMetricsPanel(currentPhase, liveMetrics, protocol),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              
              const SizedBox(height: 12),
              
              // Enhanced Control Panel
              _buildEnhancedControlPanel(flowController, protocol),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedTestHeader(ValdTestFlowController flowController, TestProtocol protocol) {
    final difficulty = TestConstants.testDifficulty[flowController.selectedTestType!]!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TestConstants.primaryBlue,
            TestConstants.secondaryBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TestConstants.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Test Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTestIcon(flowController.selectedTestType!),
                  color: Colors.white,
                  size: 28,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Test Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TestConstants.getTestName(flowController.selectedTestType!, turkish: _showTurkishUI),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _showTurkishUI 
                          ? protocol.turkishDescription 
                          : protocol.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Language & Status
              Column(
                children: [
                  // Language Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLanguageButton('EN', !_showTurkishUI),
                        _buildLanguageButton('TR', _showTurkishUI),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Status Indicator
                  _buildStatusIndicator(),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Bottom Info Row
          Row(
            children: [
              // Athlete Info
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.person,
                  label: _showTurkishUI ? 'Sporcu' : 'Athlete',
                  value: flowController.selectedAthlete?.fullName ?? 'Unknown',
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Difficulty
              _buildInfoChip(
                icon: Icons.trending_up,
                label: _showTurkishUI ? 'Zorluk' : 'Difficulty',
                value: _showTurkishUI ? difficulty.turkishName : difficulty.name,
                color: difficulty.color,
              ),
              
              const SizedBox(width: 12),
              
              // Duration
              _buildInfoChip(
                icon: Icons.timer,
                label: _showTurkishUI ? 'Süre' : 'Duration',
                value: '${protocol.duration.inSeconds}s',
              ),
              
              const SizedBox(width: 12),
              
              // Body Weight
              _buildInfoChip(
                icon: Icons.monitor_weight,
                label: _showTurkishUI ? 'Kilo' : 'Weight',
                value: '${flowController.measuredWeight?.toStringAsFixed(1) ?? '--'} kg',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _showTurkishUI = text == 'TR'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color ?? Colors.white, size: 16),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
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
      statusColor = TestConstants.warningOrange;
      statusText = _showTurkishUI ? 'Hazırlanıyor' : 'Preparing';
      statusIcon = Icons.hourglass_empty;
    } else if (_isTestActive) {
      statusColor = TestConstants.successGreen;
      statusText = _showTurkishUI ? 'Test Yapılıyor' : 'Testing';
      statusIcon = Icons.play_circle;
    } else {
      statusColor = Colors.white;
      statusText = _showTurkishUI ? 'Hazır' : 'Ready';
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
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withValues(alpha: 0.5)),
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

  Widget _buildRealTimeFeedbackBar() {
    if (!_isTestActive || _realTimeFeedback.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TestConstants.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TestConstants.primaryBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.feedback,
                color: TestConstants.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _showTurkishUI ? 'Canlı Geri Bildirim' : 'Live Feedback',
                style: TextStyle(
                  color: TestConstants.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (_currentPerformanceLevel != null)
                AnimatedBuilder(
                  animation: _performanceBounce,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _performanceBounce.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _currentPerformanceLevel!.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentPerformanceLevel!.emoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _currentPerformanceLevel!.turkishName,
                              style: TextStyle(
                                color: _currentPerformanceLevel!.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _realTimeFeedback.map((feedback) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: TestConstants.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: TestConstants.successGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  feedback,
                  style: TextStyle(
                    color: TestConstants.successGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedChartsPanel(ValdTestFlowController flowController, TestProtocol protocol) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
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
              Icon(
                Icons.analytics,
                color: TestConstants.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _showTurkishUI ? 'Gerçek Zamanlı Kuvvet Analizi' : 'Real-time Force Analysis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: TestConstants.primaryBlue,
                  ),
                ),
              ),
              // Chart Legend
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendItem(_showTurkishUI ? 'Toplam' : 'Total', TestConstants.primaryBlue),
                  const SizedBox(width: 8),
                  _buildLegendItem('Sol', TestConstants.successGreen),
                  const SizedBox(width: 8),
                  _buildLegendItem('Sağ', TestConstants.errorRed),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Chart Content
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
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        TestConstants.primaryBlue,
                        TestConstants.secondaryBlue,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: TestConstants.primaryBlue.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _countdownValue > 0 ? _countdownValue.toString() : (_showTurkishUI ? 'BAŞLA!' : 'GO!'),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _showTurkishUI ? 'Teste hazırlanın' : 'Get ready for the test',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildForceChart(ValdTestFlowController flowController) {
    if (_totalForceData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _showTurkishUI ? 'Kuvvet verisi bekleniyor...' : 'Waiting for force data...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
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
            strokeWidth: 1,
          ),
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
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
              reservedSize: 30,
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
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        lineBarsData: [
          // Total Force Line
          LineChartBarData(
            spots: _totalForceData,
            color: TestConstants.primaryBlue,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: TestConstants.primaryBlue.withValues(alpha: 0.1),
            ),
          ),
          // Left Force Line
          LineChartBarData(
            spots: _leftForceData,
            color: TestConstants.successGreen,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // Right Force Line
          LineChartBarData(
            spots: _rightForceData,
            color: TestConstants.errorRed,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        minX: _totalForceData.isNotEmpty 
            ? math.max(0, _totalForceData.last.x - _chartTimeWindow)
            : 0,
        maxX: _totalForceData.isNotEmpty ? _totalForceData.last.x : _chartTimeWindow,
        minY: 0,
        maxY: peakForce > 0 ? peakForce * 1.2 : 2000,
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedMetricsPanel(JumpPhase currentPhase, Map<String, double> liveMetrics, TestProtocol protocol) {
    return AnimatedBuilder(
      animation: _metricsOpacity,
      builder: (context, child) {
        return Opacity(
          opacity: _metricsOpacity.value,
          child: Column(
            children: [
              // Live Metrics
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.speed,
                            color: TestConstants.primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _showTurkishUI ? 'Canlı Metrikler' : 'Live Metrics',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: TestConstants.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Expanded(
                        child: _buildMetricsGrid(liveMetrics, protocol),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Phase Indicator
              Expanded(
                flex: 1,
                child: _buildPhaseIndicator(currentPhase),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricsGrid(Map<String, double> liveMetrics, TestProtocol protocol) {
    final keyMetrics = protocol.keyMetrics.take(6).toList(); // Show top 6 metrics
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: keyMetrics.length,
      itemBuilder: (context, index) {
        final metricKey = keyMetrics[index];
        final value = liveMetrics[metricKey] ?? 0.0;
        final metricName = TestConstants.metricNames[metricKey] ?? metricKey;
        
        return _buildMetricCard(
          title: metricName,
          value: _formatMetricValue(metricKey, value),
          icon: _getMetricIcon(metricKey),
          color: _getMetricColor(metricKey, value),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator(JumpPhase currentPhase) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline,
                color: TestConstants.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _showTurkishUI ? 'Test Fazı' : 'Test Phase',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: TestConstants.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getPhaseIcon(currentPhase),
                color: _getPhaseColor(currentPhase),
                size: 24,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  currentPhase.turkishName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getPhaseColor(currentPhase),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedControlPanel(ValdTestFlowController flowController, TestProtocol protocol) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
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
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: TestConstants.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _showTurkishUI ? 'Test İlerlemesi' : 'Test Progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: TestConstants.primaryBlue,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${flowController.testDuration.inSeconds}s / ${protocol.duration.inSeconds}s',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: flowController.getTestProgress(),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(TestConstants.primaryBlue),
                minHeight: 8,
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            children: [
              // Stop Button (when testing)
              if (_isTestActive)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isTestActive = false;
                        _isCountingDown = false;
                      });
                      _testingController.stop();
                      flowController.stopTestManually();
                    },
                    icon: const Icon(Icons.stop, size: 20),
                    label: Text(_showTurkishUI ? 'Testi Durdur' : 'Stop Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TestConstants.errorRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              
              // Start Button (when ready)
              if (!_isTestActive && !_isCountingDown)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: flowController.canStartTest() ? _startCountdown : null,
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: Text(_showTurkishUI ? 'Testi Başlat' : 'Start Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TestConstants.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              
              // Countdown indicator
              if (_isCountingDown)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: TestConstants.warningOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: TestConstants.warningOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          color: TestConstants.warningOrange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _showTurkishUI ? 'Başlatılıyor...' : 'Starting...',
                          style: TextStyle(
                            color: TestConstants.warningOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatMetricValue(String metricKey, double value) {
    switch (metricKey) {
      case 'jumpHeight':
      case 'estimatedJumpHeight':
        return '${value.toStringAsFixed(1)} cm';
      case 'peakForce':
      case 'averageForce':
        return '${value.toStringAsFixed(0)} N';
      case 'rfdMax':
      case 'currentRFD':
        return '${value.toStringAsFixed(0)} N/s';
      case 'flightTime':
      case 'contactTime':
        return '${value.toStringAsFixed(0)} ms';
      case 'asymmetryIndex':
      case 'currentAsymmetry':
        return '${value.toStringAsFixed(1)}%';
      case 'powerOutput':
      case 'peakPower':
        return '${value.toStringAsFixed(0)} W';
      default:
        return value.toStringAsFixed(1);
    }
  }

  IconData _getMetricIcon(String metricKey) {
    switch (metricKey) {
      case 'jumpHeight':
      case 'estimatedJumpHeight':
        return Icons.height;
      case 'peakForce':
      case 'averageForce':
        return Icons.trending_up;
      case 'rfdMax':
      case 'currentRFD':
        return Icons.speed;
      case 'asymmetryIndex':
      case 'currentAsymmetry':
        return Icons.balance;
      case 'powerOutput':
      case 'peakPower':
        return Icons.power;
      case 'flightTime':
        return Icons.flight;
      case 'contactTime':
        return Icons.touch_app;
      default:
        return Icons.analytics;
    }
  }

  Color _getMetricColor(String metricKey, double value) {
    switch (metricKey) {
      case 'asymmetryIndex':
      case 'currentAsymmetry':
        if (value > TestConstants.asymmetryThreshold) return TestConstants.errorRed;
        if (value > TestConstants.goodAsymmetryThreshold) return TestConstants.warningOrange;
        return TestConstants.successGreen;
      case 'jumpHeight':
      case 'estimatedJumpHeight':
        return TestConstants.successGreen;
      case 'peakForce':
      case 'averageForce':
        return TestConstants.primaryBlue;
      case 'rfdMax':
      case 'currentRFD':
        return TestConstants.warningOrange;
      default:
        return TestConstants.neutralGrey;
    }
  }

  IconData _getTestIcon(TestType testType) {
    switch (testType) {
      case TestType.counterMovementJump:
        return Icons.trending_up;
      case TestType.squatJump:
        return Icons.arrow_upward;
      case TestType.dropJump:
        return Icons.arrow_downward;
      case TestType.balance:
        return Icons.balance;
      case TestType.singleLegBalance:
        return Icons.accessibility_new;
      case TestType.isometricMidThigh:
        return Icons.fitness_center;
      case TestType.isometricSquat:
        return Icons.sports_gymnastics;
      case TestType.landing:
        return Icons.flight_land;
      case TestType.landAndHold:
        return Icons.pause_circle;
      case TestType.reactiveDynamic:
        return Icons.flash_on;
      case TestType.hopping:
        return Icons.directions_run;
      case TestType.changeOfDirection:
        return Icons.compare_arrows;
      case TestType.powerClean:
        return Icons.power;
      case TestType.fatigue:
        return Icons.timer;
      case TestType.recovery:
        return Icons.refresh;
      case TestType.returnToSport:
        return Icons.sports;
      case TestType.injuryRisk:
        return Icons.healing;
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
        return TestConstants.neutralGrey;
      case JumpPhase.preparatory:
        return TestConstants.primaryBlue;
      case JumpPhase.braking:
        return TestConstants.warningOrange;
      case JumpPhase.propulsive:
        return TestConstants.successGreen;
      case JumpPhase.flight:
        return Colors.purple;
      case JumpPhase.landing:
        return TestConstants.errorRed;
      case JumpPhase.stabilization:
        return Colors.teal;
      default:
        return TestConstants.neutralGrey;
    }
  }

  @override
  void dispose() {
    _countdownController.dispose();
    _testingController.dispose();
    _metricsController.dispose();
    _performanceController.dispose();
    _countdownTimer?.cancel();
    _feedbackTimer?.cancel();
    super.dispose();
  }
}