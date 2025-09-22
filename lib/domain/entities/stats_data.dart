import 'package:superlistas/domain/entities/category.dart';

class StatsData {
  final int totalItemsPurchased;
  final int completedLists;
  final Category? topCategory;
  final Map<String, int> itemsByCategory;
  // --- ATUALIZAÇÃO: Novo campo ---
  final Map<String, int> itemsByMonth; // Ex: {'2025-08': 42, '2025-07': 28}

  StatsData({
    required this.totalItemsPurchased,
    required this.completedLists,
    this.topCategory,
    required this.itemsByCategory,
    required this.itemsByMonth, // Adicionado
  });
}