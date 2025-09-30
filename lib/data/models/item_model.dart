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

  // Construtor antigo (mantido para compatibilidade com o SQLite)
  factory ItemModel.fromMap(Map<String, dynamic> map, CategoryModel category) {
    return ItemModel(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'],
      isChecked: map['isChecked'] == 1, // SQLite usa 1/0 para booleano
      notes: map['notes'],
      completionDate: map['completionDate'] != null ? DateTime.parse(map['completionDate']) : null,
      category: category,
      shoppingListId: map['shoppingListId'],
    );
  }

  // Construtor para ser usado com a consulta JOIN do SQLite e também com os dados do Firestore.
  // Ele já funciona perfeitamente para o Firestore porque espera os campos da categoria no mapa.
  factory ItemModel.fromJoinedMap(Map<String, dynamic> map) {
    final category = CategoryModel(
      id: map['categoryId'],
      name: map['categoryName'],
      icon: IconData(map['categoryIconCodePoint'], fontFamily: 'MaterialIcons'),
      colorValue: Color(map['categoryColorValue'] ?? Colors.grey.value),
    );

    return ItemModel(
      id: map['id'],
      name: map['name'],
      price: map['price']?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: map['unit'] ?? 'un',
      // <<< MUDANÇA: Firestore salva booleano como true/false, não 1/0 >>>
      isChecked: map['isChecked'] is bool ? map['isChecked'] : map['isChecked'] == 1,
      notes: map['notes'],
      completionDate: map['completionDate'] != null ? DateTime.parse(map['completionDate']) : null,
      category: category,
      shoppingListId: map['shoppingListId'],
    );
  }

  // toMap para o banco de dados local (SQLite) - NÃO ALTERAR
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'isChecked': isChecked ? 1 : 0, // Salva como 1 ou 0
      'notes': notes,
      'completionDate': completionDate?.toIso8601String(),
      'categoryId': category.id, // Salva apenas a referência
      'shoppingListId': shoppingListId,
    };
  }

  // <<< NOVO MÉTODO: toMap específico para o Firestore >>>
  // Este método inclui os dados denormalizados da categoria.
  Map<String, dynamic> toMapForFirestore() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'isChecked': isChecked, // Salva como true ou false
      'notes': notes,
      'completionDate': completionDate?.toIso8601String(),
      'shoppingListId': shoppingListId,
      // Denormalização: Salvamos os dados da categoria junto com o item
      // para evitar múltiplas leituras ao carregar uma lista.
      'categoryId': category.id,
      'categoryName': category.name,
      'categoryIconCodePoint': category.icon.codePoint,
      'categoryColorValue': category.colorValue.value,
    };
  }
}