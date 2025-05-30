// lib/presentation/widgets/vald_flow_widgets/testing_widget.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/vald_test_flow_controller.dart';
import '../../controllers/usb_controller.dart';
import '../../../domain/entities/force_data.dart';
import '../../../core/constants/test_constants.dart';

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
 
 // Live metrics calculation
 double _currentJumpHeight = 0.0;
 double _peakForce = 0.0;
 double _currentRFD = 0.0;
 double _asymmetryIndex = 0.0;
 double _impulse = 0.0;
 
 // Test phases detection
 TestPhase _currentPhase = TestPhase.preparation;
 double _bodyWeight = 0.0;

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
   _bodyWeight = (flowController.measuredWeight ?? 70.0) * 9.81; // Convert to Newtons
   
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
     case TestType.isometric:
       _chartTimeWindow = 5.0;
       break;
     case TestType.landing:
       _chartTimeWindow = 8.0;
       break;
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
     _currentPhase = TestPhase.active;
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
     
     // Update live metrics
     _updateLiveMetrics(data, elapsedTime);
     
     // Detect test phases
     _detectTestPhases(data);
   });
 }

 void _trimDataToWindow() {
   final currentTime = _totalForceData.isNotEmpty ? _totalForceData.last.x : 0;
   final cutoffTime = currentTime - _chartTimeWindow;
   
   _totalForceData.removeWhere((spot) => spot.x < cutoffTime);
   _leftForceData.removeWhere((spot) => spot.x < cutoffTime);
   _rightForceData.removeWhere((spot) => spot.x < cutoffTime);
 }

 void _updateLiveMetrics(ForceData data, double elapsedTime) {
   // Update peak force
   if (data.totalGRF > _peakForce) {
     _peakForce = data.totalGRF;
   }
   
   // Calculate RFD (simplified)
   if (_totalForceData.length > 10) {
     final recent = _totalForceData.takeLast(10);
     final forceChange = recent.last.y - recent.first.y;
     final timeChange = recent.last.x - recent.first.x;
     _currentRFD = timeChange > 0 ? forceChange / timeChange : 0;
   }
   
   // Update asymmetry
   _asymmetryIndex = data.asymmetryIndex * 100;
   
   // Calculate impulse (area under curve above body weight)
   _impulse = _calculateImpulse();
   
   // Calculate jump height (simplified flight time method)
   _currentJumpHeight = _calculateJumpHeight();
 }

 double _calculateImpulse() {
   if (_totalForceData.length < 2) return 0.0;
   
   double impulse = 0.0;
   for (int i = 1; i < _totalForceData.length; i++) {
     final deltaTime = _totalForceData[i].x - _totalForceData[i-1].x;
     final avgForce = (_totalForceData[i].y + _totalForceData[i-1].y) / 2;
     final netForce = avgForce - _bodyWeight;
     
     if (netForce > 0) {
       impulse += netForce * deltaTime;
     }
   }
   
   return impulse;
 }

 double _calculateJumpHeight() {
   if (_impulse <= 0 || _bodyWeight <= 0) return 0.0;
   
   // Simplified jump height calculation
   final velocity = _impulse / (_bodyWeight / 9.81); // v = J/m
   final height = (velocity * velocity) / (2 * 9.81); // h = v²/2g
   
   return height * 100; // Convert to cm
 }

 void _detectTestPhases(ForceData data) {
   switch (_currentPhase) {
     case TestPhase.preparation:
       if (data.totalGRF > _bodyWeight * 1.1) {
         _currentPhase = TestPhase.loading;
       }
       break;
     case TestPhase.loading:
       if (data.totalGRF < _bodyWeight * 0.9) {
         _currentPhase = TestPhase.unloading;
       }
       break;
     case TestPhase.unloading:
       if (data.totalGRF < 50) { // Takeoff threshold
         _currentPhase = TestPhase.flight;
       }
       break;
     case TestPhase.flight:
       if (data.totalGRF > _bodyWeight * 0.5) {
         _currentPhase = TestPhase.landing;
       }
       break;
     default:
       break;
   }
 }

 @override
 Widget build(BuildContext context) {
   return Consumer2<ValdTestFlowController, UsbController>(
     builder: (context, flowController, usbController, child) {
       return Padding(
         padding: const EdgeInsets.all(16),
         child: Column(
           children: [
             // Test Header
             _buildTestHeader(flowController),
             
             const SizedBox(height: 16),
             
             // Main Content
             Expanded(
               child: Row(
                 children: [
                   // Left Panel - Charts
                   Expanded(
                     flex: 3,
                     child: _buildChartsPanel(),
                   ),
                   
                   const SizedBox(width: 16),
                   
                   // Right Panel - Live Metrics
                   Expanded(
                     flex: 2,
                     child: _buildMetricsPanel(),
                   ),
                 ],
               ),
             ),
             
             const SizedBox(height: 16),
             
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
     padding: const EdgeInsets.all(20),
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
     child: Row(
       children: [
         // Test Type Icon
         Container(
           padding: const EdgeInsets.all(12),
           decoration: BoxDecoration(
             color: const Color(0xFF1565C0).withOpacity(0.1),
             borderRadius: BorderRadius.circular(12),
           ),
           child: Icon(
             _getTestTypeIcon(flowController.selectedTestType!),
             color: const Color(0xFF1565C0),
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
                 TestConstants.testNames[flowController.selectedTestType!] ?? 'Test',
                 style: const TextStyle(
                   fontSize: 20,
                   fontWeight: FontWeight.bold,
                   color: Color(0xFF1565C0),
                 ),
               ),
               Text(
                 'Athlete: ${flowController.selectedAthlete?.fullName ?? 'Unknown'}',
                 style: TextStyle(
                   fontSize: 14,
                   color: Colors.grey[600],
                 ),
               ),
               Text(
                 'Body Weight: ${flowController.measuredWeight?.toStringAsFixed(1) ?? '--'} kg',
                 style: TextStyle(
                   fontSize: 14,
                   color: Colors.grey[600],
                 ),
               ),
             ],
           ),
         ),
         
         // Status Indicator
         _buildStatusIndicator(),
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
           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
           decoration: BoxDecoration(
             color: statusColor.withOpacity(0.1),
             borderRadius: BorderRadius.circular(20),
             border: Border.all(color: statusColor.withOpacity(0.3)),
           ),
           child: Row(
             mainAxisSize: MainAxisSize.min,
             children: [
               Icon(statusIcon, color: statusColor, size: 16),
               const SizedBox(width: 8),
               Text(
                 statusText,
                 style: TextStyle(
                   color: statusColor,
                   fontSize: 14,
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

 Widget _buildChartsPanel() {
   return Container(
     padding: const EdgeInsets.all(20),
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
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         // Chart Header
         Row(
           children: [
             const Icon(
               Icons.show_chart,
               color: Color(0xFF1565C0),
               size: 20,
             ),
             const SizedBox(width: 8),
             const Text(
               'Real-time Force Analysis',
               style: TextStyle(
                 fontSize: 16,
                 fontWeight: FontWeight.bold,
                 color: Color(0xFF1565C0),
               ),
             ),
             const Spacer(),
             // Legend
             Row(
               children: [
                 _buildLegendItem('Total', const Color(0xFF1565C0)),
                 const SizedBox(width: 16),
                 _buildLegendItem('Left', Colors.green),
                 const SizedBox(width: 16),
                 _buildLegendItem('Right', Colors.red),
               ],
             ),
           ],
         ),
         
         const SizedBox(height: 16),
         
         // Countdown Overlay
         if (_isCountingDown)
           Expanded(
             child: _buildCountdownOverlay(),
           )
         else
           // Force Chart
           Expanded(
             child: _buildForceChart(),
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
                 width: 120,
                 height: 120,
                 decoration: BoxDecoration(
                   color: const Color(0xFF1565C0).withOpacity(0.1),
                   shape: BoxShape.circle,
                   border: Border.all(
                     color: const Color(0xFF1565C0),
                     width: 4,
                   ),
                 ),
                 child: Center(
                   child: Text(
                     _countdownValue > 0 ? _countdownValue.toString() : 'GO!',
                     style: const TextStyle(
                       fontSize: 48,
                       fontWeight: FontWeight.bold,
                       color: Color(0xFF1565C0),
                     ),
                   ),
                 ),
               ),
             ),
             const SizedBox(height: 24),
             const Text(
               'Get ready to perform the test',
               style: TextStyle(
                 fontSize: 18,
                 color: Colors.grey,
               ),
             ),
           ],
         ),
       );
     },
   );
 }

 Widget _buildForceChart() {
   if (_totalForceData.isEmpty) {
     return const Center(
       child: Text(
         'Waiting for force data...',
         style: TextStyle(
           fontSize: 16,
           color: Colors.grey,
         ),
       ),
     );
   }
   
   return LineChart(
     LineChartData(
       gridData: FlGridData(
         show: true,
         drawVerticalLine: true,
         drawHorizontalLine: true,
         verticalInterval: 1,
         horizontalInterval: 500,
         getDrawingVerticalLine: (value) => FlLine(
           color: Colors.grey.withOpacity(0.3),
           strokeWidth: 1,
         ),
         getDrawingHorizontalLine: (value) => FlLine(
           color: Colors.grey.withOpacity(0.3),
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
               '${value.toInt()}N',
               style: const TextStyle(fontSize: 12, color: Colors.grey),
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
               style: const TextStyle(fontSize: 12, color: Colors.grey),
             ),
           ),
         ),
         rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
         topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
       ),
       borderData: FlBorderData(
         show: true,
         border: Border.all(color: Colors.grey.withOpacity(0.3)),
       ),
       lineBarsData: [
         // Total Force Line (Blue)
         LineChartBarData(
           spots: _totalForceData,
           color: const Color(0xFF1565C0),
           barWidth: 3,
           dotData: const FlDotData(show: false),
           belowBarData: BarAreaData(
             show: true,
             color: const Color(0xFF1565C0).withOpacity(0.1),
           ),
         ),
         // Left Force Line (Green)
         LineChartBarData(
           spots: _leftForceData,
           color: Colors.green,
           barWidth: 2,
           dotData: const FlDotData(show: false),
           belowBarData: BarAreaData(show: false),
         ),
         // Right Force Line (Red)
         LineChartBarData(
           spots: _rightForceData,
           color: Colors.red,
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
       maxY: _peakForce > 0 ? _peakForce * 1.1 : 2000,
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
           borderRadius: BorderRadius.circular(1.5),
         ),
       ),
       const SizedBox(width: 4),
       Text(
         label,
         style: const TextStyle(
           fontSize: 12,
           color: Colors.grey,
         ),
       ),
     ],
   );
 }

 Widget _buildMetricsPanel() {
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
                 padding: const EdgeInsets.all(20),
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
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text(
                       'Live Metrics',
                       style: TextStyle(
                         fontSize: 16,
                         fontWeight: FontWeight.bold,
                         color: Color(0xFF1565C0),
                       ),
                     ),
                     const SizedBox(height: 20),
                     
                     // Jump Height
                     _buildMetricCard(
                       'Jump Height',
                       '${_currentJumpHeight.toStringAsFixed(1)} cm',
                       Icons.height,
                       Colors.green,
                     ),
                     
                     const SizedBox(height: 12),
                     
                     // Peak Force
                     _buildMetricCard(
                       'Peak Force',
                       '${_peakForce.toStringAsFixed(0)} N',
                       Icons.trending_up,
                       const Color(0xFF1565C0),
                     ),
                     
                     const SizedBox(height: 12),
                     
                     // RFD
                     _buildMetricCard(
                       'RFD',
                       '${_currentRFD.toStringAsFixed(0)} N/s',
                       Icons.speed,
                       Colors.orange,
                     ),
                     
                     const SizedBox(height: 12),
                     
                     // Asymmetry
                     _buildMetricCard(
                       'Asymmetry',
                       '${_asymmetryIndex.toStringAsFixed(1)}%',
                       Icons.balance,
                       _asymmetryIndex > 15 ? Colors.red : Colors.green,
                     ),
                   ],
                 ),
               ),
             ),
             
             const SizedBox(height: 16),
             
             // Test Phase Indicator
             _buildPhaseIndicator(),
           ],
         ),
       );
     },
   );
 }

 Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
   return Container(
     padding: const EdgeInsets.all(16),
     decoration: BoxDecoration(
       color: color.withOpacity(0.1),
       borderRadius: BorderRadius.circular(12),
       border: Border.all(color: color.withOpacity(0.3)),
     ),
     child: Row(
       children: [
         Icon(icon, color: color, size: 20),
         const SizedBox(width: 12),
         Expanded(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 title,
                 style: TextStyle(
                   fontSize: 12,
                   color: Colors.grey[600],
                 ),
               ),
               const SizedBox(height: 2),
               Text(
                 value,
                 style: TextStyle(
                   fontSize: 18,
                   fontWeight: FontWeight.bold,
                   color: color,
                 ),
               ),
             ],
           ),
         ),
       ],
     ),
   );
 }

 Widget _buildPhaseIndicator() {
   return Container(
     padding: const EdgeInsets.all(16),
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
         const Text(
           'Test Phase',
           style: TextStyle(
             fontSize: 14,
             fontWeight: FontWeight.bold,
             color: Color(0xFF1565C0),
           ),
         ),
         const SizedBox(height: 12),
         Row(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(
               _getPhaseIcon(_currentPhase),
               color: _getPhaseColor(_currentPhase),
               size: 24,
             ),
             const SizedBox(width: 8),
             Text(
               _getPhaseText(_currentPhase),
               style: TextStyle(
                 fontSize: 16,
                 fontWeight: FontWeight.bold,
                 color: _getPhaseColor(_currentPhase),
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
     padding: const EdgeInsets.all(20),
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
     child: Row(
       children: [
         // Test Progress
         Expanded(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 'Test Progress',
                 style: TextStyle(
                   fontSize: 14,
                   color: Colors.grey[600],
                 ),
               ),
               const SizedBox(height: 8),
               LinearProgressIndicator(
                 value: flowController.testDuration.inMilliseconds / 
                        (TestConstants.testDurations[flowController.selectedTestType!]?.inMilliseconds ?? 10000),
                 backgroundColor: Colors.grey[300],
                 valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
                 minHeight: 8,
               ),
               const SizedBox(height: 4),
               Text(
                 '${flowController.testDuration.inSeconds}s / ${TestConstants.testDurations[flowController.selectedTestType!]?.inSeconds ?? 10}s',
                 style: const TextStyle(
                   fontSize: 12,
                   color: Colors.grey,
                 ),
               ),
             ],
           ),
         ),
         
         const SizedBox(width: 32),
         
         // Start/Stop Button
         ElevatedButton.icon(
           onPressed: _isTestActive 
               ? null // Test runs automatically
               : (_isCountingDown ? null : _startCountdown),
           icon: Icon(_isCountingDown 
               ? Icons.hourglass_empty 
               : _isTestActive 
                   ? Icons.stop
                   : Icons.play_arrow),
           label: Text(_isCountingDown 
               ? 'Starting...' 
               : _isTestActive 
                   ? 'Testing...'
                   : 'Start Test'),
           style: ElevatedButton.styleFrom(
             backgroundColor: _isTestActive 
                 ? Colors.red 
                 : const Color(0xFF1565C0),
             foregroundColor: Colors.white,
             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
             shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.circular(12),
             ),
             textStyle: const TextStyle(
               fontSize: 16,
               fontWeight: FontWeight.bold,
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
     case TestType.isometric:
       return Icons.fitness_center;
     case TestType.landing:
       return Icons.arrow_downward;
   }
 }

 IconData _getPhaseIcon(TestPhase phase) {
   switch (phase) {
     case TestPhase.preparation:
       return Icons.hourglass_empty;
     case TestPhase.active:
       return Icons.play_circle;
     case TestPhase.loading:
       return Icons.arrow_downward;
     case TestPhase.unloading:
     case TestPhase.unloading:
       return Icons.arrow_upward;
     case TestPhase.flight:
       return Icons.flight;
     case TestPhase.landing:
       return Icons.padding;
   }
 }

 Color _getPhaseColor(TestPhase phase) {
   switch (phase) {
     case TestPhase.preparation:
       return Colors.grey;
     case TestPhase.active:
       return const Color(0xFF1565C0);
     case TestPhase.loading:
       return Colors.orange;
     case TestPhase.unloading:
       return Colors.green;
     case TestPhase.flight:
       return Colors.purple;
     case TestPhase.landing:
       return Colors.red;
   }
 }

 String _getPhaseText(TestPhase phase) {
   switch (phase) {
     case TestPhase.preparation:
       return 'Preparation';
     case TestPhase.active:
       return 'Active';
     case TestPhase.loading:
       return 'Loading';
     case TestPhase.unloading:
       return 'Unloading';
     case TestPhase.flight:
       return 'Flight';
     case TestPhase.landing:
       return 'Landing';
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

// Test phases enum
enum TestPhase {
 preparation,
 active,
 loading,
 unloading,
 flight,
 landing,
}

// Extension for List to get last N elements
extension ListExtension<T> on List<T> {
 List<T> takeLast(int count) {
   if (count >= length) return this;
   return sublist(length - count);
 }
}