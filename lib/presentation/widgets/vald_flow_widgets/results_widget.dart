// lib/presentation/widgets/vald_flow_widgets/results_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/vald_test_flow_controller.dart';
import '../../../core/constants/test_constants.dart';

class ResultsWidget extends StatefulWidget {
 const ResultsWidget({super.key});

 @override
 State<ResultsWidget> createState() => _ResultsWidgetState();
}

class _ResultsWidgetState extends State<ResultsWidget>
   with TickerProviderStateMixin {
 
 // Animation controllers
 late AnimationController _resultsAnimationController;
 late AnimationController _celebrationController;
 late AnimationController _chartAnimationController;
 
 // Animations
 late Animation<double> _resultsSlideAnimation;
 late Animation<double> _celebrationScale;
 late Animation<double> _chartAnimation;
 
 // Selected view
 ResultsView _selectedView = ResultsView.summary;
 
 // Normative data for comparison (VALD-style)
 final Map<String, NormativeRange> _normativeData = {
   'jumpHeight': NormativeRange(poor: 20, belowAverage: 25, average: 30, aboveAverage: 35, excellent: 40),
   'peakForce': NormativeRange(poor: 1500, belowAverage: 1800, average: 2100, aboveAverage: 2400, excellent: 2700),
   'rfd': NormativeRange(poor: 2000, belowAverage: 3000, average: 4000, aboveAverage: 5000, excellent: 6000),
   'asymmetryIndex': NormativeRange(poor: 25, belowAverage: 20, average: 15, aboveAverage: 10, excellent: 5, isLowerBetter: true),
 };

 @override
 void initState() {
   super.initState();
   _initializeAnimations();
   _startEntranceAnimation();
 }

 void _initializeAnimations() {
   // Results slide animation
   _resultsAnimationController = AnimationController(
     duration: const Duration(milliseconds: 800),
     vsync: this,
   );
   _resultsSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
     CurvedAnimation(parent: _resultsAnimationController, curve: Curves.easeOutCubic),
   );
   
   // Celebration animation
   _celebrationController = AnimationController(
     duration: const Duration(milliseconds: 1200),
     vsync: this,
   );
   _celebrationScale = Tween<double>(begin: 0.0, end: 1.0).animate(
     CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
   );
   
   // Chart animation
   _chartAnimationController = AnimationController(
     duration: const Duration(milliseconds: 1000),
     vsync: this,
   );
   _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
     CurvedAnimation(parent: _chartAnimationController, curve: Curves.easeInOut),
   );
 }

 void _startEntranceAnimation() async {
   await Future.delayed(const Duration(milliseconds: 300));
   _resultsAnimationController.forward();
   await Future.delayed(const Duration(milliseconds: 400));
   _celebrationController.forward();
   await Future.delayed(const Duration(milliseconds: 200));
   _chartAnimationController.forward();
 }

 @override
 Widget build(BuildContext context) {
   return Consumer<ValdTestFlowController>(
     builder: (context, flowController, child) {
       final results = flowController.testResults;
       if (results == null) {
         return const Center(child: CircularProgressIndicator());
       }

       return AnimatedBuilder(
         animation: _resultsSlideAnimation,
         builder: (context, child) {
           return Transform.translate(
             offset: Offset(0, (1 - _resultsSlideAnimation.value) * 50),
             child: Opacity(
               opacity: _resultsSlideAnimation.value,
               child: Padding(
                 padding: const EdgeInsets.all(16),
                 child: Column(
                   children: [
                     // Results Header
                     _buildResultsHeader(flowController, results),
                     
                     const SizedBox(height: 16),
                     
                     // View Selector
                     _buildViewSelector(),
                     
                     const SizedBox(height: 16),
                     
                     // Main Content
                     Expanded(
                       child: _buildMainContent(flowController, results),
                     ),
                     
                     const SizedBox(height: 16),
                     
                     // Action Buttons
                     _buildActionButtons(flowController),
                   ],
                 ),
               ),
             ),
           );
         },
       );
     },
   );
 }

 Widget _buildResultsHeader(ValdTestFlowController flowController, Map<String, double> results) {
   final jumpHeight = results['jumpHeight'] ?? 0.0;
   final grade = _getPerformanceGrade(jumpHeight, 'jumpHeight');
   
   return AnimatedBuilder(
     animation: _celebrationScale,
     builder: (context, child) {
       return Transform.scale(
         scale: _celebrationScale.value,
         child: Container(
           padding: const EdgeInsets.all(24),
           decoration: BoxDecoration(
             gradient: LinearGradient(
               colors: [
                 _getGradeColor(grade).withOpacity(0.1),
                 _getGradeColor(grade).withOpacity(0.05),
               ],
               begin: Alignment.topLeft,
               end: Alignment.bottomRight,
             ),
             borderRadius: BorderRadius.circular(20),
             border: Border.all(
               color: _getGradeColor(grade).withOpacity(0.3),
               width: 2,
             ),
           ),
           child: Column(
             children: [
               // Success Icon
               Container(
                 width: 80,
                 height: 80,
                 decoration: BoxDecoration(
                   color: _getGradeColor(grade).withOpacity(0.1),
                   shape: BoxShape.circle,
                 ),
                 child: Icon(
                   Icons.emoji_events,
                   size: 40,
                   color: _getGradeColor(grade),
                 ),
               ),
               
               const SizedBox(height: 16),
               
               // Test Complete
               const Text(
                 'Test Complete!',
                 style: TextStyle(
                   fontSize: 28,
                   fontWeight: FontWeight.bold,
                   color: Color(0xFF1565C0),
                 ),
               ),
               
               const SizedBox(height: 8),
               
               // Test Info
               Text(
                 '${TestConstants.testNames[flowController.selectedTestType!]} • ${flowController.selectedAthlete?.fullName}',
                 style: TextStyle(
                   fontSize: 16,
                   color: Colors.grey[600],
                 ),
               ),
               
               const SizedBox(height: 16),
               
               // Primary Result
               Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Column(
                     children: [
                       Text(
                         jumpHeight.toStringAsFixed(1),
                         style: TextStyle(
                           fontSize: 48,
                           fontWeight: FontWeight.bold,
                           color: _getGradeColor(grade),
                         ),
                       ),
                       const Text(
                         'cm',
                         style: TextStyle(
                           fontSize: 18,
                           color: Colors.grey,
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(width: 24),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     decoration: BoxDecoration(
                       color: _getGradeColor(grade),
                       borderRadius: BorderRadius.circular(20),
                     ),
                     child: Text(
                       grade.name.toUpperCase(),
                       style: const TextStyle(
                         color: Colors.white,
                         fontSize: 16,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                   ),
                 ],
               ),
             ],
           ),
         ),
       );
     },
   );
 }

 Widget _buildViewSelector() {
   return Container(
     padding: const EdgeInsets.all(4),
     decoration: BoxDecoration(
       color: Colors.grey[100],
       borderRadius: BorderRadius.circular(12),
     ),
     child: Row(
       children: ResultsView.values.map((view) {
         final isSelected = _selectedView == view;
         return Expanded(
           child: GestureDetector(
             onTap: () => setState(() => _selectedView = view),
             child: AnimatedContainer(
               duration: const Duration(milliseconds: 200),
               padding: const EdgeInsets.symmetric(vertical: 12),
               decoration: BoxDecoration(
                 color: isSelected ? Colors.white : Colors.transparent,
                 borderRadius: BorderRadius.circular(8),
                 boxShadow: isSelected ? [
                   BoxShadow(
                     color: Colors.grey.withOpacity(0.2),
                     blurRadius: 4,
                     offset: const Offset(0, 2),
                   ),
                 ] : null,
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(
                     _getViewIcon(view),
                     size: 18,
                     color: isSelected ? const Color(0xFF1565C0) : Colors.grey,
                   ),
                   const SizedBox(width: 8),
                   Text(
                     _getViewTitle(view),
                     style: TextStyle(
                       fontSize: 14,
                       fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                       color: isSelected ? const Color(0xFF1565C0) : Colors.grey,
                     ),
                   ),
                 ],
               ),
             ),
           ),
         );
       }).toList(),
     ),
   );
 }

 Widget _buildMainContent(ValdTestFlowController flowController, Map<String, double> results) {
   switch (_selectedView) {
     case ResultsView.summary:
       return _buildSummaryView(results);
     case ResultsView.detailed:
       return _buildDetailedView(results);
     case ResultsView.comparison:
       return _buildComparisonView(results);
     case ResultsView.history:
       return _buildHistoryView(flowController);
   }
 }

 Widget _buildSummaryView(Map<String, double> results) {
   return SingleChildScrollView(
     child: Column(
       children: [
         // Key Metrics Grid
         _buildKeyMetricsGrid(results),
         
         const SizedBox(height: 20),
         
         // Performance Radar Chart
         _buildPerformanceRadar(results),
         
         const SizedBox(height: 20),
         
         // Quick Insights
         _buildQuickInsights(results),
       ],
     ),
   );
 }

 Widget _buildKeyMetricsGrid(Map<String, double> results) {
   final metrics = [
     MetricCard(
       title: 'Jump Height',
       value: results['jumpHeight'] ?? 0.0,
       unit: 'cm',
       icon: Icons.height,
       color: Colors.green,
       grade: _getPerformanceGrade(results['jumpHeight'] ?? 0.0, 'jumpHeight'),
     ),
     MetricCard(
       title: 'Peak Force',
       value: results['peakForce'] ?? 0.0,
       unit: 'N',
       icon: Icons.trending_up,
       color: const Color(0xFF1565C0),
       grade: _getPerformanceGrade(results['peakForce'] ?? 0.0, 'peakForce'),
     ),
     MetricCard(
       title: 'Body Weight',
       value: results['bodyWeight'] ?? 0.0,
       unit: 'kg',
       icon: Icons.monitor_weight,
       color: Colors.purple,
       grade: PerformanceGrade.average, // No grading for body weight
     ),
     MetricCard(
       title: 'Asymmetry',
       value: results['asymmetryIndex'] ?? 0.0,
       unit: '%',
       icon: Icons.balance,
       color: (results['asymmetryIndex'] ?? 0.0) > 15 ? Colors.red : Colors.green,
       grade: _getPerformanceGrade(results['asymmetryIndex'] ?? 0.0, 'asymmetryIndex'),
     ),
   ];

   return AnimatedBuilder(
     animation: _chartAnimation,
     builder: (context, child) {
       return GridView.builder(
         shrinkWrap: true,
         physics: const NeverScrollableScrollPhysics(),
         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
           crossAxisCount: 2,
           crossAxisSpacing: 12,
           mainAxisSpacing: 12,
           childAspectRatio: 1.2,
         ),
         itemCount: metrics.length,
         itemBuilder: (context, index) {
           return Transform.scale(
             scale: _chartAnimation.value,
             child: _buildMetricCard(metrics[index]),
           );
         },
       );
     },
   );
 }

 Widget _buildMetricCard(MetricCard metric) {
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
         // Header
         Row(
           children: [
             Container(
               padding: const EdgeInsets.all(8),
               decoration: BoxDecoration(
                 color: metric.color.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(8),
               ),
               child: Icon(
                 metric.icon,
                 color: metric.color,
                 size: 20,
               ),
             ),
             const Spacer(),
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
               decoration: BoxDecoration(
                 color: _getGradeColor(metric.grade).withOpacity(0.1),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Text(
                 metric.grade.name.toUpperCase(),
                 style: TextStyle(
                   fontSize: 10,
                   fontWeight: FontWeight.bold,
                   color: _getGradeColor(metric.grade),
                 ),
               ),
             ),
           ],
         ),
         
         const SizedBox(height: 12),
         
         // Value
         RichText(
           text: TextSpan(
             children: [
               TextSpan(
                 text: metric.value.toStringAsFixed(metric.value >= 100 ? 0 : 1),
                 style: TextStyle(
                   fontSize: 24,
                   fontWeight: FontWeight.bold,
                   color: metric.color,
                 ),
               ),
               TextSpan(
                 text: ' ${metric.unit}',
                 style: const TextStyle(
                   fontSize: 14,
                   color: Colors.grey,
                 ),
               ),
             ],
           ),
         ),
         
         const SizedBox(height: 4),
         
         // Title
         Text(
           metric.title,
           style: TextStyle(
             fontSize: 12,
             fontWeight: FontWeight.w600,
             color: Colors.grey[700],
           ),
         ),
       ],
     ),
   );
 }

 Widget _buildPerformanceRadar(Map<String, double> results) {
   return Container(
     height: 300,
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
           'Performance Profile',
           style: TextStyle(
             fontSize: 18,
             fontWeight: FontWeight.bold,
             color: Color(0xFF1565C0),
           ),
         ),
         const SizedBox(height: 16),
         Expanded(
           child: AnimatedBuilder(
             animation: _chartAnimation,
             builder: (context, child) {
               return RadarChart(
                 RadarChartData(
                   radarShape: RadarShape.polygon,
                   radarBorderData: const BorderSide(color: Colors.transparent),
                   gridBorderData: BorderSide(color: Colors.grey.withOpacity(0.3)),
                   radarBackgroundColor: Colors.transparent,
                   borderData: FlBorderData(show: false),
                   tickBorderData: BorderSide(color: Colors.grey.withOpacity(0.3)),
                   ticksTextStyle: const TextStyle(fontSize: 10, color: Colors.grey),
                   dataSets: [
                     RadarDataSet(
                       fillColor: const Color(0xFF1565C0).withOpacity(0.2),
                       borderColor: const Color(0xFF1565C0),
                       borderWidth: 2,
                       dataEntries: [
                         RadarEntry(value: _normalizeForRadar(results['jumpHeight'] ?? 0.0, 'jumpHeight') * _chartAnimation.value),
                         RadarEntry(value: _normalizeForRadar(results['peakForce'] ?? 0.0, 'peakForce') * _chartAnimation.value),
                         RadarEntry(value: _normalizeForRadar(results['asymmetryIndex'] ?? 0.0, 'asymmetryIndex', isLowerBetter: true) * _chartAnimation.value),
                       ],
                     ),
                   ],
                   titleTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                   getTitle: (index, angle) {
                     switch (index) {
                       case 0:
                         return RadarChartTitle(text: 'Jump\nHeight');
                       case 1:
                         return RadarChartTitle(text: 'Peak\nForce');
                       case 2:
                         return RadarChartTitle(text: 'Symmetry');
                       default:
                         return const RadarChartTitle(text: '');
                     }
                   },
                 ),
               );
             },
           ),
         ),
       ],
     ),
   );
 }

 Widget _buildQuickInsights(Map<String, double> results) {
   final insights = _generateInsights(results);
   
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
         const Row(
           children: [
             Icon(Icons.lightbulb, color: Colors.orange, size: 20),
             SizedBox(width: 8),
             Text(
               'Key Insights',
               style: TextStyle(
                 fontSize: 18,
                 fontWeight: FontWeight.bold,
                 color: Color(0xFF1565C0),
               ),
             ),
           ],
         ),
         const SizedBox(height: 16),
         ...insights.map((insight) => Padding(
           padding: const EdgeInsets.only(bottom: 12),
           child: Row(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Container(
                 width: 6,
                 height: 6,
                 margin: const EdgeInsets.only(top: 8),
                 decoration: BoxDecoration(
                   color: insight.color,
                   shape: BoxShape.circle,
                 ),
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: Text(
                   insight.text,
                   style: const TextStyle(
                     fontSize: 14,
                     color: Colors.grey,
                     height: 1.4,
                   ),
                 ),
               ),
             ],
           ),
         )),
       ],
     ),
   );
 }

 Widget _buildDetailedView(Map<String, double> results) {
   return SingleChildScrollView(
     child: Column(
       children: [
         _buildDetailedMetricsTable(results),
         const SizedBox(height: 20),
         _buildForceTimeGraph(),
       ],
     ),
   );
 }

 Widget _buildDetailedMetricsTable(Map<String, double> results) {
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
         const Text(
           'Detailed Metrics',
           style: TextStyle(
             fontSize: 18,
             fontWeight: FontWeight.bold,
             color: Color(0xFF1565C0),
           ),
         ),
         const SizedBox(height: 16),
         Table(
           columnWidths: const {
             0: FlexColumnWidth(2),
             1: FlexColumnWidth(1),
             2: FlexColumnWidth(1),
           },
           children: [
             const TableRow(
               decoration: BoxDecoration(
                 color: Color(0xFFF8F9FA),
               ),
               children: [
                 Padding(
                   padding: EdgeInsets.all(12),
                   child: Text('Metric', style: TextStyle(fontWeight: FontWeight.bold)),
                 ),
                 Padding(
                   padding: EdgeInsets.all(12),
                   child: Text('Value', style: TextStyle(fontWeight: FontWeight.bold)),
                 ),
                 Padding(
                   padding: EdgeInsets.all(12),
                   child: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold)),
                 ),
               ],
             ),
             ...results.entries.map((entry) => TableRow(
               children: [
                 Padding(
                   padding: const EdgeInsets.all(12),
                   child: Text(_getMetricDisplayName(entry.key)),
                 ),
                 Padding(
                   padding: const EdgeInsets.all(12),
                   child: Text(_formatMetricValue(entry.key, entry.value)),
                 ),
                 Padding(
                   padding: const EdgeInsets.all(12),
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                       color: _getGradeColor(_getPerformanceGrade(entry.value, entry.key)).withOpacity(0.1),
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Text(
                       _getPerformanceGrade(entry.value, entry.key).name,
                       style: TextStyle(
                         fontSize: 12,
                         fontWeight: FontWeight.bold,
                         color: _getGradeColor(_getPerformanceGrade(entry.value, entry.key)),
                       ),
                     ),
                   ),
                 ),
               ],
             )),
           ],
         ),
       ],
     ),
   );
 }

 Widget _buildForceTimeGraph() {
   return Container(
     height: 300,
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
     child: const Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text(
           'Force-Time Curve',
           style: TextStyle(
             fontSize: 18,
             fontWeight: FontWeight.bold,
             color: Color(0xFF1565C0),
           ),
         ),
         SizedBox(height: 16),
         Expanded(
           child: Center(
             child: Text(
               'Force-time curve visualization\n(Available in full version)',
               textAlign: TextAlign.center,
               style: TextStyle(
                 fontSize: 14,
                 color: Colors.grey,
               ),
             ),
           ),
         ),
       ],
     ),
   );
 }

 Widget _buildComparisonView(Map<String, double> results) {
   return SingleChildScrollView(
     child: Column(
       children: [
         _buildNormativeComparison(results),
         const SizedBox(height: 20),
         _buildPopulationPercentiles(results),
       ],
     ),
   );
 }

 Widget _buildNormativeComparison(Map<String, double> results) {
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
         const Text(
           'Normative Comparison',
           style: TextStyle(
             fontSize: 18,
             fontWeight: FontWeight.bold,
             color: Color(0xFF1565C0),
           ),
         ),
         const SizedBox(height: 16),
         ...results.entries.where((entry) => _normativeData.containsKey(entry.key)).map(
           (entry) => Padding(
             padding: const EdgeInsets.only(bottom: 16),
             child: _buildNormativeBar(entry.key, entry.value),
           ),
         ),
       ],
     ),
   );
 }

 Widget _buildNormativeBar(String metricKey, double value) {
   final normative = _normativeData[metricKey]!;
   final grade = _getPerformanceGrade(value, metricKey);
   
   return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
       Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Text(
             _getMetricDisplayName(metricKey),
             style: const TextStyle(
               fontSize: 14,
               fontWeight: FontWeight.w600,
             ),
           ),
           Text(
             _formatMetricValue(metricKey, value),
             style: TextStyle(
               fontSize: 14,
               fontWeight: FontWeight.bold,
               color: _getGradeColor(grade),
             ),
           ),
         ],
       ),
       const SizedBox(height: 8),
       Stack(
         children: [
           // Background bar
           Container(
             height: 20,
             decoration: BoxDecoration(
               color: Colors.grey[200],
               borderRadius: BorderRadius.circular(10),
             ),
           ),
           // Grade sections
           Row(
             children: [
               Expanded(child: Container(
                 height: 20,
                 decoration: const BoxDecoration(
                   color: Colors.red,
                   borderRadius: BorderRadius.only(
                     topLeft: Radius.circular(10),
                     bottomLeft: Radius.circular(10),
                   ),
                 ),
               )),
               Expanded(child: Container(height: 20, color: Colors.orange)),
               Expanded(child: Container(height: 20, color: Colors.yellow)),
               Expanded(child: Container(height: 20, color: Colors.lightGreen)),
               Expanded(child: Container(
                 height: 20,
                 decoration: const BoxDecoration(
                   color: Colors.green,
                   borderRadius: BorderRadius.only(
                     topRight: Radius.circular(10),
                     bottomRight: Radius.circular(10),
                   ),
                 ),
               )),
             ],
           ),
           // Value indicator
           Positioned(
             left: _calculateNormativePosition(value, normative) * MediaQuery.of(context).size.width * 0.6,
             child: Container(
               width: 4,
               height: 20,
               decoration: BoxDecoration(
                 color: Colors.black,
                 borderRadius: BorderRadius.circular(2),
               ),
             ),
           ),
         ],
       ),
       const SizedBox(height: 4),
       Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Text('Poor', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
           Text('Excellent', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
         ],
       ),
     ],
   );
 }

 Widget _buildPopulationPercentiles(Map<String, double> results) {
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
     child: const Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text(
           'Population Percentiles',
           style: TextStyle(
             fontSize: 18,
             fontWeight: FontWeight.bold,
             color: Color(0xFF1565C0),
           ),
         ),
         SizedBox(height: 16),
         Center(
           child: Text(
             'Population comparison data\n(Available in full version)',
             textAlign: TextAlign.center,
             style: TextStyle(
               fontSize: 14,
               color: Colors.grey,
             ),
           ),
         ),
       ],
     ),
   );
 }

 Widget _buildHistoryView(ValdTestFlowController flowController) {
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
         Row(
           children: [
             const Icon(Icons.history, color: Color(0xFF1565C0), size: 20),
             const SizedBox(width: 8),
             const Text(
               'Test History',
               style: TextStyle(
                 fontSize: 18,
                 fontWeight: FontWeight.bold,
                 color: Color(0xFF1565C0),
               ),
             ),
             const Spacer(),
             Text(
               flowController.selectedAthlete?.fullName ?? 'Unknown',
               style: TextStyle(
                 fontSize: 14,
                 color: Colors.grey[600],
               ),
             ),
           ],
         ),
         const SizedBox(height: 20),
         Expanded(
           child: Center(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Icon(
                   Icons.timeline,
                   size: 64,
                   color: Colors.grey[400],
                 ),
                 const SizedBox(height: 16),
                 const Text(
                   'No Previous Tests',
                   style: TextStyle(
                     fontSize: 18,
                     fontWeight: FontWeight.bold,
                     color: Colors.grey,
                   ),
                 ),
                 const SizedBox(height: 8),
                 Text(
                   'This is the first test for this athlete.\nFuture tests will show progress tracking.',
                   textAlign: TextAlign.center,
                   style: TextStyle(
                     fontSize: 14,
                     color: Colors.grey[600],
                   ),
                 ),
                 const SizedBox(height: 24),
                 OutlinedButton.icon(
                   onPressed: () => setState(() => _selectedView = ResultsView.summary),
                   icon: const Icon(Icons.arrow_back),
                   label: const Text('Back to Summary'),
                   style: OutlinedButton.styleFrom(
                     foregroundColor: const Color(0xFF1565C0),
                     side: const BorderSide(color: Color(0xFF1565C0)),
                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                   ),
                 ),
               ],
             ),
           ),
         ),
       ],
     ),
   );
 }

 Widget _buildActionButtons(ValdTestFlowController flowController) {
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
         // Share Results
         Expanded(
           child: OutlinedButton.icon(
             onPressed: () => _shareResults(flowController.testResults!),
             icon: const Icon(Icons.share),
             label: const Text('Share Results'),
             style: OutlinedButton.styleFrom(
               foregroundColor: const Color(0xFF1565C0),
               side: const BorderSide(color: Color(0xFF1565C0)),
               padding: const EdgeInsets.symmetric(vertical: 16),
               shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(12),
               ),
             ),
           ),
         ),
         
         const SizedBox(width: 16),
         
         // Save & Continue
         Expanded(
           child: ElevatedButton.icon(
             onPressed: () => _saveAndContinue(flowController),
             icon: const Icon(Icons.save),
             label: const Text('Save & New Test'),
             style: ElevatedButton.styleFrom(
               backgroundColor: Colors.green,
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

 // Helper Methods
 PerformanceGrade _getPerformanceGrade(double value, String metricKey) {
   final normative = _normativeData[metricKey];
   if (normative == null) return PerformanceGrade.average;
   
   if (normative.isLowerBetter) {
     if (value <= normative.excellent) return PerformanceGrade.excellent;
     if (value <= normative.aboveAverage) return PerformanceGrade.aboveAverage;
     if (value <= normative.average) return PerformanceGrade.average;
     if (value <= normative.belowAverage) return PerformanceGrade.belowAverage;
     return PerformanceGrade.poor;
   } else {
     if (value >= normative.excellent) return PerformanceGrade.excellent;
     if (value >= normative.aboveAverage) return PerformanceGrade.aboveAverage;
     if (value >= normative.average) return PerformanceGrade.average;
     if (value >= normative.belowAverage) return PerformanceGrade.belowAverage;
     return PerformanceGrade.poor;
   }
 }

 Color _getGradeColor(PerformanceGrade grade) {
   switch (grade) {
     case PerformanceGrade.excellent:
       return Colors.green;
     case PerformanceGrade.aboveAverage:
       return Colors.lightGreen;
     case PerformanceGrade.average:
       return Colors.orange;
     case PerformanceGrade.belowAverage:
       return Colors.deepOrange;
     case PerformanceGrade.poor:
       return Colors.red;
   }
 }

 double _normalizeForRadar(double value, String metricKey, {bool isLowerBetter = false}) {
   final normative = _normativeData[metricKey];
   if (normative == null) return 0.5;
   
   if (isLowerBetter) {
     return (1.0 - ((value - normative.excellent) / (normative.poor - normative.excellent))).clamp(0.0, 1.0);
   } else {
     return ((value - normative.poor) / (normative.excellent - normative.poor)).clamp(0.0, 1.0);
   }
 }

 double _calculateNormativePosition(double value, NormativeRange normative) {
   final range = normative.excellent - normative.poor;
   final position = (value - normative.poor) / range;
   return position.clamp(0.0, 1.0);
 }

 String _getMetricDisplayName(String key) {
   switch (key) {
     case 'jumpHeight':
       return 'Jump Height';
     case 'peakForce':
       return 'Peak Force';
     case 'bodyWeight':
       return 'Body Weight';
     case 'asymmetryIndex':
       return 'Asymmetry Index';
     default:
       return key;
   }
 }

 String _formatMetricValue(String key, double value) {
   switch (key) {
     case 'jumpHeight':
       return '${value.toStringAsFixed(1)} cm';
     case 'peakForce':
       return '${value.toStringAsFixed(0)} N';
     case 'bodyWeight':
       return '${value.toStringAsFixed(1)} kg';
     case 'asymmetryIndex':
       return '${value.toStringAsFixed(1)}%';
     default:
       return value.toStringAsFixed(1);
   }
 }

 IconData _getViewIcon(ResultsView view) {
   switch (view) {
     case ResultsView.summary:
       return Icons.dashboard;
     case ResultsView.detailed:
       return Icons.table_chart;
     case ResultsView.comparison:
       return Icons.compare_arrows;
     case ResultsView.history:
       return Icons.history;
   }
 }

 String _getViewTitle(ResultsView view) {
   switch (view) {
     case ResultsView.summary:
       return 'Summary';
     case ResultsView.detailed:
       return 'Detailed';
     case ResultsView.comparison:
       return 'Compare';
     case ResultsView.history:
       return 'History';
   }
 }

 List<Insight> _generateInsights(Map<String, double> results) {
   final insights = <Insight>[];
   
   final jumpHeight = results['jumpHeight'] ?? 0.0;
   final asymmetry = results['asymmetryIndex'] ?? 0.0;
   final peakForce = results['peakForce'] ?? 0.0;
   
   // Jump height insight
   if (jumpHeight > 35) {
     insights.add(Insight(
       text: 'Excellent explosive power! Your jump height of ${jumpHeight.toStringAsFixed(1)}cm is above average.',
       color: Colors.green,
     ));
   } else if (jumpHeight < 25) {
     insights.add(Insight(
       text: 'Focus on explosive power training to improve jump height from ${jumpHeight.toStringAsFixed(1)}cm.',
       color: Colors.orange,
     ));
   }
   
   // Asymmetry insight
   if (asymmetry > 15) {
     insights.add(Insight(
       text: 'High asymmetry detected (${asymmetry.toStringAsFixed(1)}%). Consider unilateral strength training.',
       color: Colors.red,
     ));
   } else if (asymmetry < 10) {
     insights.add(Insight(
       text: 'Excellent bilateral balance with ${asymmetry.toStringAsFixed(1)}% asymmetry.',
       color: Colors.green,
     ));
   }
   
   // Peak force insight
   if (peakForce > 2500) {
     insights.add(Insight(
       text: 'Strong force production capability with ${peakForce.toStringAsFixed(0)}N peak force.',
       color: Colors.blue,
     ));
   }
   
   // Default insight if none generated
   if (insights.isEmpty) {
     insights.add(Insight(
       text: 'Test completed successfully. Continue regular training to maintain performance.',
       color: Colors.blue,
     ));
   }
   
   return insights;
 }

 void _shareResults(Map<String, double> results) {
   showDialog(
     context: context,
     builder: (context) => AlertDialog(
       title: const Text('Share Results'),
       content: const Text(
         'Results sharing functionality will be available in the full version.\n\nFeatures will include:\n• PDF report generation\n• Email sharing\n• Cloud storage integration',
       ),
       actions: [
         TextButton(
           onPressed: () => Navigator.of(context).pop(),
           child: const Text('OK'),
         ),
       ],
     ),
   );
 }

 void _saveAndContinue(ValdTestFlowController flowController) {
   // In a real app, save to database here
   showDialog(
     context: context,
     builder: (context) => AlertDialog(
       title: const Text('Results Saved'),
       content: const Text('Test results have been saved successfully!'),
       actions: [
         TextButton(
           onPressed: () {
             Navigator.of(context).pop();
             flowController.restartFlow();
           },
           child: const Text('Start New Test'),
         ),
       ],
     ),
   );
 }

 @override
 void dispose() {
   _resultsAnimationController.dispose();
   _celebrationController.dispose();
   _chartAnimationController.dispose();
   super.dispose();
 }
}

// Supporting Classes and Enums
enum ResultsView {
 summary,
 detailed,
 comparison,
 history,
}

enum PerformanceGrade {
 poor,
 belowAverage,
 average,
 aboveAverage,
 excellent,
}

class MetricCard {
 final String title;
 final double value;
 final String unit;
 final IconData icon;
 final Color color;
 final PerformanceGrade grade;

 MetricCard({
   required this.title,
   required this.value,
   required this.unit,
   required this.icon,
   required this.color,
   required this.grade,
 });
}

class NormativeRange {
 final double poor;
 final double belowAverage;
 final double average;
 final double aboveAverage;
 final double excellent;
 final bool isLowerBetter;

 NormativeRange({
   required this.poor,
   required this.belowAverage,
   required this.average,
   required this.aboveAverage,
   required this.excellent,
   this.isLowerBetter = false,
 });
}

class Insight {
 final String text;
 final Color color;

 Insight({
   required this.text,
   required this.color,
 });
}