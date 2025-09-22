import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/domain/entities/shopping_list.dart';
import 'package:superlistas/domain/repositories/shopping_list_repository.dart';

class HistoryViewModel extends StateNotifier<AsyncValue<List<ShoppingList>>> {
  final ShoppingListRepository _repository;
  final String _userId; // 1. ADICIONADO

  // 2. CONSTRUTOR ATUALIZADO
  HistoryViewModel(this._repository, this._userId) : super(const AsyncValue.loading()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      state = const AsyncValue.loading();
      // 3. USANDO O _userId PARA BUSCAR AS LISTAS
      final allLists = await _repository.getShoppingLists(_userId);

      // O restante da lógica permanece o mesmo
      final historyLists = allLists.where((list) => list.isArchived || (list.isCompleted)).toList();
      state = AsyncValue.data(historyLists);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> reuseList(ShoppingList list) async {
    try {
      // Assumindo que este método não precisa do userId, pois já tem o objeto 'list'
      await _repository.reuseShoppingList(list);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> deleteList(String id) async {
    try {
      await _repository.deleteShoppingList(id);
      loadHistory(); // Recarrega o histórico
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}