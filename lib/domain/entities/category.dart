// lib/domain/entities/category.dart
import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color colorValue; // <<< MUDANÇA: Novo campo de cor

  Category({
    required this.id,
    required this.name,
    this.icon = Icons.label_outline_rounded,
    this.colorValue = Colors.grey, // <<< MUDANÇA: Valor padrão adicionado
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Método copyWith para facilitar atualizações imutáveis
  Category copyWith({
    String? name,
    IconData? icon,
    Color? colorValue,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}