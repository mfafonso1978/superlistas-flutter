import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/domain/entities/dashboard_data.dart';
import 'package:superlistas/domain/entities/shopping_list.dart';
import 'package:superlistas/domain/repositories/shopping_list_repository.dart';

class DashboardViewModel extends StateNotifier<AsyncValue<DashboardData>> {
  final ShoppingListRepository _repository;
  final String _userId;

  DashboardViewModel(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    loadData();
  }

  Future<void> loadData() async {
    try {
      state = const AsyncValue.loading();

      // Busca TODAS as listas do usuário (ativas e históricas)
      final allLists = await _repository.getShoppingLists(_userId);

      // Ordena por data de criação (mais novas primeiro)
      allLists.sort((a, b) => b.creationDate.compareTo(a.creationDate));

      // Definições:
      // - "Concluída" = arquivada (foi para o Histórico)
      // - "Pendente"  = não arquivada
      // - "Vazia"     = não arquivada e sem itens
      final completedListsCount = allLists.where((l) => l.isArchived).length;
      final pendingLists = allLists.where((l) => !l.isArchived).toList();
      final pendingListsCount = pendingLists.length;
      final emptyListsCount =
          pendingLists.where((l) => l.totalItems == 0).length;

      // Para compatibilidade com a UI anterior
      final activeListsCount = pendingListsCount;

      // 3 mais recentes (pode incluir concluídas e pendentes)
      final recentLists = allLists.take(3).toList();

      state = AsyncValue.data(
        DashboardData(
          activeListsCount: activeListsCount,
          pendingListsCount: pendingListsCount,
          completedListsCount: completedListsCount,
          emptyListsCount: emptyListsCount,
          recentLists: recentLists,
        ),
      );
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}
