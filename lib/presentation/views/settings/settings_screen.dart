// lib/presentation/views/settings/settings_screen.dart
import 'dart:convert'; // <<< IMPORT ADICIONADO >>>
import 'dart:io';
import 'dart:typed_data'; // <<< IMPORT ADICIONADO >>>
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
import 'package:superlistas/presentation/views/settings/about_screen.dart';
import 'package:url_launcher/url_launcher.dart';

// Função _showPremiumUpsell (sem alteração)
void _showPremiumUpsell(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const PremiumScreen()),
  );
}

// Classe SettingsScreen (sem alteração)
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

    final isPasswordUser = ref.read(authViewModelProvider.notifier).isPasswordProvider();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: Text('Configurações')),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Card Aparência
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
                  const SizedBox(height: 16),
                ],

                // Card Conta
                GlassCard(
                  child: Column(
                    children: [
                      if(isPasswordUser) ...[
                        ListTile(
                          leading: Icon(Icons.lock_reset_rounded, color: scheme.secondary),
                          title: const Text('Alterar senha'),
                          subtitle: const Text('Envia um link de recuperação para seu e-mail'),
                          onTap: () => _resetPassword(context, ref),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                      ],
                      ListTile(
                        leading: Icon(Icons.no_accounts_rounded, color: scheme.error),
                        title: Text('Excluir minha conta', style: TextStyle(color: scheme.error)),
                        subtitle: const Text('Esta ação é permanente e irreversível'),
                        onTap: () => _deleteAccount(context, ref, isPasswordUser),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card Dados
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
                  const SizedBox(height: 16),
                ],

                // Card Sincronização e Apagar Dados
                GlassCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.cloud_sync_rounded, color: scheme.secondary),
                        title: const Text('Sincronização com a Nuvem'),
                        subtitle: const Text('Envie seus dados locais para a nuvem (sobrescreve)'),
                        onTap: () => _sincronizacaoInicial(context, ref),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: Icon(Icons.delete_sweep_rounded, color: scheme.error),
                        title: Text('Apagar Todos os Dados Locais', style: TextStyle(color: scheme.error)),
                        subtitle: const Text('Remove listas e itens do dispositivo'),
                        onTap: () => _apagarTodosOsDados(context, ref),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card "Sobre"
                GlassCard(
                  child: ListTile(
                    leading: Icon(Icons.info_outline_rounded, color: scheme.secondary),
                    title: const Text('Sobre o Aplicativo'),
                    subtitle: const Text('Versão, documentação e políticas'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} // Fim da classe SettingsScreen

// --- Funções Helper ---

Future<void> _resetPassword(BuildContext context, WidgetRef ref) async {
  final user = ref.read(authViewModelProvider);
  // <<< CORREÇÃO DE LINT APLICADA AQUI (`context.mounted` check) >>>
  // Guarda o ScaffoldMessenger ANTES do await
  final messenger = ScaffoldMessenger.of(context);

  if (user == null || user.email.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(backgroundColor: Colors.red, content: Text('Usuário não encontrado ou sem e-mail cadastrado.')),
    );
    return;
  }

  try {
    await ref.read(authViewModelProvider.notifier).sendPasswordResetEmail(user.email);
    // Verifica se o widget ainda está montado ANTES de usar o messenger
    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Link de recuperação enviado! Verifique seu e-mail (e a caixa de spam).')),
    );
  } catch (e) {
    // Verifica se o widget ainda está montado ANTES de usar o messenger
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(backgroundColor: Colors.red, content: Text('Erro: ${e.toString()}')),
    );
  }
}

Future<void> _deleteAccount(BuildContext context, WidgetRef ref, bool isPasswordUser) async {
  final scheme = Theme.of(context).colorScheme;
  // <<< CORREÇÃO DE LINT APLICADA AQUI (`context.mounted` checks) >>>
  // Guarda o ScaffoldMessenger e Navigator ANTES dos awaits
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context); // Usado para fechar diálogos

  if (!isPasswordUser) {
    // Não há await aqui, então o uso do context é seguro
    await showGlassDialog(
      context: context,
      title: const Text('Excluir Conta Google'),
      content: const Text('Para excluir uma conta conectada com o Google, por segurança, você precisa fazer logout e login novamente antes de prosseguir. Esta funcionalidade será aprimorada em breve.'),
      actions: [
        ElevatedButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(), child: const Text('Entendi')),
      ],
    );
    return;
  }

  final passwordController = TextEditingController();
  // Usa o context original para mostrar o diálogo
  final bool? confirm = await showGlassDialog<bool>(
    context: context,
    title: const Text('Excluir Conta'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Esta ação é permanente. Para confirmar, por favor, digite sua senha:'),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Senha'),
          onSubmitted: (_) {
            // Usa o navigator original (do context do diálogo) para fechar este diálogo específico
            if (passwordController.text.isNotEmpty) {
              Navigator.of(context, rootNavigator: true).pop(true);
            }
          },
        ),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.of(context, rootNavigator: true).pop(false), child: const Text('Cancelar')),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
        onPressed: () {
          // Usa o navigator original (do context do diálogo) para fechar este diálogo específico
          if (passwordController.text.isNotEmpty) {
            Navigator.of(context, rootNavigator: true).pop(true);
          }
        },
        child: const Text('Excluir Permanentemente'),
      ),
    ],
  );

  // Verifica montagem APÓS o primeiro await (showGlassDialog)
  if (!context.mounted || confirm != true || passwordController.text.isEmpty) {
    passwordController.dispose();
    return;
  }

  // Mostra diálogo de loading usando o context original (que ainda está montado)
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const Center(child: CircularProgressIndicator()),
  );

  try {
    await ref.read(authViewModelProvider.notifier).reauthenticateAndDeleteAccount(passwordController.text);

    // Verifica montagem APÓS o await da exclusão
    if (!navigator.canPop()) return; // Se não pode fechar o loading, algo deu errado
    navigator.pop(); // Fecha loading usando o navigator guardado

    // O messenger aqui também usa o context original, que foi verificado
    messenger.showSnackBar(
      const SnackBar(content: Text('Sua conta foi excluída com sucesso.')),
    );
    // Não precisa de mais checks de mounted aqui, pois o AuthWrapper cuidará da navegação

  } catch (e) {
    // Verifica montagem APÓS o await da exclusão (em caso de erro)
    if (!navigator.canPop()) return;
    navigator.pop(); // Fecha loading usando o navigator guardado

    // O messenger aqui também usa o context original, que foi verificado
    messenger.showSnackBar(
      SnackBar(backgroundColor: Colors.red, content: Text(e.toString())),
    );
  } finally {
    passwordController.dispose();
  }
}


