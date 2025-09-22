// lib/presentation/viewmodels/categories_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/domain/entities/category.dart';
import 'package:superlistas/domain/repositories/shopping_list_repository.dart';
import 'package:uuid/uuid.dart';

class CategoriesViewModel extends StateNotifier<AsyncValue<List<Category>>> {
  final ShoppingListRepository _repository;

  CategoriesViewModel(this._repository) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  // <<< MUDANÇA: Lista de cores base movida para cá >>>
  static const List<Color> _baseColors = [
    Color(0xFF2196F3), Color(0xFF4CAF50), Color(0xFFFF9800), Color(0xFF9C27B0),
    Color(0xFFF44336), Color(0xFF00BCD4), Color(0xFF795548), Color(0xFF607D8B),
    Color(0xFFE91E63), Color(0xFF8BC34A), Color(0xFFFF5722), Color(0xFF673AB7),
    Color(0xFF009688), Color(0xFF3F51B5), Colors.red, Colors.green, Colors.blue,
    Colors.orange, Colors.purple, Colors.brown, Colors.pink, Colors.cyan,
  ];

  Future<void> loadCategories() async {
    try {
      state = const AsyncValue.loading();
      final categories = await _repository.getCategories();
      categories.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      state = AsyncValue.data(categories);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> addCategory(String name, IconData icon) async {
    final currentState = state;
    if (!currentState.hasValue) return;

    try {
      // <<< MUDANÇA: Lógica para escolher uma cor única >>>
      final existingColors = currentState.value!.map((c) => c.colorValue.value).toSet();
      Color newColor = _baseColors.firstWhere(
            (color) => !existingColors.contains(color.value),
        orElse: () => _getUniqueColorForPreview(name), // Fallback se todas as cores base estiverem em uso
      );

      final newCategory = Category(
        id: const Uuid().v4(),
        name: name,
        icon: icon,
        colorValue: newColor, // Atribui a nova cor
      );
      await _repository.createCategory(newCategory);
      await loadCategories();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> updateCategory(String id, String name, IconData icon) async {
    final currentState = state;
    if (!currentState.hasValue) return;

    // Mantém a cor original ao editar, a menos que seja alterada explicitamente
    final originalCategory = currentState.value!.firstWhere((c) => c.id == id, orElse: () => Category(id: '', name: '', colorValue: Colors.grey));

    try {
      final updatedCategory = Category(
        id: id,
        name: name,
        icon: icon,
        colorValue: originalCategory.colorValue, // Preserva a cor existente
      );
      await _repository.updateCategory(updatedCategory);
      await loadCategories();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _repository.deleteCategory(id);
      await loadCategories();
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  // Lógica de fallback para gerar cor a partir do nome
  Color _getUniqueColorForPreview(String categoryName) {
    final hash = categoryName.hashCode;
    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = hash & 0x0000FF;
    return Color.fromARGB(255, r, g, b);
  }
}