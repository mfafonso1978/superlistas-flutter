// lib/data/models/item_model.dart
import 'package:superlistas/domain/entities/item.dart';
import 'package:superlistas/data/models/category_model.dart';
import 'package:flutter/material.dart'; // Import necessário para Color

class ItemModel extends Item {
  final String shoppingListId;

  ItemModel({
    required super.id,
    required super.name,
    required super.category,
    required this.shoppingListId,
    super.price,
    super.quantity,
    super.unit,
    super.isChecked,
    super.notes,
    super.completionDate,
  });

  // Construtor antigo (mantido para compatibilidade, se necessário em outros lugares)
  factory ItemModel.fromMap(Map<String, dynamic> map, CategoryModel category) {
    return ItemModel(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'],
      isChecked: map['isChecked'] == 1,
      notes: map['notes'],
      completionDate: map['completionDate'] != null ? DateTime.parse(map['completionDate']) : null,
      category: category,
      shoppingListId: map['shoppingListId'],
    );
  }

  // <<< NOVO CONSTRUTOR: Para ser usado com a consulta JOIN >>>
  factory ItemModel.fromJoinedMap(Map<String, dynamic> map) {
    final category = CategoryModel(
      id: map['categoryId'],
      name: map['categoryName'],
      icon: IconData(map['categoryIconCodePoint'], fontFamily: 'MaterialIcons'),
      colorValue: Color(map['categoryColorValue'] ?? Colors.grey.value),
    );
    return ItemModel.fromMap(map, category);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'isChecked': isChecked ? 1 : 0,
      'notes': notes,
      'completionDate': completionDate?.toIso8601String(),
      'categoryId': category.id,
      'shoppingListId': shoppingListId,
    };
  }
}