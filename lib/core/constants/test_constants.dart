// lib/core/constants/test_constants.dart - UNIFIED ENHANCED TURKISH SYSTEM
import 'package:flutter/material.dart';
import '../algorithms/phase_detector.dart';
import 'enhanced_test_protocols.dart';
import 'normative_constants.dart';

/// IzForce - Enhanced Turkish Force Plate Analysis System
/// Combining Enhanced Protocols with Turkish-specific features
class TestConstants {
  
  // =================== TEST TYPES & NAMES ===================
  
  /// Test names - English
  static const Map<TestType, String> testNames = {
    // Jump Tests
    TestType.counterMovementJump: 'Countermovement Jump (CMJ)',
    TestType.squatJump: 'Squat Jump (SJ)',
    TestType.dropJump: 'Drop Jump (DJ)',
    
    // Balance Tests  
    TestType.balance: 'Static Balance',
    TestType.singleLegBalance: 'Single Leg Balance',
    
    // Isometric Tests
    TestType.isometricMidThigh: 'Isometric Mid-Thigh Pull (IMTP)',
    TestType.isometricSquat: 'Isometric Squat',
    
    // Landing Tests
    TestType.landing: 'Landing Assessment',
    TestType.landAndHold: 'Land and Hold',
    
    // Reactive Tests
    TestType.reactiveDynamic: 'Reactive Dynamic',
    TestType.hopping: 'Single Leg Hopping',
    
    // Power Tests
    TestType.changeOfDirection: 'Change of Direction',
    TestType.powerClean: 'Power Clean Assessment',
    
    // Endurance Tests
    TestType.fatigue: 'Fatigue Assessment',
    TestType.recovery: 'Recovery Assessment',
    
    // Rehabilitation Tests
    TestType.returnToSport: 'Return to Sport',
    TestType.injuryRisk: 'Injury Risk Assessment',
  };

  /// Test names - Turkish
  static const Map<TestType, String> turkishTestNames = {
    // Jump Tests
    TestType.counterMovementJump: 'Karşı Hareket Sıçraması (CMJ)',
    TestType.squatJump: 'Çömelme Sıçraması (SJ)', 
    TestType.dropJump: 'Düşme Sıçraması (DJ)',
    
    // Balance Tests
    TestType.balance: 'Statik Denge',
    TestType.singleLegBalance: 'Tek Ayak Denge',
    
    // Isometric Tests
    TestType.isometricMidThigh: 'İzometrik Orta Uyluk Çekişi (IMTP)',
    TestType.isometricSquat: 'İzometrik Çömelme',
    
    // Landing Tests
    TestType.landing: 'İniş Değerlendirmesi',
    TestType.landAndHold: 'İniş ve Tutma',
    
    // Reactive Tests
    TestType.reactiveDynamic: 'Reaktif Dinamik',
    TestType.hopping: 'Tek Ayak Zıplama',
    
    // Power Tests
    TestType.changeOfDirection: 'Yön Değiştirme',
    TestType.powerClean: 'Güç Temizlik Değerlendirmesi',
    
    // Endurance Tests
    TestType.fatigue: 'Yorgunluk Değerlendirmesi',
    TestType.recovery: 'Toparlanma Değerlendirmesi',
    
    // Rehabilitation Tests
    TestType.returnToSport: 'Spora Dönüş',
    TestType.injuryRisk: 'Yaralanma Riski Değerlendirmesi',
  };
  
