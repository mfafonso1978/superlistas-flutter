// lib/data/datasources/local_datasource.dart
import 'package:sqflite/sqflite.dart';
import 'package:superlistas/core/database/database_helper.dart';
import 'package:superlistas/data/models/category_model.dart';
import 'package:superlistas/data/models/item_model.dart';
import 'package:superlistas/data/models/shopping_list_model.dart';
import 'package:superlistas/data/models/sync_operation_model.dart';
import 'package:superlistas/data/models/user_model.dart';

abstract class LocalDataSource {
  // --- Métodos de Usuário ---
  Future<void> signUp(UserModel user);
  Future<UserModel?> getUserByEmail(String email);
  Future<UserModel?> getUserById(String id);
  Future<List<UserModel>> getAllUsers();
  Future<int> updateUserPassword(String email, String newPassword);

  // --- Métodos para Categorias ---
  Future<void> addCategory(CategoryModel category);
  Future<List<CategoryModel>> getAllCategories();
  Future<CategoryModel> getCategoryById(String id);
  Future<int> updateCategory(CategoryModel category);
  Future<int> deleteCategory(String id);

  // --- Métodos para Listas de Compras ---
  Future<void> addShoppingList(ShoppingListModel shoppingList);
  Future<List<ShoppingListModel>> getAllShoppingListsForUser(String userId);
  Future<ShoppingListModel?> getShoppingListById(String id);
  Future<int> updateShoppingList(ShoppingListModel shoppingList);
  Future<int> deleteShoppingList(String id);
  Future<void> deleteAllShoppingListsForUser(String userId);

  // --- Métodos para Itens ---
  Future<void> addItem(ItemModel item);
  Future<List<ItemModel>> getItemsFromList(String shoppingListId);
  Future<int> updateItem(ItemModel item);
  Future<int> deleteItem(String id);
  Future<int> countTotalItems(String shoppingListId);
  Future<int> countCheckedItems(String shoppingListId);
  Future<List<ItemModel>> getAllItems();
  Future<double> getTotalCostOfList(String shoppingListId);
  Future<List<ItemModel>> getAllItemsForUser(String userId);
  Future<List<Map<String, dynamic>>> getRichShoppingListsForUser(String userId);
  Future<void> deleteAllItemsFromList(String shoppingListId);

  // --- Métodos de Importação/Exportação e Sincronização ---
  Future<void> performImport(String userId, Map<String, dynamic> data);
  Future<Map<String, dynamic>> getAllDataForUser(String userId);
  Future<void> deleteAllUserData(String userId);

  // --- Métodos para Unidades ---
  Future<List<String>> getAllUnits();
  Future<void> addUnit(String name);
  Future<int> deleteUnit(String name);
  Future<int> updateUnit(String oldName, String newName);

  // --- Métodos para a Fila de Sincronização ---
  Future<void> addToSyncQueue(SyncOperationModel operation);
  Future<List<SyncOperationModel>> getPendingSyncOperations(String userId);
  Future<void> removeSyncOperation(int id);
}

class LocalDataSourceImpl implements LocalDataSource {
  final DatabaseHelper databaseHelper;

  LocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<void> signUp(UserModel user) async {
    final db = await databaseHelper.database;
    await db.insert(
      DatabaseHelper.tableUsers,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableUsers,
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<UserModel?> getUserById(String id) async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableUsers,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps =
    await db.query(DatabaseHelper.tableUsers);
    return List.generate(maps.length, (i) {
      return UserModel.fromMap(maps[i]);
    });
  }

  @override
  Future<int> updateUserPassword(String email, String newPassword) async {
    final db = await databaseHelper.database;
    return await db.update(
      DatabaseHelper.tableUsers,
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> addCategory(CategoryModel category) async {
    final db = await databaseHelper.database;
    await db.insert(
      DatabaseHelper.tableCategories,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps =
    await db.query(DatabaseHelper.tableCategories);
    return List.generate(maps.length, (i) {
      return CategoryModel.fromMap(maps[i]);
    });
  }

  @override
  Future<CategoryModel> getCategoryById(String id) async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableCategories,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return CategoryModel.fromMap(maps.first);
    } else {
      throw Exception('Category with ID $id not found');
    }
  }

  @override
  Future<int> updateCategory(CategoryModel category) async {
    final db = await databaseHelper.database;
    return await db.update(
      DatabaseHelper.tableCategories,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  @override
  Future<int> deleteCategory(String id) async {
    final db = await databaseHelper.database;
    return await db.delete(
      DatabaseHelper.tableCategories,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> addShoppingList(ShoppingListModel shoppingList) async {
    final db = await databaseHelper.database;
    await db.insert(
      DatabaseHelper.tableShoppingLists,
      shoppingList.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<ShoppingListModel>> getAllShoppingListsForUser(
      String userId) async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableShoppingLists,
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) {
      return ShoppingListModel.fromMap(maps[i]);
    });
  }

  @override
  Future<ShoppingListModel?> getShoppingListById(String id) async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableShoppingLists,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ShoppingListModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<int> updateShoppingList(ShoppingListModel shoppingList) async {
    final db = await databaseHelper.database;
    return await db.update(
      DatabaseHelper.tableShoppingLists,
      shoppingList.toMap(),
      where: 'id = ?',
      whereArgs: [shoppingList.id],
    );
  }

  @override
  Future<int> deleteShoppingList(String id) async {
    final db = await databaseHelper.database;
    return await db.delete(
      DatabaseHelper.tableShoppingLists,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteAllShoppingListsForUser(String userId) async {
    final db = await databaseHelper.database;
    final userLists = await db.query(
      DatabaseHelper.tableShoppingLists,
      where: 'userId = ?',
      whereArgs: [userId],
      columns: ['id'],
    );
    if (userLists.isNotEmpty) {
      final listIds = userLists.map((row) => row['id'] as String).toList();
      final batch = db.batch();
      batch.delete(
        DatabaseHelper.tableItems,
        where: 'shoppingListId IN (${List.filled(listIds.length, '?').join(',')})',
        whereArgs: listIds,
      );
      batch.delete(
        DatabaseHelper.tableShoppingLists,
        where: 'id IN (${List.filled(listIds.length, '?').join(',')})',
        whereArgs: listIds,
      );
      await batch.commit(noResult: true);
    }
  }

  @override
  Future<void> addItem(ItemModel item) async {
    final db = await databaseHelper.database;
    await db.insert(
      DatabaseHelper.tableItems,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<ItemModel>> getItemsFromList(String shoppingListId) async {
    final db = await databaseHelper.database;
    final String sql = '''
      SELECT 
        i.*,
        c.name as categoryName,
        c.iconCodePoint as categoryIconCodePoint,
        c.colorValue as categoryColorValue
      FROM ${DatabaseHelper.tableItems} i
      INNER JOIN ${DatabaseHelper.tableCategories} c ON i.categoryId = c.id
      WHERE i.shoppingListId = ?
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, [shoppingListId]);

    return maps.map((map) => ItemModel.fromJoinedMap(map)).toList();
  }

  @override
  Future<int> updateItem(ItemModel item) async {
    final db = await databaseHelper.database;
    return await db.update(
      DatabaseHelper.tableItems,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  @override
  Future<int> deleteItem(String id) async {
    final db = await databaseHelper.database;
    return await db.delete(
      DatabaseHelper.tableItems,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> countTotalItems(String shoppingListId) async {
    final db = await databaseHelper.database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseHelper.tableItems} WHERE shoppingListId = ?',
        [shoppingListId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<int> countCheckedItems(String shoppingListId) async {
    final db = await databaseHelper.database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) FROM ${DatabaseHelper.tableItems} WHERE shoppingListId = ? AND isChecked = 1',
        [shoppingListId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<List<ItemModel>> getAllItems() async {
    final db = await databaseHelper.database;
    final String sql = '''
      SELECT 
        i.*,
        c.name as categoryName,
        c.iconCodePoint as categoryIconCodePoint,
        c.colorValue as categoryColorValue
      FROM ${DatabaseHelper.tableItems} i
      INNER JOIN ${DatabaseHelper.tableCategories} c ON i.categoryId = c.id
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(sql);

    return maps.map((map) => ItemModel.fromJoinedMap(map)).toList();
  }

  @override
  Future<double> getTotalCostOfList(String shoppingListId) async {
    final db = await databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(price * quantity) as total FROM ${DatabaseHelper.tableItems} WHERE shoppingListId = ?',
      [shoppingListId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<List<ItemModel>> getAllItemsForUser(String userId) async {
    final db = await databaseHelper.database;
    final String sql = '''
      SELECT 
        i.*,
        c.name as categoryName,
        c.iconCodePoint as categoryIconCodePoint,
        c.colorValue as categoryColorValue
      FROM ${DatabaseHelper.tableItems} i
      INNER JOIN ${DatabaseHelper.tableShoppingLists} sl ON i.shoppingListId = sl.id
      INNER JOIN ${DatabaseHelper.tableCategories} c ON i.categoryId = c.id
      WHERE sl.userId = ?
    ''';

    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, [userId]);

    return maps.map((map) => ItemModel.fromJoinedMap(map)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getRichShoppingListsForUser(
      String userId) async {
    final db = await databaseHelper.database;
    final String sql = '''
        SELECT 
            sl.*, 
            COUNT(i.id) as totalItems,
            SUM(CASE WHEN i.isChecked = 1 THEN 1 ELSE 0 END) as checkedItems,
            SUM(i.price * i.quantity) as totalCost
        FROM ${DatabaseHelper.tableShoppingLists} sl
        LEFT JOIN ${DatabaseHelper.tableItems} i ON sl.id = i.shoppingListId
        WHERE sl.userId = ?
        GROUP BY sl.id
    ''';
    return await db.rawQuery(sql, [userId]);
  }

  @override
  Future<void> deleteAllItemsFromList(String shoppingListId) async {
    final db = await databaseHelper.database;
    await db.delete(
      DatabaseHelper.tableItems,
      where: 'shoppingListId = ?',
      whereArgs: [shoppingListId],
    );
  }

  @override
  Future<void> performImport(String userId, Map<String, dynamic> data) async {
    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      final batch = txn.batch();

      final userLists = await txn.query(
        DatabaseHelper.tableShoppingLists,
        where: 'userId = ?',
        whereArgs: [userId],
        columns: ['id'],
      );
      if (userLists.isNotEmpty) {
        final listIds = userLists.map((row) => row['id'] as String).toList();
        batch.delete(
          DatabaseHelper.tableItems,
          where: 'shoppingListId IN (${List.filled(listIds.length, '?').join(',')})',
          whereArgs: listIds,
        );
      }
      batch.delete(
        DatabaseHelper.tableShoppingLists,
        where: 'userId = ?',
        whereArgs: [userId],
      );

      final List<dynamic> categories = data['categories'] ?? [];
      final List<dynamic> shoppingLists = data['shopping_lists'] ?? [];
      final List<dynamic> items = data['items'] ?? [];

      for (final categoryData in categories) {
        batch.insert(
          DatabaseHelper.tableCategories,
          categoryData as Map<String, dynamic>,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      for (final listData in shoppingLists) {
        final map = listData as Map<String, dynamic>;
        map['userId'] = userId;
        batch.insert(DatabaseHelper.tableShoppingLists, map);
      }
      for (final itemData in items) {
        batch.insert(
          DatabaseHelper.tableItems,
          itemData as Map<String, dynamic>,
        );
      }

      await batch.commit(noResult: true);
    });
  }

  @override
  Future<Map<String, dynamic>> getAllDataForUser(String userId) async {
    final shoppingLists = await getAllShoppingListsForUser(userId);
    final items = await getAllItemsForUser(userId);
    final categories = await getAllCategories();
    final units = await getAllUnits();

    return {
      'shopping_lists': shoppingLists,
      'items': items,
      'categories': categories,
      'units': units,
    };
  }

  @override
  Future<void> deleteAllUserData(String userId) async {
    final db = await databaseHelper.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      batch.delete(
        DatabaseHelper.tableShoppingLists,
        where: 'userId = ?',
        whereArgs: [userId],
      );
      batch.delete(
        DatabaseHelper.tableSyncQueue,
        where: 'userId = ?',
        whereArgs: [userId],
      );
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<List<String>> getAllUnits() async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(DatabaseHelper.tableUnits);
    return List.generate(maps.length, (i) => maps[i]['name'] as String);
  }

  @override
  Future<void> addUnit(String name) async {
    final db = await databaseHelper.database;
    await db.insert(
      DatabaseHelper.tableUnits,
      {'name': name},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<int> deleteUnit(String name) async {
    final db = await databaseHelper.database;
    return await db.delete(
      DatabaseHelper.tableUnits,
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  @override
  Future<int> updateUnit(String oldName, String newName) async {
    final db = await databaseHelper.database;
    return await db.update(
      DatabaseHelper.tableUnits,
      {'name': newName},
      where: 'name = ?',
      whereArgs: [oldName],
    );
  }

  @override
  Future<void> addToSyncQueue(SyncOperationModel operation) async {
    final db = await databaseHelper.database;
    await db.insert(DatabaseHelper.tableSyncQueue, operation.toMap());
  }

  @override
  Future<List<SyncOperationModel>> getPendingSyncOperations(String userId) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableSyncQueue,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'timestamp ASC',
    );
    return maps.map((map) => SyncOperationModel.fromMap(map)).toList();
  }

  @override
  Future<void> removeSyncOperation(int id) async {
    final db = await databaseHelper.database;
    await db.delete(
      DatabaseHelper.tableSyncQueue,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}