import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/theme.dart';
import '../models/question.dart';

class LocalDb {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'quizzbuilder.db');
    return await openDatabase(
      path,
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE questions ADD COLUMN theme_name_en TEXT');
          await db.execute('ALTER TABLE questions ADD COLUMN theme_name_fr TEXT');
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY,
            name_en TEXT,
            name_fr TEXT,
            is_active INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE themes (
            id INTEGER PRIMARY KEY,
            category_id INTEGER,
            name_en TEXT,
            name_fr TEXT,
            description_en TEXT,
            description_fr TEXT,
            is_free INTEGER,
            is_active INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE questions (
            id INTEGER PRIMARY KEY,
            theme INTEGER,
            theme_name_en TEXT,
            theme_name_fr TEXT,
            question_en TEXT,
            question_fr TEXT,
            answer_1_en TEXT,
            answer_1_fr TEXT,
            answer_2_en TEXT,
            answer_2_fr TEXT,
            answer_3_en TEXT,
            answer_3_fr TEXT,
            answer_4_en TEXT,
            answer_4_fr TEXT,
            correct_answer INTEGER,
            difficulty TEXT,
            verification_reason TEXT,
            source_url TEXT
          )
        ''');
      },
    );
  }

  // CATEGORY CRUD
  static Future<void> insertCategories(List<Category> categories) async {
    final db = await database;
    final batch = db.batch();
    for (final c in categories) {
      batch.insert('categories', {
        'id': c.id,
        'name_en': c.nameEn,
        'name_fr': c.nameFr,
        'is_active': c.isActive ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories');
    return maps.map((m) => Category(
      id: m['id'] as int,
      nameEn: m['name_en'] as String,
      nameFr: m['name_fr'] as String,
      isActive: (m['is_active'] as int) == 1,
      themesCount: 0, // Default to 0 for cached data
    )).toList();
  }

  // THEME CRUD
  static Future<void> insertThemes(List<Theme> themes) async {
    final db = await database;
    final batch = db.batch();
    for (final t in themes) {
      batch.insert('themes', {
        'id': t.id,
        'category_id': t.category,
        'name_en': t.nameEn,
        'name_fr': t.nameFr,
        'description_en': t.descriptionEn,
        'description_fr': t.descriptionFr,
        'is_free': t.isFree ? 1 : 0,
        'is_active': t.isActive ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Theme>> getThemesByCategory(int categoryId) async {
    final db = await database;
    final maps = await db.query('themes', where: 'category_id = ?', whereArgs: [categoryId]);
    return maps.map((m) => Theme(
      id: m['id'] as int,
      category: (m['category_id'] as int).toString(),
      nameEn: m['name_en'] as String,
      nameFr: m['name_fr'] as String,
      descriptionEn: m['description_en'] as String?,
      descriptionFr: m['description_fr'] as String?,
      isFree: (m['is_free'] as int) == 1,
      isActive: (m['is_active'] as int) == 1,
      questionsCount: 0, // Default to 0 for cached data
      sourceUrl: null,
    )).toList();
  }

  static Future<Theme?> getThemeById(int themeId) async {
    final db = await database;
    final maps = await db.query('themes', where: 'id = ?', whereArgs: [themeId], limit: 1);
    if (maps.isEmpty) return null;
    final m = maps.first;
    return Theme(
      id: m['id'] as int,
      category: (m['category_id'] as int).toString(),
      nameEn: m['name_en'] as String,
      nameFr: m['name_fr'] as String,
      descriptionEn: m['description_en'] as String?,
      descriptionFr: m['description_fr'] as String?,
      isFree: (m['is_free'] as int) == 1,
      isActive: (m['is_active'] as int) == 1,
      questionsCount: 0,
      sourceUrl: null,
    );
  }

  // QUESTION CRUD
  static Future<void> insertQuestions(List<Question> questions) async {
    final db = await database;
    final batch = db.batch();
    for (final q in questions) {
      batch.insert('questions', q.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Question>> getQuestionsByTheme(int themeId) async {
    final db = await database;
    final maps = await db.query('questions', where: 'theme = ?', whereArgs: [themeId]);
    return maps.map((m) => Question.fromJson(m)).toList();
  }

  // Clear all local data (for logout or refresh)
  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('categories');
    await db.delete('themes');
    await db.delete('questions');
  }
}
