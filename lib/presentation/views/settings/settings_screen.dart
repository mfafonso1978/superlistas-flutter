// lib/presentation/views/settings/settings_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:superlistas/core/ui/widgets/app_background.dart';
import 'package:superlistas/core/ui/widgets/glass_dialog.dart';
import 'package:superlistas/core/ui/widgets/shared_widgets.dart';
import 'package:superlistas/presentation/providers/providers.dart';
import 'package:superlistas/presentation/views/settings/background_selection_screen.dart';
import 'package:superlistas/presentation/views/units/units_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);

    // Lendo todas as flags relevantes para esta tela
    final remoteConfig = ref.watch(remoteConfigServiceProvider);
    final themeToggleEnabled = remoteConfig.isThemeToggleEnabled;
    final backgroundSelectEnabled = remoteConfig.isBackgroundSelectEnabled;
    final unitsScreenEnabled = remoteConfig.isUnitsScreenEnabled;
    final importExportEnabled = remoteConfig.isImportExportEnabled;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        title: Text('Configurações'),
      ),
      body: Stack(
        children: [
          AppBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Card de Aparência (só aparece se uma de suas opções estiver habilitada)
                if (themeToggleEnabled || backgroundSelectEnabled) ...[
                  GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (themeToggleEnabled)
                          SwitchListTile.adaptive(
                            secondary: Icon(Icons.dark_mode_rounded, color: scheme.secondary),
                            title: const Text('Tema escuro'),
                            subtitle: const Text('Alterne entre claro e escuro'),
                            value: themeMode == ThemeMode.dark,
                            onChanged: (v) {
                              ref.read(themeModeProvider.notifier).setMode(
                                v ? ThemeMode.dark : ThemeMode.light,
                              );
                            },
                          ),
                        if (themeToggleEnabled && backgroundSelectEnabled)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                        if (backgroundSelectEnabled)
                          ListTile(
                            leading: Icon(Icons.image_outlined, color: scheme.secondary),
                            title: const Text('Gerenciar plano de fundo'),
                            subtitle: const Text('Escolha a imagem principal do app'),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const BackgroundSelectionScreen()),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Card de Dados (só aparece se uma de suas opções estiver habilitada)
                if (unitsScreenEnabled || importExportEnabled) ...[
                  GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (unitsScreenEnabled)
                          ListTile(
                            leading: Icon(Icons.straighten_rounded, color: scheme.secondary),
                            title: const Text('Gerenciar Unidades'),
                            subtitle: const Text('Adicione ou remova unidades de medida'),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const UnitsScreen()),
                              );
                            },
                          ),
                        if (unitsScreenEnabled && importExportEnabled)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                        if (importExportEnabled) ...[
                          ListTile(
                            leading: Icon(Icons.file_upload_rounded,
                                color: scheme.secondary),
                            title: const Text('Exportar dados (Backup)'),
                            subtitle: const Text(
                                'Salva todas as suas listas e itens em um arquivo'),
                            onTap: () => _exportarDados(context, ref),
                          ),
                          const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                          ListTile(
                            leading: Icon(Icons.file_download_rounded,
                                color: scheme.secondary),
                            title: const Text('Importar dados (Restaurar)'),
                            subtitle: const Text(
                                'Substitui os dados atuais a partir de um arquivo'),
                            onTap: () => _importarDados(context, ref),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportarDados(BuildContext context, WidgetRef ref) async {
    final currentUser = ref.read(authViewModelProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para exportar.')),
      );
      return;
    }

    try {
      final jsonString = await ref.read(shoppingListRepositoryProvider).exportDataToJson(currentUser.id);

      final now = DateTime.now();
      final backupName =
          'superlistas_backup_${DateFormat('yyyyMMdd_HHmmss').format(now)}.json';

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$backupName';
      final file = File(filePath);

      await file.writeAsString(jsonString);

      final xfile = XFile(filePath, name: backupName, mimeType: 'application/json');

      await Share.shareXFiles(
        [xfile],
        subject: 'Backup Superlistas',
        text: 'Anexo está o seu backup de dados do Superlistas de $now.',
      );

    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao exportar: $e')),
      );
    }
  }

  Future<void> _importarDados(BuildContext context, WidgetRef ref) async {
    final currentUser = ref.read(authViewModelProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa estar logado para importar.')),
      );
      return;
    }

    try {
      const group = XTypeGroup(label: 'JSON', extensions: ['json']);
      final XFile? selected =
      await openFile(acceptedTypeGroups: const [group]);
      if (selected == null) return;

      final bool? confirm = await showGlassDialog<bool>(
        context: context,
        title: const Text('Atenção!'),
        content: const Text(
            'Importar um arquivo substituirá TODAS as suas listas e itens atuais. Esta ação não pode ser desfeita. Deseja continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim, substituir'),
          ),
        ],
      );

      if (confirm != true) return;

      final content = await selected.readAsString();

      await ref.read(shoppingListRepositoryProvider).importDataFromJson(currentUser.id, content);

      ref.invalidate(shoppingListsViewModelProvider(currentUser.id));
      ref.invalidate(historyViewModelProvider(currentUser.id));
      ref.invalidate(dashboardViewModelProvider(currentUser.id));
      ref.invalidate(statsViewModelProvider(currentUser.id));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dados importados com sucesso de ${selected.name}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao importar: $e')),
      );
    }
  }
}