  /// Test descriptions - Turkish
  static const Map<TestType, String> testDescriptions = {
    TestType.counterMovementJump: 'Eksantrik faz ile maksimum dikey sıçrama performansı ölçümü',
    TestType.squatJump: 'Statik çömelme pozisyonundan patlayıcı konsantrik sıçrama',
    TestType.dropJump: 'Belirli yükseklikten düşüp reaktif kuvvet ile sıçrama',
    TestType.balance: 'Statik postüral kontrol ve stabilite değerlendirmesi',
    TestType.singleLegBalance: 'Tek bacak denge ve proprioseptif kontrol ölçümü',
    TestType.isometricMidThigh: 'Maksimum izometrik kuvvet üretimi değerlendirmesi',
    TestType.isometricSquat: 'Çömelme pozisyonunda statik kuvvet ölçümü',
    TestType.landing: 'Yüksekten iniş sonrası stabilizasyon yeteneği analizi',
    TestType.landAndHold: 'Dinamik iniş sonrası uzatılmış statik stabilizasyon',
    TestType.reactiveDynamic: 'Çoklu reaktif sıçramalar ile tutarlı performans ölçümü',
    TestType.hopping: 'Tek bacak reaktif güç ve asimetri değerlendirmesi',
    TestType.changeOfDirection: 'Yanal kuvvet uygulama ve yön değiştirme yeteneği',
    TestType.powerClean: 'Olimpik hareket paterninde kuvvet-zaman analizi',
    TestType.fatigue: 'Tekrarlanan maksimum eforlarda güç çıkışı düşüşü',
    TestType.recovery: 'Yorgunluk sonrası güç toparlanma kapasitesi',
    TestType.returnToSport: 'Spora katılım için kapsamlı hazırlık değerlendirmesi',
    TestType.injuryRisk: 'Yaralanma önleme için hareket tarama analizi',
  };
  
  // =================== TEST DURATIONS ===================
  
  static const Map<TestType, Duration> testDurations = {
    // Jump Tests
    TestType.counterMovementJump: Duration(seconds: 8),
    TestType.squatJump: Duration(seconds: 6),
    TestType.dropJump: Duration(seconds: 10),
    
    // Balance Tests
    TestType.balance: Duration(seconds: 30),
    TestType.singleLegBalance: Duration(seconds: 20),
    
    // Isometric Tests
    TestType.isometricMidThigh: Duration(seconds: 5),
    TestType.isometricSquat: Duration(seconds: 5),
    
    // Landing Tests
    TestType.landing: Duration(seconds: 8),
    TestType.landAndHold: Duration(seconds: 10),
    
    // Reactive Tests
    TestType.reactiveDynamic: Duration(seconds: 15),
    TestType.hopping: Duration(seconds: 12),
    
    // Power Tests
    TestType.changeOfDirection: Duration(seconds: 10),
    TestType.powerClean: Duration(seconds: 6),
    
    // Endurance Tests
    TestType.fatigue: Duration(seconds: 60),
    TestType.recovery: Duration(seconds: 30),
    
    // Rehabilitation Tests
    TestType.returnToSport: Duration(seconds: 12),
    TestType.injuryRisk: Duration(seconds: 15),
  };

  // =================== TEST CATEGORIES ===================
  
  static const Map<TestType, TestCategory> testCategories = {
    // Jump Tests
    TestType.counterMovementJump: TestCategory.jump,
    TestType.squatJump: TestCategory.jump,
    TestType.dropJump: TestCategory.jump,
    
    // Balance Tests
    TestType.balance: TestCategory.balance,
    TestType.singleLegBalance: TestCategory.balance,
    
    // Isometric Tests
    TestType.isometricMidThigh: TestCategory.isometric,
    TestType.isometricSquat: TestCategory.isometric,
    
    // Landing Tests
    TestType.landing: TestCategory.landing,
    TestType.landAndHold: TestCategory.landing,
    
    // Reactive Tests
    TestType.reactiveDynamic: TestCategory.reactive,
    TestType.hopping: TestCategory.reactive,
    
    // Power Tests
    TestType.changeOfDirection: TestCategory.power,
    TestType.powerClean: TestCategory.power,
    
    // Endurance Tests
    TestType.fatigue: TestCategory.endurance,
    TestType.recovery: TestCategory.endurance,
    
    // Rehabilitation Tests
    TestType.returnToSport: TestCategory.rehabilitation,
    TestType.injuryRisk: TestCategory.rehabilitation,
  };

  // =================== DIFFICULTY LEVELS ===================
  
