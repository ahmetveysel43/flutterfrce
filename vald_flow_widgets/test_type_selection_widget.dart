// lib/presentation/widgets/vald_flow_widgets/test_type_selection_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/vald_test_flow_controller.dart';
import '../../../core/constants/test_constants.dart';

class TestTypeSelectionWidget extends StatefulWidget {
  const TestTypeSelectionWidget({super.key});

  @override
  State<TestTypeSelectionWidget> createState() => _TestTypeSelectionWidgetState();
}

class _TestTypeSelectionWidgetState extends State<TestTypeSelectionWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _gridAnimationController;
  late AnimationController _selectionController;
  late Animation<double> _gridAnimation;
  late Animation<double> _selectionScale;
  
  TestType? _selectedTestType;
  TestCategory _selectedCategory = TestCategory.jump;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _gridAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _gridAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gridAnimationController, curve: Curves.easeOutBack),
    );
    
    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _selectionScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _selectionController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _gridAnimationController.forward();
  }

  void _selectTestType(TestType testType) {
    setState(() {
      _selectedTestType = testType;
    });
    
    _selectionController.forward().then((_) {
      _selectionController.reverse();
    });
    
    // Update flow controller
    final flowController = context.read<ValdTestFlowController>();
    flowController.selectTestType(testType);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ValdTestFlowController>(
      builder: (context, flowController, child) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              _buildHeader(flowController),
              
              const SizedBox(height: 24),
              
              // Test Categories
              _buildCategorySelector(),
              
              const SizedBox(height: 20),
              
              // Selected Test Display
              if (_selectedTestType != null) ...[
                _buildSelectedTestCard(),
                const SizedBox(height: 20),
              ],
              
              // Test Types Grid
              Expanded(
                child: _buildTestTypesGrid(),
              ),
              
              const SizedBox(height: 20),
              
              // Continue Button
              _buildContinueButton(flowController),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ValdTestFlowController flowController) {
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
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment,
              color: Color(0xFF1565C0),
              size: 32,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Title
          const Text(
            'Choose Test Type',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Subtitle with athlete info
          Text(
            'Select the test for ${flowController.selectedAthlete?.fullName ?? 'the athlete'}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Test Categories Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem('Jump Tests', '4 Types'),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                _buildInfoItem('Balance Tests', '1 Type'),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                _buildInfoItem('Strength Tests', '1 Type'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: TestCategory.values.map((category) {
          final isSelected = _selectedCategory == category;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
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
                      _getCategoryIcon(category),
                      size: 18,
                      color: isSelected ? const Color(0xFF1565C0) : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getCategoryTitle(category),
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

  Widget _buildSelectedTestCard() {
    return AnimatedBuilder(
      animation: _selectionScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _selectionScale.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.1),
                  Colors.green.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
            ),
            child: Row(
              children: [
                // Test Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getTestTypeColor(_selectedTestType!).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTestTypeIcon(_selectedTestType!),
                    color: _getTestTypeColor(_selectedTestType!),
                    size: 28,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Test Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                           'Selected Test',
                           style: TextStyle(
                             fontSize: 12,
                             color: Colors.green,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 4),
                     Text(
                       TestConstants.testNames[_selectedTestType!] ?? 'Unknown Test',
                       style: const TextStyle(
                         fontSize: 18,
                         fontWeight: FontWeight.bold,
                         color: Color(0xFF1565C0),
                       ),
                     ),
                     const SizedBox(height: 4),
                     Text(
                       TestConstants.testDescriptions[_selectedTestType!] ?? '',
                       style: TextStyle(
                         fontSize: 14,
                         color: Colors.grey[600],
                       ),
                     ),
                     const SizedBox(height: 8),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                       decoration: BoxDecoration(
                         color: _getTestTypeColor(_selectedTestType!).withOpacity(0.1),
                         borderRadius: BorderRadius.circular(20),
                       ),
                       child: Text(
                         'Duration: ${TestConstants.testDurations[_selectedTestType!]?.inSeconds ?? 0}s',
                         style: TextStyle(
                           fontSize: 12,
                           fontWeight: FontWeight.bold,
                           color: _getTestTypeColor(_selectedTestType!),
                         ),
                       ),
                     ),
                   ],
                 ),
               ),
               
               // Change Button
               IconButton(
                 onPressed: () {
                   setState(() {
                     _selectedTestType = null;
                   });
                 },
                 icon: const Icon(Icons.edit, color: Colors.grey),
                 tooltip: 'Change Selection',
               ),
             ],
           ),
         ),
       );
     },
   );
 }

 Widget _buildTestTypesGrid() {
   final filteredTests = _getTestsForCategory(_selectedCategory);
   
   return AnimatedBuilder(
     animation: _gridAnimation,
     builder: (context, child) {
       return Transform.translate(
         offset: Offset(0, (1 - _gridAnimation.value) * 50),
         child: Opacity(
           opacity: _gridAnimation.value,
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
                 Row(
                   children: [
                     Icon(
                       _getCategoryIcon(_selectedCategory),
                       color: const Color(0xFF1565C0),
                       size: 20,
                     ),
                     const SizedBox(width: 8),
                     Text(
                       '${_getCategoryTitle(_selectedCategory)} Tests',
                       style: const TextStyle(
                         fontSize: 18,
                         fontWeight: FontWeight.bold,
                         color: Color(0xFF1565C0),
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 16),
                 Expanded(
                   child: GridView.builder(
                     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                       crossAxisCount: 2,
                       crossAxisSpacing: 16,
                       mainAxisSpacing: 16,
                       childAspectRatio: 0.85,
                     ),
                     itemCount: filteredTests.length,
                     itemBuilder: (context, index) {
                       final testType = filteredTests[index];
                       final isSelected = _selectedTestType == testType;
                       
                       return _buildTestTypeCard(testType, isSelected, index);
                     },
                   ),
                 ),
               ],
             ),
           ),
         ),
       );
     },
   );
 }

 Widget _buildTestTypeCard(TestType testType, bool isSelected, int index) {
   final color = _getTestTypeColor(testType);
   
   return AnimatedBuilder(
     animation: _gridAnimation,
     builder: (context, child) {
       return Transform.scale(
         scale: 0.5 + (_gridAnimation.value * 0.5),
         child: Material(
           color: Colors.transparent,
           child: InkWell(
             onTap: () => _selectTestType(testType),
             borderRadius: BorderRadius.circular(16),
             child: AnimatedContainer(
               duration: const Duration(milliseconds: 200),
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(
                 color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(
                   color: isSelected ? color : Colors.grey.withOpacity(0.3),
                   width: isSelected ? 2 : 1,
                 ),
                 boxShadow: isSelected ? [
                   BoxShadow(
                     color: color.withOpacity(0.2),
                     blurRadius: 8,
                     offset: const Offset(0, 4),
                   ),
                 ] : null,
               ),
               child: Column(
                 children: [
                   // Test Icon
                   Container(
                     width: 60,
                     height: 60,
                     decoration: BoxDecoration(
                       color: color.withOpacity(isSelected ? 0.2 : 0.1),
                       borderRadius: BorderRadius.circular(16),
                     ),
                     child: Icon(
                       _getTestTypeIcon(testType),
                       color: color,
                       size: 32,
                     ),
                   ),
                   
                   const SizedBox(height: 12),
                   
                   // Test Name
                   Text(
                     TestConstants.testNames[testType] ?? 'Unknown',
                     textAlign: TextAlign.center,
                     style: TextStyle(
                       fontSize: 14,
                       fontWeight: FontWeight.bold,
                       color: isSelected ? color : Colors.black87,
                     ),
                   ),
                   
                   const SizedBox(height: 8),
                   
                   // Test Description
                   Text(
                     TestConstants.testDescriptions[testType] ?? '',
                     textAlign: TextAlign.center,
                     maxLines: 2,
                     overflow: TextOverflow.ellipsis,
                     style: TextStyle(
                       fontSize: 12,
                       color: Colors.grey[600],
                       height: 1.3,
                     ),
                   ),
                   
                   const Spacer(),
                   
                   // Test Duration
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                       color: color.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Text(
                       '${TestConstants.testDurations[testType]?.inSeconds ?? 0}s',
                       style: TextStyle(
                         fontSize: 12,
                         fontWeight: FontWeight.bold,
                         color: color,
                       ),
                     ),
                   ),
                   
                   const SizedBox(height: 8),
                   
                   // Selection Indicator
                   AnimatedContainer(
                     duration: const Duration(milliseconds: 200),
                     width: 24,
                     height: 24,
                     decoration: BoxDecoration(
                       color: isSelected ? color : Colors.transparent,
                       shape: BoxShape.circle,
                       border: Border.all(
                         color: isSelected ? color : Colors.grey,
                         width: 2,
                       ),
                     ),
                     child: isSelected
                         ? const Icon(
                             Icons.check,
                             color: Colors.white,
                             size: 16,
                           )
                         : null,
                   ),
                 ],
               ),
             ),
           ),
         ),
       );
     },
   );
 }

 Widget _buildContinueButton(ValdTestFlowController flowController) {
   return SizedBox(
     width: double.infinity,
     child: ElevatedButton.icon(
       onPressed: _selectedTestType != null 
           ? () => flowController.proceedToZeroCalibration()
           : null,
       icon: const Icon(Icons.arrow_forward),
       label: const Text('Continue to Zero Calibration'),
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
   );
 }

 // Helper Methods
 List<TestType> _getTestsForCategory(TestCategory category) {
   switch (category) {
     case TestCategory.jump:
       return [
         TestType.counterMovementJump,
         TestType.squatJump,
         TestType.dropJump,
         TestType.landing,
       ];
     case TestCategory.balance:
       return [TestType.balance];
     case TestCategory.strength:
       return [TestType.isometric];
   }
 }

 IconData _getCategoryIcon(TestCategory category) {
   switch (category) {
     case TestCategory.jump:
       return Icons.trending_up;
     case TestCategory.balance:
       return Icons.balance;
     case TestCategory.strength:
       return Icons.fitness_center;
   }
 }

 String _getCategoryTitle(TestCategory category) {
   switch (category) {
     case TestCategory.jump:
       return 'Jump';
     case TestCategory.balance:
       return 'Balance';
     case TestCategory.strength:
       return 'Strength';
   }
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
       return Icons.padding;
   }
 }

 Color _getTestTypeColor(TestType testType) {
   switch (testType) {
     case TestType.counterMovementJump:
       return const Color(0xFF1565C0);
     case TestType.squatJump:
       return Colors.green;
     case TestType.dropJump:
       return Colors.orange;
     case TestType.balance:
       return Colors.purple;
     case TestType.isometric:
       return Colors.red;
     case TestType.landing:
       return Colors.teal;
   }
 }

 @override
 void dispose() {
   _gridAnimationController.dispose();
   _selectionController.dispose();
   super.dispose();
 }
}

// Test Categories Enum
enum TestCategory {
 jump,
 balance,
 strength,
}