// lib/domain/entities/shopping_list.dart

class ShoppingList {
  final String id;
  final String name;
  final DateTime creationDate;
  final int totalItems;
  final int checkedItems;
  final bool isArchived;
  final double? budget;
  final double totalCost;
  final String userId;

  ShoppingList({
    required this.id,
    required this.name,
    required this.creationDate,
    this.totalItems = 0,
    this.checkedItems = 0,
    this.isArchived = false,
    this.budget,
    this.totalCost = 0.0,
    required this.userId,
  });

  double get progress => totalItems > 0 ? checkedItems / totalItems : 0.0;
  bool get isCompleted => totalItems > 0 && totalItems == checkedItems;

  factory ShoppingList.fromRichMap(Map<String, dynamic> map) {
    return ShoppingList(
      id: map['id'],
      name: map['name'],
      creationDate: DateTime.parse(map['creationDate']),
      isArchived: map['isArchived'] == 1,
      budget: map['budget'],
      userId: map['userId'],
      totalItems: (map['totalItems'] as int?) ?? 0,
      checkedItems: (map['checkedItems'] as int?) ?? 0,
      totalCost: (map['totalCost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // <<< 1. MÉTODO copyWith ADICIONADO >>>
  ShoppingList copyWith({
    String? name,
    bool? isArchived,
    double? budget,
    // Note que não permitimos a alteração de outros campos como ID, data, etc.
  }) {
    return ShoppingList(
      id: id,
      name: name ?? this.name,
      creationDate: creationDate,
      totalItems: totalItems,
      checkedItems: checkedItems,
      isArchived: isArchived ?? this.isArchived,
      // Para o budget, precisamos de uma forma de torná-lo nulo
      // Esta é uma maneira de fazer isso, embora um pouco mais complexa
      // Por simplicidade, vamos manter a lógica original por enquanto
      // e só permitir a atualização. A lógica para zerar pode ser adicionada depois.
      budget: budget ?? this.budget,
      totalCost: totalCost,
      userId: userId,
    );
  }
}