  static const Map<TestType, TestDifficulty> testDifficulty = {
    TestType.counterMovementJump: TestDifficulty.beginner,
    TestType.squatJump: TestDifficulty.beginner,
    TestType.balance: TestDifficulty.beginner,
    TestType.landing: TestDifficulty.intermediate,
    TestType.dropJump: TestDifficulty.intermediate,
    TestType.singleLegBalance: TestDifficulty.intermediate,
    TestType.isometricSquat: TestDifficulty.intermediate,
    TestType.landAndHold: TestDifficulty.intermediate,
    TestType.injuryRisk: TestDifficulty.intermediate,
    TestType.changeOfDirection: TestDifficulty.advanced,
    TestType.reactiveDynamic: TestDifficulty.advanced,
    TestType.hopping: TestDifficulty.advanced,
    TestType.isometricMidThigh: TestDifficulty.advanced,
    TestType.powerClean: TestDifficulty.expert,
    TestType.fatigue: TestDifficulty.expert,
    TestType.recovery: TestDifficulty.expert,
    TestType.returnToSport: TestDifficulty.expert,
  };

  // =================== TURKISH SPORTS ===================
  
  static const List<String> turkishSports = [
    'Futbol',
    'Basketbol', 
    'Voleybol',
    'Atletizm',
    'Güreş',
    'Halter',
    'Hentbol',
    'Judo',
    'Karate',
    'Taekwondo',
    'Tenis',
    'Badminton',
    'Yüzme',
    'Jimnastik',
    'Boks',
    'Bisiklet',
    'Masa Tenisi',
    'Kayak',
    'Okçuluk',
    'Golf',
    'Yelken',
    'Kürek',
    'Triathlon',
    'Dağcılık',
    'Kaya Tırmanışı',
    'Eskrim',
    'Rugby',
    'Beyzbol',
    'Fitness',
    'Crossfit',
    'Dans',
    'Genel',
  ];

  // =================== SPORT RECOMMENDATIONS ===================
  
  static const Map<TestType, List<String>> recommendedSports = {
    TestType.counterMovementJump: ['Basketbol', 'Voleybol', 'Atletizm', 'Futbol'],
    TestType.squatJump: ['Halter', 'Atletizm', 'Basketbol'],
    TestType.dropJump: ['Atletizm', 'Basketbol', 'Voleybol', 'Futbol'],
    TestType.balance: ['Jimnastik', 'Kayak', 'Dans', 'Judo'],
    TestType.singleLegBalance: ['Futbol', 'Basketbol', 'Tenis', 'Atletizm'],
    TestType.isometricMidThigh: ['Halter', 'Güreş', 'Rugby', 'Futbol'],
    TestType.isometricSquat: ['Kayak', 'Voleybol', 'Basketbol'],
    TestType.landing: ['Basketbol', 'Voleybol', 'Jimnastik'],
    TestType.landAndHold: ['Jimnastik', 'Basketbol'],
    TestType.reactiveDynamic: ['Basketbol', 'Voleybol', 'Atletizm'],
    TestType.hopping: ['Futbol', 'Basketbol', 'Tenis'],
    TestType.changeOfDirection: ['Futbol', 'Basketbol', 'Tenis', 'Hentbol'],
    TestType.powerClean: ['Halter', 'Atletizm', 'Rugby', 'Güreş'],
    TestType.fatigue: ['Basketbol', 'Voleybol', 'Futbol', 'Crossfit'],
    TestType.recovery: ['Futbol', 'Basketbol', 'Tenis'],
    TestType.returnToSport: ['Tüm Sporlar', 'Rehabilitasyon'],
    TestType.injuryRisk: ['Tüm Sporlar', 'Gençlik Sporları'],
  };

  // =================== TURKISH NORMATIVE DATA ===================
  
