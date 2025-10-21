// lib/data/models/user_product_model.dart
import 'package:superlistas/domain/entities/user_product.dart';

class UserProductModel extends UserProduct {
  UserProductModel({
    required super.id,
    required super.userId,
    required super.barcode,
    required super.productName,
    super.price,
    super.unit,
    super.categoryId,
    super.notes,
    required super.createdAt,
  });

  factory UserProductModel.fromEntity(UserProduct entity) {
    return UserProductModel(
      id: entity.id,
      userId: entity.userId,
      barcode: entity.barcode,
      productName: entity.productName,
      price: entity.price,
      unit: entity.unit,
      categoryId: entity.categoryId,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }

  factory UserProductModel.fromMap(Map<String, dynamic> map) {
    return UserProductModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      barcode: map['barcode'] as String,
      productName: map['productName'] as String,
      price: (map['lastPrice'] as num?)?.toDouble(),      // ← seguro
      unit: map['preferredUnit'] as String?,
      categoryId: map['categoryId'] as String?,
      notes: map['notes'] as String?,                      // pode vir null (sem coluna)
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'barcode': barcode,
      'productName': productName,
      'lastPrice': price,
      'preferredUnit': unit,
      'categoryId': categoryId,
      'createdAt': createdAt.toIso8601String(),
      // notes não é persistido por não existir coluna
    };
  }
}