Future<void> _apagarTodosOsDados(BuildContext context, WidgetRef ref) async {
  final scheme = Theme.of(context).colorScheme;
  // <<< CORREÇÃO DE LINT APLICADA AQUI (`context.mounted` checks) >>>
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context); // Usa rootNavigator para fechar diálogos sobrepostos

  final bool? confirm = await showGlassDialog<bool>(
    context: context, // Usa context original
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
      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')), // Fecha só o diálogo glass
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
        onPressed: () => Navigator.of(context).pop(true), // Fecha só o diálogo glass
        child: const Text('Sim, Apagar Tudo'),
      ),
    ],
  );

  // Verifica montagem APÓS o await do showGlassDialog
  if (!context.mounted || confirm != true) return;


  // Mostra diálogo de loading usando o context original
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
            Text("Apagando dados..."),
          ]),
        ),
      ),
    ),
  );

  try {
    final user = ref.read(authViewModelProvider);
    if (user != null) {
      await ref.read(shoppingListRepositoryProvider).deleteAllUserData(user.id);
    } else {
      throw Exception("Usuário não encontrado para apagar os dados.");
    }

    // Verifica montagem APÓS o await do deleteAllUserData
    if (!context.mounted) return;
    // Tenta fechar o diálogo de loading
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    messenger.showSnackBar(const SnackBar(content: Text('Todos os dados foram apagados com sucesso.')));

    // Invalida e refresha providers (sem usar context aqui)
    if (user != null) {
      ref.invalidate(shoppingListsStreamProvider(user.id));
      ref.invalidate(historyViewModelProvider(user.id));
      ref.invalidate(dashboardViewModelProvider(user.id));
      ref.invalidate(statsViewModelProvider(user.id));
      ref.refresh(shoppingListsViewModelProvider(user.id));
      ref.refresh(historyViewModelProvider(user.id));
      ref.refresh(dashboardViewModelProvider(user.id));
      ref.refresh(statsViewModelProvider(user.id));
    }

  } catch (e) {
    // Verifica montagem APÓS o await (em caso de erro)
    if (!context.mounted) return;
    // Tenta fechar o diálogo de loading
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    messenger.showSnackBar(SnackBar(content: Text('Ocorreu um erro ao apagar os dados: $e'), backgroundColor: Colors.red,));
  }
}


