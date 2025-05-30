// lib/domain/entities/athlete.dart - FIXED
import '../../core/constants/test_constants.dart';
import '../../core/constants/test_constants.dart'; // ✅ ADDED: Import norm classes

/// VALD ForceDecks benzeri sporcu profil entity
class Athlete {
  /// Unique identifier
  final String id;
  
  /// İsim
  final String firstName;
  
  /// Soyisim
  final String lastName;
  
  /// Doğum tarihi
  final DateTime? dateOfBirth;
  
  /// Cinsiyet ('M' = Male, 'F' = Female, 'O' = Other)
  final String gender;
  
  /// Boy (cm)
  final double? height;
  
  /// Kilo (kg) - son ölçülen değer
  final double? weight;
  
  /// Spor dalı
  final String? sport;
  
  /// Pozisyon (futbolda kaleci, voleybolda libero vs.)
  final String? position;
  
  /// Takım/Kulüp
  final String? team;
  
  /// Antrenör
  final String? coach;
  
  /// E-posta
  final String? email;
  
  /// Telefon
  final String? phone;
  
  /// Notlar
  final String? notes;
  
  /// Yaralanma geçmişi
  final List<String> injuryHistory;
  
  /// Dominant bacak ('L' = Left, 'R' = Right, 'B' = Both)
  final String? dominantLeg;
  
  /// Aktif mi?
  final bool isActive;
  
  /// Oluşturulma tarihi
  final DateTime createdAt;
  
  /// Son güncelleme tarihi
  final DateTime updatedAt;
  
  /// Profil fotoğrafı URL'i
  final String? profileImageUrl;
  
  /// Ek metadata (JSON olarak saklanabilir)
  final Map<String, dynamic> metadata;

  const Athlete({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    this.dateOfBirth,
    this.height,
    this.weight,
    this.sport,
    this.position,
    this.team,
    this.coach,
    this.email,
    this.phone,
    this.notes,
    this.injuryHistory = const [],
    this.dominantLeg,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.profileImageUrl,
    this.metadata = const {},
  });

  /// Factory constructor for creating new athlete
  factory Athlete.create({
    required String firstName,
    required String lastName,
    required String gender,
    DateTime? dateOfBirth,
    double? height,
    double? weight,
    String? sport,
    String? position,
    String? team,
    String? coach,
    String? email,
    String? phone,
    String? notes,
    List<String>? injuryHistory,
    String? dominantLeg,
    String? profileImageUrl,
    Map<String, dynamic>? metadata,
  }) {
    return Athlete(
      id: _generateId(),
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      dateOfBirth: dateOfBirth,
      height: height,
      weight: weight,
      sport: sport,
      position: position,
      team: team,
      coach: coach,
      email: email,
      phone: phone,
      notes: notes,
      injuryHistory: injuryHistory ?? [],
      dominantLeg: dominantLeg,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      profileImageUrl: profileImageUrl,
      metadata: metadata ?? {},
    );
  }

  /// Demo/Mock athletes factory
  static List<Athlete> createMockAthletes() {
    return [
      Athlete.create(
        firstName: 'İzzet',
        lastName: 'İnce', 
        gender: 'M',
        dateOfBirth: DateTime(1979, 5, 15),
        height: 175.0,
        weight: 70.0,
        sport: 'Athletics',
        position: 'Sprinter',
        team: 'Individual',
        coach: 'Self-coached',
        email: 'izzet.ince@example.com',
        phone: '+90 555 123 4567',
        dominantLeg: 'R',
        notes: 'Experienced master athlete with consistent training background',
      ),
      
      Athlete.create(
        firstName: 'Süleyman',
        lastName: 'Ulupınar',
        gender: 'M', 
        dateOfBirth: DateTime(1989, 8, 22),
        height: 190.0,
        weight: 85.0,
        sport: 'Basketball',
        position: 'Power Forward',
        team: 'Anadolu Efes',
        coach: 'Ergin Ataman',
        email: 'suleyman.ulupinar@example.com',
        phone: '+90 555 987 6543',
        dominantLeg: 'R',
        notes: 'Professional basketball player, focus on explosive power',
      ),
      
      Athlete.create(
        firstName: 'Ayşe',
        lastName: 'Kaya',
        gender: 'F',
        dateOfBirth: DateTime(2002, 3, 10),
        height: 165.0,
        weight: 55.0,
        sport: 'Athletics',
        position: 'Long Jumper',
        team: 'Galatasaray',
        coach: 'Mehmet Yılmaz',
        email: 'ayse.kaya@example.com',
        phone: '+90 555 456 7890',
        dominantLeg: 'L',
        notes: 'Young promising athlete, excellent technique',
      ),
      
      Athlete.create(
        firstName: 'Mehmet',
        lastName: 'Demir',
        gender: 'M',
        dateOfBirth: DateTime(1995, 11, 5),
        height: 180.0,
        weight: 75.0,
        sport: 'Football',
        position: 'Midfielder',
        team: 'Fenerbahçe',
        coach: 'İsmail Kartal',
        dominantLeg: 'R',
        notes: 'Central midfielder, good bilateral balance',
      ),
      
      Athlete.create(
        firstName: 'Zeynep',
        lastName: 'Şahin',
        gender: 'F',
        dateOfBirth: DateTime(1998, 7, 18),
        height: 170.0,
        weight: 60.0,
        sport: 'Volleyball',
        position: 'Outside Hitter',
        team: 'VakıfBank',
        coach: 'Giovanni Guidetti',
        dominantLeg: 'R',
        injuryHistory: ['Right ankle sprain (2023)'],
        notes: 'Explosive jumper, recovering from minor injury',
      ),
    ];
  }

