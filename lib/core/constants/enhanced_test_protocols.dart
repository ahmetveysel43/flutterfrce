// lib/presentation/widgets/vald_flow_widgets/enhanced_test_selection_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/vald_test_flow_controller.dart';
import '../../../core/constants/test_constants.dart';
import '../../../core/constants/enhanced_test_protocols.dart';

class EnhancedTestSelectionWidget extends StatefulWidget {
  const EnhancedTestSelectionWidget({super.key});

  @override
  State<EnhancedTestSelectionWidget> createState() => _EnhancedTestSelectionWidgetState();
}

class _EnhancedTestSelectionWidgetState extends State<EnhancedTestSelectionWidget>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  TestCategory _selectedCategory = TestCategory.jump;
  TestDifficulty? _selectedDifficulty;
  String? _selectedSport;
  bool _showTurkish = false;
  
  final List<String> _popularSports = [
    'Basketball', 'Volleyball', 'Soccer', 'Tennis', 'Track & Field',
    'Football', 'Rugby', 'Wrestling', 'Gymnastics', 'Swimming'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: TestCategory.values.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedCategory = TestCategory.values[_tabController.index];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ValdTestFlowController>(
      builder: (context, controller, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with filters
              _buildHeader(),
              
              const SizedBox(height: 20),
              
              // Filter Row
              _buildFilterRow(),
              
              const SizedBox(height: 20),
              
              // Category Tabs
              _buildCategoryTabs(),
              
              const SizedBox(height: 20),
              
              // Test Grid
              Expanded(
                child: _buildTestGrid(controller),
              ),
              
              const SizedBox(height: 20),
              
              // Action Buttons
              _buildActionButtons(controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _showTurkish ? 'Test Türü Seçin' : 'Choose Test Type',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _showTurkish 
                    ? '18 farklı test protokolünden sporcunuza uygun olanı seçin'
                    : 'Select the appropriate test from 18 different protocols for your athlete',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        // Language Toggle
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageButton('EN', !_showTurkish),
              _buildLanguageButton('TR', _showTurkish),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _showTurkish = text == 'TR'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1565C0) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        // Difficulty Filter
        _buildFilterChip(
          label: _showTurkish ? 'Zorluk' : 'Difficulty',
          value: _selectedDifficulty?.name,
          onTap: () => _showDifficultyDialog(),
          icon: Icons.trending_up,
        ),
        
        // Sport Filter
        _buildFilterChip(
          label: _showTurkish ? 'Spor' : 'Sport',
          value: _selectedSport,
          onTap: () => _showSportDialog(),
          icon: Icons.sports,
        ),
        
        // Clear Filters
        if (_selectedDifficulty != null || _selectedSport != null)
          _buildClearFiltersButton(),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    String? value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value != null ? const Color(0xFF1565C0).withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value != null ? const Color(0xFF1565C0) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: value != null ? const Color(0xFF1565C0) : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              value ?? label,
              style: TextStyle(
                color: value != null ? const Color(0xFF1565C0) : Colors.grey[600],
                fontSize: 12,
                fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: value != null ? const Color(0xFF1565C0) : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearFiltersButton() {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedDifficulty = null;
        _selectedSport = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.clear, size: 16, color: Colors.red[600]),
            const SizedBox(width: 4),
            Text(
              _showTurkish ? 'Temizle' : 'Clear',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: const Color(0xFF1565C0),
          borderRadius: BorderRadius.circular(20),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabs: TestCategory.values.map((category) {
          return Tab(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getCategoryIcon(category), size: 16),
                  const SizedBox(width: 6),
                  Text(_showTurkish ? category.turkishName : category.name),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTestGrid(ValdTestFlowController controller) {
    final tests = _getFilteredTests();
    
    if (tests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _showTurkish ? 'Filtrelere uygun test bulunamadı' : 'No tests found matching filters',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: tests.length,
      itemBuilder: (context, index) {
        final testType = tests[index];
        final protocol = TestConstants.getProtocol(testType)!;
        final isSelected = controller.selectedTestType == testType;
        
        return _buildTestCard(
          testType: testType,
          protocol: protocol,
          isSelected: isSelected,
          onTap: () => controller.selectTestType(testType),
        );
      },
    );
  }

  Widget _buildTestCard({
    required TestType testType,
    required TestProtocol protocol,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final difficulty = TestConstants.testDifficulty[testType]!;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1565C0) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1565C0) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? const Color(0xFF1565C0).withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.1),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Colors.white.withValues(alpha: 0.2)
                          : const Color(0xFF1565C0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTestIcon(testType),
                      color: isSelected ? Colors.white : const Color(0xFF1565C0),
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: difficulty.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _showTurkish ? difficulty.turkishName : difficulty.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: difficulty.color,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Test Name
              Text(
                _showTurkish ? protocol.turkishName : protocol.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF1565C0),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Description
              Text(
                _showTurkish ? protocol.turkishDescription : protocol.description,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white70 : Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const Spacer(),
              
              // Duration
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: isSelected ? Colors.white70 : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${protocol.duration.inSeconds}s',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 16,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ValdTestFlowController controller) {
    return Row(
      children: [
        // Test Details Button
        if (controller.selectedTestType != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showTestDetails(controller.selectedTestType!),
              icon: const Icon(Icons.info_outline, size: 18),
              label: Text(_showTurkish ? 'Test Detayları' : 'Test Details'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF1565C0)),
                foregroundColor: const Color(0xFF1565C0),
              ),
            ),
          ),
        
        if (controller.selectedTestType != null) const SizedBox(width: 16),
        
        // Continue Button
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: controller.selectedTestType != null 
                ? () => controller.proceedToZeroCalibration()
                : null,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: Text(_showTurkish ? 'Kalibrasyon' : 'Calibration'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
            ),
          ),
        ),
      ],
    );
  }

  List<TestType> _getFilteredTests() {
    var tests = TestConstants.getTestsByCategory(_selectedCategory);
    
    if (_selectedDifficulty != null) {
      tests = tests.where((test) => 
        TestConstants.testDifficulty[test] == _selectedDifficulty
      ).toList();
    }
    
    if (_selectedSport != null) {
      tests = tests.where((test) =>
        TestConstants.recommendedSports[test]?.contains(_selectedSport) ?? false
      ).toList();
    }
    
    return tests;
  }

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_showTurkish ? 'Zorluk Seviyesi' : 'Difficulty Level'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TestDifficulty.values.map((difficulty) {
            return ListTile(
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: difficulty.color,
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(_showTurkish ? difficulty.turkishName : difficulty.name),
              onTap: () {
                setState(() => _selectedDifficulty = difficulty);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_showTurkish ? 'Spor Seçin' : 'Select Sport'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _popularSports.length,
            itemBuilder: (context, index) {
              final sport = _popularSports[index];
              return ListTile(
                leading: const Icon(Icons.sports),
                title: Text(sport),
                onTap: () {
                  setState(() => _selectedSport = sport);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showTestDetails(TestType testType) {
    final protocol = TestConstants.getProtocol(testType)!;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(_getTestIcon(testType), color: const Color(0xFF1565C0)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _showTurkish ? protocol.turkishName : protocol.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      Text(
                        _showTurkish ? protocol.turkishDescription : protocol.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Instructions
                      Text(
                        _showTurkish ? 'Talimatlar:' : 'Instructions:',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(_showTurkish ? protocol.turkishInstructions : protocol.instructions)
                          .map((instruction) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ', style: TextStyle(fontSize: 14)),
                                    Expanded(
                                      child: Text(instruction, style: const TextStyle(fontSize: 14)),
                                    ),
                                  ],
                                ),
                              )),
                      
                      const SizedBox(height: 20),
                      
                      // Sport Recommendations
                      Text(
                        _showTurkish ? 'Önerilen Sporlar:' : 'Recommended Sports:',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: protocol.sportRecommendations.map((sport) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              sport.split(':')[0], // Show only sport name
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1565C0),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(TestCategory category) {
    switch (category) {
      case TestCategory.jump:
        return Icons.trending_up;
      case TestCategory.balance:
        return Icons.balance;
      case TestCategory.isometric:
        return Icons.fitness_center;
      case TestCategory.landing:
        return Icons.flight_land;
      case TestCategory.reactive:
        return Icons.flash_on;
      case TestCategory.power:
        return Icons.power;
      case TestCategory.endurance:
        return Icons.timer;
      case TestCategory.rehabilitation:
        return Icons.healing;
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}