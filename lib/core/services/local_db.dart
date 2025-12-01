import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
// sqflite isn't supported on web. Use conditional in-memory fallback there.
import 'package:sqflite/sqflite.dart';

class LocalDb {
  static final LocalDb _instance = LocalDb._();
  factory LocalDb() => _instance;
  LocalDb._();

  Database? _db;
  final List<Map<String, Object?>> _inMemory = [];

  Future<Database> get db async {
    if (kIsWeb) {
      throw StateError('Local DB not available on web; use in-memory methods directly');
    }
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'gmdcrr.db');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, v) async {
        await db.execute('''
        CREATE TABLE village_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          payload TEXT,
          imagePath TEXT,
          lat REAL,
          lng REAL,
          status TEXT,
          createdAt INTEGER,
          remoteSurveyId INTEGER
        )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE village_entries ADD COLUMN remoteSurveyId INTEGER');
        }
      },
    );
    return _db!;
  }

  Future<int> insertEntry(Map<String, Object?> row) async {
    if (kIsWeb) {
      // emulate autoincrement id
      final id = (_inMemory.isEmpty) ? 1 : ((_inMemory.map((r) => r['id'] as int).reduce((a, b) => a > b ? a : b)) + 1);
      final copy = Map<String, Object?>.from(row);
      copy['id'] = id;
      _inMemory.add(copy);
      return id;
    }
    final d = await db;
    return d.insert('village_entries', row);
  }

  Future<List<Map<String, Object?>>> pendingEntries() async {
    if (kIsWeb) {
      return _inMemory.where((r) => r['status'] == 'pending').toList();
    }
    final d = await db;
    return d.query('village_entries', where: 'status = ?', whereArgs: ['pending']);
  }

  Future<int> deleteEntry(int id) async {
    if (kIsWeb) {
      final idx = _inMemory.indexWhere((r) => r['id'] == id);
      if (idx >= 0) {
        _inMemory.removeAt(idx);
        return 1;
      }
      return 0;
    }
    final d = await db;
    return d.delete('village_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> markUploaded(int id) async {
    if (kIsWeb) {
      final idx = _inMemory.indexWhere((r) => r['id'] == id);
      if (idx >= 0) {
        _inMemory[idx]['status'] = 'uploaded';
        return 1;
      }
      return 0;
    }
    final d = await db;
    return d.update('village_entries', {'status': 'uploaded'}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateEntry(int id, Map<String, Object?> values) async {
    if (kIsWeb) {
      final idx = _inMemory.indexWhere((r) => r['id'] == id);
      if (idx >= 0) {
        _inMemory[idx].addAll(values);
        return 1;
      }
      return 0;
    }
    final d = await db;
    return d.update('village_entries', values, where: 'id = ?', whereArgs: [id]);
  }
}
