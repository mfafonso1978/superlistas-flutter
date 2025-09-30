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
import 'package:superlistas/presentation/views/premium/premium_screen.dart';
import 'package:superlistas/presentation/views/settings/background_selection_screen.dart';
import 'package:superlistas/presentation/views/units/units_screen.dart';

void _showPremiumUpsell(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const PremiumScreen()),
  );
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final remoteConfig = ref.watch(remoteConfigServiceProvider);
    final isPremium = remoteConfig.isUserPremium;
    final themeToggleEnabled = remoteConfig.isThemeToggleEnabled;
    final backgroundSelectEnabled = remoteConfig.isBackgroundSelectEnabled;
    final unitsScreenEnabled = remoteConfig.isUnitsScreenEnabled;
    final importExportEnabled = remoteConfig.isImportExportEnabled;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('Configurações')),
      body: Stack(
        children: [
          AppBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (themeToggleEnabled || backgroundSelectEnabled) ...[
                  GlassCard(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (themeToggleEnabled)
                        SwitchListTile.adaptive(
                          secondary: Icon(Icons.dark_mode_rounded, color: scheme.secondary),
                          title: const Text('Tema escuro'),
                          subtitle: const Text('Alterne entre claro e escuro'),
                          value: themeMode == ThemeMode.dark,
                          onChanged: (v) {
                            ref.read(themeModeProvider.notifier).setMode(v ? ThemeMode.dark : ThemeMode.light);
                          },
                        ),
                      if (themeToggleEnabled && backgroundSelectEnabled) const Divider(height: 1, indent: 16, endIndent: 16),
                      if (backgroundSelectEnabled)
                        ListTile(
                          leading: Icon(isPremium ? Icons.image_outlined : Icons.lock_outline, color: scheme.secondary),
                          title: const Text('Gerenciar plano de fundo'),
                          subtitle: const Text('Escolha a imagem principal do app'),
                          onTap: () {
                            if (isPremium) {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BackgroundSelectionScreen()));
                            } else {
                              _showPremiumUpsell(context);
                            }
                          },
                        ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                ],
                if (unitsScreenEnabled || importExportEnabled) ...[
                  GlassCard(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (unitsScreenEnabled)
                        ListTile(
                          leading: Icon(isPremium ? Icons.straighten_rounded : Icons.lock_outline, color: scheme.secondary),
                          title: const Text('Gerenciar Unidades'),
                          subtitle: const Text('Adicione ou remova unidades de medida'),
                          onTap: () {
                            if (isPremium) {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UnitsScreen()));
                            } else {
                              _showPremiumUpsell(context);
                            }
                          },
                        ),
                      if (unitsScreenEnabled && importExportEnabled) const Divider(height: 1, indent: 16, endIndent: 16),
                      if (importExportEnabled) ...[
                        ListTile(
                          leading: Icon(Icons.file_upload_rounded, color: scheme.secondary),
                          title: const Text('Exportar dados (Backup)'),
                          subtitle: const Text('Salva todas as suas listas e itens em um arquivo'),
                          onTap: () => _exportarDados(context, ref),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          leading: Icon(Icons.file_download_rounded, color: scheme.secondary),
                          title: const Text('Importar dados (Restaurar)'),
                          subtitle: const Text('Substitui os dados atuais a partir de um arquivo'),
                          onTap: () => _importarDados(context, ref),
                        ),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 12),
                ],
                GlassCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.cloud_upload_rounded, color: scheme.secondary),
                        title: const Text('Sincronização Inicial'),
                        subtitle: const Text('Envie seus dados locais para a nuvem'),
                        onTap: () => _sincronizacaoInicial(context, ref),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: Icon(Icons.delete_forever, color: scheme.error),
                        title: Text('Apagar Todos os Dados', style: TextStyle(color: scheme.error)),
                        subtitle: const Text('Remove todas as listas e itens permanentemente.'),
                        onTap: () => _apagarTodosOsDados(context, ref),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _apagarTodosOsDados(BuildContext context, WidgetRef ref) async {
    final scheme = Theme.of(context).colorScheme;

    final bool? confirm = await showGlassDialog<bool>(
      context: context,
      maxHeightFraction: 0.55,
      title: Row(children: [
        Icon(Icons.warning_amber_rounded, color: scheme.error),
        const SizedBox(width: 12),
        const Expanded(child: Text('AÇÃO IRREVERSÍVEL')),
      ]),
      content: const Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Você tem certeza absoluta que deseja apagar TODOS os seus dados?', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        Text('Esta ação removerá:'),
        Text('- Todas as suas listas de compras ativas.'),
        Text('- Todo o seu histórico.'),
        SizedBox(height: 8),
        Text('Os dados não poderão ser recuperados.'),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sim, Apagar Tudo'),
        ),
      ],
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Processando..."),
            ]),
          ),
        ),
      ),
    );

    try {
      await ref.read(settingsViewModelProvider.notifier).deleteAllUserData();

      // CORREÇÃO APLICADA AQUI: Verifica se o widget ainda está montado antes de usar o context.
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Fecha o diálogo "Processando"
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Todos os dados foram apagados com sucesso.')));

      final currentUser = ref.read(authViewModelProvider);
      if (currentUser != null) {
        ref.invalidate(shoppingListsStreamProvider(currentUser.id));
        ref.invalidate(historyViewModelProvider(currentUser.id));
        ref.invalidate(dashboardViewModelProvider(currentUser.id));
        ref.invalidate(statsViewModelProvider(currentUser.id));
      }

    } catch (e) {
      // CORREÇÃO APLICADA AQUI: Verifica também no bloco de erro.
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Fecha o diálogo "Processando"
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ocorreu um erro: $e')));
    }
  }

  Future<void> _sincronizacaoInicial(BuildContext context, WidgetRef ref) async {
    final bool? confirm = await showGlassDialog<bool>(
      context: context,
      title: const Text('Confirmar Sincronização'),
      content: const Text('Isso enviará todos os seus dados locais para a nuvem. Esta ação sobrescreverá quaisquer dados existentes na nuvem. Continuar?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sim, Sincronizar')),
      ],
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Sincronizando..."),
            ]),
          ),
        ),
      ),
    );

    try {
      await ref.read(settingsViewModelProvider.notifier).performInitialCloudSync();

      // CORREÇÃO APLICADA AQUI:
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sincronização concluída com sucesso!')));
    } catch (e) {
      // CORREÇÃO APLICADA AQUI:
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha na sincronização: $e')));
    }
  }


  Future<void> _exportarDados(BuildContext context, WidgetRef ref) async {
    final currentUser = ref.read(authViewModelProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Você precisa estar logado para exportar.')));
      return;
    }
    try {
      final jsonString = await ref.read(shoppingListRepositoryProvider).exportDataToJson(currentUser.id);

      // CORREÇÃO APLICADA AQUI:
      if (!context.mounted) return;
      final now = DateTime.now();
      final backupName = 'superlistas_backup_${DateFormat('yyyyMMdd_HHmmss').format(now)}.json';
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$backupName';
      final file = File(filePath);
      await file.writeAsString(jsonString);
      final xfile = XFile(filePath, name: backupName, mimeType: 'application/json');
      await Share.shareXFiles([xfile], subject: 'Backup Superlistas', text: 'Anexo está o seu backup de dados do Superlistas de $now.');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao exportar: $e')));
    }
  }

  Future<void> _importarDados(BuildContext context, WidgetRef ref) async {
    final currentUser = ref.read(authViewModelProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Você precisa estar logado para importar.')));
      return;
    }
    try {
      const group = XTypeGroup(label: 'JSON', extensions: ['json']);
      final XFile? selected = await openFile(acceptedTypeGroups: const [group]);
      if (selected == null) return;

      // CORREÇÃO APLICADA AQUI:
      if (!context.mounted) return;
      final bool? confirm = await showGlassDialog<bool>(
        context: context,
        title: const Text('Atenção!'),
        content: const Text('Importar um arquivo substituirá TODAS as suas listas e itens atuais. Esta ação não pode ser desfeita. Deseja continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Flexible(
              child: Text(
                'Sim, substituir',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
      if (confirm != true) return;
      final content = await selected.readAsString();
      await ref.read(shoppingListRepositoryProvider).importDataFromJson(currentUser.id, content);

      // CORREÇÃO APLICADA AQUI:
      if (!context.mounted) return;
      ref.invalidate(shoppingListsViewModelProvider(currentUser.id));
      ref.invalidate(historyViewModelProvider(currentUser.id));
      ref.invalidate(dashboardViewModelProvider(currentUser.id));
      ref.invalidate(statsViewModelProvider(currentUser.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dados importados com sucesso de ${selected.name}')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao importar: $e')));
    }
  }
}