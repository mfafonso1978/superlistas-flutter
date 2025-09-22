// lib/data/models/category_model.dart
import 'package:superlistas/domain/entities/category.dart';
import 'package:flutter/material.dart';

class CategoryModel extends Category {
  CategoryModel({
    required String id,
    required String name,
    required IconData icon,
    required Color colorValue,
  }) : super(
    id: id,
    name: name,
    icon: icon,
    colorValue: colorValue,
  );

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      icon: IconData(map['iconCodePoint'], fontFamily: 'MaterialIcons'),
      colorValue: Color(map['colorValue'] ?? Colors.grey.value),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'colorValue': colorValue.value,
    };
  }
}