// lib/core/constants/enhanced_test_protocols.dart
import 'package:flutter/material.dart';

/// Enhanced Test Protocols for IzForce - VALD ForceDecks Alternative
/// Comprehensive 18 test protocol system with Turkish localization
class EnhancedTestProtocols {
  
  // =================== TEST TYPES ENUM ===================
  
  /// All available test types in IzForce system
  static const Map<TestType, TestProtocol> protocols = {
    // Jump Tests
    TestType.counterMovementJump: TestProtocol(
      name: 'Countermovement Jump',
      turkishName: 'Karşı Hareket Sıçraması',
      description: 'Vertical jump test with countermovement phase for maximum height assessment',
      turkishDescription: 'Maksimum yükseklik değerlendirmesi için karşı hareket fazlı dikey sıçrama testi',
      category: TestCategory.jump,
      difficulty: TestDifficulty.beginner,
      duration: Duration(seconds: 8),
      instructions: [
        'Stand upright on both force plates',
        'Keep hands on hips throughout the movement',
        'Perform a quick downward movement followed by maximum vertical jump',
        'Land softly on both feet',
        'Remain still for 2 seconds after landing',
      ],
      turkishInstructions: [
        'Her iki kuvvet platformunda dik durun',
        'Hareket boyunca ellerinizi kalçalarınızda tutun',
        'Hızlı bir aşağı hareket yapın, ardından maksimum dikey sıçrama',
        'Her iki ayakla yumuşak iniş yapın',
        'İnişten sonra 2 saniye hareketsiz kalın',
      ],
      sportRecommendations: ['Basketball', 'Volleyball', 'Athletics', 'Football'],
      validationRules: ValidationRules(
        minPeakForce: 1200.0,
        maxAsymmetry: 20.0,
        minFlightTime: 100.0,
        maxContactTime: null,
      ),
    ),
    
    TestType.squatJump: TestProtocol(
      name: 'Squat Jump',
      turkishName: 'Çömelme Sıçraması',
      description: 'Static squat position jump test for pure concentric power assessment',
      turkishDescription: 'Saf konsantrik güç değerlendirmesi için statik çömelme pozisyonundan sıçrama testi',
      category: TestCategory.jump,
      difficulty: TestDifficulty.beginner,
      duration: Duration(seconds: 6),
      instructions: [
        'Start in a 90° squat position',
        'Hold the position for 2 seconds',
        'Jump as high as possible without countermovement',
        'Keep hands on hips',
        'Land softly and hold position',
      ],
      turkishInstructions: [
        '90° çömelme pozisyonunda başlayın',
        'Pozisyonu 2 saniye tutun',
        'Karşı hareket yapmadan mümkün olduğunca yüksek sıçrayın',
        'Ellerinizi kalçalarınızda tutun',
        'Yumuşak iniş yapın ve pozisyonu koruyun',
      ],
      sportRecommendations: ['Weightlifting', 'Athletics', 'Basketball'],
      validationRules: ValidationRules(
        minPeakForce: 1000.0,
        maxAsymmetry: 20.0,
        minFlightTime: 80.0,
        maxContactTime: null,
      ),
    ),
    
    TestType.dropJump: TestProtocol(
      name: 'Drop Jump',
      turkishName: 'Düşme Sıçraması',
      description: 'Reactive strength assessment with drop and immediate jump',
      turkishDescription: 'Düşme ve anında sıçrama ile reaktif kuvvet değerlendirmesi',
      category: TestCategory.reactive,
      difficulty: TestDifficulty.intermediate,
      duration: Duration(seconds: 10),
      instructions: [
        'Start on 30cm box above the platforms',
        'Step off (do not jump) from the box',
        'Land on both feet simultaneously',
        'Immediately jump as high as possible',
        'Minimize ground contact time',
      ],
      turkishInstructions: [
        'Platformların 30cm üstündeki kutudan başlayın',
        'Kutudan aşağı adım atın (sıçramayın)',
        'Her iki ayakla aynı anda inin',
        'Hemen mümkün olduğunca yüksek sıçrayın',
        'Zemin temas süresini minimize edin',
      ],
      sportRecommendations: ['Athletics', 'Basketball', 'Volleyball', 'Football'],
      validationRules: ValidationRules(
        minPeakForce: 1500.0,
        maxAsymmetry: 15.0,
        minFlightTime: 120.0,
        maxContactTime: 250.0,
      ),
    ),
    
    TestType.balance: TestProtocol(
      name: 'Static Balance',
      turkishName: 'Statik Denge',
      description: 'Postural control assessment in quiet standing',
      turkishDescription: 'Sakin duruşta postüral kontrol değerlendirmesi',
      category: TestCategory.balance,
      difficulty: TestDifficulty.beginner,
      duration: Duration(seconds: 30),
      instructions: [
        'Stand quietly on both feet',
        'Keep arms at your sides',
        'Look straight ahead at a fixed point',
        'Minimize body movement',
        'Breathe normally',
      ],
      turkishInstructions: [
        'Her iki ayak üzerinde sakin durun',
        'Kollarınızı yanlarınızda tutun',
        'Sabit bir noktaya doğru bakın',
        'Vücut hareketini minimize edin',
        'Normal nefes alın',
      ],
      sportRecommendations: ['Gymnastics', 'Skiing', 'Dance', 'Judo'],
      validationRules: ValidationRules(
        minPeakForce: null,
        maxAsymmetry: 10.0,
        minFlightTime: null,
        maxContactTime: null,
      ),
    ),
    
    TestType.singleLegBalance: TestProtocol(
      name: 'Single Leg Balance',
      turkishName: 'Tek Ayak Denge',
      description: 'Unilateral balance assessment and asymmetry detection',
      turkishDescription: 'Tek taraflı denge değerlendirmesi ve asimetri tespiti',
      category: TestCategory.balance,
      difficulty: TestDifficulty.intermediate,
      duration: Duration(seconds: 20),
      instructions: [
        'Stand on one leg (dominant first)',
        'Lift the opposite leg to 90° hip flexion',
        'Keep arms crossed over chest',
        'Maintain position for full duration',
        'Repeat with opposite leg',
      ],
      turkishInstructions: [
        'Tek ayak üzerinde durun (önce dominant)',
        'Karşı bacağı 90° kalça fleksiyonuna kaldırın',
        'Kolları göğsünüzde çaprazlayın',
        'Tam süre boyunca pozisyonu koruyun',
        'Karşı bacakla tekrarlayın',
      ],
      sportRecommendations: ['Football', 'Basketball', 'Tennis', 'Athletics'],
      validationRules: ValidationRules(
        minPeakForce: null,
        maxAsymmetry: 25.0,
        minFlightTime: null,
        maxContactTime: null,
      ),
    ),
    
    TestType.isometricMidThigh: TestProtocol(
      name: 'Isometric Mid-Thigh Pull',
      turkishName: 'İzometrik Orta Uyluk Çekişi',
      description: 'Maximum isometric strength assessment',
      turkishDescription: 'Maksimum izometrik kuvvet değerlendirmesi',
      category: TestCategory.isometric,
      difficulty: TestDifficulty.advanced,
      duration: Duration(seconds: 5),
      instructions: [
        'Stand with feet shoulder-width apart',
        'Maintain slight knee bend (120-140°)',
        'Pull up with maximum force',
        'Hold maximum effort for 3-5 seconds',
        'Do not move feet during pull',
      ],
      turkishInstructions: [
        'Ayakları omuz genişliğinde açın',
        'Hafif diz büküklüğü koruyun (120-140°)',
        'Maksimum kuvvetle yukarı çekin',
        'Maksimum eforu 3-5 saniye tutun',
        'Çekiş sırasında ayakları hareket ettirmeyin',
      ],
      sportRecommendations: ['Weightlifting', 'Wrestling', 'Rugby', 'Football'],
      validationRules: ValidationRules(
        minPeakForce: 2000.0,
        maxAsymmetry: 15.0,
        minFlightTime: null,
        maxContactTime: null,
      ),
    ),
    
    TestType.isometricSquat: TestProtocol(
      name: 'Isometric Squat',
      turkishName: 'İzometrik Çömelme',
      description: 'Isometric leg strength in squat position',
      turkishDescription: 'Çömelme pozisyonunda izometrik bacak kuvveti',
      category: TestCategory.isometric,
      difficulty: TestDifficulty.intermediate,
      duration: Duration(seconds: 5),
      instructions: [
        'Assume 90° squat position',
        'Push down with maximum force',
        'Maintain position throughout test',
        'Keep back straight',
        'Hold maximum effort for full duration',
      ],
      turkishInstructions: [
        '90° çömelme pozisyonu alın',
        'Maksimum kuvvetle aşağı bastırın',
        'Test boyunca pozisyonu koruyun',
        'Sırtı dik tutun',
        'Tam süre boyunca maksimum efor gösterin',
      ],
      sportRecommendations: ['Skiing', 'Volleyball', 'Basketball'],
      validationRules: ValidationRules(
        minPeakForce: 1500.0,
        maxAsymmetry: 15.0,
        minFlightTime: null,
        maxContactTime: null,
      ),
    ),
    
    TestType.landing: TestProtocol(
      name: 'Landing Assessment',
      turkishName: 'İniş Değerlendirmesi',
      description: 'Landing mechanics and stabilization assessment',
      turkishDescription: 'İniş mekaniği ve stabilizasyon değerlendirmesi',
      category: TestCategory.landing,
      difficulty: TestDifficulty.intermediate,
      duration: Duration(seconds: 8),
      instructions: [
        'Jump from 40cm height',
        'Land on both feet simultaneously',
        'Absorb landing with controlled movement',
        'Stabilize as quickly as possible',
        'Hold final position for 3 seconds',
      ],
      turkishInstructions: [
        '40cm yükseklikten atlayın',
        'Her iki ayakla aynı anda inin',
        'Kontrollü hareketle inişi absorbe edin',
        'Mümkün olduğunca hızlı stabilize olun',
        'Son pozisyonu 3 saniye tutun',
      ],
      sportRecommendations: ['Basketball', 'Volleyball', 'Gymnastics'],
      validationRules: ValidationRules(
        minPeakForce: 1200.0,
        maxAsymmetry: 20.0,
        minFlightTime: null,
        maxContactTime: null,
      ),
    ),
    
    TestType.landAndHold: TestProtocol(
      name: 'Land and Hold',
      turkishName: 'İniş ve Tutma',
      description: 'Dynamic landing with extended stabilization hold',
      turkishDescription: 'Uzatılmış stabilizasyon tutuşu ile dinamik iniş',
      category: TestCategory.landing,
      difficulty: TestDifficulty.intermediate,
      duration: Duration(seconds: 10),
      instructions: [
        'Jump from designated height',
        'Land in athletic position',
        'Hold landing position for 5 seconds',
        'Minimize movement during hold',
        'Maintain good posture throughout',
      ],
      turkishInstructions: [
        'Belirlenen yükseklikten atlayın',
        'Atletik pozisyonda inin',
        'İniş pozisyonunu 5 saniye tutun',
        'Tutuş sırasında hareketi minimize edin',
        'Boyunca iyi postürü koruyun',
      ],
      sportRecommendations: ['Gymnastics', 'Basketball'],
      validationRules: ValidationRules(
        minPeakForce: 1000.0,
        maxAsymmetry: 20.0,
        minFlightTime: null,
        maxContactTime: null,
      ),
    ),
    
    TestType.reactiveDynamic: TestProtocol(
      name: 'Reactive Dynamic',
      turkishName: 'Reaktif Dinamik',
      description: 'Multiple reactive jumps for consistency assessment',
      turkishDescription: 'Tutarlılık değerlendirmesi için çoklu reaktif sıçramalar',
      category: TestCategory.reactive,
      difficulty: TestDifficulty.advanced,
      duration: Duration(seconds: 15),
      instructions: [
        'Perform 5 consecutive jumps',
        'Minimize ground contact time',
        'Maintain consistent jump height',
        'Use arms naturally',
        'Focus on quick turnaround',
      ],
      turkishInstructions: [
        '5 ardışık sıçrama yapın',
        'Zemin temas süresini minimize edin',
        'Tutarlı sıçrama yüksekliği koruyun',
        'Kolları doğal kullanın',
        'Hızlı dönüşe odaklanın',
      ],
      sportRecommendations: ['Basketball', 'Volleyball', 'Athletics'],
      validationRules: ValidationRules(
        minPeakForce: 1200.0,
        maxAsymmetry: 15.0,
        minFlightTime: 100.0,
        maxContactTime: 300.0,
      ),
    ),
    
    TestType.hopping: TestProtocol(
      name: 'Single Leg Hopping',
      turkishName: 'Tek Ayak Zıplama',
      description: 'Unilateral reactive power and asymmetry assessment',
      turkishDescription: 'Tek taraflı reaktif güç ve asimetri değerlendirmesi',
      category: TestCategory.reactive,
      difficulty: TestDifficulty.advanced,
      duration: Duration(seconds: 12),
      instructions: [
        'Hop on one leg for 10 repetitions',
        'Maintain forward momentum',
        'Minimize ground contact time',
        'Test both legs separately',
        'Keep hands on hips',
      ],
      turkishInstructions: [
        'Tek ayakla 10 tekrar zıplayın',
        'İleri momentumu koruyun',
        'Zemin temas süresini minimize edin',
        'Her iki bacağı ayrı ayrı test edin',
        'Elleri kalçalarda tutun',
      ],
      sportRecommendations: ['Football', 'Basketball', 'Tennis'],
      validationRules: ValidationRules(
        minPeakForce: 800.0,
        maxAsymmetry: 20.0,
        minFlightTime: 80.0,
        maxContactTime: 250.0,
      ),
    ),
    
    TestType.changeOfDirection: TestProtocol(
      name: 'Change of Direction',
      turkishName: 'Yön Değiştirme',
      description: 'Lateral force application and direction change ability',
      turkishDescription: 'Yanal kuvvet uygulama ve yön değiştirme yeteneği',
      category: TestCategory.power,
      difficulty: TestDifficulty.advanced,
      duration: Duration(seconds: 10),
      instructions: [
        'Start in athletic stance',
        'Push off laterally with maximum force',
        'Change direction rapidly',
        'Return to center position',
        'Repeat in opposite direction',
      ],
      turkishInstructions: [
        'Atletik duruşta başlayın',
        'Yanal olarak maksimum kuvvetle itin',
        'Hızla yön değiştirin',
        'Merkez pozisyona dönün',
        'Karşı yönde tekrarlayın',
      ],
      sportRecommendations: ['Football', 'Basketball', 'Tennis', 'Handball'],
      validationRules: ValidationRules(
        minPeakForce: 1000.0,
        maxAsymmetry: 25.0,
        minFlightTime: null,
        maxContactTime: null,
      ),
    ),
    
    TestType.powerClean: TestProtocol(
      name: 'Power Clean Assessment',
      turkishName: 'Güç Temizlik Değerlendirmesi',
      description: 'Olympic movement pattern force-time analysis',
      turkishDescription: 'Olimpik hareket paterninde kuvvet-zaman analizi',
      category: TestCategory.power,
      difficulty: TestDifficulty.expert,
      duration: Duration(seconds: 6),
      instructions: [
        'Simulate power clean movement',
        'Triple extension pattern',
        'Maximum acceleration phase',
        'Quick transition to catch',
        'Hold final position briefly',
      ],
      turkishInstructions: [
        'Güç temizlik hareketini simüle edin',
        'Üçlü ekstansiyon paterni',
        'Maksimum akselerasyon fazı',
        'Yakalamaya hızlı geçiş',
        'Son pozisyonu kısaca tutun',
      ],
      sportRecommendations: ['Weightlifting', 'Athletics', 'Rugby', 'Wrestling'],
      validationRules: ValidationRules(
        minPeakForce: 2000.0,
        maxAsymmetry: 10.0,
        minFlightTime: null,
        maxContactTime: null,
      ),
    ),
    
    TestType.fatigue: TestProtocol(
      name: 'Fatigue Assessment',
      turkishName: 'Yorgunluk Değerlendirmesi',
      description: 'Power output decline over repeated maximum efforts',
      turkishDescription: 'Tekrarlanan maksimum eforlarda güç çıkışı düşüşü',
      category: TestCategory.endurance,
      difficulty: TestDifficulty.expert,
      duration: Duration(seconds: 60),
      instructions: [
        'Perform 15 maximum jumps',
        'Jump every 4 seconds on command',
        'Maintain maximum effort throughout',
        'No rest between jumps',
        'Monitor fatigue progression',
      ],
      turkishInstructions: [
        '15 maksimum sıçrama yapın',
        'Komutta her 4 saniyede sıçrayın',
        'Boyunca maksimum eforu koruyun',
        'Sıçramalar arası dinlenme yok',
        'Yorgunluk ilerlemesini takip edin',
      ],
      sportRecommendations: ['Basketball', 'Volleyball', 'Football', 'CrossFit'],
      validationRules: ValidationRules(
        minPeakForce: 1000.0,
        maxAsymmetry: 25.0,
        minFlightTime: 50.0,
        maxContactTime: null,
      ),
    ),
    
    TestType.recovery: TestProtocol(
      name: 'Recovery Assessment',
      turkishName: 'Toparlanma Değerlendirmesi',
      description: 'Power recovery capacity after fatigue',
      turkishDescription: 'Yorgunluk sonrası güç toparlanma kapasitesi',
      category: TestCategory.endurance,
      difficulty: TestDifficulty.expert,
      duration: Duration(seconds: 30),
      instructions: [
        'Perform after fatigue protocol',
        'Rest for designated period',
        'Perform 3 maximum effort jumps',
        'Compare to fresh baseline',
        'Assess recovery percentage',
      ],
      turkishInstructions: [
        'Yorgunluk protokolünden sonra yapın',
        'Belirlenen süre dinlenin',
        '3 maksimum efor sıçraması yapın',
        'Taze baseline ile karşılaştırın',
        'Toparlanma yüzdesini değerlendirin',
      ],
      sportRecommendations: ['Football', 'Basketball', 'Tennis'],
      validationRules: ValidationRules(
        minPeakForce: 800.0,
        maxAsymmetry: 20.0,
        minFlightTime: 80.0,
        maxContactTime: null,
      ),
    ),
    
    TestType.returnToSport: TestProtocol(
      name: 'Return to Sport',
      turkishName: 'Spora Dönüş',
      description: 'Comprehensive readiness assessment for sport participation',
      turkishDescription: 'Spora katılım için kapsamlı hazırlık değerlendirmesi',
      category: TestCategory.rehabilitation,
      difficulty: TestDifficulty.expert,
      duration: Duration(seconds: 12),
      instructions: [
        'Complete movement screening battery',
        'Test bilateral and unilateral tasks',
        'Assess under fatigue',
        'Check asymmetry thresholds',
        'Evaluate confidence and pain',
      ],
      turkishInstructions: [
        'Hareket tarama bataryasını tamamlayın',
        'İki taraflı ve tek taraflı görevleri test edin',
        'Yorgunluk altında değerlendirin',
        'Asimetri eşiklerini kontrol edin',
        'Güven ve ağrıyı değerlendirin',
      ],
      sportRecommendations: ['All Sports', 'Rehabilitation'],
      validationRules: ValidationRules(
        minPeakForce: 1000.0,
        maxAsymmetry: 10.0,
        minFlightTime: 100.0,
        maxContactTime: null,
      ),
    ),
    
    TestType.injuryRisk: TestProtocol(
      name: 'Injury Risk Assessment',
      turkishName: 'Yaralanma Riski Değerlendirmesi',
      description: 'Movement screening for injury prevention',
      turkishDescription: 'Yaralanma önleme için hareket tarama analizi',
      category: TestCategory.rehabilitation,
      difficulty: TestDifficulty.intermediate,
      duration: Duration(seconds: 15),
      instructions: [
        'Perform standardized movement tasks',
        'Focus on landing mechanics',
        'Assess force asymmetries',
        'Check stability patterns',
        'Identify risk factors',
      ],
      turkishInstructions: [
        'Standart hareket görevlerini yapın',
        'İniş mekaniğine odaklanın',
        'Kuvvet asimetrilerini değerlendirin',
        'Stabilite paternlerini kontrol edin',
        'Risk faktörlerini belirleyin',
      ],
      sportRecommendations: ['All Sports', 'Youth Sports'],
      validationRules: ValidationRules(
        minPeakForce: 800.0,
        maxAsymmetry: 15.0,
        minFlightTime: 80.0,
        maxContactTime: null,
      ),
    ),
  };
}

