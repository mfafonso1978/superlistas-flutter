// lib/data/datasources/firestore_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:superlistas/data/models/category_model.dart';
import 'package:superlistas/data/models/item_model.dart';
import 'package:superlistas/data/models/shopping_list_model.dart';
import 'package:flutter/material.dart';

abstract class RemoteDataSource {
  // Métodos para Listas de Compras
  Stream<List<ShoppingListModel>> getShoppingListsStream(String userId);
  Future<void> saveShoppingList(ShoppingListModel list);
  Future<void> deleteShoppingList(String listId, String userId);

  // Métodos para Itens
  Stream<List<ItemModel>> getItemsStream(String userId, String listId);
  Future<void> saveItem(ItemModel item, String userId);
  Future<void> deleteItem(String itemId, String userId, String listId);

  // Métodos para Categorias
  Stream<List<CategoryModel>> getCategoriesStream(String userId);
  Future<void> saveCategory(CategoryModel category, String userId);
  Future<void> deleteCategory(String categoryId, String userId);

  // Métodos para Unidades de Medida
  Future<void> saveAllUnits(List<String> units, String userId);
  Future<List<String>> getAllUnits(String userId);

  // Método para sincronização inicial
  Future<void> performInitialSync(String userId, Map<String, dynamic> localData);
  Future<void> deleteAllUserData(String userId);
}

class FirestoreDataSourceImpl implements RemoteDataSource {
  final FirebaseFirestore _firestore;

  FirestoreDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference _userDoc(String userId) => _firestore.collection('users').doc(userId);
  CollectionReference _shoppingListsCollection(String userId) => _userDoc(userId).collection('shopping_lists');
  CollectionReference _itemsCollection(String userId, String listId) => _shoppingListsCollection(userId).doc(listId).collection('items');
  CollectionReference _categoriesCollection(String userId) => _userDoc(userId).collection('categories');
  DocumentReference _unitsDoc(String userId) => _userDoc(userId).collection('app_data').doc('units');

  @override
  Stream<List<ShoppingListModel>> getShoppingListsStream(String userId) {
    return _shoppingListsCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ShoppingListModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<void> saveShoppingList(ShoppingListModel list) {
    return _shoppingListsCollection(list.userId).doc(list.id).set(list.toMap());
  }

  @override
  Future<void> deleteShoppingList(String listId, String userId) {
    return _shoppingListsCollection(userId).doc(listId).delete();
  }

  @override
  Stream<List<ItemModel>> getItemsStream(String userId, String listId) {
    return _itemsCollection(userId, listId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ItemModel.fromJoinedMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<void> saveItem(ItemModel item, String userId) {
    return _itemsCollection(userId, item.shoppingListId)
        .doc(item.id)
        .set(item.toMapForFirestore());
  }

  @override
  Future<void> deleteItem(String itemId, String userId, String listId) {
    return _itemsCollection(userId, listId).doc(itemId).delete();
  }

  @override
  Stream<List<CategoryModel>> getCategoriesStream(String userId) {
    return _categoriesCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<void> saveCategory(CategoryModel category, String userId) {
    return _categoriesCollection(userId).doc(category.id).set(category.toMap());
  }

  @override
  Future<void> deleteCategory(String categoryId, String userId) {
    return _categoriesCollection(userId).doc(categoryId).delete();
  }

  @override
  Future<void> saveAllUnits(List<String> units, String userId) {
    return _unitsDoc(userId).set({'names': units});
  }

  @override
  Future<List<String>> getAllUnits(String userId) async {
    final doc = await _unitsDoc(userId).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      return List<String>.from(data['names'] ?? []);
    }
    return [];
  }

  @override
  Future<void> performInitialSync(String userId, Map<String, dynamic> localData) async {
    final batch = _firestore.batch();
    final List<CategoryModel> categories = localData['categories'];
    for (final category in categories) {
      final docRef = _categoriesCollection(userId).doc(category.id);
      batch.set(docRef, category.toMap());
    }
    final List<ShoppingListModel> lists = localData['shopping_lists'];
    final List<ItemModel> allItems = localData['items'];
    for (final list in lists) {
      final docRef = _shoppingListsCollection(userId).doc(list.id);
      batch.set(docRef, list.toMap());
      final itemsForThisList = allItems.where((item) => item.shoppingListId == list.id);
      for (final item in itemsForThisList) {
        final itemDocRef = _itemsCollection(userId, list.id).doc(item.id);
        batch.set(itemDocRef, item.toMapForFirestore());
      }
    }
    final List<String> units = localData['units'];
    if (units.isNotEmpty) {
      final unitsDocRef = _unitsDoc(userId);
      batch.set(unitsDocRef, {'names': units});
    }
    await batch.commit();
  }

  @override
  Future<void> deleteAllUserData(String userId) async {
    final batch = _firestore.batch();
    final shoppingListsSnapshot = await _shoppingListsCollection(userId).get();
    for (final doc in shoppingListsSnapshot.docs) {
      final itemsSnapshot = await _itemsCollection(userId, doc.id).get();
      for (final itemDoc in itemsSnapshot.docs) {
        batch.delete(itemDoc.reference);
      }
      batch.delete(doc.reference);
    }
    final categoriesSnapshot = await _categoriesCollection(userId).get();
    for (final doc in categoriesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    final unitsDoc = _unitsDoc(userId);
    batch.delete(unitsDoc);
    await batch.commit();
  }
}

extension ItemModelFirestore on ItemModel {
  Map<String, dynamic> toMapForFirestore() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'isChecked': isChecked,
      'notes': notes,
      'completionDate': completionDate?.toIso8601String(),
      'shoppingListId': shoppingListId,
      'categoryId': category.id,
      'categoryName': category.name,
      'categoryIconCodePoint': category.icon.codePoint,
      'categoryColorValue': category.colorValue.value,
    };
  }
}