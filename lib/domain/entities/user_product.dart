// lib/domain/entities/user_product.dart

import 'package:equatable/equatable.dart';

class UserProduct extends Equatable {
  // <<< CORREÇÃO APLICADA AQUI >>>
  final String id;
  final String userId;
  final String barcode;
  final String productName;
  final double? price;
  final String? unit;
  final String? categoryId;
  final String? notes;
  final DateTime createdAt;

  const UserProduct({
    required this.id,
    required this.userId,
    required this.barcode,
    required this.productName,
    this.price,
    this.unit,
    this.categoryId,
    this.notes,
    required this.createdAt,
  });

  @override
  // <<< CORREÇÃO APLICADA AQUI >>>
  List<Object?> get props => [id, userId, barcode, productName, price, unit, categoryId, notes, createdAt];
}