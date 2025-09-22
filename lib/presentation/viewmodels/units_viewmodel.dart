// lib/presentation/viewmodels/units_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/domain/repositories/shopping_list_repository.dart';

class UnitsViewModel extends StateNotifier<AsyncValue<List<String>>> {
  final ShoppingListRepository _repository;

  UnitsViewModel(this._repository) : super(const AsyncValue.loading()) {
    loadUnits();
  }

  Future<void> loadUnits() async {
    try {
      state = const AsyncValue.loading();
      final units = await _repository.getAllUnits();
      units.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      state = AsyncValue.data(units);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> addUnit(String name) async {
    final currentState = state;
    if (!currentState.hasValue || name.trim().isEmpty) return;

    final unitToAdd = name.trim();
    if (currentState.value!.any((u) => u.toLowerCase() == unitToAdd.toLowerCase())) {
      // Evita duplicatas
      return;
    }

    try {
      final currentUnits = List<String>.from(currentState.value!)..add(unitToAdd);
      currentUnits.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      state = AsyncValue.data(currentUnits);

      await _repository.addUnit(unitToAdd);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> deleteUnit(String name) async {
    final currentState = state;
    if (!currentState.hasValue) return;

    try {
      final currentUnits = currentState.value!.where((u) => u != name).toList();
      state = AsyncValue.data(currentUnits);

      await _repository.deleteUnit(name);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> updateUnit(String oldName, String newName) async {
    final currentState = state;
    if (!currentState.hasValue || newName.trim().isEmpty || oldName == newName) return;

    final unitToUpdate = newName.trim();
    if (currentState.value!.any((u) => u.toLowerCase() == unitToUpdate.toLowerCase())) {
      // Evita criar uma duplicata
      return;
    }

    try {
      final currentUnits = currentState.value!.map((u) => u == oldName ? unitToUpdate : u).toList();
      currentUnits.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      state = AsyncValue.data(currentUnits);

      await _repository.updateUnit(oldName, unitToUpdate);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}