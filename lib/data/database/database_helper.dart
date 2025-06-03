// SQLite database helper
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tuckshop.db');

    return openDatabase(
      path,
      version: 3, // Incremented version
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE employees (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            role TEXT,
            duty TEXT,
            performanceScore INTEGER DEFAULT 0
          )
        ''');
        db.execute('''
          CREATE TABLE stocks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            quantity INTEGER,
            category TEXT,
            expiryDate TEXT
          )
        ''');
        db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT,
            role TEXT
          )
        ''');
        // Insert default admin
        db.insert('users', {
          'username': 'admin',
          'password': 'admin123',
          'role': 'admin',
        });
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 2) {
          db.execute(
            'ALTER TABLE employees ADD COLUMN performanceScore INTEGER DEFAULT 0',
          );
        }
        if (oldVersion < 3) {
          db.execute('''
            CREATE TABLE stocks (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              quantity INTEGER,
              category TEXT,
              expiryDate TEXT
            )
          ''');
        }
      },
    );
  }
}
