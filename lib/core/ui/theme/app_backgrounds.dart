// lib/core/ui/theme/app_backgrounds.dart
import 'package:flutter/foundation.dart';

@immutable
class BackgroundTheme {
  final String key;
  final String displayName;
  final String lightAssetPath;
  final String darkAssetPath;

  const BackgroundTheme({
    required this.key,
    required this.displayName,
    required this.lightAssetPath,
    required this.darkAssetPath,
  });
}

const List<BackgroundTheme> availableBackgrounds = [
  BackgroundTheme(
    key: 'default',
    displayName: 'Padrão',
    lightAssetPath: 'assets/images/bg_home.jpg',
    darkAssetPath: 'assets/images/bg_home_black.jpg',
  ),
  BackgroundTheme(
    key: 'mountains',
    displayName: 'Montanhas',
    lightAssetPath: 'assets/images/bg_mountains_light.jpg',
    darkAssetPath: 'assets/images/bg_mountains_dark.jpg',
  ),
  BackgroundTheme(
    key: 'abstract',
    displayName: 'Abstrato',
    lightAssetPath: 'assets/images/bg_abstract_light.jpg',
    darkAssetPath: 'assets/images/bg_abstract_dark.jpg',
  ),
];