  /// Turkish population jump norms (cm) - Age and gender based
  static const Map<String, JumpNorms> turkishJumpNorms = {
    'erkek_genç': JumpNorms(  // 18-25 yaş erkek
      poor: 28.0,
      belowAverage: 32.0,
      average: 38.0,
      aboveAverage: 44.0,
      excellent: 50.0,
    ),
    'erkek_yetiskin': JumpNorms(  // 26-35 yaş erkek
      poor: 25.0,
      belowAverage: 30.0,
      average: 35.0,
      aboveAverage: 41.0,
      excellent: 47.0,
    ),
    'erkek_master': JumpNorms(  // 36+ yaş erkek
      poor: 22.0,
      belowAverage: 27.0,
      average: 32.0,
      aboveAverage: 38.0,
      excellent: 44.0,
    ),
    'kadin_genç': JumpNorms(  // 18-25 yaş kadın
      poor: 22.0,
      belowAverage: 26.0,
      average: 31.0,
      aboveAverage: 36.0,
      excellent: 42.0,
    ),
    'kadin_yetiskin': JumpNorms(  // 26-35 yaş kadın
      poor: 20.0,
      belowAverage: 24.0,
      average: 29.0,
      aboveAverage: 34.0,
      excellent: 40.0,
    ),
    'kadin_master': JumpNorms(  // 36+ yaş kadın
      poor: 18.0,
      belowAverage: 22.0,
      average: 27.0,
      aboveAverage: 32.0,
      excellent: 38.0,
    ),
    
    // Sport-specific norms
    'basketbol_erkek': JumpNorms(
      poor: 35.0,
      belowAverage: 40.0,
      average: 45.0,
      aboveAverage: 52.0,
      excellent: 60.0,
    ),
    'voleybol_erkek': JumpNorms(
      poor: 38.0,
      belowAverage: 43.0,
      average: 48.0,
      aboveAverage: 55.0,
      excellent: 63.0,
    ),
    'futbol_erkek': JumpNorms(
      poor: 30.0,
      belowAverage: 35.0,
      average: 40.0,
      aboveAverage: 46.0,
      excellent: 52.0,
    ),
    'basketbol_kadin': JumpNorms(
      poor: 28.0,
      belowAverage: 33.0,
      average: 38.0,
      aboveAverage: 44.0,
      excellent: 50.0,
    ),
    'voleybol_kadin': JumpNorms(
      poor: 30.0,
      belowAverage: 35.0,
      average: 40.0,
      aboveAverage: 46.0,
      excellent: 52.0,
    ),
  };
  
  /// Turkish population force norms (Newton)
  static const Map<String, ForceNorms> turkishForceNorms = {
    'erkek_genç': ForceNorms(
      poor: 1800.0,
      belowAverage: 2200.0,
      average: 2600.0,
      aboveAverage: 3000.0,
      excellent: 3500.0,
    ),
    'erkek_yetiskin': ForceNorms(
      poor: 1600.0,
      belowAverage: 2000.0,
      average: 2400.0,
      aboveAverage: 2800.0,
      excellent: 3200.0,
    ),
    'kadin_genç': ForceNorms(
      poor: 1200.0,
      belowAverage: 1500.0,
      average: 1800.0,
      aboveAverage: 2100.0,
      excellent: 2500.0,
    ),
    'kadin_yetiskin': ForceNorms(
      poor: 1000.0,
      belowAverage: 1300.0,
      average: 1600.0,
      aboveAverage: 1900.0,
      excellent: 2200.0,
    ),
  };

  // =================== TURKISH UI TEXTS ===================
  
  /// Error messages - Turkish
  static const Map<String, String> errorMessages = {
    'baglanti_yok': 'Platform bağlantısı bulunamadı',
    'kalibre_edilmedi': 'Platform kalibre edilmemiş',
    'sporcu_secilmedi': 'Lütfen bir sporcu seçin',
    'test_tipi_secilmedi': 'Lütfen test türünü seçin',
    'agirlik_olculmedi': 'Vücut ağırlığı ölçülmedi',
    'veri_kaydi_hatasi': 'Veri kaydedilirken hata oluştu',
    'yetersiz_veri': 'Test için yeterli veri toplanamadı',
    'platform_bos_degil': 'Platformları boşaltın ve tekrar deneyin',
    'stabilite_yetersiz': 'Daha sabit durmaya çalışın',
    'test_yarida_kesildi': 'Test yarıda kesildi',
    'asimetri_yuksek': 'Asimetri çok yüksek (%{value}), daha dengeli hareket edin',
    'ucus_suresi_kisa': 'Uçuş süresi çok kısa, daha yüksek sıçramaya çalışın',
    'temas_suresi_uzun': 'Temas süresi çok uzun, daha hızlı hareket edin',
  };
  
