// lib/domain/repositories/shopping_list_repository.dart
import 'package:superlistas/domain/entities/category.dart';
import 'package:superlistas/domain/entities/item.dart';
import 'package:superlistas/domain/entities/shopping_list.dart';
import 'package:superlistas/domain/entities/stats_data.dart';

abstract class ShoppingListRepository {
  Future<ShoppingList> getShoppingListById(String id);
  Future<List<ShoppingList>> getShoppingLists(String userId);
  Future<void> createShoppingList(ShoppingList list);
  Future<void> updateShoppingList(ShoppingList list);
  Future<void> deleteShoppingList(String id);
  Future<void> reuseShoppingList(ShoppingList listToReuse);

  Future<List<Item>> getItems(String listId);
  Future<void> createItem(Item item, String listId);
  Future<void> updateItem(Item item, String listId);
  Future<void> deleteItem(String id);

  Future<List<Category>> getCategories();
  Future<void> createCategory(Category category);
  // <<< NOVOS métodos para categorias >>>
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String categoryId);

  Future<StatsData> getStats(String userId);

  Future<String> exportDataToJson(String userId);
  Future<void> importDataFromJson(String userId, String jsonString);

  // --- Métodos para Unidades ---
  Future<List<String>> getAllUnits();
  Future<void> addUnit(String name);
  Future<void> deleteUnit(String name);
  Future<void> updateUnit(String oldName, String newName);
}