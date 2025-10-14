// lib/presentation/viewmodels/list_items_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/domain/entities/item.dart';
import 'package:superlistas/domain/repositories/shopping_list_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:superlistas/domain/entities/shopping_list.dart';
import 'package:superlistas/presentation/providers/providers.dart';

class ListItemsViewModel extends StateNotifier<AsyncValue<List<Item>>> {
  final Ref ref;
  final ShoppingListRepository _repository;
  final String _shoppingListId;

  ListItemsViewModel(this.ref, this._repository, this._shoppingListId)
      : super(const AsyncValue.data([]));

  Future<void> _invalidateDependentProviders() async {
    try {
      final list = await _repository.getShoppingListById(_shoppingListId);
      final userId = list.ownerId;

      ref.invalidate(listItemsStreamProvider(_shoppingListId));
      ref.invalidate(shoppingListsStreamProvider(userId));
      ref.invalidate(dashboardViewModelProvider(userId));
      ref.invalidate(singleListProvider(_shoppingListId));
    } catch (_) {
      // Ignora erros
    }
  }

  Future<void> addItem(Item item) async {
    final itemToAdd = Item(
      id: const Uuid().v4(),
      name: item.name,
      category: item.category,
      price: item.price,
      quantity: item.quantity,
      unit: item.unit,
      isChecked: item.isChecked,
      notes: item.notes,
      completionDate: item.isChecked ? DateTime.now() : null,
    );

    try {
      await _repository.createItem(itemToAdd, _shoppingListId);
      await _invalidateDependentProviders();
    } catch (e) {
      await _invalidateDependentProviders();
    }
  }

  Future<void> updateItem(Item item) async {
    final itemToUpdate = item.copyWith(
      completionDate:
      item.isChecked ? (item.completionDate ?? DateTime.now()) : null,
    );

    try {
      await _repository.updateItem(itemToUpdate, _shoppingListId);
      await _invalidateDependentProviders();
    } catch (e) {
      await _invalidateDependentProviders();
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      final list = await _repository.getShoppingListById(_shoppingListId);
      final userId = list.ownerId;

      await _repository.deleteItem(itemId, _shoppingListId, userId);
      await _invalidateDependentProviders();
    } catch (e) {
      await _invalidateDependentProviders();
    }
  }

  Future<void> archiveList(ShoppingList list) async {
    try {
      final listToArchive = list.copyWith(isArchived: true);
      await _repository.updateShoppingList(listToArchive);

      ref.invalidate(shoppingListsStreamProvider(list.ownerId));
      ref.invalidate(historyViewModelProvider(list.ownerId));
      ref.invalidate(dashboardViewModelProvider(list.ownerId));
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}