import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Service class for handling local storage of family surveys using SQLite.
class LocalSurveyService {
  static const _databaseName = "FamilySurvey.db";
  static const _databaseVersion = 2;
  static const table = 'family_surveys';
  static const tableVillages = 'villages';

  static const columnId = 'id'; // Corresponds to the server's familySurveyId
  static const columnHeadName = 'head_name';
  static const columnHouseNo = 'house_no';
  static const columnSurveyData = 'survey_data';
  static const columnUpdatedAt = 'updated_at';

  // Make this a singleton class.
  LocalSurveyService._privateConstructor();
  static final LocalSurveyService instance = LocalSurveyService._privateConstructor();

  // Only have a single app-wide reference to the database.
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // this opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY,
            $columnHeadName TEXT NOT NULL,
            $columnHouseNo TEXT NOT NULL,
            $columnSurveyData TEXT NOT NULL,
            $columnUpdatedAt TEXT NOT NULL
          )
          ''');
    await db.execute('''
          CREATE TABLE $tableVillages (
            id INTEGER PRIMARY KEY,
            payload TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
          ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
          CREATE TABLE $tableVillages (
            id INTEGER PRIMARY KEY,
            payload TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
          ''');
    }
  }

  /// Inserts a new survey or updates an existing one based on the ID.
  Future<int> insertOrUpdate(Map<String, dynamic> surveyData) async {
    final db = await instance.database;
    final id = surveyData['family']['id'];
    final headName = surveyData['members']?[0]?['name'] ?? '';
    final houseNo = surveyData['family']?['house_no'] ?? '';

    final Map<String, dynamic> row = {
      columnId: id,
      columnHeadName: headName,
      columnHouseNo: houseNo,
      columnSurveyData: jsonEncode(surveyData),
      columnUpdatedAt: DateTime.now().toIso8601String(),
    };

    if (id == null) {
      // For new surveys, we can't use the server ID. We'll use a temporary negative ID
      // based on a hash of headName and houseNo to handle upserts.
      final tempId = -(headName.hashCode ^ houseNo.hashCode);
      row[columnId] = tempId;
    }

    return await db.insert(
      table,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetches all locally saved surveys.
  Future<List<Map<String, dynamic>>> queryAllSurveys() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(table, orderBy: "$columnUpdatedAt DESC");

    // Decode the JSON data and add a flag to identify them as local drafts.
    return maps.map((map) {
      final survey = jsonDecode(map[columnSurveyData] as String) as Map<String, dynamic>;
      // The ID in the DB might be a temporary negative one, so we use the one from the JSON.
      final serverId = survey['family']['id'];
      return {
        'id': serverId,
        'head_name': map[columnHeadName],
        'house_no': map[columnHouseNo],
        'status': 'local_draft', // Custom status for UI
        'is_local': true,
        'survey_data': survey, // Pass the full data for opening the form
      };
    }).toList();
  }

  /// Deletes a survey from the local database by its server ID.
  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  /// Saves the village payload to local storage.
  Future<void> saveVillage(Map<String, dynamic> villageData) async {
    final db = await instance.database;
    final village = villageData['data']?['village'];
    if (village != null && village['id'] != null) {
      await db.insert(
        tableVillages,
        {
          'id': village['id'],
          'payload': jsonEncode(villageData),
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Retrieves the most recently saved village data.
  Future<Map<String, dynamic>?> getLastSavedVillage() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableVillages,
      orderBy: '$columnUpdatedAt DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return jsonDecode(maps.first['payload'] as String) as Map<String, dynamic>;
    }
    return null;
  }
}