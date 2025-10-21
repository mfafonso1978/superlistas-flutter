// lib/domain/entities/item.dart
import 'package:superlistas/domain/entities/category.dart';
import 'package:equatable/equatable.dart';

class Item extends Equatable {
  final String id;
  final String name;
  final double price;
  final double quantity;
  final String unit;
  final bool isChecked;
  final Category category;
  final String? notes;
  final DateTime? completionDate;
  final String? barcode; // <<< CAMPO ADICIONADO AQUI

  const Item({
    required this.id,
    required this.name,
    required this.category,
    this.price = 0.0,
    this.quantity = 1.0,
    this.unit = 'un',
    this.isChecked = false,
    this.notes,
    this.completionDate,
    this.barcode, // <<< CAMPO ADICIONADO AQUI
  });

  double get subtotal => price * quantity;

  @override
  List<Object?> get props => [
    id,
    name,
    category,
    price,
    quantity,
    unit,
    isChecked,
    notes,
    completionDate,
    barcode, // <<< CAMPO ADICIONADO AQUI
  ];

  Item copyWith({
    String? id,
    String? name,
    double? price,
    double? quantity,
    String? unit,
    bool? isChecked,
    Category? category,
    String? notes,
    DateTime? completionDate,
    String? barcode,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isChecked: isChecked ?? this.isChecked,
      notes: notes ?? this.notes,
      completionDate: (isChecked == false) ? null : (completionDate ?? this.completionDate),
      barcode: barcode ?? this.barcode,
    );
  }
}