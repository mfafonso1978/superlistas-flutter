import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  // AJUSTE: O estado inicial agora é 'light'.
  ThemeModeNotifier() : super(ThemeMode.light) {
    _load();
  }

  SharedPreferences? _prefs;

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs!.getString('themeMode');
    if (saved != null) {
      try {
        state = ThemeMode.values.firstWhere((m) => m.name == saved);
      } catch (_) {}
    }
  }

  void setMode(ThemeMode mode) {
    state = mode;
    _prefs?.setString('themeMode', mode.name);
  }

  void toggle() {
    setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}