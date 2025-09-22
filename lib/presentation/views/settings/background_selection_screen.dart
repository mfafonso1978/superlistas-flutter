// lib/presentation/views/settings/background_selection_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/core/ui/theme/app_backgrounds.dart';
import 'package:superlistas/core/ui/widgets/app_background.dart';
import 'package:superlistas/core/ui/widgets/shared_widgets.dart';
import 'package:superlistas/presentation/providers/providers.dart';

class BackgroundSelectionScreen extends ConsumerWidget {
  const BackgroundSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentKey = ref.watch(backgroundProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        title: Text('Plano de Fundo'),
      ),
      body: Stack(
        children: [
          AppBackground(),
          SafeArea(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: availableBackgrounds.length,
              itemBuilder: (context, index) {
                final background = availableBackgrounds[index];
                return _BackgroundPreviewCard(
                  background: background,
                  isSelected: background.key == currentKey,
                  onTap: () {
                    ref
                        .read(backgroundProvider.notifier)
                        .setBackground(background.key);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundPreviewCard extends StatelessWidget {
  final BackgroundTheme background;
  final bool isSelected;
  final VoidCallback onTap;

  const _BackgroundPreviewCard({
    required this.background,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // <<< CORREÇÃO APLICADA AQUI >>>
    // Escolhe qual imagem de preview mostrar com base no tema atual do app.
    final String previewImagePath =
    isDark ? background.darkAssetPath : background.lightAssetPath;

    return GlassCard(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Preview de uma única imagem, ocupando todo o espaço.
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    // <<< MUDANÇA PRINCIPAL: Em vez de uma Row, agora temos uma única Imagem >>>
                    child: Image.asset(
                      previewImagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Indicador de seleção
                  if (isSelected)
                    Container(
                      decoration: BoxDecoration(
                        color: scheme.secondary.withOpacity(0.3),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        border: Border.all(color: scheme.secondary, width: 3),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 48,
                          shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Legenda
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                background.displayName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}