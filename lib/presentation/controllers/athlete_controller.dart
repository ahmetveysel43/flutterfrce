// lib/presentation/controllers/athlete_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:izLab/core/extensions/list_extensions.dart';
import '../../domain/entities/athlete.dart';
import '../../core/constants/test_constants.dart';
import '../../services/database_service.dart';
import '../../app/injection_container.dart';

/// VALD ForceDecks benzeri sporcu profil yönetimi
class AthleteController extends ChangeNotifier {
  DatabaseService? _databaseService;
  
  // State
  List<Athlete> _athletes = [];
  List<Athlete> _filteredAthletes = [];
  Athlete? _selectedAthlete;
  AthleteFilter _currentFilter = const AthleteFilter();
  bool _isLoading = false;
  String? _errorMessage;
  
  // Search and filter
  String _searchQuery = '';
  String? _selectedSport;
  String? _selectedTeam;
  String? _selectedGender;
  bool _showActiveOnly = true;

  // Constructor with safe initialization
  AthleteController() {
    try {
      if (sl.isRegistered<DatabaseService>()) {
        _databaseService = sl<DatabaseService>();
      }
    } catch (e) {
      debugPrint('❌ Database service not available: $e');
      // Will use fallback methods
    }
  }

  // Getters
  List<Athlete> get athletes => List.unmodifiable(_athletes);
  List<Athlete> get filteredAthletes => List.unmodifiable(_filteredAthletes);
  Athlete? get selectedAthlete => _selectedAthlete;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Filter getters
  String get searchQuery => _searchQuery;
  String? get selectedSport => _selectedSport;
  String? get selectedTeam => _selectedTeam;
  String? get selectedGender => _selectedGender;
  bool get showActiveOnly => _showActiveOnly;
  
  // Statistics
  int get totalAthletes => _athletes.length;
  int get activeAthletes => _athletes.where((a) => a.isActive).length;
  int get filteredCount => _filteredAthletes.length;
  
  // Quick access lists
  List<String> get availableSports => _athletes.uniqueSports;
  List<String> get availableTeams => _athletes.uniqueTeams;
  
  Map<String, int> get athletesBySport {
    final map = <String, int>{};
    for (final athlete in _athletes) {
      final sport = athlete.sport ?? 'Unknown';
      map[sport] = (map[sport] ?? 0) + 1;
    }
    return map;
  }
  
  Map<String, int> get athletesByGender {
    final map = <String, int>{};
    for (final athlete in _athletes) {
      final gender = athlete.genderDisplay;
      map[gender] = (map[gender] ?? 0) + 1;
    }
    return map;
  }

  /// Sporcuları yükle
  Future<void> loadAthletes() async {
    _setLoading(true);
    _clearError();
    
    try {
      debugPrint('👥 Sporcular yükleniyor...');
      
      // Try to load from database first
      if (_databaseService != null) {
        try {
          _athletes = await _databaseService!.getAllAthletes();
          debugPrint('✅ Database\'den ${_athletes.length} sporcu yüklendi');
        } catch (e) {
          debugPrint('❌ Database hatası: $e, mock data kullanılıyor');
          _athletes = Athlete.createMockAthletes();
        }
      } else {
        // Fallback to mock data
        debugPrint('⚠️ Database service yok, mock data kullanılıyor');
        _athletes = Athlete.createMockAthletes();
      }
      
      // Apply current filter
      _applyFilters();
      
      debugPrint('✅ ${_athletes.length} sporcu yüklendi');
      
    } catch (e) {
      _setError('Sporcular yüklenirken hata: $e');
      debugPrint('❌ Sporcu yükleme hatası: $e');
      // Fallback to empty list
      _athletes = [];
      _applyFilters();
    } finally {
      _setLoading(false);
    }
  }

