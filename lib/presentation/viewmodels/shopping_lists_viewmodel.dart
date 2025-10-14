// lib/presentation/viewmodels/shopping_lists_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/domain/entities/item.dart';
import 'package:superlistas/domain/entities/member.dart';
import 'package:superlistas/domain/entities/shopping_list.dart';
import 'package:superlistas/domain/repositories/shopping_list_repository.dart';
import 'package:superlistas/presentation/providers/providers.dart';
import 'package:uuid/uuid.dart';

class ShoppingListsViewModel extends StateNotifier<AsyncValue<List<ShoppingList>>> {
  final Ref ref;
  final ShoppingListRepository _repository;
  final String _userId;

  ShoppingListsViewModel(this.ref, this._repository, this._userId)
      : super(const AsyncValue.data([]));

  void _invalidateAllProviders() {
    ref.invalidate(shoppingListsStreamProvider(_userId));
    ref.invalidate(dashboardViewModelProvider(_userId));
    ref.invalidate(historyViewModelProvider(_userId));
  }

  Future<String> addList(String name, {double? budget}) async {
    final currentUser = ref.read(authViewModelProvider);
    final newMember = Member(
      uid: _userId,
      name: currentUser?.name ?? 'Você',
      photoUrl: currentUser?.photoUrl,
    );

    final newList = ShoppingList(
      id: const Uuid().v4(),
      name: name,
      creationDate: DateTime.now(),
      budget: budget,
      ownerId: _userId,
      members: [newMember],
    );

    try {
      await _repository.createShoppingList(newList);
      _invalidateAllProviders();
      return newList.id;
    } catch (e) {
      _invalidateAllProviders();
      rethrow;
    }
  }

  Future<void> updateList(ShoppingList list, String newName, {double? budget}) async {
    final updatedList = list.copyWith(name: newName, budget: budget);
    try {
      await _repository.updateShoppingList(updatedList);
      _invalidateAllProviders();
    } catch (e) {
      _invalidateAllProviders();
    }
  }

  Future<void> archiveList(ShoppingList list) async {
    try {
      final listToArchive = list.copyWith(isArchived: true);
      await _repository.updateShoppingList(listToArchive);
      _invalidateAllProviders();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> deleteList(String id) async {
    try {
      await _repository.deleteShoppingList(id);
      _invalidateAllProviders();
    } catch (e) {
      _invalidateAllProviders();
    }
  }

  Future<void> shareList({required String listId, required String email}) async {
    await _repository.shareList(listId: listId, newMemberEmail: email);
    _invalidateAllProviders();
  }

  Future<void> removeMember({required String listId, required String memberIdToRemove}) async {
    await _repository.removeMember(listId: listId, memberIdToRemove: memberIdToRemove);
    _invalidateAllProviders();
    ref.invalidate(singleListProvider(listId));
  }
  Future<void> leaveList({required String listId}) async {
    await _repository.leaveList(listId: listId);
    _invalidateAllProviders();
  }

  Future<String> _createEmptyList({
    required String name,
    double? budget,
  }) async {
    final newId = const Uuid().v4();
    final currentUser = ref.read(authViewModelProvider);
    final newMember = Member(
      uid: _userId,
      name: currentUser?.name ?? 'Você',
      photoUrl: currentUser?.photoUrl,
    );

    final newList = ShoppingList(
      id: newId,
      name: name,
      creationDate: DateTime.now(),
      budget: budget,
      ownerId: _userId,
      members: [newMember],
    );
    await _repository.createShoppingList(newList);
    return newId;
  }

  Future<String> createFromTemplate({
    required String name,
    double? budget,
    List<Item> items = const [],
  }) async {
    try {
      final newListId = await _createEmptyList(name: name, budget: budget);
      for (final it in items) {
        final cloned = Item(
          id: const Uuid().v4(),
          name: it.name,
          category: it.category,
          price: it.price,
          quantity: it.quantity,
          unit: it.unit,
          isChecked: false,
          notes: it.notes,
          completionDate: null,
        );
        await _repository.createItem(cloned, newListId);
      }
      _invalidateAllProviders();
      return newListId;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return '';
    }
  }

  Future<String> duplicateListById(
      String listId, {
        String prefix = 'Cópia – ',
        bool cloneItems = true,
      }) async {
    try {
      final source = await _repository.getShoppingListById(listId);
      return await duplicateList(
        source,
        prefix: prefix,
        cloneItems: cloneItems,
      );
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return '';
    }
  }

  Future<String> duplicateList(
      ShoppingList source, {
        String prefix = 'Cópia – ',
        bool cloneItems = true,
      }) async {
    try {
      final newListId = await _createEmptyList(
        name: '$prefix${source.name}',
        budget: source.budget,
      );

      if (cloneItems) {
        final items = await _repository.getItems(source.id);
        for (final it in items) {
          final cloned = Item(
            id: const Uuid().v4(),
            name: it.name,
            category: it.category,
            price: it.price,
            quantity: it.quantity,
            unit: it.unit,
            isChecked: false,
            notes: it.notes,
            completionDate: null,
          );
          await _repository.createItem(cloned, newListId);
        }
      }
      _invalidateAllProviders();
      return newListId;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return '';
    }
  }

  Future<int> archiveCompletedLists() async {
    try {
      final all = await ref.read(shoppingListsStreamProvider(_userId).future);
      final toArchive = all.where((l) => l.isCompleted && !l.isArchived).toList();
      if (toArchive.isEmpty) return 0;

      for (final l in toArchive) {
        final updated = l.copyWith(isArchived: true);
        await _repository.updateShoppingList(updated);
      }
      _invalidateAllProviders();
      return toArchive.length;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return 0;
    }
  }
}