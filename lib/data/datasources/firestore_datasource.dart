// lib/data/datasources/firestore_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:superlistas/data/models/category_model.dart';
import 'package:superlistas/data/models/item_model.dart';
import 'package:superlistas/data/models/shopping_list_model.dart';
import 'package:superlistas/data/models/user_model.dart';

abstract class RemoteDataSource {
  Stream<List<ShoppingListModel>> getShoppingListsStream(String userId);
  Future<void> saveShoppingList(ShoppingListModel list);
  Future<void> deleteShoppingList(String listId, String userId);
  Future<ShoppingListModel> getShoppingListById(String listId, String userId);
  Future<String?> findUserUidByEmail(String email);
  Future<List<UserModel>> getUsersFromIds(List<String> userIds);
  Future<void> removeMemberFromList(String listId, String memberIdToRemove);

  Stream<List<ItemModel>> getItemsStream(String userId, String listId);
  Future<List<ItemModel>> getItems(String listId);
  Future<void> saveItem(ItemModel item, String userId);
  Future<void> deleteItem(String itemId, String userId, String listId);
  Stream<List<CategoryModel>> getCategoriesStream(String userId);
  Future<void> saveCategory(CategoryModel category, String userId);
  Future<void> deleteCategory(String categoryId, String userId);
  Future<void> saveAllUnits(List<String> units, String userId);
  Future<List<String>> getAllUnits(String userId);
  Future<void> performInitialSync(String userId, Map<String, dynamic> localData);
  Future<void> deleteAllUserData(String userId);
}

class FirestoreDataSourceImpl implements RemoteDataSource {
  final FirebaseFirestore _firestore;

  FirestoreDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _shoppingListsCollection => _firestore.collection('shopping_lists');
  DocumentReference _userDoc(String userId) => _usersCollection.doc(userId);
  CollectionReference _itemsCollection(String listId) => _shoppingListsCollection.doc(listId).collection('items');
  CollectionReference _categoriesCollection(String userId) => _userDoc(userId).collection('categories');
  DocumentReference _unitsDoc(String userId) => _userDoc(userId).collection('app_data').doc('units');

  // <<< CORREÇÃO APLICADA AQUI >>>
  @override
  Stream<List<ShoppingListModel>> getShoppingListsStream(String userId) {
    return _shoppingListsCollection
    // O nome do campo correto é "memberIds", não "members".
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ShoppingListModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<List<UserModel>> getUsersFromIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    final userDocs = await _usersCollection.where(FieldPath.documentId, whereIn: userIds).get();
    return userDocs.docs.map((doc) => UserModel.fromFirestoreMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<ShoppingListModel> getShoppingListById(String listId, String userId) async {
    final doc = await _shoppingListsCollection.doc(listId).get();
    if (!doc.exists) {
      throw Exception("Lista não encontrada.");
    }
    final model = ShoppingListModel.fromMap(doc.data() as Map<String, dynamic>);
    if (!model.memberIds.contains(userId)) {
      throw Exception("Acesso negado.");
    }
    return model;
  }

  @override
  Future<String?> findUserUidByEmail(String email) async {
    final querySnapshot = await _usersCollection
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }
    return null;
  }

  @override
  Future<void> saveShoppingList(ShoppingListModel list) {
    return _shoppingListsCollection.doc(list.id).set(list.toFirestoreMap());
  }

  @override
  Future<void> removeMemberFromList(String listId, String memberIdToRemove) {
    return _shoppingListsCollection.doc(listId).update({
      'memberIds': FieldValue.arrayRemove([memberIdToRemove]) // Também corrigido aqui para consistência
    });
  }

  @override
  Future<void> deleteShoppingList(String listId, String userId) async {
    final itemsSnapshot = await _itemsCollection(listId).get();
    final batch = _firestore.batch();
    for (var doc in itemsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_shoppingListsCollection.doc(listId));
    return batch.commit();
  }

  @override
  Stream<List<ItemModel>> getItemsStream(String userId, String listId) {
    return _itemsCollection(listId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ItemModel.fromJoinedMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<List<ItemModel>> getItems(String listId) async {
    final snapshot = await _itemsCollection(listId).get();
    return snapshot.docs
        .map((doc) => ItemModel.fromJoinedMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveItem(ItemModel item, String userId) {
    return _itemsCollection(item.shoppingListId)
        .doc(item.id)
        .set(item.toMapForFirestore());
  }

  @override
  Future<void> deleteItem(String itemId, String userId, String listId) {
    return _itemsCollection(listId).doc(itemId).delete();
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
      final docRef = _shoppingListsCollection.doc(list.id);
      batch.set(docRef, list.toFirestoreMap());
      final itemsForThisList = allItems.where((item) => item.shoppingListId == list.id);
      for (final item in itemsForThisList) {
        final itemDocRef = _itemsCollection(list.id).doc(item.id);
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

    final ownedListsSnapshot = await _shoppingListsCollection.where('ownerId', isEqualTo: userId).get();
    for (final doc in ownedListsSnapshot.docs) {
      final itemsSnapshot = await _itemsCollection(doc.id).get();
      for (final itemDoc in itemsSnapshot.docs) {
        batch.delete(itemDoc.reference);
      }
      batch.delete(doc.reference);
    }

    final categoriesSnapshot = await _categoriesCollection(userId).get();
    for (final doc in categoriesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_unitsDoc(userId));
    batch.delete(_userDoc(userId));

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