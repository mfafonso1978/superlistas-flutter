// lib/data/repositories/shopping_list_repository_impl.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:superlistas/data/datasources/local_datasource.dart';
import 'package:superlistas/data/datasources/remote_config_service.dart';
import 'package:superlistas/data/datasources/firestore_datasource.dart';
import 'package:superlistas/data/models/category_model.dart';
import 'package:superlistas/data/models/item_model.dart';
import 'package:superlistas/data/models/shopping_list_model.dart';
import 'package:superlistas/data/models/sync_operation_model.dart';
import 'package:superlistas/domain/entities/category.dart' as domain;
import 'package:superlistas/domain/entities/item.dart';
import 'package:superlistas/domain/entities/shopping_list.dart';
import 'package:superlistas/domain/entities/stats_data.dart';
import 'package:superlistas/domain/repositories/shopping_list_repository.dart';
import 'package:uuid/uuid.dart';

class ShoppingListRepositoryImpl implements ShoppingListRepository {
  final LocalDataSource localDataSource;
  final RemoteDataSource remoteDataSource;
  final RemoteConfigService remoteConfigService;

  ShoppingListRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.remoteConfigService,
  });

  bool _shouldSync() {
    final isPremium = remoteConfigService.isUserPremium;
    final isSyncEnabled = remoteConfigService.isCloudSyncEnabled;
    return isPremium && isSyncEnabled;
  }

  String? _getCurrentUserIdAuth() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Stream<List<ShoppingList>> getShoppingListsStream(String userId) {
    if (_shouldSync()) {
      return remoteDataSource.getShoppingListsStream(userId).asyncMap((remoteLists) async {
        await localDataSource.deleteAllShoppingListsForUser(userId);
        for (final list in remoteLists) {
          await localDataSource.addShoppingList(list);
        }
        final richListMaps = await localDataSource.getRichShoppingListsForUser(userId);
        return richListMaps.map((map) => ShoppingList.fromRichMap(map)).toList();
      });
    } else {
      return Stream.fromFuture(getShoppingLists(userId));
    }
  }

  @override
  Stream<List<Item>> getItemsStream(String userId, String listId) {
    if (_shouldSync()) {
      return remoteDataSource.getItemsStream(userId, listId).asyncMap((remoteItems) async {
        await localDataSource.deleteAllItemsFromList(listId);
        for (final item in remoteItems) {
          await localDataSource.addItem(item);
        }
        return remoteItems.cast<Item>().toList();
      });
    } else {
      return Stream.fromFuture(getItems(listId));
    }
  }

  @override
  Future<List<ShoppingList>> getShoppingLists(String userId) async {
    final richListMaps = await localDataSource.getRichShoppingListsForUser(userId);
    return richListMaps.map((map) => ShoppingList.fromRichMap(map)).toList();
  }

  @override
  Future<ShoppingList> getShoppingListById(String id) async {
    final model = await localDataSource.getShoppingListById(id);
    if (model == null) throw Exception('Lista não encontrada com o ID: $id');
    final totalItems = await localDataSource.countTotalItems(model.id);
    final checkedItems = await localDataSource.countCheckedItems(model.id);
    final totalCost = await localDataSource.getTotalCostOfList(model.id);
    return ShoppingList(id: model.id, name: model.name, creationDate: model.creationDate, isArchived: model.isArchived, budget: model.budget, userId: model.userId, totalItems: totalItems, checkedItems: checkedItems, totalCost: totalCost);
  }

  @override
  Future<void> createShoppingList(ShoppingList list) async {
    final listModel = ShoppingListModel(id: list.id, name: list.name, creationDate: list.creationDate, isArchived: list.isArchived, budget: list.budget, userId: list.userId);
    await localDataSource.addShoppingList(listModel);
    if (_shouldSync()) {
      try { await remoteDataSource.saveShoppingList(listModel); } catch (e) {
        if (kDebugMode) { print("Falha na sincronização, adicionando à fila: $e"); }
        await localDataSource.addToSyncQueue(SyncOperationModel(
          userId: list.userId, entityType: 'shopping_list', entityId: list.id,
          operationType: 'save', payload: jsonEncode(listModel.toMap()),
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  @override
  Future<void> updateShoppingList(ShoppingList list) async {
    final listModel = ShoppingListModel(id: list.id, name: list.name, creationDate: list.creationDate, isArchived: list.isArchived, budget: list.budget, userId: list.userId);
    await localDataSource.updateShoppingList(listModel);
    if (_shouldSync()) {
      try { await remoteDataSource.saveShoppingList(listModel); } catch (e) {
        if (kDebugMode) { print("Falha na sincronização, adicionando à fila: $e"); }
        await localDataSource.addToSyncQueue(SyncOperationModel(
          userId: list.userId, entityType: 'shopping_list', entityId: list.id,
          operationType: 'save', payload: jsonEncode(listModel.toMap()),
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  @override
  Future<void> deleteShoppingList(String id) async {
    final list = await localDataSource.getShoppingListById(id);
    if (list == null) return;
    await localDataSource.deleteShoppingList(id);
    if (_shouldSync()) {
      try { await remoteDataSource.deleteShoppingList(id, list.userId); } catch (e) {
        if (kDebugMode) { print("Falha na sincronização, adicionando à fila: $e"); }
        await localDataSource.addToSyncQueue(SyncOperationModel(
          userId: list.userId, entityType: 'shopping_list', entityId: id,
          operationType: 'delete', timestamp: DateTime.now(),
        ));
      }
    }
  }

  @override
  Future<void> reuseShoppingList(ShoppingList listToReuse) async {
    const uuid = Uuid();
    final newList = ShoppingList(
      id: uuid.v4(), name: '${listToReuse.name} (cópia)',
      creationDate: DateTime.now(), isArchived: false,
      budget: listToReuse.budget, userId: listToReuse.userId,
    );
    await createShoppingList(newList);

    final oldItems = await localDataSource.getItemsFromList(listToReuse.id);
    for (final oldItem in oldItems) {
      final newItem = Item(
        id: uuid.v4(), name: oldItem.name, category: oldItem.category,
        price: oldItem.price, quantity: oldItem.quantity,
        unit: oldItem.unit, notes: oldItem.notes,
        isChecked: false, completionDate: null,
      );
      await createItem(newItem, newList.id);
    }
  }

  @override
  Future<List<Item>> getItems(String listId) async {
    final itemModels = await localDataSource.getItemsFromList(listId);
    return itemModels.cast<Item>().toList();
  }

  @override
  Future<void> createItem(Item item, String listId) async {
    final list = await localDataSource.getShoppingListById(listId);
    if (list == null) throw Exception("Lista não encontrada para adicionar o item");
    final itemModel = ItemModel(
      id: item.id, name: item.name, price: item.price, quantity: item.quantity,
      unit: item.unit, isChecked: item.isChecked, notes: item.notes,
      completionDate: item.completionDate,
      category: item.category as CategoryModel,
      shoppingListId: listId,
    );
    await localDataSource.addItem(itemModel);
    if (_shouldSync()) {
      try { await remoteDataSource.saveItem(itemModel, list.userId); } catch (e) {
        if (kDebugMode) { print("Falha na sincronização, adicionando à fila: $e"); }
        await localDataSource.addToSyncQueue(SyncOperationModel(
          userId: list.userId, entityType: 'item', entityId: item.id,
          operationType: 'save', payload: jsonEncode(itemModel.toMapForFirestore()),
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  @override
  Future<void> updateItem(Item item, String listId) async {
    final list = await localDataSource.getShoppingListById(listId);
    if (list == null) throw Exception("Lista não encontrada para atualizar o item");
    final itemModel = ItemModel(
      id: item.id, name: item.name, price: item.price, quantity: item.quantity,
      unit: item.unit, isChecked: item.isChecked, notes: item.notes,
      completionDate: item.completionDate,
      category: item.category as CategoryModel,
      shoppingListId: listId,
    );
    await localDataSource.updateItem(itemModel);
    if (_shouldSync()) {
      try { await remoteDataSource.saveItem(itemModel, list.userId); } catch (e) {
        if (kDebugMode) { print("Falha na sincronização, adicionando à fila: $e"); }
        await localDataSource.addToSyncQueue(SyncOperationModel(
          userId: list.userId, entityType: 'item', entityId: item.id,
          operationType: 'save', payload: jsonEncode(itemModel.toMapForFirestore()),
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  @override
  Future<void> deleteItem(String itemId, String listId, String userId) async {
    await localDataSource.deleteItem(itemId);
    if (_shouldSync()) {
      try { await remoteDataSource.deleteItem(itemId, userId, listId); }
      catch (e) {
        if (kDebugMode) { print("Falha na sincronização de exclusão de item: $e"); }
        await localDataSource.addToSyncQueue(SyncOperationModel(
          userId: userId,
          entityType: 'item',
          entityId: itemId,
          operationType: 'delete',
          payload: jsonEncode({'listId': listId}),
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  @override
  Future<List<domain.Category>> getCategories() async {
    final categories = await localDataSource.getAllCategories();
    return categories.cast<domain.Category>().toList();
  }

  @override
  Future<void> createCategory(domain.Category category) async {
    final categoryModel = CategoryModel(id: category.id, name: category.name, icon: category.icon, colorValue: category.colorValue);
    await localDataSource.addCategory(categoryModel);
    if (_shouldSync()) {
      final userId = _getCurrentUserIdAuth();
      if (userId != null) {
        try { await remoteDataSource.saveCategory(categoryModel, userId); }
        catch (e) { if (kDebugMode) { print("Falha ao sincronizar criação de categoria: $e"); } }
      }
    }
  }

  @override
  Future<void> updateCategory(domain.Category category) async {
    final categoryModel = CategoryModel(id: category.id, name: category.name, icon: category.icon, colorValue: category.colorValue);
    await localDataSource.updateCategory(categoryModel);
    if (_shouldSync()) {
      final userId = _getCurrentUserIdAuth();
      if (userId != null) {
        try { await remoteDataSource.saveCategory(categoryModel, userId); }
        catch (e) { if (kDebugMode) { print("Falha ao sincronizar atualização de categoria: $e"); } }
      }
    }
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await localDataSource.deleteCategory(categoryId);
    if (_shouldSync()) {
      final userId = _getCurrentUserIdAuth();
      if (userId != null) {
        try { await remoteDataSource.deleteCategory(categoryId, userId); }
        catch (e) { if (kDebugMode) { print("Falha ao sincronizar exclusão de categoria: $e"); } }
      }
    }
  }

  @override
  Future<StatsData> getStats(String userId) async {
    final allLists = await getShoppingLists(userId);
    final allItems = await localDataSource.getAllItemsForUser(userId);
    final completedLists = allLists.where((list) => list.isCompleted).length;
    final totalItemsPurchased = allItems.where((item) => item.isChecked).length;
    final Map<String, int> itemsByCategory = {};
    final Map<String, domain.Category> categoryMap = {};
    final Map<String, int> itemsByMonth = {};
    for (final item in allItems) {
      if (item.isChecked) {
        itemsByCategory.update(item.category.name, (value) => value + 1, ifAbsent: () => 1);
        if (!categoryMap.containsKey(item.category.name)) {
          categoryMap[item.category.name] = item.category;
        }
        if (item.completionDate != null) {
          final monthKey = DateFormat('yyyy-MM').format(item.completionDate!);
          itemsByMonth.update(monthKey, (value) => value + 1, ifAbsent: () => 1);
        }
      }
    }
    domain.Category? topCategory;
    if (itemsByCategory.isNotEmpty) {
      final topCategoryName = itemsByCategory.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      topCategory = categoryMap[topCategoryName];
    }
    return StatsData(
      totalItemsPurchased: totalItemsPurchased,
      completedLists: completedLists,
      topCategory: topCategory,
      itemsByCategory: itemsByCategory,
      itemsByMonth: itemsByMonth,
    );
  }

  @override
  Future<String> exportDataToJson(String userId) async {
    final categories = await localDataSource.getAllCategories();
    final shoppingLists = await localDataSource.getAllShoppingListsForUser(userId);
    final items = await localDataSource.getAllItemsForUser(userId);
    final categoriesMap = categories.map((c) => c.toMap()).toList();
    final listsMap = shoppingLists.map((l) => l.toMap()).toList();
    final itemsMap = items.map((i) => i.toMap()).toList();
    final exportData = {
      'metadata': { 'version': 1, 'exportedAt': DateTime.now().toIso8601String(), 'appName': 'Superlistas', },
      'data': { 'categories': categoriesMap, 'shopping_lists': listsMap, 'items': itemsMap, }
    };
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  @override
  Future<void> importDataFromJson(String userId, String jsonString) async {
    try {
      final decodedJson = jsonDecode(jsonString) as Map<String, dynamic>;
      if (!decodedJson.containsKey('data')) { throw Exception("Arquivo JSON inválido: chave 'data' não encontrada."); }
      final data = decodedJson['data'] as Map<String, dynamic>;
      if (!data.containsKey('categories') || !data.containsKey('shopping_lists') || !data.containsKey('items')) { throw Exception("Arquivo JSON inválido: uma ou mais chaves de dados estão faltando."); }
      await localDataSource.performImport(userId, data);
    } catch (e) {
      throw Exception("Falha ao processar o arquivo JSON: $e");
    }
  }

  @override
  Future<void> performInitialCloudSync(String userId) async {
    final localData = await localDataSource.getAllDataForUser(userId);
    await remoteDataSource.performInitialSync(userId, localData);
  }

  @override
  Future<void> processSyncQueue(String userId) async {
    final pendingOperations = await localDataSource.getPendingSyncOperations(userId);
    if (pendingOperations.isEmpty) return;

    for (final op in pendingOperations) {
      try {
        if (op.entityType == 'shopping_list') {
          if (op.operationType == 'save') {
            final model = ShoppingListModel.fromMap(jsonDecode(op.payload!));
            await remoteDataSource.saveShoppingList(model);
          } else if (op.operationType == 'delete') {
            await remoteDataSource.deleteShoppingList(op.entityId, op.userId);
          }
        } else if (op.entityType == 'item') {
          if (op.operationType == 'save') {
            final model = ItemModel.fromJoinedMap(jsonDecode(op.payload!));
            await remoteDataSource.saveItem(model, op.userId);
          } else if (op.operationType == 'delete') {
            final payload = jsonDecode(op.payload!);
            await remoteDataSource.deleteItem(op.entityId, op.userId, payload['listId']);
          }
        }

        await localDataSource.removeSyncOperation(op.id!);
      } catch (e) {
        if (kDebugMode) { print("Falha ao processar item da fila (ID: ${op.id}). Erro: $e"); }
        continue;
      }
    }
  }

  @override
  Future<void> deleteAllUserData(String userId) async {
    await localDataSource.deleteAllUserData(userId);
    if (_shouldSync()) {
      try {
        await remoteDataSource.deleteAllUserData(userId);
      } catch (e) {
        if (kDebugMode) { print("Falha ao apagar dados da nuvem: $e"); }
        throw Exception("Falha ao apagar dados da nuvem. Verifique sua conexão e tente novamente.");
      }
    }
  }

  @override
  Future<List<String>> getAllUnits() => localDataSource.getAllUnits();

  @override
  Future<void> addUnit(String name) async {
    await localDataSource.addUnit(name);
    if (_shouldSync()) {
      final userId = _getCurrentUserIdAuth();
      if (userId != null) {
        final allUnits = await localDataSource.getAllUnits();
        try { await remoteDataSource.saveAllUnits(allUnits, userId); }
        catch (e) { if (kDebugMode) { print("Falha ao sincronizar adição de unidade: $e"); } }
      }
    }
  }

  @override
  Future<void> deleteUnit(String name) async {
    await localDataSource.deleteUnit(name);
    if (_shouldSync()) {
      final userId = _getCurrentUserIdAuth();
      if (userId != null) {
        final allUnits = await localDataSource.getAllUnits();
        try { await remoteDataSource.saveAllUnits(allUnits, userId); }
        catch (e) { if (kDebugMode) { print("Falha ao sincronizar exclusão de unidade: $e"); } }
      }
    }
  }

  @override
  Future<void> updateUnit(String oldName, String newName) async {
    await localDataSource.updateUnit(oldName, newName);
    if (_shouldSync()) {
      final userId = _getCurrentUserIdAuth();
      if (userId != null) {
        final allUnits = await localDataSource.getAllUnits();
        try { await remoteDataSource.saveAllUnits(allUnits, userId); }
        catch (e) { if (kDebugMode) { print("Falha ao sincronizar atualização de unidade: $e"); } }
      }
    }
  }
}