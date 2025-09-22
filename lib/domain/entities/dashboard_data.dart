import 'package:superlistas/domain/entities/shopping_list.dart';

class DashboardData {
  final int activeListsCount;      // sinônimo de pendentes (não arquivadas)
  final int pendingListsCount;     // igual activeListsCount (mantido por clareza na UI)
  final int completedListsCount;   // arquivadas (histórico)
  final int emptyListsCount;       // ativas com 0 itens
  final List<ShoppingList> recentLists;

  const DashboardData({
    required this.activeListsCount,
    required this.pendingListsCount,
    required this.completedListsCount,
    required this.emptyListsCount,
    required this.recentLists,
  });
}
