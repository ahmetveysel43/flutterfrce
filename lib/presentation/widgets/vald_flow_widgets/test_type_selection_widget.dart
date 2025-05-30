// lib/presentation/widgets/vald_flow_widgets/test_type_selection_widget.dart - OVERFLOW COMPLETELY FIXED
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
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              _buildCompactHeader(flowController),
              
              const SizedBox(height: 16),
              
              // Test Categories
              _buildCategorySelector(),
              
              const SizedBox(height: 16),
              
              // Selected Test Display
              if (_selectedTestType != null) ...[
                _buildSelectedTestCard(),
                const SizedBox(height: 16),
              ],
              
              // Test Types Grid
              SizedBox(
                height: 380, // ✅ FIXED: Increased height slightly for better spacing
                child: _buildTestTypesGrid(),
              ),
              
              const SizedBox(height: 16),
              
              // Continue Button
              _buildContinueButton(flowController),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactHeader(ValdTestFlowController flowController) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon and Title Row
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment,
                  color: Color(0xFF1565C0),
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Title and Subtitle - ✅ FIXED: Better text overflow handling
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose Test Type',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                      overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                    ),
                    Text(
                      'Test for ${flowController.selectedAthlete?.fullName ?? 'athlete'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Test Categories Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _buildInfoItem('Jump Tests', '4')), // ✅ FIXED: Wrapped in Expanded
                Container(width: 1, height: 20, color: Colors.grey[300]),
                Expanded(child: _buildInfoItem('Balance', '1')), // ✅ FIXED: Wrapped in Expanded
                Container(width: 1, height: 20, color: Colors.grey[300]),
                Expanded(child: _buildInfoItem('Strength', '1')), // ✅ FIXED: Wrapped in Expanded
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
          overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center, // ✅ FIXED: Center align text
          overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: TestCategory.values.map((category) {
          final isSelected = _selectedCategory == category;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // ✅ FIXED: Added mainAxisSize
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      size: 16,
                      color: isSelected ? const Color(0xFF1565C0) : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Flexible( // ✅ FIXED: Wrapped text in Flexible
                      child: Text(
                        _getCategoryTitle(category),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF1565C0) : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
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
    if (_selectedTestType == null) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _selectionScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _selectionScale.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.1),
                  Colors.green.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
            ),
            child: Row(
              children: [
                // Test Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getTestTypeColor(_selectedTestType!).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTestTypeIcon(_selectedTestType!),
                    color: _getTestTypeColor(_selectedTestType!),
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Test Info - ✅ FIXED: Better text overflow handling
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 6),
                          Flexible( // ✅ FIXED: Wrapped in Flexible
                            child: Text(
                              'Selected Test',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        TestConstants.testNames[_selectedTestType!] ?? 'Unknown Test',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                        overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                      ),
                      const SizedBox(height: 2),
                      Text(
                        TestConstants.testDescriptions[_selectedTestType!] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                  icon: const Icon(Icons.edit, color: Colors.grey, size: 18),
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
          offset: Offset(0, (1 - _gridAnimation.value) * 20),
          child: Opacity(
            opacity: _gridAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
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
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible( // ✅ FIXED: Wrapped in Flexible
                        child: Text(
                          '${_getCategoryTitle(_selectedCategory)} Tests',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                          overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Grid with better spacing
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0, // ✅ FIXED: Made cards more square for better text fit
                      ),
                      itemCount: filteredTests.length,
                      itemBuilder: (context, index) {
                        final testType = filteredTests[index];
                        final isSelected = _selectedTestType == testType;
                        
                        return _buildCompactTestTypeCard(testType, isSelected, index);
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

  // ✅ COMPLETELY FIXED: Much better overflow handling for test cards
  Widget _buildCompactTestTypeCard(TestType testType, bool isSelected, int index) {
    final color = _getTestTypeColor(testType);
    
    return AnimatedBuilder(
      animation: _gridAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.7 + (_gridAnimation.value * 0.3),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectTestType(testType),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8), // ✅ FIXED: Reduced padding for more space
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Test Icon
                    Container(
                      width: 36, // ✅ FIXED: Made smaller to leave more room for text
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(isSelected ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getTestTypeIcon(testType),
                        color: color,
                        size: 18, // ✅ FIXED: Smaller icon
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Test Name - ✅ COMPLETELY FIXED: Better text handling
                    Flexible( // ✅ FIXED: Use Flexible instead of fixed height
                      child: Text(
                        _getShortTestName(testType), // ✅ FIXED: Use shorter names
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11, // ✅ FIXED: Slightly smaller font
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : Colors.black87,
                        ),
                        maxLines: 2, // ✅ FIXED: Allow up to 2 lines
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Test Duration
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${TestConstants.testDurations[testType]?.inSeconds ?? 0}s',
                        style: TextStyle(
                          fontSize: 9, // ✅ FIXED: Smaller font
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Selection Indicator
                    Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected ? color : Colors.grey,
                      size: 14, // ✅ FIXED: Smaller icon
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ✅ NEW: Helper method for shorter test names to prevent overflow
  String _getShortTestName(TestType testType) {
    switch (testType) {
      case TestType.counterMovementJump:
        return 'Counter\nMovement'; // ✅ FIXED: Split long names
      case TestType.squatJump:
        return 'Squat Jump';
      case TestType.dropJump:
        return 'Drop Jump';
      case TestType.balance:
        return 'Balance';
      case TestType.isometric:
        return 'Isometric';
      case TestType.landing:
        return 'Landing';
    }
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