  /// Success messages - Turkish
  static const Map<String, String> successMessages = {
    'baglanti_basarili': 'Platform başarıyla bağlandı',
    'kalibrasyon_tamam': 'Sıfır kalibrasyonu tamamlandı',
    'agirlik_olculdu': 'Vücut ağırlığı başarıyla ölçüldü',
    'test_tamamlandi': 'Test başarıyla tamamlandı',
    'veri_kaydedildi': 'Veriler başarıyla kaydedildi',
    'rapor_olusturuldu': 'Rapor başarıyla oluşturuldu',
    'sporcu_eklendi': 'Sporcu başarıyla eklendi',
    'sporcu_guncellendi': 'Sporcu bilgileri güncellendi',
  };
  
  /// Metric names - Turkish
  static const Map<String, String> metricNames = {
    'jumpHeight': 'Sıçrama Yüksekliği',
    'peakForce': 'Zirve Kuvvet',
    'averageForce': 'Ortalama Kuvvet',
    'rfdMax': 'Maksimum RFD',
    'rfd100ms': '100ms RFD',
    'rfd200ms': '200ms RFD',
    'impulse': 'Toplam İmpuls',
    'takeoffVelocity': 'Kalkış Hızı',
    'flightTime': 'Uçuş Süresi',
    'contactTime': 'Temas Süresi',
    'reactiveStrengthIndex': 'Reaktif Kuvvet İndeksi',
    'asymmetryIndex': 'Asimetri İndeksi',
    'leftPeakForce': 'Sol Zirve Kuvvet',
    'rightPeakForce': 'Sağ Zirve Kuvvet',
    'landingRFD': 'İniş RFD',
    'timeToStabilization': 'Stabilizasyon Süresi',
    'cogVelocity': 'Ağırlık Merkezi Hızı',
    'cogSway': 'Ağırlık Merkezi Salınımı',
    'bodyWeight': 'Vücut Ağırlığı',
    'powerOutput': 'Güç Çıkışı',
    'forceAt100ms': '100ms Kuvvet',
    'forceAt200ms': '200ms Kuvvet',
  };

  // =================== TECHNICAL CONSTANTS ===================
  
  /// Platform technical specifications
  static const double platformWidth = 40.0; // cm
  static const double platformHeight = 60.0; // cm
  static const int loadCellsPerPlatform = 4;
  static const double maxForceCapacity = 10000.0; // Newton
  static const int samplingRate = 1000; // Hz
  static const int bitResolution = 24; // bit
  
  /// Calibration standards
  static const double zeroCalibrationDuration = 3.0; // seconds
  static const double zeroStabilityThreshold = 5.0; // Newton
  static const double weightStabilityThreshold = 0.5; // kg
  static const int weightStableDuration = 3; // seconds
  static const double minimumBodyWeight = 25.0; // kg
  static const double maximumBodyWeight = 250.0; // kg
  
  /// VALD standards
  static const double asymmetryThreshold = 15.0; // percent
  static const double goodAsymmetryThreshold = 10.0; // percent
  static const double excellentAsymmetryThreshold = 5.0; // percent

  // =================== COLOR SCHEME ===================
  
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color secondaryBlue = Color(0xFF42A5F5);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color warningOrange = Color(0xFFEF6C00);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color neutralGrey = Color(0xFF616161);
  static const Color turkishFlag = Color(0xFFE30A17);
  static const Color goldAccent = Color(0xFFFFD700);
  
  /// Performance level colors
  static const Map<PerformanceLevel, Color> performanceColors = {
    PerformanceLevel.zayif: errorRed,
    PerformanceLevel.ortalamaAlti: warningOrange,
    PerformanceLevel.ortalama: neutralGrey,
    PerformanceLevel.ortalamaUstu: successGreen,
    PerformanceLevel.mukemmel: goldAccent,
  };

  // =================== NORMATIVE DATA GETTERS ===================
  
  /// Jump norms getter
  static Map<String, JumpNorms> get jumpNorms => TurkishNorms.jumpNorms;
  
