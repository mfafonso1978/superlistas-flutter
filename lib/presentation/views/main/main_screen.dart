// lib/presentation/views/main/main_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/core/ui/widgets/custom_drawer.dart';
import 'package:superlistas/core/ui/widgets/shared_widgets.dart';
import 'package:superlistas/presentation/providers/providers.dart';
import 'package:superlistas/presentation/views/history/history_screen.dart';
import 'package:superlistas/presentation/views/home/home_screen.dart';
import 'package:superlistas/presentation/views/shopping_lists/shopping_lists_screen.dart';
import 'package:superlistas/presentation/views/stats/stats_screen.dart';
import 'package:url_launcher/url_launcher.dart';

final mainScaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) {
  return GlobalKey<ScaffoldState>();
});

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVersion();
    });
  }

  Future<void> _checkVersion() async {
    if (!mounted) return;
    final remoteConfigService = ref.read(remoteConfigServiceProvider);
    await remoteConfigService.initialize();
    if (!mounted) return;
    final packageInfo = await ref.read(packageInfoProvider.future);
    final currentBuildNumber = int.parse(packageInfo.buildNumber);
    final minVersion = remoteConfigService.minSupportedVersionCode;
    final latestVersion = remoteConfigService.latestVersionCode;
    if (currentBuildNumber < minVersion) {
      if (mounted) _showUpdateDialog(isMandatory: true);
    } else if (currentBuildNumber < latestVersion) {
      if (mounted) _showUpdateDialog(isMandatory: false);
    }
  }

  void _showUpdateDialog({required bool isMandatory}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: !isMandatory,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Consumer(
                builder: (context, ref, child) {
                  final remoteConfigService = ref.read(remoteConfigServiceProvider);
                  return AlertDialog(
                    backgroundColor: (isDark ? theme.colorScheme.surface : Colors.white)
                        .withAlpha((255 * 0.85).toInt()),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    title: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isMandatory ? Icons.system_update_alt_rounded : Icons.info_outline_rounded,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 12),
                          Text(isMandatory ? 'Atualização Obrigatória' : 'Nova Versão Disponível'),
                        ],
                      ),
                    ),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          Text('Uma nova versão (${remoteConfigService.latestVersionName}) do Superlistas está disponível!'),
                          const SizedBox(height: 16),
                          const Text('Novidades:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(remoteConfigService.releaseNotes.replaceAll('\\n', '\n')),
                        ],
                      ),
                    ),
                    actionsAlignment: MainAxisAlignment.end,
                    actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    actions: <Widget>[
                      if (!isMandatory)
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: Colors.blue.shade700),
                          child: const Text('Depois'),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isMandatory ? Colors.red : Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Atualizar Agora'),
                        onPressed: () async {
                          final url = Uri.parse(remoteConfigService.updateUrl);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ],
                  );
                }
            ),
          ),
        );
      },
    );
  }

  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    ShoppingListsScreen(),
    HistoryScreen(),
    StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(mainScreenIndexProvider);
    final currentUser = ref.watch(authViewModelProvider);
    final scaffoldKey = ref.watch(mainScaffoldKeyProvider);

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isPremium = ref.watch(remoteConfigServiceProvider).isPremiumStatsEnabled;

    return Scaffold(
      key: scaffoldKey,
      drawer: CustomDrawer(isPremium: isPremium),
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: selectedIndex,
            children: _pages,
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _MainBottomNavBar(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context, ref, selectedIndex, currentUser.id),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context, WidgetRef ref, int index, String userId) {
    final addListEnabled = ref.watch(remoteConfigServiceProvider).isAddListEnabled;
    if (!addListEnabled) return null;

    // O índice da tela de listas é sempre 1 no IndexedStack fixo
    if (index == 1) {
      return Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom + 80,
        ),
        child: FloatingActionButton.extended(
          onPressed: () => showAddOrEditListDialog(
            context: context,
            ref: ref,
            userId: userId,
          ),
          label: const Text('Nova Lista'),
          icon: const Icon(Icons.add),
        ),
      );
    }
    return null;
  }
}

class _MainBottomNavBar extends ConsumerWidget {
  const _MainBottomNavBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(mainScreenIndexProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final remoteConfig = ref.watch(remoteConfigServiceProvider);
    final dashboardEnabled = remoteConfig.isDashboardScreenEnabled;
    final listsEnabled = remoteConfig.isShoppingListsScreenEnabled;
    final historyEnabled = remoteConfig.isHistoryScreenEnabled;
    final statsEnabled = remoteConfig.isStatsScreenEnabled;
    final isPremium = remoteConfig.isPremiumStatsEnabled;

    final List<BottomNavigationBarItem> visibleItems = [];
    if (dashboardEnabled) visibleItems.add(const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'));
    if (listsEnabled) visibleItems.add(const BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'Listas'));
    if (historyEnabled) visibleItems.add(const BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Histórico'));
    if (statsEnabled) visibleItems.add(BottomNavigationBarItem(icon: Icon(isPremium ? Icons.bar_chart_rounded : Icons.lock_outline), label: 'Estatísticas'));

    if (visibleItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                  scheme.surface.withAlpha((255 * 0.80).toInt()),
                  scheme.surface.withAlpha((255 * 0.70).toInt()),
                ]
                    : [
                  Colors.white.withAlpha((255 * 0.6).toInt()),
                  Colors.white.withAlpha((255 * 0.4).toInt()),
                ],
              ),
              border: Border(top: BorderSide(color: scheme.onSurface.withOpacity(0.08), width: 1.5)),
            ),
            child: BottomNavigationBar(
              items: visibleItems,
              currentIndex: selectedIndex,
              onTap: (tappedIndex) {
                // Mapeia o índice clicado (da lista visível) para o índice real do IndexedStack
                final Map<int, int> visibleIndexToRealIndexMap = {};
                int currentVisibleIndex = 0;
                if(dashboardEnabled) { visibleIndexToRealIndexMap[currentVisibleIndex++] = 0; }
                if(listsEnabled) { visibleIndexToRealIndexMap[currentVisibleIndex++] = 1; }
                if(historyEnabled) { visibleIndexToRealIndexMap[currentVisibleIndex++] = 2; }
                if(statsEnabled) { visibleIndexToRealIndexMap[currentVisibleIndex++] = 3; }

                final realIndex = visibleIndexToRealIndexMap[tappedIndex];
                if (realIndex == null) return;

                if (realIndex == 3 && !isPremium) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funcionalidade Premium!')),
                  );
                  return;
                }

                final user = ref.read(authViewModelProvider.notifier).currentUser;
                if (realIndex == 0 && user != null) {
                  ref.invalidate(dashboardViewModelProvider(user.id));
                }
                ref.read(mainScreenIndexProvider.notifier).state = realIndex;
              },
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: const Color(0xFF1565C0),
              unselectedItemColor: scheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}