// lib/data/repositories/shopping_list_repository_impl.dart
import 'dart:convert';
import 'package:flutter/material.dart'; // <<< ADICIONADO PARA 'Color'
import 'package:intl/intl.dart';
import 'package:superlistas/data/datasources/local_datasource.dart';
import 'package:superlistas/data/models/category_model.dart';
import 'package:superlistas/data/models/item_model.dart';
import 'package:superlistas/data/models/shopping_list_model.dart';
import 'package:superlistas/domain/entities/category.dart';
import 'package:superlistas/domain/entities/item.dart';
import 'package:superlistas/domain/entities/shopping_list.dart';
import 'package:superlistas/domain/entities/stats_data.dart';
import 'package:superlistas/domain/repositories/shopping_list_repository.dart';
import 'package:uuid/uuid.dart';

class ShoppingListRepositoryImpl implements ShoppingListRepository {
  final LocalDataSource localDataSource;

  ShoppingListRepositoryImpl({required this.localDataSource});

  @override
  Future<ShoppingList> getShoppingListById(String id) async {
    final model = await localDataSource.getShoppingListById(id);
    if (model == null) {
      throw Exception('Lista não encontrada com o ID: $id');
    }

    final totalItems = await localDataSource.countTotalItems(model.id);
    final checkedItems = await localDataSource.countCheckedItems(model.id);
    final totalCost = await localDataSource.getTotalCostOfList(model.id);

    return ShoppingList(
      id: model.id,
      name: model.name,
      creationDate: model.creationDate,
      isArchived: model.isArchived,
      budget: model.budget,
      userId: model.userId,
      totalItems: totalItems,
      checkedItems: checkedItems,
      totalCost: totalCost,
    );
  }

  @override
  Future<void> reuseShoppingList(ShoppingList listToReuse) async {
    const uuid = Uuid();
    final newList = ShoppingListModel(
      id: uuid.v4(),
      name: '${listToReuse.name} (cópia)',
      creationDate: DateTime.now(),
      isArchived: false,
      budget: listToReuse.budget,
      userId: listToReuse.userId,
    );
    await localDataSource.addShoppingList(newList);

    final oldItems = await localDataSource.getItemsFromList(listToReuse.id);

    for (final oldItem in oldItems) {
      final newItem = ItemModel(
        id: uuid.v4(),
        name: oldItem.name,
        price: oldItem.price,
        quantity: oldItem.quantity,
        unit: oldItem.unit,
        notes: oldItem.notes,
        isChecked: false,
        completionDate: null,
        category: oldItem.category as CategoryModel,
        shoppingListId: newList.id,
      );
      await localDataSource.addItem(newItem);
    }
  }

  @override
  Future<void> updateShoppingList(ShoppingList list) async {
    final listModel = ShoppingListModel(
      id: list.id,
      name: list.name,
      creationDate: list.creationDate,
      isArchived: list.isArchived,
      budget: list.budget,
      userId: list.userId,
    );
    await localDataSource.updateShoppingList(listModel);
  }

