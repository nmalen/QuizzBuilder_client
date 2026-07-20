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
      version: 3,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE questions ADD COLUMN theme_name_en TEXT');
          await db.execute('ALTER TABLE questions ADD COLUMN theme_name_fr TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE themes ADD COLUMN questions_count INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE themes ADD COLUMN easy_questions_count INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE themes ADD COLUMN medium_questions_count INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE themes ADD COLUMN hard_questions_count INTEGER DEFAULT 0');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS entitlements (
              theme_id INTEGER PRIMARY KEY
            )
          ''');
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
            is_active INTEGER,
            questions_count INTEGER DEFAULT 0,
            easy_questions_count INTEGER DEFAULT 0,
            medium_questions_count INTEGER DEFAULT 0,
            hard_questions_count INTEGER DEFAULT 0
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
        await db.execute('''
          CREATE TABLE entitlements (
            theme_id INTEGER PRIMARY KEY
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
        'questions_count': t.questionsCount,
        'easy_questions_count': t.easyQuestionsCount,
        'medium_questions_count': t.mediumQuestionsCount,
        'hard_questions_count': t.hardQuestionsCount,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Theme _themeFromRow(Map<String, Object?> m) {
    return Theme(
      id: m['id'] as int,
      category: (m['category_id'] as int).toString(),
      nameEn: m['name_en'] as String,
      nameFr: m['name_fr'] as String,
      descriptionEn: m['description_en'] as String?,
      descriptionFr: m['description_fr'] as String?,
      isFree: (m['is_free'] as int) == 1,
      isActive: (m['is_active'] as int) == 1,
      questionsCount: (m['questions_count'] as int?) ?? 0,
      easyQuestionsCount: (m['easy_questions_count'] as int?) ?? 0,
      mediumQuestionsCount: (m['medium_questions_count'] as int?) ?? 0,
      hardQuestionsCount: (m['hard_questions_count'] as int?) ?? 0,
      sourceUrl: null,
    );
  }

  static Future<List<Theme>> getThemesByCategory(int categoryId) async {
    final db = await database;
    final maps = await db.query('themes', where: 'category_id = ?', whereArgs: [categoryId]);
    return maps.map(_themeFromRow).toList();
  }

  static Future<Theme?> getThemeById(int themeId) async {
    final db = await database;
    final maps = await db.query('themes', where: 'id = ?', whereArgs: [themeId], limit: 1);
    if (maps.isEmpty) return null;
    return _themeFromRow(maps.first);
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

  /// Cheap count query, used to check whether a theme's questions are
  /// already fully cached before triggering a network re-download.
  static Future<int> getQuestionCountForTheme(int themeId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM questions WHERE theme = ?',
      [themeId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ENTITLEMENTS
  /// Persists the set of theme ids the current user has access to (free
  /// themes are not included; callers add those via `Theme.isFree`).
  /// Used so `isThemeEntitled` still works offline after an app restart,
  /// before any network refresh has had a chance to run.
  static Future<void> setEntitledThemeIds(Set<int> themeIds) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('entitlements');
      final batch = txn.batch();
      for (final id in themeIds) {
        batch.insert(
          'entitlements',
          {'theme_id': id},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  static Future<Set<int>> getEntitledThemeIds() async {
    final db = await database;
    final maps = await db.query('entitlements');
    return maps.map((m) => m['theme_id'] as int).toSet();
  }

  // Clear all local data (for logout or refresh)
  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('categories');
    await db.delete('themes');
    await db.delete('questions');
    await db.delete('entitlements');
  }
}
