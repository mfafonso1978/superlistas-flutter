// lib/presentation/viewmodels/shopping_lists_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/domain/entities/item.dart';
import 'package:superlistas/domain/entities/shopping_list.dart';
import 'package:superlistas/domain/repositories/shopping_list_repository.dart';
import 'package:uuid/uuid.dart';

class ShoppingListsViewModel extends StateNotifier<AsyncValue<List<ShoppingList>>> {
  final ShoppingListRepository _repository;
  final String _userId;

  ShoppingListsViewModel(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    loadLists();
  }

  Future<void> loadLists() async {
    try {
      state = const AsyncValue.loading();
      final allLists = await _repository.getShoppingLists(_userId);
      // O filtro para listas ativas permanece
      final activeLists = allLists.where((list) => !list.isArchived).toList();
      state = AsyncValue.data(activeLists);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  // <<< 2. MÉTODO addList REATORADO >>>
  Future<void> addList(String name, {double? budget}) async {
    final currentState = state;
    // Só prossegue se já tivermos dados
    if (!currentState.hasValue) return;

    // Cria a nova lista com valores iniciais
    final newList = ShoppingList(
      id: const Uuid().v4(),
      name: name,
      creationDate: DateTime.now(),
      budget: budget,
      userId: _userId,
      totalItems: 0,
      checkedItems: 0,
      totalCost: 0.0,
    );

    try {
      // Atualização Otimista: Adiciona à lista em memória e atualiza a UI
      final currentLists = currentState.value!;
      state = AsyncValue.data([...currentLists, newList]);

      // Tenta persistir a mudança no banco de dados
      await _repository.createShoppingList(newList);
    } catch (e, s) {
      // Se der erro, reverte o estado e o reporta
      state = AsyncValue.error(e, s);
      // Opcionalmente, poderia voltar ao estado anterior: state = currentState;
    }
  }

  // <<< 3. MÉTODO updateList REATORADO >>>
  Future<void> updateList(ShoppingList list, String newName, {double? budget}) async {
    final currentState = state;
    if (!currentState.hasValue) return;

    // Cria a versão atualizada da lista usando o copyWith
    final updatedList = list.copyWith(name: newName, budget: budget);

    try {
      // Atualização Otimista: Substitui o item na lista em memória
      final currentLists = currentState.value!;
      final newLists = [
        for (final l in currentLists)
          if (l.id == updatedList.id) updatedList else l
      ];
      state = AsyncValue.data(newLists);

      // Tenta persistir a mudança
      await _repository.updateShoppingList(updatedList);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  // <<< 4. MÉTODO archiveList REATORADO >>>
  Future<void> archiveList(ShoppingList list) async {
    final currentState = state;
    if (!currentState.hasValue) return;

    // A "atualização" aqui é remover a lista da visão de listas ativas
    try {
      // Atualização Otimista: Remove da lista em memória
      final currentLists = currentState.value!;
      final newLists = currentLists.where((l) => l.id != list.id).toList();
      state = AsyncValue.data(newLists);

      // Tenta persistir a mudança (setando isArchived = true)
      final listToArchive = list.copyWith(isArchived: true);
      await _repository.updateShoppingList(listToArchive);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  // <<< 5. MÉTODO deleteList REATORADO >>>
  Future<void> deleteList(String id) async {
    final currentState = state;
    if (!currentState.hasValue) return;

    try {
      // Atualização Otimista: Remove da lista em memória
      final currentLists = currentState.value!;
      final newLists = currentLists.where((l) => l.id != id).toList();
      state = AsyncValue.data(newLists);

      // Tenta persistir a mudança
      await _repository.deleteShoppingList(id);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  // O restante dos métodos (de template, duplicação, etc.) permanece o mesmo por enquanto,
  // pois eles já contêm lógicas mais complexas que chamam esses métodos base.
  // Eles se beneficiarão automaticamente da velocidade dos métodos base refatorados.

  // =====================================================
  //                  AÇÕES (com ITENS)
  // =====================================================

  /// Helper: cria uma lista vazia e retorna o ID.
  Future<String> _createEmptyList({
    required String name,
    double? budget,
  }) async {
    final newId = const Uuid().v4();
    final newList = ShoppingList(
      id: newId,
      name: name,
      creationDate: DateTime.now(),
      budget: budget,
      userId: _userId,
    );
    await _repository.createShoppingList(newList);
    return newId;
  }

  /// Cria uma lista a partir de um template (nome/orçamento + itens).
  Future<String> createFromTemplate({
    required String name,
    double? budget,
    List<Item> items = const [],
  }) async {
    try {
      // Esta ação cria uma lista e itens, é mais complexa.
      // A melhor abordagem é realizar a ação e depois recarregar.
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

      await loadLists(); // Recarga é apropriada aqui devido à complexidade.
      return newListId;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return '';
    }
  }

  /// Duplica uma lista a partir do ID.
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

  /// Duplica uma lista (nome/orçamento) e, opcionalmente, clona seus itens.
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

      await loadLists(); // Recarga é apropriada aqui também.
      return newListId;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return '';
    }
  }

  /// Arquiva todas as listas concluídas (não arquivadas) do usuário.
  Future<int> archiveCompletedLists() async {
    try {
      // Esta operação em lote também justifica uma recarga.
      final all = await _repository.getShoppingLists(_userId);
      final toArchive = all.where((l) => l.isCompleted && !l.isArchived).toList();
      if (toArchive.isEmpty) return 0;

      for (final l in toArchive) {
        final updated = l.copyWith(isArchived: true);
        await _repository.updateShoppingList(updated);
      }

      await loadLists();
      return toArchive.length;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return 0;
    }
  }
}