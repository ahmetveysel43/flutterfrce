// lib/presentation/widgets/vald_flow_widgets/weight_measurement_widget.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/vald_test_flow_controller.dart';
import '../../controllers/usb_controller.dart';

class WeightMeasurementWidget extends StatefulWidget {
 const WeightMeasurementWidget({super.key});

 @override
 State<WeightMeasurementWidget> createState() => _WeightMeasurementWidgetState();
}

class _WeightMeasurementWidgetState extends State<WeightMeasurementWidget>
   with TickerProviderStateMixin {
 
 // Animation controllers
 late AnimationController _scaleAnimationController;
 late AnimationController _stabilityAnimationController;
 late AnimationController _successAnimationController;
 
 // Animations
 late Animation<double> _scaleAnimation;
 late Animation<Color?> _stabilityColorAnimation;
 late Animation<double> _successScale;
 
 // Weight measurement state
 final List<double> _weightSamples = [];
 double? _currentWeight;
 double? _stableWeight;
 bool _isWeightStable = false;
 bool _isPersonOnPlatform = false;
 double _stabilityScore = 0.0;
 Timer? _measurementTimer;
 
 // Stability thresholds (VALD standards)
 static const double _stabilityThreshold = 0.5; // kg
 static const int _requiredStableSamples = 30; // 3 seconds at 10Hz
 static const double _minimumWeight = 30.0; // kg
 static const double _maximumWeight = 200.0; // kg
 
 // UI state
 String _instructionText = 'Step onto both platforms';
 Color _instructionColor = Colors.grey;
 IconData _statusIcon = Icons.monitor_weight;

 @override
 void initState() {
   super.initState();
   _initializeAnimations();
   _startWeightMeasurement();
 }

 void _initializeAnimations() {
   // Scale animation for weight display
   _scaleAnimationController = AnimationController(
     duration: const Duration(milliseconds: 300),
     vsync: this,
   );
   _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
     CurvedAnimation(parent: _scaleAnimationController, curve: Curves.elasticOut),
   );
   
   // Stability color animation
   _stabilityAnimationController = AnimationController(
     duration: const Duration(milliseconds: 800),
     vsync: this,
   );
   _stabilityColorAnimation = ColorTween(
     begin: Colors.orange,
     end: Colors.green,
   ).animate(CurvedAnimation(
     parent: _stabilityAnimationController,
     curve: Curves.easeInOut,
   ));
   
   // Success animation
   _successAnimationController = AnimationController(
     duration: const Duration(milliseconds: 500),
     vsync: this,
   );
   _successScale = Tween<double>(begin: 1.0, end: 1.2).animate(
     CurvedAnimation(parent: _successAnimationController, curve: Curves.elasticOut),
   );
 }

 void _startWeightMeasurement() {
   _measurementTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
     if (!mounted) {
       timer.cancel();
       return;
     }
     
     final usbController = context.read<UsbController>();
     final latestData = usbController.latestForceData;
     
     if (latestData != null) {
       _processWeightData(latestData.totalGRF);
     }
   });
 }

 void _processWeightData(double totalForce) {
   // Convert force to weight (subtract zero offset, convert N to kg)
   final flowController = context.read<ValdTestFlowController>();
   final zeroOffset = flowController.zeroOffsetLeft + flowController.zeroOffsetRight;
   final weightKg = (totalForce - zeroOffset) / 9.81;
   
   setState(() {
     _currentWeight = weightKg;
     
     // Check if person is on platform
     _isPersonOnPlatform = weightKg > _minimumWeight && weightKg < _maximumWeight;
     
     if (_isPersonOnPlatform) {
       _weightSamples.add(weightKg);
       
       // Keep only recent samples for stability calculation
       while (_weightSamples.length > 50) { // 5 seconds of data
         _weightSamples.removeAt(0);
       }
       
       _calculateStability();
       _updateInstructions();
       
     } else {
       // Clear samples when person steps off
       _weightSamples.clear();
       _isWeightStable = false;
       _stableWeight = null;
       _stabilityScore = 0.0;
       _updateInstructionsForEmpty();
     }
   });
 }

 void _calculateStability() {
   if (_weightSamples.length < 10) return;
   
   // Calculate recent stability using last 30 samples
   final recentSamples = _weightSamples.length >= _requiredStableSamples
       ? _weightSamples.sublist(_weightSamples.length - _requiredStableSamples)
       : _weightSamples;
   
   // Calculate mean and standard deviation
   final mean = recentSamples.reduce((a, b) => a + b) / recentSamples.length;
   final variance = recentSamples
       .map((w) => math.pow(w - mean, 2))
       .reduce((a, b) => a + b) / recentSamples.length;
   final stdDev = math.sqrt(variance);
   
   // Update stability metrics
   _stabilityScore = (1.0 - (stdDev / _stabilityThreshold)).clamp(0.0, 1.0);
   _isWeightStable = stdDev < _stabilityThreshold && recentSamples.length >= _requiredStableSamples;
   
   if (_isWeightStable && _stableWeight == null) {
     // First time achieving stability
     _stableWeight = mean;
     _onWeightStabilized();
   } else if (_isWeightStable) {
     // Update stable weight with running average
     _stableWeight = mean;
   }
 }

 void _updateInstructions() {
   if (_isWeightStable) {
     _instructionText = 'Weight measurement complete';
     _instructionColor = Colors.green;
     _statusIcon = Icons.check_circle;
     _stabilityAnimationController.forward();
   } else if (_stabilityScore > 0.7) {
     _instructionText = 'Hold still... measuring';
     _instructionColor = Colors.blue;
     _statusIcon = Icons.hourglass_empty;
   } else if (_stabilityScore > 0.3) {
     _instructionText = 'Stand still on both platforms';
     _instructionColor = Colors.orange;
     _statusIcon = Icons.accessibility;
   } else {
     _instructionText = 'Minimize movement';
     _instructionColor = Colors.red;
     _statusIcon = Icons.warning;
   }
 }

 void _updateInstructionsForEmpty() {
   _instructionText = 'Step onto both platforms';
   _instructionColor = Colors.grey;
   _statusIcon = Icons.monitor_weight;
   _stabilityAnimationController.reverse();
 }

 void _onWeightStabilized() {
   // Trigger success animation
   _successAnimationController.forward();
   
   // Update flow controller
   final flowController = context.read<ValdTestFlowController>();
   // The controller will automatically detect the stable weight
   
   // Auto-advance after 2 seconds of stability
   Timer(const Duration(seconds: 2), () {
     if (_isWeightStable && mounted) {
       flowController.proceedToTesting();
     }
   });
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
             
             // Weight Display
             Expanded(
               child: _buildWeightDisplay(),
             ),
             
             const SizedBox(height: 32),
             
             // Platform Visualization
             _buildPlatformVisualization(),
             
             const SizedBox(height: 24),
             
             // Continue Button
             _buildContinueButton(flowController),
           ],
         ),
       );
     },
   );
 }

 Widget _buildInstructionsHeader() {
   return AnimatedBuilder(
     animation: _stabilityColorAnimation,
     builder: (context, child) {
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
             // Status Icon
             AnimatedBuilder(
               animation: _successScale,
               builder: (context, child) {
                 return Transform.scale(
                   scale: _successScale.value,
                   child: Container(
                     width: 64,
                     height: 64,
                     decoration: BoxDecoration(
                       color: _instructionColor.withOpacity(0.1),
                       shape: BoxShape.circle,
                     ),
                     child: Icon(
                       _statusIcon,
                       color: _instructionColor,
                       size: 32,
                     ),
                   ),
                 );
               },
             ),
             
             const SizedBox(height: 16),
             
             // Title
             const Text(
               'Body Weight Measurement',
               style: TextStyle(
                 fontSize: 24,
                 fontWeight: FontWeight.bold,
                 color: Color(0xFF1565C0),
               ),
             ),
             
             const SizedBox(height: 8),
             
             // Dynamic Instructions
             AnimatedSwitcher(
               duration: const Duration(milliseconds: 300),
               child: Text(
                 _instructionText,
                 key: ValueKey(_instructionText),
                 textAlign: TextAlign.center,
                 style: TextStyle(
                   fontSize: 16,
                   color: _instructionColor,
                   fontWeight: FontWeight.w600,
                 ),
               ),
             ),
             
             const SizedBox(height: 16),
             
             // Stability Progress
             if (_isPersonOnPlatform) ...[
               Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: _instructionColor.withOpacity(0.05),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(
                     color: _instructionColor.withOpacity(0.2),
                   ),
                 ),
                 child: Column(
                   children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         const Text(
                           'Stability',
                           style: TextStyle(
                             fontSize: 14,
                             fontWeight: FontWeight.w600,
                           ),
                         ),
                         Text(
                           '${(_stabilityScore * 100).toInt()}%',
                           style: TextStyle(
                             fontSize: 14,
                             fontWeight: FontWeight.bold,
                             color: _instructionColor,
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 8),
                     LinearProgressIndicator(
                       value: _stabilityScore,
                       backgroundColor: Colors.grey[300],
                       valueColor: AlwaysStoppedAnimation<Color>(_instructionColor),
                       minHeight: 6,
                     ),
                   ],
                 ),
               ),
             ],
           ],
         ),
       );
     },
   );
 }

 Widget _buildWeightDisplay() {
   return AnimatedBuilder(
     animation: _scaleAnimation,
     builder: (context, child) {
       return Transform.scale(
         scale: _scaleAnimation.value,
         child: Container(
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
               // Weight Value
               if (_currentWeight != null && _isPersonOnPlatform) ...[
                 Text(
                   (_stableWeight ?? _currentWeight!).toStringAsFixed(1),
                   style: const TextStyle(
                     fontSize: 72,
                     fontWeight: FontWeight.bold,
                     color: Color(0xFF1565C0),
                   ),
                 ),
                 const Text(
                   'kg',
                   style: TextStyle(
                     fontSize: 24,
                     color: Colors.grey,
                   ),
                 ),
                 
                 const SizedBox(height: 16),
                 
                 // BMI Calculation (if stable)
                 if (_stableWeight != null) ...[
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     decoration: BoxDecoration(
                       color: Colors.green.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(20),
                     ),
                     child: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         const Icon(
                           Icons.fitness_center,
                           color: Colors.green,
                           size: 16,
                         ),
                         const SizedBox(width: 8),
                         Text(
                           'Weight: ${_stableWeight!.toStringAsFixed(1)} kg',
                           style: const TextStyle(
                             fontSize: 14,
                             fontWeight: FontWeight.bold,
                             color: Colors.green,
                           ),
                         ),
                       ],
                     ),
                   ),
                 ],
                 
               ] else ...[
                 // Empty State
                 const Icon(
                   Icons.monitor_weight,
                   size: 64,
                   color: Colors.grey,
                 ),
                 const SizedBox(height: 16),
                 const Text(
                   '--.-',
                   style: TextStyle(
                     fontSize: 72,
                     fontWeight: FontWeight.bold,
                     color: Colors.grey,
                   ),
                 ),
                 const Text(
                   'kg',
                   style: TextStyle(
                     fontSize: 24,
                     color: Colors.grey,
                   ),
                 ),
               ],
             ],
           ),
         ),
       );
     },
   );
 }

 Widget _buildPlatformVisualization() {
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
         // Left Platform
         Expanded(
           child: _buildSinglePlatformVisual(
             'Left Platform',
             _currentWeight != null ? _currentWeight! * 0.48 : 0,
             const Color(0xFF1565C0),
           ),
         ),
         
         const SizedBox(width: 24),
         
         // Weight Distribution Indicator
         Column(
           children: [
             const Icon(
               Icons.balance,
               color: Colors.grey,
               size: 24,
             ),
             const SizedBox(height: 8),
             if (_isPersonOnPlatform && _currentWeight != null) ...[
               Text(
                 'Balance',
                 style: TextStyle(
                   fontSize: 12,
                   color: Colors.grey[600],
                 ),
               ),
               const SizedBox(height: 4),
               // Simple balance indicator
               Container(
                 width: 4,
                 height: 40,
                 decoration: BoxDecoration(
                   color: _stabilityScore > 0.7 ? Colors.green : Colors.orange,
                   borderRadius: BorderRadius.circular(2),
                 ),
               ),
             ],
           ],
         ),
         
         const SizedBox(width: 24),
         
         // Right Platform
         Expanded(
           child: _buildSinglePlatformVisual(
             'Right Platform',
             _currentWeight != null ? _currentWeight! * 0.52 : 0,
             Colors.green,
           ),
         ),
       ],
     ),
   );
 }

 Widget _buildSinglePlatformVisual(String title, double weight, Color color) {
   final isActive = weight > 10; // More than 10kg indicates person is on it
   
   return Column(
     children: [
       Text(
         title,
         style: TextStyle(
           fontSize: 14,
           fontWeight: FontWeight.w600,
           color: Colors.grey[700],
         ),
       ),
       const SizedBox(height: 12),
       
       // Platform Visual
       AnimatedContainer(
         duration: const Duration(milliseconds: 300),
         width: 80,
         height: 120,
         decoration: BoxDecoration(
           color: isActive ? color.withOpacity(0.2) : color.withOpacity(0.05),
           borderRadius: BorderRadius.circular(12),
           border: Border.all(
             color: isActive ? color : color.withOpacity(0.3),
             width: isActive ? 3 : 2,
           ),
         ),
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(
               isActive ? Icons.person : Icons.person_outline,
               color: isActive ? color : Colors.grey,
               size: 32,
             ),
             const SizedBox(height: 8),
             Text(
               '${weight.toStringAsFixed(1)}kg',
               style: TextStyle(
                 fontSize: 12,
                 fontWeight: FontWeight.bold,
                 color: isActive ? color : Colors.grey,
               ),
             ),
           ],
         ),
       ),
     ],
   );
 }

 Widget _buildContinueButton(ValdTestFlowController flowController) {
   return SizedBox(
     width: double.infinity,
     child: ElevatedButton.icon(
       onPressed: _isWeightStable ? () => flowController.proceedToTesting() : null,
       icon: Icon(_isWeightStable ? Icons.check : Icons.hourglass_empty),
       label: Text(_isWeightStable ? 'Continue to Test' : 'Measuring Weight...'),
       style: ElevatedButton.styleFrom(
         backgroundColor: _isWeightStable ? Colors.green : Colors.grey,
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
   );
 }

 @override
 void dispose() {
   _scaleAnimationController.dispose();
   _stabilityAnimationController.dispose();
   _successAnimationController.dispose();
   _measurementTimer?.cancel();
   super.dispose();
 }
}