  // Computed properties
  String get fullName => '$firstName $lastName';
  
  String get displayName => fullName;
  
  int? get age {
    if (dateOfBirth == null) return null;
    final today = DateTime.now();
    int age = today.year - dateOfBirth!.year;
    if (today.month < dateOfBirth!.month || 
        (today.month == dateOfBirth!.month && today.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }
  
  String get ageGroup {
    final athleteAge = age;
    if (athleteAge == null) return 'Unknown';
    if (athleteAge < 18) return 'Youth';
    if (athleteAge < 23) return 'Junior';
    if (athleteAge < 35) return 'Senior';
    if (athleteAge < 50) return 'Master 1';
    return 'Master 2';
  }
  
  String get genderDisplay {
    switch (gender.toUpperCase()) {
      case 'M':
        return 'Male';
      case 'F':
        return 'Female';
      default:
        return 'Other';
    }
  }
  
  double? get bmi {
    if (height == null || weight == null) return null;
    final heightM = height! / 100.0;
    return weight! / (heightM * heightM);
  }
  
  String? get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return null;
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25.0) return 'Normal';
    if (bmiValue < 30.0) return 'Overweight';
    return 'Obese';
  }
  
  String get profileSummary {
    final parts = <String>[];
    
    if (age != null) parts.add('Age: $age');
    if (sport != null) parts.add(sport!);
    if (position != null) parts.add(position!);
    if (team != null) parts.add(team!);
    
    return parts.isNotEmpty ? parts.join(' • ') : 'No details';
  }
  
  String get displayInfo {
    final parts = <String>[];
    
    if (age != null) parts.add('${age}y');
    parts.add(genderDisplay);
    if (sport != null) parts.add(sport!);
    
    return parts.join(' • ');
  }
  
   String get normativeKey {
    final genderKey = gender.toLowerCase() == 'm' ? 'male' : 'female';
    final ageKey = (age ?? 25) < 35 ? 'adult' : 'master';
    return '${genderKey}_$ageKey';
  }
  
  /// Sporcu için jump norms
  JumpNorms? get jumpNorms => TestConstants.jumpNorms[normativeKey];
  
  /// Sporcu için force norms  
  ForceNorms? get forceNorms => TestConstants.forceNorms[normativeKey];
  
  /// Sporcu için RFD norms
  RFDNorms? get rfdNorms => TestConstants.rfdNorms[normativeKey];

  /// Sport-adjusted jump norms
  JumpNorms? get sportAdjustedJumpNorms {
    return TestConstants.getSportAdjustedJumpNorms(normativeKey, sport);
  }