  /// Yeni sporcu ekle
  Future<bool> addAthlete(Athlete athlete) async {
    _setLoading(true);
    _clearError();
    
    try {
      debugPrint('➕ Yeni sporcu ekleniyor: ${athlete.fullName}');
      
      // Check for duplicate names
      final existingAthlete = await _databaseService?.findAthleteByName(
        athlete.firstName, 
        athlete.lastName
      );
      
      if (existingAthlete != null) {
        throw Exception('Bu isimde bir sporcu zaten mevcut');
      }
      
      // Insert to database
      await _databaseService?.insertAthlete(athlete);
      
      // Reload athletes
      await loadAthletes();
      
      debugPrint('✅ Sporcu başarıyla eklendi: ${athlete.fullName}');
      return true;
      
    } catch (e) {
      _setError('Sporcu eklenirken hata: $e');
      debugPrint('❌ Sporcu ekleme hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sporcu güncelle
  Future<bool> updateAthlete(Athlete updatedAthlete) async {
    _setLoading(true);
    _clearError();
    
    try {
      debugPrint('📝 Sporcu güncelleniyor: ${updatedAthlete.fullName}');
      
      // Update in database
      final success = await _databaseService?.updateAthlete(updatedAthlete);
      
      if (!success!) {
        throw Exception('Sporcu güncellenemedi');
      }
      
      // Update selected athlete if it's the same one
      if (_selectedAthlete?.id == updatedAthlete.id) {
        _selectedAthlete = updatedAthlete;
      }
      
      // Reload athletes
      await loadAthletes();
      
      debugPrint('✅ Sporcu başarıyla güncellendi: ${updatedAthlete.fullName}');
      return true;
      
    } catch (e) {
      _setError('Sporcu güncellenirken hata: $e');
      debugPrint('❌ Sporcu güncelleme hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sporcu sil
  Future<bool> deleteAthlete(String athleteId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final athlete = await _databaseService?.getAthlete(athleteId);
      if (athlete == null) {
        throw Exception('Sporcu bulunamadı');
      }
      
      debugPrint('🗑️ Sporcu siliniyor: ${athlete.fullName}');
      
      // Delete from database
      final success = await _databaseService?.deleteAthlete(athleteId);
      
      if (!success!) {
        throw Exception('Sporcu silinemedi');
      }
      
      // Clear selection if deleted athlete was selected
      if (_selectedAthlete?.id == athleteId) {
        _selectedAthlete = null;
      }
      
      // Reload athletes
      await loadAthletes();
      
      debugPrint('✅ Sporcu başarıyla silindi: ${athlete.fullName}');
      return true;
      
    } catch (e) {
      _setError('Sporcu silinirken hata: $e');
      debugPrint('❌ Sporcu silme hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sporcu seç
  void selectAthlete(Athlete? athlete) {
    _selectedAthlete = athlete;
    debugPrint('👤 Seçilen sporcu: ${athlete?.fullName ?? 'Hiçbiri'}');
    notifyListeners();
  }

  /// ID ile sporcu bul
  Athlete? getAthleteById(String id) {
    try {
      return _athletes.where((a) => a.id == id).first;
    } catch (e) {
      return null;
    }
  }

  /// Search query ayarla
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _updateFilter();
      debugPrint('🔍 Arama sorgusu: "$query"');
    }
  }

  /// Sport filter ayarla
  void setSportFilter(String? sport) {
    if (_selectedSport != sport) {
      _selectedSport = sport;
      _updateFilter();
      debugPrint('🏃 Spor filtresi: ${sport ?? 'Tümü'}');
    }
  }

  /// Team filter ayarla
  void setTeamFilter(String? team) {
    if (_selectedTeam != team) {
      _selectedTeam = team;
      _updateFilter();
      debugPrint('👥 Takım filtresi: ${team ?? 'Tümü'}');
    }
  }

  /// Gender filter ayarla
  void setGenderFilter(String? gender) {
    if (_selectedGender != gender) {
      _selectedGender = gender;
      _updateFilter();
      debugPrint('⚧ Cinsiyet filtresi: ${gender ?? 'Tümü'}');
    }
  }

  /// Active only filter toggle
  void setShowActiveOnly(bool activeOnly) {
    if (_showActiveOnly != activeOnly) {
      _showActiveOnly = activeOnly;
      _updateFilter();
      debugPrint('✅ Sadece aktif sporcular: $activeOnly');
    }
  }

  /// Tüm filtreleri temizle
  void clearFilters() {
    _searchQuery = '';
    _selectedSport = null;
    _selectedTeam = null;
    _selectedGender = null;
    _showActiveOnly = true;
    _updateFilter();
    debugPrint('🧹 Filtreler temizlendi');
  }

  /// Filtreleri güncelle
  void _updateFilter() {
    _currentFilter = AthleteFilter(
      searchTerm: _searchQuery.isEmpty ? null : _searchQuery,
      sport: _selectedSport,
      gender: _selectedGender,
      team: _selectedTeam,
      isActive: _showActiveOnly ? true : null,
    );
    _applyFilters();
  }

  /// Filtreleri uygula
  void _applyFilters() {
    _filteredAthletes = _athletes.filter(_currentFilter).sortByName();
    notifyListeners();
  }

  /// Sporcu ağırlığını güncelle (test sonrası)
  void updateAthleteWeight(String athleteId, double weightKg) {
    final athlete = getAthleteById(athleteId);
    if (athlete != null) {
      final updatedAthlete = athlete.copyWith(weight: weightKg);
      updateAthlete(updatedAthlete);
      debugPrint('⚖️ Sporcu ağırlığı güncellendi: ${athlete.fullName} → ${weightKg}kg');
    }
  }

  /// Batch operations
  
  /// Birden fazla sporcu ekle
  Future<int> addMultipleAthletes(List<Athlete> athletes) async {
    _setLoading(true);
    int successCount = 0;
    
    try {
      for (final athlete in athletes) {
        try {
          // Simulate delay between additions
          await Future.delayed(const Duration(milliseconds: 100));
          
          // Check for duplicates
          final exists = _athletes.any(
            (a) => a.firstName == athlete.firstName && a.lastName == athlete.lastName
          );
          
          if (!exists) {
            _athletes.add(athlete);
            successCount++;
          }
        } catch (e) {
          debugPrint('❌ Sporcu eklenemedi: ${athlete.fullName} - $e');
        }
      }
      
      _applyFilters();
      debugPrint('✅ Batch ekleme tamamlandı: $successCount/${athletes.length}');
      
    } finally {
      _setLoading(false);
    }
    
    return successCount;
  }

  /// Export athletes to JSON
  String exportAthletesToJson() {
    final data = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'totalAthletes': _athletes.length,
      'athletes': _athletes.map((a) => a.toJson()).toList(),
    };
    
    return jsonEncode(data);
  }

  /// Import athletes from JSON
  Future<int> importAthletesFromJson(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      final athletesData = data['athletes'] as List;
      
      final importedAthletes = athletesData
          .map((json) => Athlete.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return await addMultipleAthletes(importedAthletes);
      
    } catch (e) {
      _setError('JSON import hatası: $e');
      return 0;
    }
  }

  /// Quick stats
  Map<String, dynamic> getQuickStats() {
    return {
      'totalAthletes': totalAthletes,
      'activeAthletes': activeAthletes,
      'inactiveAthletes': totalAthletes - activeAthletes,
      'averageAge': _athletes.isNotEmpty 
          ? _athletes.where((a) => a.age != null).map((a) => a.age!).reduce((a, b) => a + b) / _athletes.where((a) => a.age != null).length
          : 0,
      'sportCount': availableSports.length,
      'teamCount': availableTeams.length,
      'athletesBySport': athletesBySport,
      'athletesByGender': athletesByGender,
    };
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Athlete controller extensions for advanced operations
extension AthleteControllerExtensions on AthleteController {
  /// Get athletes by age group
  List<Athlete> getAthletesByAgeGroup(String ageGroup) {
    return athletes.where((athlete) => athlete.ageGroup == ageGroup).toList();
  }

  /// Get athletes with recent tests (bu özellik ileride implement edilecek)
  List<Athlete> getAthletesWithRecentTests({int days = 30}) {
    // Mock implementation - gerçekte test veritabanından çekilecek
    return athletes.take(3).toList();
  }

  /// Get athletes needing attention (yaralanma geçmişi olan)
  List<Athlete> getAthletesNeedingAttention() {
    return athletes.where((athlete) => athlete.injuryHistory.isNotEmpty).toList();
  }

  /// Validate athlete data
  List<String> validateAthleteData(Athlete athlete) {
    final errors = <String>[];
    
    if (athlete.firstName.trim().isEmpty) {
      errors.add('İsim boş olamaz');
    }
    
    if (athlete.lastName.trim().isEmpty) {
      errors.add('Soyisim boş olamaz');
    }
    
    if (!['M', 'F', 'O'].contains(athlete.gender.toUpperCase())) {
      errors.add('Geçersiz cinsiyet değeri');
    }
    
    if (athlete.height != null && (athlete.height! < 100 || athlete.height! > 250)) {
      errors.add('Boy değeri 100-250 cm arasında olmalı');
    }
    
    if (athlete.weight != null && (athlete.weight! < 30 || athlete.weight! > 200)) {
      errors.add('Kilo değeri 30-200 kg arasında olmalı');
    }
    
    if (athlete.email != null && athlete.email!.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(athlete.email!)) {
        errors.add('Geçersiz e-posta formatı');
      }
    }
    
    return errors;
  }

  /// Get recommended tests for athlete
  List<TestType> getRecommendedTests(Athlete athlete) {
    final recommendations = <TestType>[];
    
    // Sport-based recommendations
    switch (athlete.sport?.toLowerCase()) {
      case 'basketball':
      case 'volleyball':
        recommendations.addAll([
          TestType.counterMovementJump,
          TestType.dropJump,
          TestType.landing,
        ]);
        break;
      case 'football':
      case 'soccer':
        recommendations.addAll([
          TestType.counterMovementJump,
          TestType.squatJump,
          TestType.balance,
        ]);
        break;
      case 'athletics':
      case 'track and field':
        recommendations.addAll([
          TestType.counterMovementJump,
          TestType.squatJump,
          TestType.isometric,
        ]);
        break;
      default:
        recommendations.addAll([
          TestType.counterMovementJump,
          TestType.balance,
        ]);
    }
    
    // Age-based adjustments
    if (athlete.age != null && athlete.age! > 50) {
      recommendations.add(TestType.balance);
      recommendations.remove(TestType.dropJump); // Safer for older athletes
    }
    
    // Injury history adjustments
    if (athlete.injuryHistory.isNotEmpty) {
      recommendations.add(TestType.balance);
      // Potential recommendation to avoid certain tests based on injury type
    }
    
    return recommendations.distinct().toList();
  }
}