import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/domain/entities/stats_data.dart';
import 'package:superlistas/domain/repositories/shopping_list_repository.dart';

class StatsViewModel extends StateNotifier<AsyncValue<StatsData>> {
  final ShoppingListRepository _repository;
  final String _userId; // 1. ADICIONADO

  // 2. CONSTRUTOR ATUALIZADO
  StatsViewModel(this._repository, this._userId) : super(const AsyncValue.loading()) {
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      state = const AsyncValue.loading();
      // 3. USANDO O _userId PARA BUSCAR AS ESTATÍSTICAS
      final stats = await _repository.getStats(_userId);
      state = AsyncValue.data(stats);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}