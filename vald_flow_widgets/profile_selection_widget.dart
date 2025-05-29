// lib/presentation/widgets/vald_flow_widgets/profile_selection_widget.dart
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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAthletes();
    _searchController.addListener(_onSearchChanged);
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

  void _loadAthletes() async {
    final athleteController = sl<AthleteController>();
    await athleteController.loadAthletes();
    
    if (mounted) {
      setState(() {
        _filteredAthletes = athleteController.athletes;
      });
      _listAnimationController.forward();
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    final athleteController = sl<AthleteController>();
    
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredAthletes = athleteController.athletes;
      } else {
        _filteredAthletes = athleteController.athletes.where((athlete) {
          return athlete.firstName.toLowerCase().contains(query) ||
                 athlete.lastName.toLowerCase().contains(query) ||
                 athlete.fullName.toLowerCase().contains(query) ||
                 (athlete.sport?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  void _selectAthlete(Athlete athlete) {
    setState(() {
      _selectedAthlete = athlete;
    });
    
    _selectionAnimationController.forward().then((_) {
      _selectionAnimationController.reverse();
    });
    
    // Update flow controller
    final flowController = context.read<ValdTestFlowController>();
    flowController.selectAthlete(athlete);
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
              _buildHeader(),
              
              const SizedBox(height: 24),
              
              // Search Bar
              _buildSearchBar(),
              
              const SizedBox(height: 20),
              
              // Selected Athlete Display
              if (_selectedAthlete != null) ...[
                _buildSelectedAthleteCard(),
                const SizedBox(height: 20),
              ],
              
              // Athletes List
              Expanded(
                child: _buildAthletesList(),
              ),
              
              const SizedBox(height: 20),
              
              // Quick Actions
              _buildQuickActions(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
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
              Icons.person_search,
              color: Color(0xFF1565C0),
              size: 32,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Title
          const Text(
            'Select Athlete Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            'Choose the athlete who will perform the test',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Athletes', _filteredAthletes.length.toString()),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                _buildStatItem('Selected', _selectedAthlete != null ? '1' : '0'),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                _buildStatItem('Ready', _selectedAthlete != null ? 'Yes' : 'No'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(4),
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
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search athletes by name or sport...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0)),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSelectedAthleteCard() {
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
                // Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _selectedAthlete!.gender == 'M' 
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.pink.withOpacity(0.1),
                  child: Text(
                    _selectedAthlete!.firstName[0].toUpperCase() + 
                    _selectedAthlete!.lastName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _selectedAthlete!.gender == 'M' ? Colors.blue : Colors.pink,
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Selected Athlete',
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
                        _selectedAthlete!.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedAthlete!.displayInfo,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
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
                    final flowController = context.read<ValdTestFlowController>();
                    flowController.selectAthlete(_selectedAthlete!);
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

  Widget _buildAthletesList() {
    if (_filteredAthletes.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _listSlideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _listSlideAnimation.value) * 50),
          child: Opacity(
            opacity: _listSlideAnimation.value,
            child: Container(
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
                  // List Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.people, color: Color(0xFF1565C0), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _isSearching 
                              ? 'Search Results (${_filteredAthletes.length})'
                              : 'All Athletes (${_filteredAthletes.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Athletes List
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filteredAthletes.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey[200],
                        height: 1,
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1565C0).withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected 
                ? Border.all(color: const Color(0xFF1565C0).withOpacity(0.3))
                : null,
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: athlete.gender == 'M' 
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.pink.withOpacity(0.1),
                child: Text(
                  athlete.firstName[0].toUpperCase() + athlete.lastName[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: athlete.gender == 'M' ? Colors.blue : Colors.pink,
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      athlete.fullName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFF1565C0) : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      athlete.displayInfo,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (athlete.phone != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        athlete.phone!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Selection Indicator
              if (isSelected) ...[
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF1565C0),
                  size: 24,
                ),
              ] else ...[
                Icon(
                  Icons.radio_button_unchecked,
                  color: Colors.grey[400],
                  size: 24,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSearching ? Icons.search_off : Icons.person_add,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _isSearching ? 'No athletes found' : 'No athletes available',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSearching 
                ? 'Try a different search term'
                : 'Add athletes to start testing',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddAthleteDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add New Athlete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
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
          // Add New Athlete
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showAddAthleteDialog(),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Athlete'),
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
          
          // Continue Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _selectedAthlete != null 
                  ? () {
                      final flowController = context.read<ValdTestFlowController>();
                      flowController.proceedToTestSelection();
                    }
                  : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue'),
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

  void _showAddAthleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Athlete'),
        content: const Text(
          'Athlete management functionality will be available in the athlete management section.\n\nFor now, you can select from existing athletes or add athletes through the main menu.',
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

  @override
  void dispose() {
    _listAnimationController.dispose();
    _selectionAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}