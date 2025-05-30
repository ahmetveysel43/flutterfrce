// lib/services/database_service.dart - FIXED VERSION
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../domain/entities/athlete.dart';
import '../domain/entities/force_data.dart';
import '../core/constants/test_constants.dart';
import '../core/extensions/list_extensions.dart';
import 'dart:math' as math;
import 'dart:convert';

/// VALD ForceDecks compatible database service - FIXED VERSION
class DatabaseService {
  static Database? _database;
  
  // Cache management
  List<Athlete>? _athletesCache;
  Map<String, List<TestSession>> _testSessionsCache = {};

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'izforce_vald.db');
    
    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    debugPrint('🗄️ Creating IzForce VALD database v$version');
    
    // Athletes table
    await db.execute('''
      CREATE TABLE athletes(
        id TEXT PRIMARY KEY,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        date_of_birth TEXT,
        gender TEXT NOT NULL,
        height REAL,
        weight REAL,
        sport TEXT,
        position TEXT,
        team TEXT,
        coach TEXT,
        email TEXT,
        phone TEXT,
        notes TEXT,
        injury_history TEXT,
        dominant_leg TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        profile_image_url TEXT,
        metadata TEXT
      )
    ''');

    // Test sessions table
    await db.execute('''
      CREATE TABLE test_sessions(
        id TEXT PRIMARY KEY,
        athlete_id TEXT NOT NULL,
        test_type TEXT NOT NULL,
        session_date TEXT NOT NULL,
        body_weight REAL,
        zero_offset_left REAL NOT NULL DEFAULT 0,
        zero_offset_right REAL NOT NULL DEFAULT 0,
        session_status TEXT NOT NULL DEFAULT 'completed',
        session_duration INTEGER,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (athlete_id) REFERENCES athletes (id) ON DELETE CASCADE
      )
    ''');

    // Force data table
    await db.execute('''
      CREATE TABLE force_data(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        left_grf REAL NOT NULL,
        right_grf REAL NOT NULL,
        total_grf REAL NOT NULL,
        left_cop_x REAL NOT NULL,
        left_cop_y REAL NOT NULL,
        right_cop_x REAL NOT NULL,
        right_cop_y REAL NOT NULL,
        asymmetry_index REAL NOT NULL,
        load_rate REAL NOT NULL,
        left_load_cells TEXT,
        right_load_cells TEXT,
        FOREIGN KEY (session_id) REFERENCES test_sessions (id) ON DELETE CASCADE
      )
    ''');

    // Test results table
    await db.execute('''
      CREATE TABLE test_results(
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        metric_name TEXT NOT NULL,
        metric_value REAL NOT NULL,
        metric_unit TEXT,
        performance_level TEXT,
        percentile REAL,
        is_primary_metric INTEGER NOT NULL DEFAULT 0,
        calculated_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES test_sessions (id) ON DELETE CASCADE
      )
    ''');

    await _createIndexes(db);
    debugPrint('✅ Database created successfully');
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_athletes_active ON athletes(is_active)');
    await db.execute('CREATE INDEX idx_test_sessions_athlete ON test_sessions(athlete_id)');
    await db.execute('CREATE INDEX idx_force_data_session ON force_data(session_id)');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 Upgrading database from v$oldVersion to v$newVersion');
    
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS athletes');
      await db.execute('DROP TABLE IF EXISTS test_sessions');
      await db.execute('DROP TABLE IF EXISTS force_data');
      await db.execute('DROP TABLE IF EXISTS test_results');
      await _createDatabase(db, newVersion);
    }
  }

  // ATHLETE OPERATIONS - FIXED TYPE CASTING
  Future<String> insertAthlete(Athlete athlete) async {
    final db = await database;
    try {
      await db.insert('athletes', _athleteToMap(athlete));
      _clearAthletesCache();
      debugPrint('✅ Athlete inserted: ${athlete.fullName}');
      return athlete.id;
    } catch (e) {
      debugPrint('❌ Error inserting athlete: $e');
      throw Exception('Failed to insert athlete: $e');
    }
  }

  Future<Athlete?> getAthlete(String id) async {
    final db = await database;
    try {
      final maps = await db.query(
        'athletes',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return _athleteFromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting athlete: $e');
      return null;
    }
  }

  Future<List<Athlete>> getAllAthletes() async {
    if (_athletesCache != null) return _athletesCache!;
    
    final db = await database;
    try {
      final maps = await db.query(
        'athletes',
        orderBy: 'first_name ASC, last_name ASC',
      );
      
      _athletesCache = maps.map((map) => _athleteFromMap(map)).toList();
      return _athletesCache!;
    } catch (e) {
      debugPrint('❌ Error getting athletes: $e');
      return [];
    }
  }

  Future<bool> updateAthlete(Athlete athlete) async {
    final db = await database;
    try {
      final count = await db.update(
        'athletes',
        _athleteToMap(athlete),
        where: 'id = ?',
        whereArgs: [athlete.id],
      );
      
      _clearAthletesCache();
      debugPrint('✅ Athlete updated: ${athlete.fullName}');
      return count > 0;
    } catch (e) {
      debugPrint('❌ Error updating athlete: $e');
      return false;
    }
  }

  Future<bool> deleteAthlete(String id) async {
    final db = await database;
    try {
      final count = await db.delete(
        'athletes',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      _clearAthletesCache();
      debugPrint('✅ Athlete deleted: $id');
      return count > 0;
    } catch (e) {
      debugPrint('❌ Error deleting athlete: $e');
      return false;
    }
  }

  // TEST SESSION OPERATIONS
  Future<String> createTestSession({
    required String athleteId,
    required TestType testType,
    double? bodyWeight,
    double zeroOffsetLeft = 0.0,
    double zeroOffsetRight = 0.0,
  }) async {
    final db = await database;
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      await db.insert('test_sessions', {
        'id': sessionId,
        'athlete_id': athleteId,
        'test_type': testType.name,
        'session_date': DateTime.now().toIso8601String(),
        'body_weight': bodyWeight,
        'zero_offset_left': zeroOffsetLeft,
        'zero_offset_right': zeroOffsetRight,
        'session_status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ Test session created: $sessionId');
      return sessionId;
    } catch (e) {
      debugPrint('❌ Error creating test session: $e');
      throw Exception('Failed to create test session: $e');
    }
  }

  // MOCK DATA GENERATION - SIMPLIFIED
  Future<void> generateMockData() async {
    debugPrint('🎭 Generating mock data...');
    
    try {
      // Check if athletes already exist
      final existingAthletes = await getAllAthletes();
      if (existingAthletes.isNotEmpty) {
        debugPrint('✅ Mock data already exists (${existingAthletes.length} athletes)');
        return;
      }

      // Create mock athletes
      final mockAthletes = Athlete.createMockAthletes();
      for (final athlete in mockAthletes) {
        await insertAthlete(athlete);
      }
      
      debugPrint('✅ Mock data generation completed');
    } catch (e) {
      debugPrint('❌ Error generating mock data: $e');
    }
  }

  // DATABASE UTILITY METHODS
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;
    
    try {
      final athleteCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM athletes')
      ) ?? 0;
      
      final sessionCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM test_sessions')
      ) ?? 0;
      
      return {
        'athletes': athleteCount,
        'test_sessions': sessionCount,
        'database_size_mb': await _getDatabaseSizeMB(),
      };
    } catch (e) {
      debugPrint('❌ Error getting database stats: $e');
      return {};
    }
  }

  Future<double> _getDatabaseSizeMB() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'izforce_vald.db');
      final file = File(path);
      
      if (await file.exists()) {
        final sizeBytes = await file.length();
        return sizeBytes / (1024 * 1024);
      }
      
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // HELPER METHODS - FIXED TYPE CASTING
  Map<String, dynamic> _athleteToMap(Athlete athlete) {
    return {
      'id': athlete.id,
      'first_name': athlete.firstName,
      'last_name': athlete.lastName,
      'date_of_birth': athlete.dateOfBirth?.toIso8601String(),
      'gender': athlete.gender,
      'height': athlete.height,
      'weight': athlete.weight,
      'sport': athlete.sport,
      'position': athlete.position,
      'team': athlete.team,
      'coach': athlete.coach,
      'email': athlete.email,
      'phone': athlete.phone,
      'notes': athlete.notes,
      'injury_history': jsonEncode(athlete.injuryHistory),
      'dominant_leg': athlete.dominantLeg,
      'is_active': athlete.isActive ? 1 : 0,
      'created_at': athlete.createdAt.toIso8601String(),
      'updated_at': athlete.updatedAt.toIso8601String(),
      'profile_image_url': athlete.profileImageUrl,
      'metadata': jsonEncode(athlete.metadata),
    };
  }

  Athlete _athleteFromMap(Map<String, dynamic> map) {
    return Athlete(
      id: map['id'] as String,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      dateOfBirth: map['date_of_birth'] != null 
          ? DateTime.parse(map['date_of_birth'] as String)
          : null,
      gender: map['gender'] as String,
      height: map['height'] != null ? (map['height'] as num).toDouble() : null,
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      sport: map['sport'] as String?,
      position: map['position'] as String?,
      team: map['team'] as String?,
      coach: map['coach'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      notes: map['notes'] as String?,
      injuryHistory: map['injury_history'] != null 
          ? List<String>.from(jsonDecode(map['injury_history'] as String))
          : [],
      dominantLeg: map['dominant_leg'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      profileImageUrl: map['profile_image_url'] as String?,
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['metadata'] as String))
          : {},
    );
  }

  void _clearAthletesCache() {
    _athletesCache = null;
  }

  void clearAllCaches() {
    _athletesCache = null;
    _testSessionsCache.clear();
    debugPrint('🧹 All caches cleared');
  }

  // Quick find athlete by name
  Future<Athlete?> findAthleteByName(String firstName, String lastName) async {
    final athletes = await getAllAthletes();
    try {
      return athletes.firstWhere(
        (athlete) => athlete.firstName == firstName && athlete.lastName == lastName,
      );
    } catch (e) {
      return null;
    }
  }

  // Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

/// Test session model for database operations
class TestSession {
  final String id;
  final String athleteId;
  final TestType testType;
  final DateTime sessionDate;
  final double? bodyWeight;
  final String sessionStatus;
  final Duration? sessionDuration;

  const TestSession({
    required this.id,
    required this.athleteId,
    required this.testType,
    required this.sessionDate,
    this.bodyWeight,
    required this.sessionStatus,
    this.sessionDuration,
  });
}