// =================== ENUMS AND CLASSES ===================

enum TestType {
  // Jump Tests
  counterMovementJump,
  squatJump,
  dropJump,
  
  // Balance Tests
  balance,
  singleLegBalance,
  
  // Isometric Tests
  isometricMidThigh,
  isometricSquat,
  
  // Landing Tests
  landing,
  landAndHold,
  
  // Reactive Tests
  reactiveDynamic,
  hopping,
  
  // Power Tests
  changeOfDirection,
  powerClean,
  
  // Endurance Tests
  fatigue,
  recovery,
  
  // Rehabilitation Tests
  returnToSport,
  injuryRisk,
}

enum TestCategory {
  jump,
  balance,
  isometric,
  landing,
  reactive,
  power,
  endurance,
  rehabilitation,
}

enum TestDifficulty {
  beginner,
  intermediate,
  advanced,
  expert,
}

class TestProtocol {
  final String name;
  final String turkishName;
  final String description;
  final String turkishDescription;
  final TestCategory category;
  final TestDifficulty difficulty;
  final Duration duration;
  final List<String> instructions;
  final List<String> turkishInstructions;
  final List<String> sportRecommendations;
  final ValidationRules validationRules;

  const TestProtocol({
    required this.name,
    required this.turkishName,
    required this.description,
    required this.turkishDescription,
    required this.category,
    required this.difficulty,
    required this.duration,
    required this.instructions,
    required this.turkishInstructions,
    required this.sportRecommendations,
    required this.validationRules,
  });
}

