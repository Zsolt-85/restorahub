import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/appointment.dart';
import '../models/user.dart';

class DatabaseHelper {
  static const _dbVersion = 6;

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'restorahub.db');

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (var version = oldVersion + 1; version <= newVersion; version++) {
      switch (version) {
        case 2:
          await _migrateToV2(db);
          break;
        case 3:
          break;
        case 4:
          await _addColumnIfNotExists(db, 'users', 'phone', 'TEXT');
          break;
        case 5:
          await _addColumnIfNotExists(db, 'users', 'specialty', 'TEXT');
          await _addColumnIfNotExists(
              db, 'users', 'workStartTime', "TEXT DEFAULT '09:00'");
          await _addColumnIfNotExists(
              db, 'users', 'workEndTime', "TEXT DEFAULT '17:00'");
          await _addColumnIfNotExists(
              db, 'users', 'slotDurationMinutes', 'INTEGER DEFAULT 60');
          await _addColumnIfNotExists(
              db, 'appointments', 'durationMinutes', 'INTEGER DEFAULT 60');
          await db.update(
            'users',
            {'specialty': 'Massage'},
            where: "role = 'professional' AND (specialty IS NULL OR specialty = '')",
          );
          break;
        case 6:
          await _addColumnIfNotExists(
              db, 'appointments', 'customerEmail', 'TEXT');
          await _addColumnIfNotExists(
              db, 'appointments', 'professionalEmail', 'TEXT');
          break;
      }
    }
  }

  Future<void> _migrateToV2(Database db) async {
    final usersTable = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='users'",
    );
    if (usersTable.isEmpty) {
      await db.execute(_usersCreateSql);
    }

    final appointmentsTable = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='appointments'",
    );
    if (appointmentsTable.isEmpty) {
      await _createAppointmentsTable(db);
    } else {
      await _ensureAppointmentColumns(db);
    }
  }

  Future<void> _ensureAppointmentColumns(Database db) async {
    await _addColumnIfNotExists(db, 'appointments', 'service', 'TEXT');
    await _addColumnIfNotExists(db, 'appointments', 'dateTime', 'TEXT');
    await _addColumnIfNotExists(db, 'appointments', 'customerId', 'INTEGER');
    await _addColumnIfNotExists(db, 'appointments', 'customerName', 'TEXT');
    await _addColumnIfNotExists(db, 'appointments', 'customerPhone', 'TEXT');
    await _addColumnIfNotExists(db, 'appointments', 'professionalId', 'INTEGER');
    await _addColumnIfNotExists(
        db, 'appointments', 'professionalName', 'TEXT');
    await _addColumnIfNotExists(
        db, 'appointments', 'professionalPhone', 'TEXT');
    await _addColumnIfNotExists(
        db, 'appointments', 'durationMinutes', 'INTEGER DEFAULT 60');
    await _addColumnIfNotExists(db, 'appointments', 'customerEmail', 'TEXT');
    await _addColumnIfNotExists(db, 'appointments', 'professionalEmail', 'TEXT');
  }

  Future<void> _addColumnIfNotExists(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((col) => col['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  static const _usersCreateSql = '''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        phone TEXT NOT NULL DEFAULT '',
        specialty TEXT NOT NULL DEFAULT '',
        workStartTime TEXT NOT NULL DEFAULT '09:00',
        workEndTime TEXT NOT NULL DEFAULT '17:00',
        slotDurationMinutes INTEGER NOT NULL DEFAULT 60
      )
    ''';

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_usersCreateSql);
    await _createAppointmentsTable(db);
  }

  Future<void> _createAppointmentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE appointments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        service TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL DEFAULT 60,
        customerId INTEGER,
        customerName TEXT,
        customerPhone TEXT,
        customerEmail TEXT,
        professionalId INTEGER,
        professionalName TEXT,
        professionalPhone TEXT,
        professionalEmail TEXT
      )
    ''');
  }

  Map<String, dynamic> _userInsertMap(User user) {
    return {
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
      'password': user.password,
      'role': user.role,
      'specialty': user.specialty,
      'workStartTime': user.workStartTime,
      'workEndTime': user.workEndTime,
      'slotDurationMinutes': user.slotDurationMinutes,
    };
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    return db.insert('users', _userInsertMap(user));
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  Future<bool> isEmailTaken(String email, {int? excludeUserId}) async {
    final db = await database;
    final result = excludeUserId == null
        ? await db.query(
            'users',
            where: 'email = ?',
            whereArgs: [email.trim()],
            limit: 1,
          )
        : await db.query(
            'users',
            where: 'email = ? AND id != ?',
            whereArgs: [email.trim(), excludeUserId],
            limit: 1,
          );
    return result.isNotEmpty;
  }

  Future<List<User>> getUsersByRole(String role) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: [role],
      orderBy: 'name ASC',
    );
    return result.map((row) => User.fromMap(row)).toList();
  }

  Future<List<User>> getProfessionalsBySpecialty(String specialty) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: "role = 'professional' AND specialty = ?",
      whereArgs: [specialty],
      orderBy: 'name ASC',
    );
    return result.map((row) => User.fromMap(row)).toList();
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return db.update(
      'users',
      _userInsertMap(user),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> syncUserInAppointments(User user) async {
    if (user.id == null) return;

    final db = await database;

    await db.update(
      'appointments',
      {
        'customerName': user.name,
        'customerPhone': user.phone,
        'customerEmail': user.email,
      },
      where: 'customerId = ?',
      whereArgs: [user.id],
    );

    await db.update(
      'appointments',
      {
        'professionalName': user.name,
        'professionalPhone': user.phone,
        'professionalEmail': user.email,
      },
      where: 'professionalId = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> insertAppointment(Appointment appt) async {
    final db = await database;
    return db.insert('appointments', appt.toMap());
  }

  Future<List<Appointment>> getAppointments() async {
    final db = await database;
    final result = await db.query(
      'appointments',
      orderBy: 'dateTime ASC',
    );
    return result.map((e) => Appointment.fromMap(e)).toList();
  }

  Future<int> updateAppointment(Appointment appt) async {
    final db = await database;
    return db.update(
      'appointments',
      appt.toMap(),
      where: 'id = ?',
      whereArgs: [appt.id],
    );
  }

  Future<int> deleteAppointment(int id) async {
    final db = await database;
    return db.delete(
      'appointments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
