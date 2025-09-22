// lib/presentation/viewmodels/background_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:superlistas/core/ui/theme/app_backgrounds.dart';

const _kBackgroundKey = 'backgroundKey';

class BackgroundNotifier extends StateNotifier<String> {
  // O estado inicial é a chave do primeiro plano de fundo da nossa lista
  BackgroundNotifier() : super(availableBackgrounds.first.key) {
    _load();
  }

  SharedPreferences? _prefs;

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    // Carrega a chave salva, ou usa o padrão se não houver nada
    final savedKey = _prefs!.getString(_kBackgroundKey) ?? state;

    // Garante que a chave carregada ainda é válida
    if (availableBackgrounds.any((b) => b.key == savedKey)) {
      state = savedKey;
    }
  }

  void setBackground(String key) {
    // Verifica se a chave é válida antes de atualizar
    if (availableBackgrounds.any((b) => b.key == key)) {
      state = key;
      _prefs?.setString(_kBackgroundKey, key);
    }
  }
}