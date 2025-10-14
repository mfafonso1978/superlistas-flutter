// lib/core/database/database_helper.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static const _databaseName = "Superlistas.db";
  // <<< VERSÃO INCREMENTADA PARA ACIONAR A MIGRAÇÃO >>>
  static const _databaseVersion = 9;

  static const String tableUsers = 'users';
  static const String tableCategories = 'categories';
  static const String tableShoppingLists = 'shopping_lists';
  static const String tableItems = 'items';
  static const String tableUnits = 'units';
  static const String tableSyncQueue = 'sync_queue';

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
        password TEXT NOT NULL,
        photoUrl TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE $tableCategories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        iconCodePoint INTEGER NOT NULL,
        colorValue INTEGER NOT NULL
      )
    ''');

    // <<< ESTRUTURA ATUALIZADA PARA NOVAS INSTALAÇÕES >>>
    batch.execute('''
      CREATE TABLE $tableShoppingLists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        creationDate TEXT NOT NULL,
        isArchived INTEGER NOT NULL DEFAULT 0,
        budget REAL,
        ownerId TEXT NOT NULL,
        members TEXT NOT NULL,
        FOREIGN KEY (ownerId) REFERENCES $tableUsers (id) ON DELETE CASCADE
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

    batch.execute('''
      CREATE TABLE $tableSyncQueue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        entityType TEXT NOT NULL,
        entityId TEXT NOT NULL,
        operationType TEXT NOT NULL,
        payload TEXT,
        timestamp TEXT NOT NULL
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
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE $tableCategories ADD COLUMN colorValue INTEGER NOT NULL DEFAULT ${Colors.grey.value}');
      await _updateExistingCategoryColors(db);
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE $tableSyncQueue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT NOT NULL,
          entityType TEXT NOT NULL,
          entityId TEXT NOT NULL,
          operationType TEXT NOT NULL,
          payload TEXT,
          timestamp TEXT NOT NULL
        )
      ''');
    }
    // <<< NOVO SCRIPT DE MIGRAÇÃO PARA A VERSÃO 9 >>>
    if (oldVersion < 9) {
      await db.transaction((txn) async {
        // 1. Renomeia a coluna antiga para a nova
        await txn.execute('ALTER TABLE $tableShoppingLists RENAME COLUMN userId TO ownerId');
        // 2. Adiciona a nova coluna de membros
        await txn.execute('ALTER TABLE $tableShoppingLists ADD COLUMN members TEXT');
        // 3. Adiciona a coluna de foto de perfil na tabela de usuários
        await txn.execute('ALTER TABLE $tableUsers ADD COLUMN photoUrl TEXT');
      });

      // 4. Preenche a nova coluna 'members' com o 'ownerId' de cada lista
      final lists = await db.query(tableShoppingLists, columns: ['id', 'ownerId']);
      final batch = db.batch();
      for (final list in lists) {
        final ownerId = list['ownerId'];
        if (ownerId != null) {
          batch.update(
            tableShoppingLists,
            {'members': jsonEncode([ownerId])}, // Cria uma lista JSON com o ownerId
            where: 'id = ?',
            whereArgs: [list['id']],
          );
        }
      }
      await batch.commit(noResult: true);
    }
  }

  Future<void> _seedDatabase(Database db) async {
    await _seedCategories(db);
    await _seedUnits(db);
  }

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
        'colorValue': _getColorForIndex(i).value,
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