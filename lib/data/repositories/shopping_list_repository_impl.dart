// lib/data/repositories/shopping_list_repository_impl.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:superlistas/data/datasources/local_datasource.dart';
import 'package:superlistas/data/datasources/remote_config_service.dart';
import 'package:superlistas/data/datasources/firestore_datasource.dart';

import 'package:superlistas/data/models/category_model.dart';
import 'package:superlistas/data/models/item_model.dart';
import 'package:superlistas/data/models/shopping_list_model.dart';
import 'package:superlistas/data/models/sync_operation_model.dart';
import 'package:superlistas/data/models/user_product_model.dart';

import 'package:superlistas/domain/entities/category.dart' as domain;
import 'package:superlistas/domain/entities/item.dart';
import 'package:superlistas/domain/entities/member.dart';
import 'package:superlistas/domain/entities/shopping_list.dart';
import 'package:superlistas/domain/entities/stats_data.dart';
import 'package:superlistas/domain/entities/user_product.dart';
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
    final isPremium   = remoteConfigService.isUserPremium;
    final isCloudOn   = remoteConfigService.isCloudSyncEnabled;
    return isPremium && isCloudOn;
  }

  String? _currentUid() => FirebaseAuth.instance.currentUser?.uid;

  // helper seguro
  CategoryModel _toCat(domain.Category c) => CategoryModel(
    id: c.id,
    name: c.name,
    icon: c.icon,
    colorValue: c.colorValue,
  );

  // ---------------------------------------------------------------------------
  // LISTAS
  // ---------------------------------------------------------------------------
  @override
  Stream<List<ShoppingList>> getShoppingListsStream(String uid) {
    if (_shouldSync()) {
      return remoteDataSource.getShoppingListsStream(uid).asyncMap((models) async {
        // carrega membros para todos
        final memberIds = models.expand((m) => m.memberIds).toSet().toList();
        final users     = await remoteDataSource.getUsersFromIds(memberIds);
        final usersMap  = {for (var u in users) u.id: u};

        // converte e calcula totais
        final lists = await Future.wait(models.map((m) async {
          final items   = await remoteDataSource.getItems(m.id);
          final members = m.memberIds
              .map((id) => Member(uid: id, name: usersMap[id]?.name ?? 'Usuário',
              photoUrl: usersMap[id]?.photoUrl))
              .toList();

          return ShoppingList(
            id          : m.id,
            name        : m.name,
            creationDate: m.creationDate,
            isArchived  : m.isArchived,
            budget      : m.budget ?? 0.0,
            ownerId     : m.ownerId,
            members     : members,
            totalItems  : items.length,
            checkedItems: items.where((e) => e.isChecked).length,
            totalCost   : items.fold(0.0, (s, e) => s + e.subtotal),
          );
        }));

        // <<< CORREÇÃO APLICADA AQUI >>>
        // A linha que apagava tudo foi removida.
        // await localDataSource.deleteAllShoppingListsForUser(uid);

        // Agora, o loop abaixo vai inserir novas listas ou ATUALIZAR as existentes.
        for (final l in lists) {
          final model = ShoppingListModel(
            id         : l.id,
            name       : l.name,
            creationDate: l.creationDate,
            isArchived : l.isArchived,
            budget     : l.budget,
            ownerId    : l.ownerId,
            memberIds  : l.members.map((m) => m.uid).toList(),
          );
          await localDataSource.addShoppingList(model);
        }
        return lists;
      });
    }
    // fallback offline
    return Stream.fromFuture(getShoppingLists(uid));
  }

  @override
  Future<List<ShoppingList>> getShoppingLists(String uid) async {
    final maps = await localDataSource.getRichShoppingListsForUser(uid);
    return maps.map((m) => ShoppingList.fromRichMap(m)).toList();
  }

  @override
  Future<ShoppingList> getShoppingListById(String id) async {
    final uid = _currentUid();

    // ---------- vers. online ----------
    if (_shouldSync() && uid != null) {
      final m       = await remoteDataSource.getShoppingListById(id, uid);
      final users   = await remoteDataSource.getUsersFromIds(m.memberIds);
      final uMap    = {for (var u in users) u.id: u};
      final members = m.memberIds
          .map((x) => Member(uid: x, name: uMap[x]?.name ?? 'Usuário',
          photoUrl: uMap[x]?.photoUrl))
          .toList();

      final items    = await getItems(id);
      final totalCost= items.fold(0.0, (s, e) => s + e.subtotal);

      return ShoppingList(
        id          : m.id,
        name        : m.name,
        creationDate: m.creationDate,
        isArchived  : m.isArchived,
        budget      : m.budget ?? 0.0,
        ownerId     : m.ownerId,
        members     : members,
        totalItems  : items.length,
        checkedItems: items.where((e) => e.isChecked).length,
        totalCost   : totalCost,
      );
    }

    // ---------- vers. offline ----------
    final model = await localDataSource.getShoppingListById(id);
    if (model == null) throw Exception('Lista não encontrada ($id)');

    final members = model.memberIds.map((x) => Member(uid: x, name: 'Usuário')).toList();

    final total   = await localDataSource.countTotalItems(id);
    final checked = await localDataSource.countCheckedItems(id);
    final cost    = await localDataSource.getTotalCostOfList(id);

    return ShoppingList(
      id          : model.id,
      name        : model.name,
      creationDate: model.creationDate,
      isArchived  : model.isArchived,
      budget      : model.budget ?? 0.0,
      ownerId     : model.ownerId,
      members     : members,
      totalItems  : total,
      checkedItems: checked,
      totalCost   : cost,
    );
  }

  @override
  Future<void> createShoppingList(ShoppingList l) async {
    final model = ShoppingListModel(
      id         : l.id,
      name       : l.name,
      creationDate: l.creationDate,
      isArchived : l.isArchived,
      budget     : l.budget,
      ownerId    : l.ownerId,
      memberIds  : [l.ownerId],
    );
    await localDataSource.addShoppingList(model);

    if (_shouldSync()) {
      try {
        await remoteDataSource.saveShoppingList(model);
      } catch (e) {
        if (kDebugMode) print('Sync falhou, enfileirando: $e');
        await localDataSource.addToSyncQueue(SyncOperationModel(
          userId       : l.ownerId,
          entityType   : 'shopping_list',
          entityId     : l.id,
          operationType: 'save',
          payload      : jsonEncode(model.toFirestoreMap()),
          timestamp    : DateTime.now(),
        ));
      }
    }
  }

  @override
  Future<void> updateShoppingList(ShoppingList l) async {
    final model = ShoppingListModel(
      id         : l.id,
      name       : l.name,
      creationDate: l.creationDate,
      isArchived : l.isArchived,
      budget     : l.budget,
      ownerId    : l.ownerId,
      memberIds  : l.members.map((m) => m.uid).toList(),
    );
    await localDataSource.updateShoppingList(model);

    if (_shouldSync()) {
      try {
        await remoteDataSource.saveShoppingList(model);
      } catch (e) {
        if (kDebugMode) print('Sync falhou, enfileirando: $e');
        await localDataSource.addToSyncQueue(SyncOperationModel(
          userId       : l.ownerId,
          entityType   : 'shopping_list',
          entityId     : l.id,
          operationType: 'save',
          payload      : jsonEncode(model.toFirestoreMap()),
          timestamp    : DateTime.now(),
        ));
      }
    }
  }

  @override
  Future<void> deleteShoppingList(String id) async {
    final local = await localDataSource.getShoppingListById(id);
    if (local == null) return;

    await localDataSource.deleteShoppingList(id);

    if (_shouldSync()) {
      try {
        await remoteDataSource.deleteShoppingList(id, local.ownerId);
      } catch (e) {
        if (kDebugMode) print('Sync delete falhou, fila: $e');
        await localDataSource.addToSyncQueue(SyncOperationModel(
          userId       : local.ownerId,
          entityType   : 'shopping_list',
          entityId     : id,
          operationType: 'delete',
          timestamp    : DateTime.now(),
        ));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // MEMBROS REMOTOS (share / remove / leave)
  // ---------------------------------------------------------------------------
  @override
  Future<void> shareList({required String listId, required String newMemberEmail}) async {
    if (!_shouldSync()) throw Exception('Compartilhar requer sync premium.');
    final uid = _currentUid() ?? (throw Exception('Usuário não autenticado.'));

    final newUid = await remoteDataSource.findUserUidByEmail(newMemberEmail)
        ?? (throw Exception('Usuário não encontrado.'));
    if (newUid == uid) throw Exception('Você já é dono da lista.');

    final m = await remoteDataSource.getShoppingListById(listId, uid);
    if (m.memberIds.contains(newUid)) throw Exception('Usuário já é membro.');

    final updated = ShoppingListModel(
      id         : m.id,
      name       : m.name,
      creationDate: m.creationDate,
      isArchived : m.isArchived,
      budget     : m.budget ?? 0.0,
      ownerId    : m.ownerId,
      memberIds  : [...m.memberIds, newUid],
    );
    await remoteDataSource.saveShoppingList(updated);
  }

  @override
  Future<void> removeMember({required String listId, required String memberIdToRemove}) async {
    if (!_shouldSync()) throw Exception('Função premium.');
    final uid = _currentUid() ?? (throw Exception('Usuário não autenticado.'));

    final m = await remoteDataSource.getShoppingListById(listId, uid);
    if (uid != m.ownerId) throw Exception('Somente o proprietário pode remover.');
    if (memberIdToRemove == m.ownerId) throw Exception('Não remova o dono.');

    await remoteDataSource.removeMemberFromList(listId, memberIdToRemove);
  }

  @override
  Future<void> leaveList({required String listId}) async {
    if (!_shouldSync()) throw Exception('Função premium.');
    final uid = _currentUid() ?? (throw Exception('Usuário não autenticado.'));

    final m = await remoteDataSource.getShoppingListById(listId, uid);
    if (uid == m.ownerId) throw Exception('O dono não pode sair: exclua a lista.');
    await remoteDataSource.removeMemberFromList(listId, uid);
  }

  // ---------------------------------------------------------------------------
  // ITENS
  // ---------------------------------------------------------------------------
  @override
  Stream<List<Item>> getItemsStream(String uid, String listId) {
    if (_shouldSync()) {
      return remoteDataSource.getItemsStream(uid, listId).asyncMap((items) async {
        await localDataSource.deleteAllItemsFromList(listId);
        for (final i in items) {
          await localDataSource.addItem(i);
        }
        return items.cast<Item>().toList();
      });
    }
    return Stream.fromFuture(getItems(listId));
  }

  @override
  Future<List<Item>> getItems(String listId) async {
    if (_shouldSync()) {
      return (await remoteDataSource.getItems(listId)).cast<Item>().toList();
    }
    final local = await localDataSource.getItemsFromList(listId);
    return local.cast<Item>().toList();
  }

  @override
  Future<void> createItem(Item e, String listId) async {
    final list = await getShoppingListById(listId);

    final model = ItemModel(
      id            : e.id,
      name          : e.name,
      price         : e.price,
      quantity      : e.quantity,
      unit          : e.unit,
      isChecked     : e.isChecked,
      notes         : e.notes,
      completionDate: e.completionDate,
      category      : _toCat(e.category),
      shoppingListId: listId,
      barcode       : e.barcode,
    );

    await localDataSource.addItem(model);

    if (_shouldSync()) {
      try {
        await remoteDataSource.saveItem(model, list.ownerId);
      } catch (e) {
        if (kDebugMode) print('Fila save item: $e');
        await localDataSource.addToSyncQueue(SyncOperationModel(
          userId       : list.ownerId,
          entityType   : 'item',
          entityId     : model.id,
          operationType: 'save',
          payload      : jsonEncode(model.toMapForFirestore()),
          timestamp    : DateTime.now(),
        ));
      }
    }
  }

  @override
  Future<void> updateItem(Item e, String listId) async {
    final list = await getShoppingListById(listId);

    final model = ItemModel(
      id            : e.id,
      name          : e.name,
      price         : e.price,
      quantity      : e.quantity,
      unit          : e.unit,
      isChecked     : e.isChecked,
      notes         : e.notes,
      completionDate: e.completionDate,
      category      : _toCat(e.category),
      shoppingListId: listId,
      barcode       : e.barcode,
    );

    await localDataSource.updateItem(model);

    if (_shouldSync()) {
      try {
        await remoteDataSource.saveItem(model, list.ownerId);
      } catch (e) {
        if (kDebugMode) print('Fila upd item: $e');
        await localDataSource.addToSyncQueue(SyncOperationModel(
          userId       : list.ownerId,
          entityType   : 'item',
          entityId     : model.id,
          operationType: 'save',
          payload      : jsonEncode(model.toMapForFirestore()),
          timestamp    : DateTime.now(),
        ));
      }
    }
  }

  @override
  Future<void> deleteItem(String itemId, String listId, String ownerId) async {
    await localDataSource.deleteItem(itemId);
    if (_shouldSync()) {
      try {
        await remoteDataSource.deleteItem(itemId, ownerId, listId);
      } catch (e) {
        if (kDebugMode) print('Fila del item: $e');
        await localDataSource.addToSyncQueue(SyncOperationModel(
          userId       : ownerId,
          entityType   : 'item',
          entityId     : itemId,
          operationType: 'delete',
          payload      : jsonEncode({'listId': listId}),
          timestamp    : DateTime.now(),
        ));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // ESTATÍSTICAS
  // ---------------------------------------------------------------------------
  @override
  Future<StatsData> getStats(String uid) async {
    final lists = await getShoppingLists(uid);
    final items = await localDataSource.getAllItemsForUser(uid);
    final completed = lists.where((l) => l.isCompleted).length;
    final purchased = items.where((i) => i.isChecked).length;

    final byCat   = <String,int>{};
    final catMap  = <String,domain.Category>{};
    final byMonth = <String,int>{};

    for (final i in items.where((e) => e.isChecked)) {
      byCat.update(i.category.name, (v) => v + 1, ifAbsent: () => 1);
      catMap[i.category.name] = i.category;

      if (i.completionDate != null) {
        final k = DateFormat('yyyy-MM').format(i.completionDate!);
        byMonth.update(k, (v) => v + 1, ifAbsent: () => 1);
      }
    }

    domain.Category? top;
    if (byCat.isNotEmpty) {
      final name = byCat.entries.reduce((a,b) => a.value > b.value ? a : b).key;
      top = catMap[name];
    }

    return StatsData(
      totalItemsPurchased: purchased,
      completedLists     : completed,
      topCategory        : top,
      itemsByCategory    : byCat,
      itemsByMonth       : byMonth,
    );
  }

  // ---------------------------------------------------------------------------
  // IMPORT / EXPORT
  // ---------------------------------------------------------------------------
  @override
  Future<String> exportDataToJson(String uid) async {
    final cats  = await localDataSource.getAllCategories();
    final lists = await localDataSource.getAllShoppingListsForUser(uid);
    final items = await localDataSource.getAllItemsForUser(uid);

    final data = {
      'metadata': {
        'version'   : 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'appName'   : 'Superlistas',
      },
      'data': {
        'categories'    : cats.map((c) => c.toMap()).toList(),
        'shopping_lists': lists.map((l) => l.toDbMap()).toList(),
        'items'         : items.map((i) => i.toMap()).toList(),
      }
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  @override
  Future<void> importDataFromJson(String uid, String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString) as Map<String,dynamic>;
      if (!decoded.containsKey('data')) throw Exception('Sem chave data.');

      final data = decoded['data'] as Map<String,dynamic>;
      if (!data.keys.toSet().containsAll(
          const {'categories','shopping_lists','items'})) {
        throw Exception('JSON incompleto.');
      }
      await localDataSource.performImport(uid, data);
    } catch (e) {
      throw Exception('Falha no import: $e');
    }
  }

  @override
  Future<void> performInitialCloudSync(String uid) async {
    final local = await localDataSource.getAllDataForUser(uid);
    await remoteDataSource.performInitialSync(uid, local);
  }

  // ---------------------------------------------------------------------------
  // FILA DE SYNC
  // ---------------------------------------------------------------------------
  ItemModel _fromPayload(Map<String,dynamic> m) {
    final cat = CategoryModel(
      id        : m['categoryId'] as String,
      name      : m['categoryName'] as String,
      icon      : IconData(m['categoryIconCodePoint'] as int, fontFamily: 'MaterialIcons'),
      colorValue: Color(m['categoryColorValue'] as int),
    );
    return ItemModel(
      id            : m['id'] as String,
      name          : m['name'] as String,
      price         : (m['price'] as num?)?.toDouble() ?? 0.0,
      quantity      : (m['quantity'] as num?)?.toDouble() ?? 1.0,
      unit          : m['unit'] as String? ?? 'un',
      isChecked     : m['isChecked'] as bool? ?? false,
      notes         : m['notes'] as String?,
      completionDate: m['completionDate'] != null
          ? DateTime.parse(m['completionDate'] as String)
          : null,
      category      : cat,
      shoppingListId: m['shoppingListId'] as String,
      barcode       : m['barcode'] as String?,
    );
  }

  @override
  Future<void> processSyncQueue(String uid) async {
    final ops = await localDataSource.getPendingSyncOperations(uid);
    if (ops.isEmpty) return;

    for (final op in ops) {
      try {
        if (op.entityType == 'shopping_list') {
          if (op.operationType == 'save') {
            final model = ShoppingListModel.fromMap(jsonDecode(op.payload!));
            await remoteDataSource.saveShoppingList(model);
          } else {
            await remoteDataSource.deleteShoppingList(op.entityId, op.userId);
          }
        } else { // item
          if (op.operationType == 'save') {
            final model = _fromPayload(jsonDecode(op.payload!));
            await remoteDataSource.saveItem(model, op.userId);
          } else {
            final listId = (jsonDecode(op.payload!)['listId'] as String);
            await remoteDataSource.deleteItem(op.entityId, op.userId, listId);
          }
        }
        await localDataSource.removeSyncOperation(op.id!);
      } catch (e) {
        if (kDebugMode) print('Erro processando fila (${op.id}): $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // UNIDADES
  // ---------------------------------------------------------------------------
  @override
  Future<List<String>> getAllUnits() => localDataSource.getAllUnits();

  @override
  Future<void> addUnit(String n) async {
    await localDataSource.addUnit(n);
    if (_shouldSync()) {
      final uid = _currentUid();
      if (uid != null) {
        try {
          await remoteDataSource.saveAllUnits(await localDataSource.getAllUnits(), uid);
        } catch (_) {}
      }
    }
  }

  @override
  Future<void> deleteUnit(String n) async {
    await localDataSource.deleteUnit(n);
    if (_shouldSync()) {
      final uid = _currentUid();
      if (uid != null) {
        try {
          await remoteDataSource.saveAllUnits(await localDataSource.getAllUnits(), uid);
        } catch (_) {}
      }
    }
  }

  @override
  Future<void> updateUnit(String oldName, String newName) async {
    await localDataSource.updateUnit(oldName, newName);
    if (_shouldSync()) {
      final uid = _currentUid();
      if (uid != null) {
        try {
          await remoteDataSource.saveAllUnits(await localDataSource.getAllUnits(), uid);
        } catch (_) {}
      }
    }
  }

  // ---------------------------------------------------------------------------
  // CATEGORIAS
  // ---------------------------------------------------------------------------
  @override
  Future<void> createCategory(domain.Category c) async =>
      localDataSource.addCategory(_toCat(c));

  @override
  Future<List<domain.Category>> getCategories() async =>
      (await localDataSource.getAllCategories())
          .map((m) => domain.Category(
        id   : m.id,
        name : m.name,
        icon : m.icon,
        colorValue: m.colorValue,
      ))
          .toList();

  @override
  Future<void> updateCategory(domain.Category c) async =>
      localDataSource.updateCategory(_toCat(c));

  @override
  Future<void> deleteCategory(String id) async =>
      localDataSource.deleteCategory(id);

  // ---------------------------------------------------------------------------
  // PRODUTOS (EAN)
  // ---------------------------------------------------------------------------
  @override
  Future<UserProduct?> findProductByBarcode(String code) async =>
      await localDataSource.getUserProductByBarcode(code);

  @override
  Future<void> saveProduct(UserProduct p) async {
    final prod = UserProduct(
      id         : p.id.isEmpty ? const Uuid().v4() : p.id,
      userId     : p.userId,
      barcode    : p.barcode,
      productName: p.productName,
      price      : p.price,
      unit       : p.unit,
      categoryId : p.categoryId,
      notes      : p.notes,
      createdAt  : p.createdAt,
    );
    await localDataSource.saveUserProduct(UserProductModel.fromEntity(prod));
  }

  // ---------------------------------------------------------------------------
  // REUSE LIST
  // ---------------------------------------------------------------------------
  @override
  Future<void> reuseShoppingList(ShoppingList src) async {
    final newId = const Uuid().v4();
    final newList = ShoppingListModel(
      id         : newId,
      name       : src.name,
      creationDate: DateTime.now(),
      isArchived : false,
      budget     : src.budget,
      ownerId    : src.ownerId,
      memberIds  : src.members.map((m) => m.uid).toList(),
    );
    await localDataSource.addShoppingList(newList);

    final oldItems = await localDataSource.getItemsFromList(src.id);
    for (final it in oldItems) {
      final dup = ItemModel(
        id            : const Uuid().v4(),
        name          : it.name,
        price         : it.price,
        quantity      : it.quantity,
        unit          : it.unit,
        isChecked     : false,
        notes         : it.notes,
        completionDate: null,
        category      : _toCat(it.category),
        shoppingListId: newId,
        barcode       : it.barcode,
      );
      await localDataSource.addItem(dup);

      if (_shouldSync()) {
        try {
          await remoteDataSource.saveItem(dup, src.ownerId);
        } catch (_) {
          await localDataSource.addToSyncQueue(SyncOperationModel(
            userId       : src.ownerId,
            entityType   : 'item',
            entityId     : dup.id,
            operationType: 'save',
            payload      : jsonEncode(dup.toMapForFirestore()),
            timestamp    : DateTime.now(),
          ));
        }
      }
    }

    if (_shouldSync()) {
      try {
        await remoteDataSource.saveShoppingList(newList);
      } catch (_) {
        await localDataSource.addToSyncQueue(SyncOperationModel(
          userId       : src.ownerId,
          entityType   : 'shopping_list',
          entityId     : newId,
          operationType: 'save',
          payload      : jsonEncode(newList.toFirestoreMap()),
          timestamp    : DateTime.now(),
        ));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE ALL USER DATA
  // ---------------------------------------------------------------------------
  @override
  Future<void> deleteAllUserData(String uid) async {
    await localDataSource.deleteAllUserData(uid);
    if (_shouldSync()) {
      try {
        await remoteDataSource.deleteAllUserData(uid);
      } catch (_) {}
    }
  }
}