Future<void> _sincronizacaoInicial(BuildContext context, WidgetRef ref) async {
  // <<< CORREÇÃO DE LINT APLICADA AQUI (`context.mounted` checks) >>>
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context); // Usa rootNavigator

  final bool? confirm = await showGlassDialog<bool>(
    context: context, // Usa context original
    title: const Text('Confirmar Sincronização Inicial'),
    content: const Text('Isso enviará todos os seus dados locais para a nuvem. Esta ação sobrescreverá quaisquer dados existentes na nuvem para este usuário. Continuar?'),
    actions: [
      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')), // Fecha só o glass
      ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sim, Sincronizar')), // Fecha só o glass
    ],
  );

  // Verifica montagem APÓS o await do showGlassDialog
  if (!context.mounted || confirm != true) return;


  // Mostra diálogo de loading usando o context original
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
    final user = ref.read(authViewModelProvider);
    if (user != null) {
      await ref.read(shoppingListRepositoryProvider).performInitialCloudSync(user.id);
    } else {
      throw Exception("Usuário não encontrado para sincronizar.");
    }

    // Verifica montagem APÓS o await do sync
    if (!context.mounted) return;
    // Tenta fechar o diálogo de loading
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    messenger.showSnackBar(const SnackBar(content: Text('Sincronização inicial concluída com sucesso!')));
  } catch (e) {
    // Verifica montagem APÓS o await (em caso de erro)
    if (!context.mounted) return;
    // Tenta fechar o diálogo de loading
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    messenger.showSnackBar(SnackBar(content: Text('Falha na sincronização inicial: $e'), backgroundColor: Colors.red,));
  }
}


Future<void> _exportarDados(BuildContext context, WidgetRef ref) async {
  final currentUser = ref.read(authViewModelProvider);
  // <<< CORREÇÃO DE LINT APLICADA AQUI (`context.mounted` checks) >>>
  final messenger = ScaffoldMessenger.of(context);
  // Não precisamos guardar o navigator aqui ainda

  if (currentUser == null) {
    messenger.showSnackBar(const SnackBar(content: Text('Você precisa estar logado para exportar.')));
    return;
  }
  try {
    // Mostra indicador de progresso ANTES do await
    showDialog(
      context: context, // Usa context original
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Exportando dados..."),
            ]),
          ),
        ),
      ),
    );

    final jsonString = await ref.read(shoppingListRepositoryProvider).exportDataToJson(currentUser.id);

    // Verifica montagem APÓS o await da exportação
    if (!context.mounted) return;
    // Tenta fechar o diálogo de loading
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    // Continua com a lógica de salvar/compartilhar
    final now = DateTime.now();
    final backupName = 'superlistas_backup_${DateFormat('yyyyMMdd_HHmmss').format(now)}.json';

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final FileSaveLocation? result = await getSaveLocation(suggestedName: backupName);
      // Verifica montagem APÓS o await do getSaveLocation
      if (!context.mounted || result == null) return;

      final Uint8List fileData = utf8.encode(jsonString);
      final xFile = XFile.fromData(fileData, name: backupName, mimeType: 'application/json');
      await xFile.saveTo(result.path); // saveTo pode levar um tempo

      // Verifica montagem APÓS o await do saveTo
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Backup salvo em: ${result.path}')));

    } else if (Platform.isAndroid || Platform.isIOS) {
      final tempDir = await getTemporaryDirectory();
      // Verifica montagem APÓS o await do getTemporaryDirectory
      if (!context.mounted) return;

      final filePath = '${tempDir.path}/$backupName';
      final file = File(filePath);
      await file.writeAsString(jsonString); // Escrever pode levar um tempo

      // Verifica montagem APÓS o await do writeAsString
      if (!context.mounted) return;

      final xfile = XFile(filePath, name: backupName, mimeType: 'application/json');
      final shareResult = await Share.shareXFiles([xfile], subject: 'Backup Superlistas', text: 'Anexo está o seu backup de dados do Superlistas de $now.');

      // Limpa o arquivo temporário
      // Não precisa verificar mounted aqui pois delete é rápido
      if (shareResult.status == ShareResultStatus.success || shareResult.status == ShareResultStatus.dismissed) {
        await file.delete();
      }
    } else {
      messenger.showSnackBar(const SnackBar(content: Text('Exportação não suportada nesta plataforma.')));
    }

  } catch (e) {
    // Verifica montagem APÓS o await (em caso de erro)
    if (!context.mounted) return;
    // Tenta fechar o diálogo de loading
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    messenger.showSnackBar(SnackBar(content: Text('Falha ao exportar: $e'), backgroundColor: Colors.red));
  }
}