  /// Force norms getter
  static Map<String, ForceNorms> get forceNorms => TurkishNorms.forceNorms;
  
  /// RFD norms getter
  static Map<String, RFDNorms> get rfdNorms => TurkishNorms.rfdNorms;
  
  /// Get sport-adjusted jump norms
  static JumpNorms? getSportAdjustedJumpNorms(String normKey, String? sport) {
    // Sport-specific adjustments
    final baseNorms = TurkishNorms.jumpNorms[normKey];
    if (baseNorms == null) return null;
    
    // Apply sport-specific multipliers
    double multiplier = 1.0;
    switch (sport?.toLowerCase()) {
      case 'basketball':
      case 'volleyball':
        multiplier = 1.15; // Higher expectations for jumping sports
        break;
      case 'athletics':
        multiplier = 1.25; // Highest expectations for track & field
        break;
      case 'football':
      case 'soccer':
        multiplier = 1.05; // Slightly higher for football
        break;
      default:
        multiplier = 1.0; // No adjustment for other sports
    }
    
    return JumpNorms(
      poor: baseNorms.poor * multiplier,
      belowAverage: baseNorms.belowAverage * multiplier,
      average: baseNorms.average * multiplier,
      aboveAverage: baseNorms.aboveAverage * multiplier,
      excellent: baseNorms.excellent * multiplier,
    );
  }
  
