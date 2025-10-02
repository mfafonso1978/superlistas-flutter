// lib/presentation/views/main/main_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/core/ui/widgets/custom_drawer.dart';
import 'package:superlistas/core/ui/widgets/shared_widgets.dart';
import 'package:superlistas/presentation/providers/providers.dart';
import 'package:superlistas/presentation/views/history/history_screen.dart';
import 'package:superlistas/presentation/views/home/home_screen.dart';
import 'package:superlistas/presentation/views/premium/premium_screen.dart';
import 'package:superlistas/presentation/views/shopping_lists/shopping_lists_screen.dart';
import 'package:superlistas/presentation/views/stats/stats_screen.dart';
import 'package:url_launcher/url_launcher.dart';

void _showPremiumUpsell(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const PremiumScreen()),
  );
}

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
                      side: BorderSide(color: Colors.white.withAlpha((255 * 0.2).toInt())),
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

    return Scaffold(
      key: scaffoldKey,
      drawer: const CustomDrawer(),
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

    final listsTabIndex = ref.read(remoteConfigServiceProvider).isDashboardScreenEnabled ? 1 : 0;

    if (index == listsTabIndex) {
      return Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom + 80,
        ),
        child: FloatingActionButton(
          onPressed: () => showAddOrEditListDialog(
            context: context,
            ref: ref,
            userId: userId,
          ),
          shape: const CircleBorder(),
          child: const Icon(Icons.add),
        ),
      );
    }
    return null;
  }
}

// #############################################################################
// CORREÇÃO FINAL APLICADA NO WIDGET ABAIXO
// #############################################################################
class _MainBottomNavBar extends ConsumerWidget {
  const _MainBottomNavBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(mainScreenIndexProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Define as cores de fundo sólidas com base no tema
    final Color backgroundColor = isDark ? const Color(0xFF344049) : Colors.white;

    final remoteConfig = ref.watch(remoteConfigServiceProvider);
    final dashboardEnabled = remoteConfig.isDashboardScreenEnabled;
    final listsEnabled = remoteConfig.isShoppingListsScreenEnabled;
    final historyEnabled = remoteConfig.isHistoryScreenEnabled;
    final statsEnabled = remoteConfig.isStatsScreenEnabled;
    final isPremium = remoteConfig.isUserPremium;

    final List<BottomNavigationBarItem> visibleItems = [];
    if (dashboardEnabled) visibleItems.add(const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'));
    if (listsEnabled) visibleItems.add(const BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'Listas'));
    if (historyEnabled) visibleItems.add(const BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Histórico'));
    if (statsEnabled) visibleItems.add(BottomNavigationBarItem(icon: Icon(isPremium ? Icons.bar_chart_rounded : Icons.lock_outline), label: 'Estatísticas'));

    if (visibleItems.isEmpty) {
      return const SizedBox.shrink();
    }

    int realIndexToVisibleIndex(int realIndex) {
      int visibleIndex = 0;
      if (dashboardEnabled && realIndex >= 0) { if (realIndex == 0) return visibleIndex; visibleIndex++; }
      if (listsEnabled && realIndex >= 1) { if (realIndex == 1) return visibleIndex; visibleIndex++; }
      if (historyEnabled && realIndex >= 2) { if (realIndex == 2) return visibleIndex; visibleIndex++; }
      if (statsEnabled && realIndex >= 3) { if (realIndex == 3) return visibleIndex; }
      return 0;
    }

    // Estrutura simplificada sem BackdropFilter
    return Container(
      decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(top: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0,-2),
            )
          ]
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          items: visibleItems,
          currentIndex: realIndexToVisibleIndex(selectedIndex),
          onTap: (tappedIndex) {
            final Map<int, int> visibleIndexToRealIndexMap = {};
            int currentVisibleIndex = 0;
            if(dashboardEnabled) { visibleIndexToRealIndexMap[currentVisibleIndex++] = 0; }
            if(listsEnabled) { visibleIndexToRealIndexMap[currentVisibleIndex++] = 1; }
            if(historyEnabled) { visibleIndexToRealIndexMap[currentVisibleIndex++] = 2; }
            if(statsEnabled) { visibleIndexToRealIndexMap[currentVisibleIndex++] = 3; }

            final realIndex = visibleIndexToRealIndexMap[tappedIndex];
            if (realIndex == null) return;

            if (realIndex == 3 && !isPremium) {
              _showPremiumUpsell(context);
              return;
            }

            ref.read(mainScreenIndexProvider.notifier).state = realIndex;
          },
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent, // Importante para a cor do Container aparecer
          elevation: 0,
          selectedItemColor: const Color(0xFF1565C0),
          unselectedItemColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
    );
  }
}