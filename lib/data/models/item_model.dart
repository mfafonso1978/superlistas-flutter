// lib/data/models/item_model.dart
import 'package:superlistas/domain/entities/item.dart';
import 'package:superlistas/data/models/category_model.dart';
import 'package:flutter/material.dart';

class ItemModel extends Item {
  final String shoppingListId;

  const ItemModel({
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
    super.barcode,
  });

  /// Conversor seguro do domínio -> model (sem casts)
  factory ItemModel.fromEntity(Item e, {required String shoppingListId}) {
    return ItemModel(
      id: e.id,
      name: e.name,
      category: CategoryModel.fromEntity(e.category),
      shoppingListId: shoppingListId,
      price: e.price,
      quantity: e.quantity,
      unit: e.unit,
      isChecked: e.isChecked,
      notes: e.notes,
      completionDate: e.completionDate,
      barcode: e.barcode,
    );
  }

  factory ItemModel.fromMap(Map<String, dynamic> map, CategoryModel category) {
    return ItemModel(
      id: map['id'],
      name: map['name'],
      price: (map['price'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'],
      isChecked: map['isChecked'] == 1,
      notes: map['notes'],
      completionDate: map['completionDate'] != null
          ? DateTime.parse(map['completionDate'])
          : null,
      category: category,
      shoppingListId: map['shoppingListId'],
      barcode: map['barcode'],
    );
  }

  // <<< CORREÇÃO APLICADA AQUI >>>
  /// Usado quando vem do JOIN com a tabela de categorias (local) ou do Firestore.
  factory ItemModel.fromJoinedMap(Map<String, dynamic> map) {
    // A verificação agora procura pelo ID da categoria e pelo nome,
    // que são os campos que garantem a existência de uma categoria.
    final categoryDataExists = map['categoryId'] != null &&
        (map['categoryName'] != null || map['category_name'] != null);

    final category = categoryDataExists
        ? CategoryModel.fromMap({
      // Usa o ID da categoria que vem no próprio item
      'id': map['categoryId'],
      // Usa 'categoryName' (padrão do Firestore) ou 'category_name' (padrão do SQLite)
      'name': map['categoryName'] ?? map['category_name'],
      'iconCodePoint': map['categoryIconCodePoint'] ?? map['category_iconCodePoint'],
      'colorValue': map['categoryColorValue'] ?? map['category_colorValue'],
    })
        : CategoryModel.uncategorized();

    return ItemModel(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: map['unit'] as String? ?? 'un',
      isChecked: map['isChecked'] is bool
          ? map['isChecked'] as bool
          : (map['isChecked'] as int?) == 1,
      notes: map['notes'] as String?,
      completionDate: map['completionDate'] != null
          ? DateTime.parse(map['completionDate'] as String)
          : null,
      category: category, // Usa a categoria corrigida
      shoppingListId: map['shoppingListId'] as String,
      barcode: map['barcode'] as String?,
    );
  }

  /// Mapa para o **SQLite local** (mantém a coluna `categoryId`!)
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
      'barcode': barcode,
    };
  }

  /// Mapa para **Firestore** / fila de sync
  Map<String, dynamic> toMapForFirestore() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'isChecked': isChecked,
      'notes': notes,
      'completionDate': completionDate?.toIso8601String(),
      'shoppingListId': shoppingListId,
      'categoryId': category.id,
      'categoryName': category.name,
      'categoryIconCodePoint': category.icon.codePoint,
      'categoryColorValue': category.colorValue.value,
      'barcode': barcode,
    };
  }
}