 Map<String, String> assessPerformance({
    double? jumpHeight,
    double? peakPower,
    double? peakForce,
    double? bodyweightMultiple,
    double? rfd50,
    double? rfd100,
    double? rfd200,
    double? asymmetryPercent,
    bool isElite = false,
  }) {
    return TestConstants.assessPerformance(
      normativeKey: normativeKey,
      sport: sport,
      jumpHeight: jumpHeight,
      peakPower: peakPower,
      peakForce: peakForce,
      bodyweightMultiple: bodyweightMultiple,
      rfd50: rfd50,
      rfd100: rfd100,
      rfd200: rfd200,
      asymmetryPercent: asymmetryPercent,
      isElite: isElite,
    );
  }
  /// Copy with method
  Athlete copyWith({
    String? id,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    String? sport,
    String? position,
    String? team,
    String? coach,
    String? email,
    String? phone,
    String? notes,
    List<String>? injuryHistory,
    String? dominantLeg,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profileImageUrl,
    Map<String, dynamic>? metadata,
  }) {
    return Athlete(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      sport: sport ?? this.sport,
      position: position ?? this.position,
      team: team ?? this.team,
      coach: coach ?? this.coach,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      injuryHistory: injuryHistory ?? this.injuryHistory,
      dominantLeg: dominantLeg ?? this.dominantLeg,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  /// JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'height': height,
      'weight': weight,
      'sport': sport,
      'position': position,
      'team': team,
      'coach': coach,
      'email': email,
      'phone': phone,
      'notes': notes,
      'injuryHistory': injuryHistory,
      'dominantLeg': dominantLeg,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'profileImageUrl': profileImageUrl,
      'metadata': metadata,
    };
  }

  /// JSON deserialization
  factory Athlete.fromJson(Map<String, dynamic> json) {
    return Athlete(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      gender: json['gender'] as String,
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      sport: json['sport'] as String?,
      position: json['position'] as String?,
      team: json['team'] as String?,
      coach: json['coach'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      notes: json['notes'] as String?,
      injuryHistory: json['injuryHistory'] != null 
          ? (json['injuryHistory'] as List).cast<String>()
          : [],
      dominantLeg: json['dominantLeg'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      profileImageUrl: json['profileImageUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  String toString() {
    return 'Athlete(id: $id, name: $fullName, sport: $sport, age: $age)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Athlete && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Private helper methods
  static String _generateId() {
    // Simple ID generation - gerçek uygulamada UUID kullanılabilir
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'athlete_$timestamp';
  }
}

/// Athlete filtering and search helper
class AthleteFilter {
  final String? searchTerm;
  final String? sport;
  final String? gender;
  final String? team;
  final String? ageGroup;
  final bool? isActive;

  const AthleteFilter({
    this.searchTerm,
    this.sport,
    this.gender,
    this.team,
    this.ageGroup,
    this.isActive,
  });

  bool matches(Athlete athlete) {
    // Search term matching
    if (searchTerm != null && searchTerm!.isNotEmpty) {
      final term = searchTerm!.toLowerCase();
      final matchesName = athlete.fullName.toLowerCase().contains(term);
      final matchesSport = athlete.sport?.toLowerCase().contains(term) ?? false;
      final matchesTeam = athlete.team?.toLowerCase().contains(term) ?? false;
      final matchesPosition = athlete.position?.toLowerCase().contains(term) ?? false;
      
      if (!matchesName && !matchesSport && !matchesTeam && !matchesPosition) {
        return false;
      }
    }

    // Sport filter
    if (sport != null && athlete.sport != sport) {
      return false;
    }

    // Gender filter
    if (gender != null && athlete.gender != gender) {
      return false;
    }

    // Team filter
    if (team != null && athlete.team != team) {
      return false;
    }

    // Age group filter
    if (ageGroup != null && athlete.ageGroup != ageGroup) {
      return false;
    }

    // Active status filter
    if (isActive != null && athlete.isActive != isActive) {
      return false;
    }

    return true;
  }
}

/// Athlete list extensions
extension AthleteListExtension on List<Athlete> {
  /// Filter athletes
  List<Athlete> filter(AthleteFilter filter) {
    return where((athlete) => filter.matches(athlete)).toList();
  }

  /// Sort athletes by name
  List<Athlete> sortByName() {
    final sorted = List<Athlete>.from(this);
    sorted.sort((a, b) => a.fullName.compareTo(b.fullName));
    return sorted;
  }

  /// Sort athletes by sport
  List<Athlete> sortBySport() {
    final sorted = List<Athlete>.from(this);
    sorted.sort((a, b) => (a.sport ?? '').compareTo(b.sport ?? ''));
    return sorted;
  }

  /// Get unique sports
  List<String> get uniqueSports {
    return map((athlete) => athlete.sport).where((sport) => sport != null).cast<String>().toSet().toList()..sort();
  }

  /// Get unique teams
  List<String> get uniqueTeams {
    return map((athlete) => athlete.team).where((team) => team != null).cast<String>().toSet().toList()..sort();
  }

  /// Get athletes by sport
  List<Athlete> getBySport(String sport) {
    return where((athlete) => athlete.sport == sport).toList();
  }

  /// Get active athletes
  List<Athlete> get activeAthletes {
    return where((athlete) => athlete.isActive).toList();
  }
}