Future<void> _importarDados(BuildContext context, WidgetRef ref) async {
  final currentUser = ref.read(authViewModelProvider);
  // <<< CORREÇÃO DE LINT APLICADA AQUI (`context.mounted` checks) >>>
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context); // Usa rootNavigator

  if (currentUser == null) {
    messenger.showSnackBar(const SnackBar(content: Text('Você precisa estar logado para importar.')));
    return;
  }
  try {
    const group = XTypeGroup(label: 'JSON', extensions: ['json']);
    final XFile? selected = await openFile(acceptedTypeGroups: const [group]);

    // Verifica montagem APÓS o await do openFile
    if (!context.mounted || selected == null) return;

    final bool? confirm = await showGlassDialog<bool>(
      context: context, // Usa context original
      title: const Text('Atenção!'),
      content: const Text('Importar um arquivo substituirá TODAS as suas listas e itens atuais. Esta ação não pode ser desfeita. Deseja continuar?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')), // Fecha só o glass
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () => Navigator.of(context).pop(true), // Fecha só o glass
          child: const Flexible(
            child: Text(
              'Sim, substituir',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );

    // Verifica montagem APÓS o await do showGlassDialog
    if (!context.mounted || confirm != true) return;

    // Mostra indicador de progresso usando context original
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
              Text("Importando dados..."),
            ]),
          ),
        ),
      ),
    );

    final content = await selected.readAsString(); // Leitura pode demorar
    // Verifica montagem APÓS o await da leitura do arquivo
    if (!context.mounted) return;

    await ref.read(shoppingListRepositoryProvider).importDataFromJson(currentUser.id, content); // Importação pode demorar

    // Verifica montagem APÓS o await da importação
    if (!context.mounted) return;
    // Tenta fechar o diálogo de loading
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    // Invalida e refresha providers (sem usar context aqui)
    ref.invalidate(shoppingListsStreamProvider(currentUser.id));
    ref.invalidate(historyViewModelProvider(currentUser.id));
    ref.invalidate(dashboardViewModelProvider(currentUser.id));
    ref.invalidate(statsViewModelProvider(currentUser.id));
    ref.refresh(shoppingListsViewModelProvider(currentUser.id));
    ref.refresh(historyViewModelProvider(currentUser.id));
    ref.refresh(dashboardViewModelProvider(currentUser.id));
    ref.refresh(statsViewModelProvider(currentUser.id));

    messenger.showSnackBar(SnackBar(content: Text('Dados importados com sucesso de ${selected.name}')));

  } catch (e) {
    // Verifica montagem APÓS o await (em caso de erro)
    if (!context.mounted) return;
    // Tenta fechar o diálogo de loading
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    messenger.showSnackBar(SnackBar(content: Text('Falha ao importar: $e'), backgroundColor: Colors.red));
  }
}