class ValidationRules {
  final double? minPeakForce;
  final double? maxAsymmetry;
  final double? minFlightTime;
  final double? maxContactTime;

  const ValidationRules({
    this.minPeakForce,
    this.maxAsymmetry,
    this.minFlightTime,
    this.maxContactTime,
  });
}

// =================== EXTENSIONS ===================

extension TestTypeExtension on TestType {
  String get name {
    return EnhancedTestProtocols.protocols[this]?.name ?? 'Unknown Test';
  }
  
  String get turkishName {
    return EnhancedTestProtocols.protocols[this]?.turkishName ?? 'Bilinmeyen Test';
  }
  
  TestCategory get category {
    return EnhancedTestProtocols.protocols[this]?.category ?? TestCategory.jump;
  }
  
  TestDifficulty get difficulty {
    return EnhancedTestProtocols.protocols[this]?.difficulty ?? TestDifficulty.beginner;
  }
  
  Duration get duration {
    return EnhancedTestProtocols.protocols[this]?.duration ?? const Duration(seconds: 10);
  }
}

extension TestCategoryExtension on TestCategory {
  String get name {
    switch (this) {
      case TestCategory.jump:
        return 'Jump Tests';
      case TestCategory.balance:
        return 'Balance Tests';
      case TestCategory.isometric:
        return 'Isometric Tests';
      case TestCategory.landing:
        return 'Landing Tests';
      case TestCategory.reactive:
        return 'Reactive Tests';
      case TestCategory.power:
        return 'Power Tests';
      case TestCategory.endurance:
        return 'Endurance Tests';
      case TestCategory.rehabilitation:
        return 'Rehabilitation Tests';
    }
  }
  