  @override
  Future<StatsData> getStats(String userId) async {
    final allLists = await getShoppingLists(userId);
    final allItems = await localDataSource.getAllItemsForUser(userId);

    final completedLists = allLists.where((list) => list.isCompleted).length;
    final totalItemsPurchased = allItems.where((item) => item.isChecked).length;

    final Map<String, int> itemsByCategory = {};
    final Map<String, Category> categoryMap = {};
    final Map<String, int> itemsByMonth = {};

    for (final item in allItems) {
      if (item.isChecked) {
        itemsByCategory.update(item.category.name, (value) => value + 1,
            ifAbsent: () => 1);
        if (!categoryMap.containsKey(item.category.name)) {
          categoryMap[item.category.name] = item.category;
        }

        if (item.completionDate != null) {
          final monthKey = DateFormat('yyyy-MM').format(item.completionDate!);
          itemsByMonth.update(monthKey, (value) => value + 1, ifAbsent: () => 1);
        }
      }
    }

    Category? topCategory;
    if (itemsByCategory.isNotEmpty) {
      final topCategoryName =
          itemsByCategory.entries.reduce((a, b) => a.value > b.value ? a : b).key;
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
  Future<List<ShoppingList>> getShoppingLists(String userId) async {
    final richListMaps =
    await localDataSource.getRichShoppingListsForUser(userId);

    return richListMaps.map((map) => ShoppingList.fromRichMap(map)).toList();
  }

  @override
  Future<void> createCategory(Category category) async {
    final categoryModel = CategoryModel(
      id: category.id,
      name: category.name,
      icon: category.icon,
      colorValue: category.colorValue, // <<< CORRIGIDO
    );
    await localDataSource.addCategory(categoryModel);
  }

  @override
  Future<void> updateCategory(Category category) async {
    final categoryModel = CategoryModel(
      id: category.id,
      name: category.name,
      icon: category.icon,
      colorValue: category.colorValue, // <<< CORRIGIDO
    );
    await localDataSource.updateCategory(categoryModel);
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await localDataSource.deleteCategory(categoryId);
  }

  @override
  Future<void> createItem(Item item, String listId) async {
    final itemModel = ItemModel(
      id: item.id,
      name: item.name,
      price: item.price,
      quantity: item.quantity,
      unit: item.unit,
      isChecked: item.isChecked,
      notes: item.notes,
      completionDate: item.completionDate,
      category: CategoryModel(
        id: item.category.id,
        name: item.category.name,
        icon: item.category.icon,
        colorValue: item.category.colorValue, // <<< CORRIGIDO
      ),
      shoppingListId: listId,
    );
    await localDataSource.addItem(itemModel);
  }

  @override
  Future<void> createShoppingList(ShoppingList list) async {
    final listModel = ShoppingListModel(
      id: list.id,
      name: list.name,
      creationDate: list.creationDate,
      isArchived: list.isArchived,
      budget: list.budget,
      userId: list.userId,
    );
    await localDataSource.addShoppingList(listModel);
  }

  @override
  Future<void> deleteItem(String id) async {
    await localDataSource.deleteItem(id);
  }

  @override
  Future<void> deleteShoppingList(String id) async {
    await localDataSource.deleteShoppingList(id);
  }

  @override
  Future<List<Category>> getCategories() async {
    final categories = await localDataSource.getAllCategories();
    // O cast direto funciona porque CategoryModel estende Category
    return categories.map((model) => model as Category).toList();
  }

  @override
  Future<List<Item>> getItems(String listId) async {
    final itemModels = await localDataSource.getItemsFromList(listId);
    // O cast direto funciona porque ItemModel estende Item
    return itemModels.map((model) => model as Item).toList();
  }

  @override
  Future<void> updateItem(Item item, String listId) async {
    final itemModel = ItemModel(
      id: item.id,
      name: item.name,
      price: item.price,
      quantity: item.quantity,
      unit: item.unit,
      isChecked: item.isChecked,
      notes: item.notes,
      completionDate: item.completionDate,
      category: CategoryModel(
        id: item.category.id,
        name: item.category.name,
        icon: item.category.icon,
        colorValue: item.category.colorValue, // <<< CORRIGIDO
      ),
      shoppingListId: listId,
    );
    await localDataSource.updateItem(itemModel);
  }

  @override
  Future<String> exportDataToJson(String userId) async {
    final categories = await localDataSource.getAllCategories();
    final shoppingLists =
    await localDataSource.getAllShoppingListsForUser(userId);
    final items = await localDataSource.getAllItemsForUser(userId);

    final categoriesMap = categories.map((c) => c.toMap()).toList();
    final listsMap = shoppingLists.map((l) => l.toMap()).toList();
    final itemsMap = items.map((i) => i.toMap()).toList();

    final exportData = {
      'metadata': {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'appName': 'Superlistas',
      },
      'data': {
        'categories': categoriesMap,
        'shopping_lists': listsMap,
        'items': itemsMap,
      }
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  @override
  Future<void> importDataFromJson(String userId, String jsonString) async {
    try {
      final decodedJson = jsonDecode(jsonString) as Map<String, dynamic>;

      if (!decodedJson.containsKey('data')) {
        throw Exception("Arquivo JSON inválido: chave 'data' não encontrada.");
      }
      final data = decodedJson['data'] as Map<String, dynamic>;
      if (!data.containsKey('categories') ||
          !data.containsKey('shopping_lists') ||
          !data.containsKey('items')) {
        throw Exception(
            "Arquivo JSON inválido: uma ou mais chaves de dados estão faltando.");
      }

      await localDataSource.performImport(userId, data);
    } catch (e) {
      throw Exception("Falha ao processar o arquivo JSON: $e");
    }
  }

  @override
  Future<List<String>> getAllUnits() {
    return localDataSource.getAllUnits();
  }

  @override
  Future<void> addUnit(String name) {
    return localDataSource.addUnit(name);
  }

  @override
  Future<void> deleteUnit(String name) {
    return localDataSource.deleteUnit(name);
  }

  @override
  Future<void> updateUnit(String oldName, String newName) {
    return localDataSource.updateUnit(oldName, newName);
  }
}