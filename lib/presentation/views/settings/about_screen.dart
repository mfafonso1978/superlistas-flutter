// lib/presentation/views/settings/about_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/core/ui/widgets/app_background.dart';
import 'package:superlistas/core/ui/widgets/glass_dialog.dart';
import 'package:superlistas/core/ui/widgets/shared_widgets.dart';
import 'package:superlistas/presentation/providers/providers.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  // Função helper para abrir URLs
  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Mostra um erro se não conseguir abrir a URL
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir o link: $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfoAsync = ref.watch(packageInfoProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Defina suas URLs aqui
    const String urlDocumentacao = 'https://github.com/mfafonso1978/superlistas-flutter/wiki'; // Wiki do GitHub
    const String urlLimitacoes = 'https://github.com/mfafonso1978/superlistas-flutter/wiki/Planos%E2%80%90e%E2%80%90Limitacoes'; //Página na Wiki
    const String urlPoliticaPrivacidade = 'https://github.com/mfafonso1978/superlistas-flutter/blob/main/PRIVACY_POLICY.md'; // Política de privacidade

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        title: Text('Sobre o Superlistas'),
      ),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Card da Versão
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Image.asset('assets/launcher_icon/icon.png', height: 60), // Use o ícone do app
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Superlistas',
                                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              packageInfoAsync.when(
                                data: (info) => Text(
                                  'Versão ${info.version} (Build ${info.buildNumber})',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                                ),
                                loading: () => Text(
                                  'Carregando versão...',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                                ),
                                error: (e, s) => Text(
                                  'Versão indisponível',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '© 2025 Superlistas',
                                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant.withOpacity(0.7)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Card de Links Úteis
                GlassCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.menu_book_rounded, color: scheme.secondary),
                        title: const Text('Como Usar (Documentação)'),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () => _launchUrl(context, urlDocumentacao),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: Icon(Icons.compare_arrows_rounded, color: scheme.secondary),
                        title: const Text('Limites Gratuito vs. Premium'),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () => _launchUrl(context, urlLimitacoes),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: Icon(Icons.privacy_tip_outlined, color: scheme.secondary),
                        title: const Text('Política de Privacidade'),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () => _launchUrl(context, urlPoliticaPrivacidade),
                      ),
                    ],
                  ),
                ),

                // Você pode adicionar mais seções aqui (Ex: Agradecimentos, Licenças de Código Aberto)
              ],
            ),
          ),
        ],
      ),
    );
  }
}