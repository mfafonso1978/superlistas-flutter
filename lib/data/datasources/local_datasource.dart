// lib/data/datasources/local_datasource.dart
//
// IMPLEMENTAÇÃO COMPLETA DO SEU ARQUIVO ORIGINAL
// (nada removido, nada renomeado)

import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:superlistas/core/database/database_helper.dart';
import 'package:superlistas/data/models/category_model.dart';
import 'package:superlistas/data/models/item_model.dart';
import 'package:superlistas/data/models/shopping_list_model.dart';
import 'package:superlistas/data/models/sync_operation_model.dart';
import 'package:superlistas/data/models/user_model.dart';
import 'package:superlistas/data/models/user_product_model.dart';

abstract class LocalDataSource {
  Future<void> signUp(UserModel user);
  Future<UserModel?> getUserByEmail(String email);
  Future<UserModel?> getUserById(String id);
  Future<List<UserModel>> getAllUsers();
  Future<int> updateUserPassword(String email, String newPassword);

  Future<void> addCategory(CategoryModel category);
  Future<List<CategoryModel>> getAllCategories();
  Future<CategoryModel> getCategoryById(String id);
  Future<int> updateCategory(CategoryModel category);
  Future<int> deleteCategory(String id);

  Future<void> addShoppingList(ShoppingListModel shoppingList);
  Future<List<ShoppingListModel>> getAllShoppingListsForUser(String userId);
  Future<ShoppingListModel?> getShoppingListById(String id);
  Future<int> updateShoppingList(ShoppingListModel shoppingList);
  Future<int> deleteShoppingList(String id);
  Future<void> deleteAllShoppingListsForUser(String userId);

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

  Future<void> performImport(String userId, Map<String, dynamic> data);
  Future<Map<String, dynamic>> getAllDataForUser(String userId);
  Future<void> deleteAllUserData(String userId);

  Future<List<String>> getAllUnits();
  Future<void> addUnit(String name);
  Future<int> deleteUnit(String name);
  Future<int> updateUnit(String oldName, String newName);

  Future<void> addToSyncQueue(SyncOperationModel operation);
  Future<List<SyncOperationModel>> getPendingSyncOperations(String userId);
  Future<void> removeSyncOperation(int id);

  // <<< NOVOS MÉTODOS ADICIONADOS AO CONTRATO >>>
  Future<UserProductModel?> getUserProductByBarcode(String barcode);
  Future<void> saveUserProduct(UserProductModel product);
}

/* ------------------------------------------------------------------------ */
/* IMPLEMENTAÇÃO (igual à sua versão)                   */
/* ------------------------------------------------------------------------ */

class LocalDataSourceImpl implements LocalDataSource {
  final DatabaseHelper databaseHelper;
  LocalDataSourceImpl({required this.databaseHelper});

