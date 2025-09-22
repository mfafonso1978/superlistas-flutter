// lib/core/ui/widgets/app_background.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/core/ui/theme/app_backgrounds.dart';
import 'package:superlistas/presentation/providers/providers.dart';

class AppBackground extends ConsumerWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Ouve o provider para obter a chave do plano de fundo selecionado
    final selectedKey = ref.watch(backgroundProvider);

    // 2. Encontra o objeto BackgroundTheme correspondente
    final background = availableBackgrounds.firstWhere(
          (b) => b.key == selectedKey,
      orElse: () => availableBackgrounds.first, // Medida de segurança
    );

    // 3. Escolhe a imagem correta com base no tema
    final String imagePath =
    isDark ? background.darkAssetPath : background.lightAssetPath;

    final double overlayOpacity = isDark ? 0.65 : 0.40;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        Positioned.fill(
          child: ColoredBox(
            color: Colors.black.withOpacity(overlayOpacity),
          ),
        ),
      ],
    );
  }
}