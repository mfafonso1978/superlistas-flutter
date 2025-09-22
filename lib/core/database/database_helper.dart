// lib/core/database/database_helper.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static const _databaseName = "Superlistas.db";
  // <<< MUDANÇA 1: ATUALIZAR A VERSÃO DO BANCO DE DADOS >>>
  static const _databaseVersion = 7;

  static const String tableUsers = 'users';
  static const String tableCategories = 'categories';
  static const String tableShoppingLists = 'shopping_lists';
  static const String tableItems = 'items';
  static const String tableUnits = 'units';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE $tableUsers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE $tableCategories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        iconCodePoint INTEGER NOT NULL,
        colorValue INTEGER NOT NULL  -- <<< MUDANÇA 2: Adicionado no CREATE
      )
    ''');

    batch.execute('''
      CREATE TABLE $tableShoppingLists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        creationDate TEXT NOT NULL,
        isArchived INTEGER NOT NULL DEFAULT 0,
        budget REAL,
        userId TEXT NOT NULL, 
        FOREIGN KEY (userId) REFERENCES $tableUsers (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE $tableItems (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        price REAL NOT NULL DEFAULT 0.0,
        quantity REAL NOT NULL DEFAULT 1.0,
        unit TEXT NOT NULL DEFAULT 'un',
        isChecked INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        completionDate TEXT, 
        categoryId TEXT NOT NULL,
        shoppingListId TEXT NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES $tableCategories (id) ON DELETE CASCADE,
        FOREIGN KEY (shoppingListId) REFERENCES $tableShoppingLists (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE $tableUnits (
        name TEXT PRIMARY KEY
      )
    ''');

    await batch.commit(noResult: true);

    await _seedDatabase(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $tableItems ADD COLUMN completionDate TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE $tableItems ADD COLUMN price REAL NOT NULL DEFAULT 0.0');
      await db.execute('ALTER TABLE $tableItems ADD COLUMN unit TEXT NOT NULL DEFAULT "un"');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE $tableShoppingLists ADD COLUMN budget REAL');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableUsers (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL
        )
      ''');
      await db.execute('ALTER TABLE $tableShoppingLists ADD COLUMN userId TEXT');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableUnits (
          name TEXT PRIMARY KEY
        )
      ''');
      await _seedUnits(db);
    }
    // <<< MUDANÇA 3: NOVA MIGRAÇÃO >>>
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE $tableCategories ADD COLUMN colorValue INTEGER NOT NULL DEFAULT ${Colors.grey.value}');
      // Opcional: Atualizar as categorias existentes com cores únicas
      await _updateExistingCategoryColors(db);
    }
  }

  Future<void> _seedDatabase(Database db) async {
    await _seedCategories(db);
    await _seedUnits(db);
  }

  // <<< MUDANÇA 4: Gerador de cores e lista de cores base >>>
  static const List<Color> _baseColors = [
    Color(0xFF2196F3), Color(0xFF4CAF50), Color(0xFFFF9800), Color(0xFF9C27B0),
    Color(0xFFF44336), Color(0xFF00BCD4), Color(0xFF795548), Color(0xFF607D8B),
    Color(0xFFE91E63), Color(0xFF8BC34A), Color(0xFFFF5722), Color(0xFF673AB7),
    Color(0xFF009688), Color(0xFF3F51B5),
  ];

  Color _getColorForIndex(int index) {
    return _baseColors[index % _baseColors.length];
  }

  Future<void> _seedCategories(Database db) async {
    const uuid = Uuid();
    final List<Map<String, dynamic>> defaultCategories = [
      {'name': 'Hortifruti', 'icon': Icons.local_florist_outlined},
      {'name': 'Padaria', 'icon': Icons.bakery_dining_outlined},
      {'name': 'Açougue e Frios', 'icon': Icons.set_meal_outlined},
      {'name': 'Mercearia', 'icon': Icons.storefront_outlined},
      {'name': 'Limpeza', 'icon': Icons.cleaning_services_outlined},
      {'name': 'Higiene Pessoal', 'icon': Icons.spa_outlined},
      {'name': 'Bebidas', 'icon': Icons.local_bar_outlined},
      {'name': 'Outros', 'icon': Icons.label_outline_rounded},
    ];

    final batch = db.batch();
    for (var i = 0; i < defaultCategories.length; i++) {
      var cat = defaultCategories[i];
      batch.insert(tableCategories, {
        'id': uuid.v4(),
        'name': cat['name'],
        'iconCodePoint': (cat['icon'] as IconData).codePoint,
        'colorValue': _getColorForIndex(i).value, // <<< MUDANÇA 5: Adiciona cor no seed
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedUnits(Database db) async {
    final List<String> defaultUnits = ['un', 'pct', 'kg', 'g', 'L', 'ml', 'dz', 'm'];
    final batch = db.batch();
    for (var unit in defaultUnits) {
      batch.insert(tableUnits, {'name': unit}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  // <<< MUDANÇA 6: Novo método para atualizar cores de categorias antigas na migração >>>
  Future<void> _updateExistingCategoryColors(Database db) async {
    final categories = await db.query(tableCategories, columns: ['id']);
    final batch = db.batch();
    for (var i = 0; i < categories.length; i++) {
      final id = categories[i]['id'] as String;
      batch.update(
        tableCategories,
        {'colorValue': _getColorForIndex(i).value},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }
}