  String get turkishName {
    switch (this) {
      case TestCategory.jump:
        return 'Sıçrama Testleri';
      case TestCategory.balance:
        return 'Denge Testleri';
      case TestCategory.isometric:
        return 'İzometrik Testler';
      case TestCategory.landing:
        return 'İniş Testleri';
      case TestCategory.reactive:
        return 'Reaktif Testler';
      case TestCategory.power:
        return 'Güç Testleri';
      case TestCategory.endurance:
        return 'Dayanıklılık Testleri';
      case TestCategory.rehabilitation:
        return 'Rehabilitasyon Testleri';
    }
  }
}

extension TestDifficultyExtension on TestDifficulty {
  String get name {
    switch (this) {
      case TestDifficulty.beginner:
        return 'Beginner';
      case TestDifficulty.intermediate:
        return 'Intermediate';
      case TestDifficulty.advanced:
        return 'Advanced';
      case TestDifficulty.expert:
        return 'Expert';
    }
  }
  
  String get turkishName {
    switch (this) {
      case TestDifficulty.beginner:
        return 'Başlangıç';
      case TestDifficulty.intermediate:
        return 'Orta';
      case TestDifficulty.advanced:
        return 'İleri';
      case TestDifficulty.expert:
        return 'Uzman';
    }
  }
  
  Color get color {
    switch (this) {
      case TestDifficulty.beginner:
        return Colors.green;
      case TestDifficulty.intermediate:
        return Colors.orange;
      case TestDifficulty.advanced:
        return Colors.red;
      case TestDifficulty.expert:
        return Colors.purple;
    }
  }
}