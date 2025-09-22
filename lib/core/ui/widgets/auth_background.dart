// lib/core/ui/widgets/auth_background.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/core/ui/theme/app_backgrounds.dart';
import 'package:superlistas/presentation/providers/providers.dart';

class AuthBackground extends ConsumerWidget {
  const AuthBackground({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedKey = ref.watch(backgroundProvider);
    final background = availableBackgrounds.firstWhere(
          (b) => b.key == selectedKey,
      orElse: () => availableBackgrounds.first,
    );
    final String imagePath =
    isDark ? background.darkAssetPath : background.lightAssetPath;

    final double overlayOpacity = isDark ? 0.60 : 0.30;

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