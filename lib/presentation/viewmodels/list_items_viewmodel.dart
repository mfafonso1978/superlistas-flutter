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
      : super(const AsyncValue.loading()) {
    loadItems();
  }

  Future<void> loadItems() async {
    try {
      state = const AsyncValue.loading();
      final items = await _repository.getItems(_shoppingListId);
      state = AsyncValue.data(items);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  // Esta função de invalidação em cascata permanece a mesma
  Future<void> _invalidateAllForListOwner() async {
    try {
      final list = await _repository.getShoppingListById(_shoppingListId);
      final userId = list.userId;

      ref.invalidate(shoppingListsViewModelProvider(userId));
      ref.invalidate(historyViewModelProvider(userId));
      ref.invalidate(dashboardViewModelProvider(userId));
    } catch (_) {
      // Ignora falha de descoberta
    }
  }

  // <<< 6. MÉTODO addItem REATORADO >>>
  Future<void> addItem(Item item) async {
    final currentState = state;
    if (!currentState.hasValue) return;

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
      // Atualização Otimista
      final currentItems = currentState.value!;
      state = AsyncValue.data([...currentItems, itemToAdd]);

      // Persistência
      await _repository.createItem(itemToAdd, _shoppingListId);
      await _invalidateAllForListOwner();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  // <<< 7. MÉTODO updateItem (já estava bom, apenas confirmando) >>>
  Future<void> updateItem(Item item) async {
    final currentState = state;
    if (!currentState.hasValue) return;

    final itemToUpdate = item.copyWith(
      completionDate:
      item.isChecked ? (item.completionDate ?? DateTime.now()) : null,
    );

    try {
      // Atualização Otimista
      final currentItems = currentState.value!;
      final updatedList = [
        for (final i in currentItems) if (i.id == itemToUpdate.id) itemToUpdate else i
      ];
      state = AsyncValue.data(updatedList);

      // Persistência
      await _repository.updateItem(itemToUpdate, _shoppingListId);
      await _invalidateAllForListOwner();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  /// Usado pelo botão "Concluir compra": arquiva a lista
  Future<void> archiveList(ShoppingList list) async {
    try {
      final listToArchive = list.copyWith(isArchived: true);
      await _repository.updateShoppingList(listToArchive);
      await _invalidateAllForListOwner();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  // <<< 8. MÉTODO deleteItem REATORADO >>>
  Future<void> deleteItem(String id) async {
    final currentState = state;
    if (!currentState.hasValue) return;

    try {
      // Atualização Otimista
      final currentItems = currentState.value!;
      final newItems = currentItems.where((item) => item.id != id).toList();
      state = AsyncValue.data(newItems);

      // Persistência
      await _repository.deleteItem(id);
      await _invalidateAllForListOwner();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}