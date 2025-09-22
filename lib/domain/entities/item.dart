import 'package:superlistas/domain/entities/category.dart';

class Item {
  final String id;
  final String name;
  // --- ATUALIZAÇÃO: Novos campos e tipo de dado alterado ---
  final double price;
  final double quantity;
  final String unit;
  final bool isChecked;
  final Category category;
  final String? notes;
  final DateTime? completionDate;

  Item({
    required this.id,
    required this.name,
    required this.category,
    this.price = 0.0,
    this.quantity = 1.0,
    this.unit = 'un',
    this.isChecked = false,
    this.notes,
    this.completionDate,
  });

  // Helper para calcular o subtotal do item
  double get subtotal => price * quantity;

  Item copyWith({
    String? name,
    double? price,
    double? quantity,
    String? unit,
    bool? isChecked,
    Category? category,
    String? notes,
    DateTime? completionDate,
  }) {
    return Item(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isChecked: isChecked ?? this.isChecked,
      notes: notes ?? this.notes,
      completionDate: (isChecked == false) ? null : (completionDate ?? this.completionDate),
    );
  }
}