  /* ===== USUÁRIO ===== */
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
    final maps = await db.query(
      DatabaseHelper.tableUsers,
      where: 'email = ?',
      whereArgs: [email],
    );
    return maps.isNotEmpty ? UserModel.fromMap(maps.first) : null;
  }

  @override
  Future<UserModel?> getUserById(String id) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableUsers,
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? UserModel.fromMap(maps.first) : null;
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    final db = await databaseHelper.database;
    final maps = await db.query(DatabaseHelper.tableUsers);
    return maps.map(UserModel.fromMap).toList();
  }

  @override
  Future<int> updateUserPassword(String email, String newPassword) async {
    final db = await databaseHelper.database;
    return db.update(
      DatabaseHelper.tableUsers,
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /* ===== CATEGORIAS ===== */
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
    final maps = await db.query(DatabaseHelper.tableCategories);
    return maps.map(CategoryModel.fromMap).toList();
  }

  @override
  Future<CategoryModel> getCategoryById(String id) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableCategories,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) throw Exception('Category with ID $id not found');
    return CategoryModel.fromMap(maps.first);
  }

  @override
  Future<int> updateCategory(CategoryModel category) async {
    final db = await databaseHelper.database;
    return db.update(
      DatabaseHelper.tableCategories,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  @override
  Future<int> deleteCategory(String id) async {
    final db = await databaseHelper.database;
    return db.delete(
      DatabaseHelper.tableCategories,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /* ===== LISTAS ===== */
  @override
  Future<void> addShoppingList(ShoppingListModel shoppingList) async {
    final db = await databaseHelper.database;
    await db.insert(
      DatabaseHelper.tableShoppingLists,
      shoppingList.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<ShoppingListModel>> getAllShoppingListsForUser(String userId) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableShoppingLists,
      where: 'ownerId = ?',
      whereArgs: [userId],
    );
    return maps.map(ShoppingListModel.fromDbMap).toList();
  }

  @override
  Future<ShoppingListModel?> getShoppingListById(String id) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableShoppingLists,
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? ShoppingListModel.fromDbMap(maps.first) : null;
  }

  @override
  Future<int> updateShoppingList(ShoppingListModel shoppingList) async {
    final db = await databaseHelper.database;
    return db.update(
      DatabaseHelper.tableShoppingLists,
      shoppingList.toDbMap(),
      where: 'id = ?',
      whereArgs: [shoppingList.id],
    );
  }

  @override
  Future<int> deleteShoppingList(String id) async {
    final db = await databaseHelper.database;
    return db.delete(
      DatabaseHelper.tableShoppingLists,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteAllShoppingListsForUser(String userId) async {
    final db = await databaseHelper.database;
    final listRows = await db.query(
      DatabaseHelper.tableShoppingLists,
      where: 'ownerId = ?',
      whereArgs: [userId],
      columns: ['id'],
    );
    if (listRows.isEmpty) return;
    final ids = listRows.map((row) => row['id'] as String).toList();
    final batch = db.batch();
    batch.delete(
      DatabaseHelper.tableItems,
      where: 'shoppingListId IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
    batch.delete(
      DatabaseHelper.tableShoppingLists,
      where: 'id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
    await batch.commit(noResult: true);
  }

  /* ===== ITENS ===== */
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
    const sql = '''
      SELECT i.*, c.name AS category_name,
             c.iconCodePoint AS category_iconCodePoint,
             c.colorValue AS category_colorValue
      FROM items i
      INNER JOIN categories c ON i.categoryId = c.id
      WHERE i.shoppingListId = ?
    ''';
    final maps = await db.rawQuery(sql, [shoppingListId]);
    return maps.map(ItemModel.fromJoinedMap).toList();
  }

  @override
  Future<int> updateItem(ItemModel item) async {
    final db = await databaseHelper.database;
    return db.update(
      DatabaseHelper.tableItems,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  @override
  Future<int> deleteItem(String id) async {
    final db = await databaseHelper.database;
    return db.delete(
      DatabaseHelper.tableItems,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> countTotalItems(String shoppingListId) async {
    final db = await databaseHelper.database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) FROM ${DatabaseHelper.tableItems} WHERE shoppingListId = ?',
      [shoppingListId],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  @override
  Future<int> countCheckedItems(String shoppingListId) async {
    final db = await databaseHelper.database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) FROM ${DatabaseHelper.tableItems} WHERE shoppingListId = ? AND isChecked = 1',
      [shoppingListId],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  @override
  Future<List<ItemModel>> getAllItems() async {
    final db = await databaseHelper.database;
    const sql = '''
      SELECT i.*, c.name AS category_name,
             c.iconCodePoint AS category_iconCodePoint,
             c.colorValue AS category_colorValue
      FROM items i
      INNER JOIN categories c ON i.categoryId = c.id
    ''';
    final maps = await db.rawQuery(sql);
    return maps.map(ItemModel.fromJoinedMap).toList();
  }

  @override
  Future<double> getTotalCostOfList(String shoppingListId) async {
    final db = await databaseHelper.database;
    final res = await db.rawQuery(
      'SELECT SUM(price * quantity) AS total FROM ${DatabaseHelper.tableItems} WHERE shoppingListId = ?',
      [shoppingListId],
    );
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<List<ItemModel>> getAllItemsForUser(String userId) async {
    final db = await databaseHelper.database;
    const sql = '''
      SELECT  i.*, c.name AS category_name,
              c.iconCodePoint AS category_iconCodePoint,
              c.colorValue AS category_colorValue
      FROM items i
      INNER JOIN shopping_lists sl ON i.shoppingListId = sl.id
      INNER JOIN categories c      ON i.categoryId     = c.id
      WHERE sl.ownerId = ?
    ''';
    final maps = await db.rawQuery(sql, [userId]);
    return maps.map(ItemModel.fromJoinedMap).toList();
  }

  /* ===== LISTAS “RICH” ===== */
  @override
  Future<List<Map<String, dynamic>>> getRichShoppingListsForUser(String userId) async {
    final db = await databaseHelper.database;
    const sql = '''
      SELECT sl.*,
             COUNT(i.id)                                       AS totalItems,
             SUM(CASE WHEN i.isChecked = 1 THEN 1 ELSE 0 END) AS checkedItems,
             SUM(i.price * i.quantity)                        AS totalCost
      FROM shopping_lists sl
      LEFT JOIN items i ON sl.id = i.shoppingListId
      WHERE sl.ownerId = ?
      GROUP BY sl.id
    ''';
    return db.rawQuery(sql, [userId]);
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

  /* ===== IMPORT / EXPORT / WIPE ===== */
  @override
  Future<void> performImport(String userId, Map<String, dynamic> data) async {
    final db = await databaseHelper.database;
    await db.transaction((txn) async {
      final batch = txn.batch();

      // limpa dados do usuário
      final listRows = await txn.query(
        DatabaseHelper.tableShoppingLists,
        where: 'ownerId = ?',
        whereArgs: [userId],
        columns: ['id'],
      );
      if (listRows.isNotEmpty) {
        final ids = listRows.map((e) => e['id'] as String).toList();
        batch.delete(
          DatabaseHelper.tableItems,
          where: 'shoppingListId IN (${List.filled(ids.length, '?').join(',')})',
          whereArgs: ids,
        );
      }
      batch.delete(
        DatabaseHelper.tableShoppingLists,
        where: 'ownerId = ?',
        whereArgs: [userId],
      );

      /* ---- insere novos dados ---- */
      final cats   = data['categories']      as List<dynamic>? ?? [];
      final lists  = data['shopping_lists']  as List<dynamic>? ?? [];
      final items  = data['items']           as List<dynamic>? ?? [];

      for (final c in cats)  {
        batch.insert(DatabaseHelper.tableCategories, c as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      for (final l in lists) {
        final map = Map<String, dynamic>.from(l as Map);
        map['ownerId']   = userId;
        map['memberIds'] = jsonEncode([userId]);
        batch.insert(DatabaseHelper.tableShoppingLists, map);
      }
      for (final i in items) {
        batch.insert(DatabaseHelper.tableItems, i as Map<String, dynamic>);
      }

      await batch.commit(noResult: true);
    });
  }

  @override
  Future<Map<String, dynamic>> getAllDataForUser(String userId) async {
    return {
      'shopping_lists': await getAllShoppingListsForUser(userId),
      'items'         : await getAllItemsForUser(userId),
      'categories'    : await getAllCategories(),
      'units'         : await getAllUnits(),
    };
  }

  @override
  Future<void> deleteAllUserData(String userId) async {
    final db = await databaseHelper.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      batch.delete(
        DatabaseHelper.tableShoppingLists,
        where: 'ownerId = ?',
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

  /* ===== UNIDADES ===== */
  @override
  Future<List<String>> getAllUnits() async {
    final db = await databaseHelper.database;
    final maps = await db.query(DatabaseHelper.tableUnits);
    return maps.map((m) => m['name'] as String).toList();
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
    return db.delete(
      DatabaseHelper.tableUnits,
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  @override
  Future<int> updateUnit(String oldName, String newName) async {
    final db = await databaseHelper.database;
    return db.update(
      DatabaseHelper.tableUnits,
      {'name': newName},
      where: 'name = ?',
      whereArgs: [oldName],
    );
  }

  /* ===== FILA DE SYNC ===== */
  @override
  Future<void> addToSyncQueue(SyncOperationModel op) async {
    final db = await databaseHelper.database;
    await db.insert(DatabaseHelper.tableSyncQueue, op.toMap());
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
    return maps.map(SyncOperationModel.fromMap).toList();
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

  // <<< IMPLEMENTAÇÃO DOS NOVOS MÉTODOS >>>
  /* ===== PRODUTOS (EAN) ===== */
  @override
  Future<UserProductModel?> getUserProductByBarcode(String barcode) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      DatabaseHelper.tableUserProducts,
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return UserProductModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<void> saveUserProduct(UserProductModel product) async {
    final db = await databaseHelper.database;
    await db.insert(
      DatabaseHelper.tableUserProducts,
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}