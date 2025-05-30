// lib/presentation/widgets/vald_flow_widgets/profile_selection_widget.dart - FIXED OVERFLOW & RESPONSIVE
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/vald_test_flow_controller.dart';
import '../../controllers/athlete_controller.dart';
import '../../../domain/entities/athlete.dart';
import '../../../app/injection_container.dart';

class ProfileSelectionWidget extends StatefulWidget {
  const ProfileSelectionWidget({super.key});

  @override
  State<ProfileSelectionWidget> createState() => _ProfileSelectionWidgetState();
}

class _ProfileSelectionWidgetState extends State<ProfileSelectionWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _listAnimationController;
  late AnimationController _selectionAnimationController;
  late Animation<double> _listSlideAnimation;
  late Animation<double> _selectionScale;
  
  final TextEditingController _searchController = TextEditingController();
  List<Athlete> _filteredAthletes = [];
  Athlete? _selectedAthlete;
  bool _isSearching = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _searchController.addListener(_onSearchChanged);
    
    // ✅ FIXED: Load athletes safely without causing setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitialized) {
        _loadAthletesFromController();
      }
    });
  }

  void _initializeAnimations() {
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _listSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listAnimationController, curve: Curves.easeOutCubic),
    );
    
    _selectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _selectionScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _selectionAnimationController, curve: Curves.easeInOut),
    );
  }

  // ✅ FIXED: Safe athlete loading
  void _loadAthletesFromController() async {
    try {
      final athleteController = context.read<AthleteController>();
      
      // Ensure athletes are loaded
      if (athleteController.totalAthletes == 0) {
        await athleteController.loadAthletes();
      }
      
      if (mounted) {
        setState(() {
          _filteredAthletes = List.from(athleteController.athletes);
          _isInitialized = true;
        });
        _listAnimationController.forward();
      }
    } catch (e) {
      debugPrint('❌ Error loading athletes: $e');
      if (mounted) {
        setState(() {
          _filteredAthletes = [];
          _isInitialized = true;
        });
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    
    if (!mounted || !_isInitialized) return;
    
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        final athleteController = context.read<AthleteController>();
        _filteredAthletes = List.from(athleteController.athletes);
      } else {
        final athleteController = context.read<AthleteController>();
        _filteredAthletes = athleteController.athletes.where((athlete) {
          return athlete.firstName.toLowerCase().contains(query) ||
                 athlete.lastName.toLowerCase().contains(query) ||
                 athlete.fullName.toLowerCase().contains(query) ||
                 (athlete.sport?.toLowerCase().contains(query) ?? false) ||
                 (athlete.team?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  void _selectAthlete(Athlete athlete) {
    if (!mounted) return;
    
    setState(() {
      _selectedAthlete = athlete;
    });
    
    _selectionAnimationController.forward().then((_) {
      if (mounted) {
        _selectionAnimationController.reverse();
      }
    });
    
    // Update flow controller
    final flowController = context.read<ValdTestFlowController>();
    flowController.selectAthlete(athlete);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ValdTestFlowController>(
      builder: (context, flowController, child) {
        return SingleChildScrollView( // ✅ FIXED: Added ScrollView to prevent overflow
          padding: const EdgeInsets.all(12), // ✅ FIXED: Reduced padding
          child: Column(
            children: [
              // Header
              _buildCompactHeader(),
              
              const SizedBox(height: 12), // ✅ FIXED: Reduced spacing
              
              // Search Bar
              _buildSearchBar(),
              
              const SizedBox(height: 12),
              
              // Selected Athlete Display
              if (_selectedAthlete != null) ...[
                _buildSelectedAthleteCard(),
                const SizedBox(height: 12),
              ],
              
              // Athletes List - ✅ FIXED: Made properly scrollable
              SizedBox(
                height: 350, // ✅ FIXED: Increased height for better usability
                child: _buildAthletesList(),
              ),
              
              const SizedBox(height: 12),
              
              // Quick Actions
              _buildQuickActions(),
            ],
          ),
        );
      },
    );
  }

  // ✅ FIXED: More compact and responsive header
  Widget _buildCompactHeader() {
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
                  Icons.person_search,
                  color: Color(0xFF1565C0),
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Title and Subtitle - ✅ FIXED: Better overflow handling
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Athlete',
                      style: TextStyle(
                        fontSize: 18, // ✅ FIXED: Smaller font
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                      overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                    ),
                    Text(
                      'Choose athlete for testing',
                      style: TextStyle(
                        fontSize: 12, // ✅ FIXED: Smaller font
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Stats Row - ✅ FIXED: More responsive layout
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IntrinsicHeight( // ✅ FIXED: Better height management
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(child: _buildCompactStatItem('Athletes', _filteredAthletes.length.toString())),
                  Container(width: 1, color: Colors.grey[300]),
                  Expanded(child: _buildCompactStatItem('Selected', _selectedAthlete != null ? '1' : '0')),
                  Container(width: 1, color: Colors.grey[300]),
                  Expanded(child: _buildCompactStatItem('Ready', _selectedAthlete != null ? 'Yes' : 'No')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min, // ✅ FIXED: Added mainAxisSize
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
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
          textAlign: TextAlign.center, // ✅ FIXED: Center align
          overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(4),
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
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search athletes...',
          hintStyle: TextStyle(
            fontSize: 14, // ✅ FIXED: Smaller hint text
            color: Colors.grey[500],
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0), size: 20), // ✅ FIXED: Smaller icon
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 18), // ✅ FIXED: Smaller icon
                  onPressed: () {
                    _searchController.clear();
                  },
                  iconSize: 18, // ✅ FIXED: Explicit icon size
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // ✅ FIXED: Reduced padding
        ),
        style: const TextStyle(fontSize: 14), // ✅ FIXED: Consistent font size
      ),
    );
  }

  Widget _buildSelectedAthleteCard() {
    if (_selectedAthlete == null) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _selectionScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _selectionScale.value,
          child: Container(
            padding: const EdgeInsets.all(14), // ✅ FIXED: Reduced padding
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
                // Avatar
                CircleAvatar(
                  radius: 22, // ✅ FIXED: Smaller avatar
                  backgroundColor: _selectedAthlete!.gender == 'M' 
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.pink.withOpacity(0.1),
                  child: Text(
                    _selectedAthlete!.firstName.isNotEmpty && _selectedAthlete!.lastName.isNotEmpty
                        ? _selectedAthlete!.firstName[0].toUpperCase() + 
                          _selectedAthlete!.lastName[0].toUpperCase()
                        : '??', // ✅ FIXED: Safe string access
                    style: TextStyle(
                      fontSize: 14, // ✅ FIXED: Smaller font
                      fontWeight: FontWeight.bold,
                      color: _selectedAthlete!.gender == 'M' ? Colors.blue : Colors.pink,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Info - ✅ FIXED: Better overflow handling
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 14), // ✅ FIXED: Smaller icon
                          SizedBox(width: 4), // ✅ FIXED: Reduced spacing
                          Flexible( // ✅ FIXED: Wrapped in Flexible
                            child: Text(
                              'Selected Athlete',
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
                      const SizedBox(height: 4),
                      Text(
                        _selectedAthlete!.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                        overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedAthlete!.displayInfo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                        maxLines: 1, // ✅ FIXED: Limit lines
                      ),
                    ],
                  ),
                ),
                
                // Change Button
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedAthlete = null;
                    });
                    // ✅ FIXED: Just clear local state, don't call flow controller with null
                    // The flow controller will be updated when a new athlete is selected
                  },
                  icon: const Icon(Icons.edit, color: Colors.grey, size: 18), // ✅ FIXED: Smaller icon
                  tooltip: 'Change Selection',
                  iconSize: 18, // ✅ FIXED: Explicit icon size
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAthletesList() {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
        ),
      );
    }

    if (_filteredAthletes.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _listSlideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _listSlideAnimation.value) * 15), // ✅ FIXED: Reduced animation distance
          child: Opacity(
            opacity: _listSlideAnimation.value,
            child: Container(
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
                  // List Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.people, color: Color(0xFF1565C0), size: 18),
                        const SizedBox(width: 6),
                        Expanded( // ✅ FIXED: Wrapped in Expanded
                          child: Text(
                            _isSearching 
                                ? 'Results (${_filteredAthletes.length})'
                                : 'All Athletes (${_filteredAthletes.length})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1565C0),
                            ),
                            overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Athletes List - ✅ FIXED: Proper scrolling with better performance
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16), // ✅ FIXED: Optimized padding
                      itemCount: _filteredAthletes.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey[200],
                        height: 1,
                        thickness: 0.5, // ✅ FIXED: Thinner divider
                      ),
                      itemBuilder: (context, index) {
                        final athlete = _filteredAthletes[index];
                        final isSelected = _selectedAthlete?.id == athlete.id;
                        
                        return _buildAthleteListItem(athlete, isSelected);
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

  Widget _buildAthleteListItem(Athlete athlete, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectAthlete(athlete),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), // ✅ FIXED: Optimized padding
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1565C0).withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected 
                ? Border.all(color: const Color(0xFF1565C0).withOpacity(0.3))
                : null,
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 18, // ✅ FIXED: Smaller avatar for list
                backgroundColor: athlete.gender == 'M' 
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.pink.withOpacity(0.1),
                child: Text(
                  athlete.firstName.isNotEmpty && athlete.lastName.isNotEmpty
                      ? athlete.firstName[0].toUpperCase() + athlete.lastName[0].toUpperCase()
                      : '??', // ✅ FIXED: Safe string access
                  style: TextStyle(
                    fontSize: 12, // ✅ FIXED: Smaller font
                    fontWeight: FontWeight.bold,
                    color: athlete.gender == 'M' ? Colors.blue : Colors.pink,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Info - ✅ FIXED: Better overflow handling
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      athlete.fullName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFF1565C0) : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                    ),
                    const SizedBox(height: 2),
                    Text(
                      athlete.displayInfo,
                      style: TextStyle(
                        fontSize: 11, // ✅ FIXED: Smaller font
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
                      maxLines: 1, // ✅ FIXED: Limit lines
                    ),
                  ],
                ),
              ),
              
              // Selection Indicator
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? const Color(0xFF1565C0) : Colors.grey[400],
                size: 18, // ✅ FIXED: Smaller icon
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSearching ? Icons.search_off : Icons.person_add,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            _isSearching ? 'No athletes found' : 'No athletes available',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center, // ✅ FIXED: Center align
          ),
          const SizedBox(height: 6),
          Text(
            _isSearching 
                ? 'Try a different search term'
                : 'Athletes will appear here when loaded',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center, // ✅ FIXED: Center align
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
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
      child: Row(
        children: [
          // Continue Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _selectedAthlete != null 
                  ? () {
                      final flowController = context.read<ValdTestFlowController>();
                      flowController.proceedToTestSelection();
                    }
                  : null,
              icon: const Icon(Icons.arrow_forward, size: 18), // ✅ FIXED: Smaller icon
              label: const Text(
                'Continue',
                overflow: TextOverflow.ellipsis, // ✅ FIXED: Added overflow handling
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12), // ✅ FIXED: Consistent padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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

  @override
  void dispose() {
    _listAnimationController.dispose();
    _selectionAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}