// lib/presentation/viewmodels/settings_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/domain/repositories/shopping_list_repository.dart';

class SettingsViewModel extends StateNotifier<AsyncValue<void>> {
  final ShoppingListRepository _repository;
  final String _userId;

  SettingsViewModel(this._repository, this._userId) : super(const AsyncValue.data(null));

  Future<void> performInitialCloudSync() async {
    state = const AsyncValue.loading();
    try {
      await _repository.performInitialCloudSync(_userId);

      // CORREÇÃO APLICADA AQUI: Verifica se o ViewModel ainda está "montado".
      if (!mounted) return;

      state = const AsyncValue.data(null);
    } catch (e, s) {
      // CORREÇÃO APLICADA AQUI:
      if (!mounted) return;
      state = AsyncValue.error(e, s);
      rethrow; // Propaga o erro para a UI poder capturá-lo.
    }
  }

  Future<void> deleteAllUserData() async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteAllUserData(_userId);

      // CORREÇÃO APLICADA AQUI: Verifica se o ViewModel ainda está "montado".
      if (!mounted) return;

      state = const AsyncValue.data(null);
    } catch (e, s) {
      // CORREÇÃO APLICADA AQUI:
      if (!mounted) return;
      state = AsyncValue.error(e, s);
      rethrow; // Propaga o erro para a UI poder capturá-lo.
    }
  }
}