  /// Comprehensive performance assessment
  static Map<String, String> assessPerformance({
    required String normativeKey,
    String? sport,
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
    final assessment = <String, String>{};
    
    // Jump height assessment
    if (jumpHeight != null) {
      final norms = getSportAdjustedJumpNorms(normativeKey, sport) ?? 
                   TurkishNorms.jumpNorms[normativeKey];
      if (norms != null) {
        assessment['jumpHeight'] = norms.getLevel(jumpHeight);
      }
    }
    
    // Force assessment
    if (peakForce != null) {
      final norms = TurkishNorms.forceNorms[normativeKey];
      if (norms != null) {
        assessment['peakForce'] = norms.getLevel(peakForce);
      }
    }
    
    // RFD assessment
    if (rfd100 != null) {
      final norms = TurkishNorms.rfdNorms[normativeKey];
      if (norms != null) {
        assessment['rfd100'] = norms.getLevel(rfd100);
      }
    }
    
    // Asymmetry assessment
    if (asymmetryPercent != null) {
      if (asymmetryPercent <= excellentAsymmetryThreshold) {
        assessment['asymmetry'] = 'Excellent';
      } else if (asymmetryPercent <= goodAsymmetryThreshold) {
        assessment['asymmetry'] = 'Good';
      } else if (asymmetryPercent <= asymmetryThreshold) {
        assessment['asymmetry'] = 'Acceptable';
      } else {
        assessment['asymmetry'] = 'Needs Attention';
      }
    }
    
    // Overall assessment
    final scores = assessment.values.where((v) => v != null).toList();
    if (scores.isNotEmpty) {
      final excellentCount = scores.where((s) => s == 'Excellent').length;
      final totalCount = scores.length;
      
      if (excellentCount >= totalCount * 0.75) {
        assessment['overall'] = 'Excellent';
      } else if (excellentCount >= totalCount * 0.5) {
        assessment['overall'] = 'Good';
      } else {
        assessment['overall'] = 'Needs Improvement';
      }
    }
    
    return assessment;
  }

  // =================== HELPER METHODS ===================
  
  /// Get full test protocol by test type
  static TestProtocol? getProtocol(TestType testType) {
    return EnhancedTestProtocols.protocols[testType];
  }
  
  /// Get test name with language preference
  static String getTestName(TestType testType, {bool turkish = false}) {
    if (turkish) {
      return turkishTestNames[testType] ?? testNames[testType] ?? 'Bilinmeyen Test';
    }
    return testNames[testType] ?? 'Unknown Test';
  }
  
  /// Get tests by category
  static List<TestType> getTestsByCategory(TestCategory category) {
    return testCategories.entries
        .where((entry) => entry.value == category)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Get tests by difficulty
  static List<TestType> getTestsByDifficulty(TestDifficulty difficulty) {
    return testDifficulty.entries
        .where((entry) => entry.value == difficulty)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Get tests by sport
  static List<TestType> getTestsBySport(String sport) {
    return recommendedSports.entries
        .where((entry) => entry.value.contains(sport))
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Check if test is suitable for athlete level
  static bool isTestSuitableForLevel(TestType testType, AthleteLevel level) {
    final difficulty = testDifficulty[testType] ?? TestDifficulty.beginner;
    
    switch (level) {
      case AthleteLevel.beginner:
        return difficulty == TestDifficulty.beginner;
      case AthleteLevel.intermediate:
        return [TestDifficulty.beginner, TestDifficulty.intermediate].contains(difficulty);
      case AthleteLevel.advanced:
        return difficulty != TestDifficulty.expert;
      case AthleteLevel.elite:
        return true;
    }
  }
  
  /// Generate norm key for Turkish athlete
  static String getTurkishNormKey(String gender, int? age, String? sport) {
    final genderKey = gender.toLowerCase() == 'm' ? 'erkek' : 'kadin';
    
    // Sport-specific norm if available
    if (sport != null) {
      final sportKey = '${sport.toLowerCase()}_$genderKey';
      if (turkishJumpNorms.containsKey(sportKey)) {
        return sportKey;
      }
    }
    
    // Age group determination
    String ageKey = 'yetiskin';
    if (age != null) {
      if (age <= 25) {
        ageKey = 'genç';
      } else if (age >= 36) {
        ageKey = 'master';
      }
    }
    
    return '${genderKey}_$ageKey';
  }
  
  /// Get performance level from jump height
  static PerformanceLevel getJumpPerformanceLevel(double jumpHeight, String normKey) {
    final norms = turkishJumpNorms[normKey];
    if (norms == null) return PerformanceLevel.ortalama;
    return norms.getLevel(jumpHeight);
  }
  
  /// Get performance level from force
  static PerformanceLevel getForcePerformanceLevel(double force, String normKey) {
    final norms = turkishForceNorms[normKey];
    if (norms == null) return PerformanceLevel.ortalama;
    return norms.getLevel(force);
  }
  
  /// Validate test data against protocol rules
  static TestValidationResult validateTest(TestType testType, TestResult result) {
    final protocol = getProtocol(testType);
    if (protocol == null) {
      return TestValidationResult(isValid: false, errors: ['Protokol bulunamadı']);
    }
    
    final errors = <String>[];
    final warnings = <String>[];
    final rules = protocol.validationRules;
    
    // Check asymmetry
    if (rules.maxAsymmetry != null && result.asymmetryIndex != null) {
      if (result.asymmetryIndex! > rules.maxAsymmetry!) {
        errors.add(errorMessages['asimetri_yuksek']!
            .replaceAll('{value}', result.asymmetryIndex!.toStringAsFixed(1)));
      }
    }
    
    // Check flight time for jump tests
    if (rules.minFlightTime != null && result.flightTime != null) {
      if (result.flightTime! < rules.minFlightTime!) {
        errors.add(errorMessages['ucus_suresi_kisa']!);
      }
    }
    
    // Check contact time for reactive tests
    if (rules.maxContactTime != null && result.contactTime != null) {
      if (result.contactTime! > rules.maxContactTime!) {
        errors.add(errorMessages['temas_suresi_uzun']!);
      }
    }
    
    // Check peak force minimums
    if (rules.minPeakForce != null && result.peakForce != null) {
      if (result.peakForce! < rules.minPeakForce!) {
        warnings.add('Zirve kuvvet düşük: ${result.peakForce!.toStringAsFixed(0)}N');
      }
    }
    
    return TestValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
  
  /// Get test category Turkish name
  static String getTestCategoryName(TestCategory category, {bool turkish = true}) {
    if (turkish) {
      switch (category) {
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
    } else {
      return category.name;
    }
  }
  
  /// Get recommended test sequence for sport
  static List<TestType> getRecommendedSequence(String sport, AthleteLevel level) {
    final sportTests = getTestsBySport(sport);
    return sportTests.where((test) => isTestSuitableForLevel(test, level)).toList();
  }
}

// =================== ENUMS ===================

enum TestDifficulty {
  beginner,
  intermediate, 
  advanced,
  expert,
}

enum AthleteLevel {
  beginner,
  intermediate,
  advanced,
  elite,
}

enum PerformanceLevel {
  zayif,
  ortalamaAlti,
  ortalama,
  ortalamaUstu,
  mukemmel,
}

// =================== NORM CLASSES ===================

class JumpNorms {
  final double poor;
  final double belowAverage;
  final double average;
  final double aboveAverage;
  final double excellent;
  
  const JumpNorms({
    required this.poor,
    required this.belowAverage,
    required this.average,
    required this.aboveAverage,
    required this.excellent,
  });
  
  PerformanceLevel getLevel(double value) {
    if (value >= excellent) return PerformanceLevel.mukemmel;
    if (value >= aboveAverage) return PerformanceLevel.ortalamaUstu;
    if (value >= average) return PerformanceLevel.ortalama;
    if (value >= belowAverage) return PerformanceLevel.ortalamaAlti;
    return PerformanceLevel.zayif;
  }
}

class ForceNorms {
  final double poor;
  final double belowAverage;
  final double average;
  final double aboveAverage;
  final double excellent;
  
  const ForceNorms({
    required this.poor,
    required this.belowAverage,
    required this.average,
    required this.aboveAverage,
    required this.excellent,
  });
  
  PerformanceLevel getLevel(double value) {
    if (value >= excellent) return PerformanceLevel.mukemmel;
    if (value >= aboveAverage) return PerformanceLevel.ortalamaUstu;
    if (value >= average) return PerformanceLevel.ortalama;
    if (value >= belowAverage) return PerformanceLevel.ortalamaAlti;
    return PerformanceLevel.zayif;
  }
}

// =================== VALIDATION CLASSES ===================

class TestValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  
  const TestValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });
  
  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
}

class TestResult {
  final TestType testType;
  final DateTime timestamp;
  final Duration testDuration;
  final double? jumpHeight;
  final double? peakForce;
  final double? peakPower;
  final double? asymmetryIndex;
  final Duration? flightTime;
  final Duration? contactTime;
  final String? athleteGender;
  final Map<String, double> additionalMetrics;
  
  const TestResult({
    required this.testType,
    required this.timestamp,
    required this.testDuration,
    this.jumpHeight,
    this.peakForce,
    this.peakPower,
    this.asymmetryIndex,
    this.flightTime,
    this.contactTime,
    this.athleteGender,
    this.additionalMetrics = const {},
  });
}

// =================== EXTENSIONS ===================

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

extension PerformanceLevelExtension on PerformanceLevel {
  String get turkishName {
    switch (this) {
      case PerformanceLevel.zayif:
        return 'Zayıf';
      case PerformanceLevel.ortalamaAlti:
        return 'Ortalama Altı';
      case PerformanceLevel.ortalama:
        return 'Ortalama';
      case PerformanceLevel.ortalamaUstu:
        return 'Ortalama Üstü';
      case PerformanceLevel.mukemmel:
        return 'Mükemmel';
    }
  }
  
  Color get color => TestConstants.performanceColors[this]!;
  
  IconData get icon {
    switch (this) {
      case PerformanceLevel.zayif:
        return Icons.trending_down;
      case PerformanceLevel.ortalamaAlti:
        return Icons.remove;
      case PerformanceLevel.ortalama:
        return Icons.trending_flat;
      case PerformanceLevel.ortalamaUstu:
        return Icons.trending_up;
      case PerformanceLevel.mukemmel:
        return Icons.star;
    }
  }
  
  String get emoji {
    switch (this) {
      case PerformanceLevel.zayif:
        return '😞';
      case PerformanceLevel.ortalamaAlti:
        return '😐';
      case PerformanceLevel.ortalama:
        return '🙂';
      case PerformanceLevel.ortalamaUstu:
        return '😊';
      case PerformanceLevel.mukemmel:
        return '🏆';
    }
  }
}