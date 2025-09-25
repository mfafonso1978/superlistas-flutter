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

    final remoteConfigService = ref.read(remoteConfigServiceProvider);

    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (context) => PopScope(
        canPop: !isMandatory,
        child: AlertDialog(
          title: Text(isMandatory ? 'Atualização Obrigatória' : 'Nova Versão Disponível'),
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
          actions: <Widget>[
            if (!isMandatory)
              TextButton(
                child: const Text('Depois'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ElevatedButton(
              child: const Text('Atualizar Agora'),
              onPressed: () async {
                final url = Uri.parse(remoteConfigService.updateUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ),
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

    final remoteConfigService = ref.watch(remoteConfigServiceProvider);
    final isPremium = remoteConfigService.isPremiumStatsEnabled;

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
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _MainBottomNavBar(isPremium: isPremium),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context, ref, selectedIndex, currentUser.id),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context, WidgetRef ref, int index, String userId) {
    switch (index) {
      case 1: // Tela de Minhas Listas
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
      default:
        return null;
    }
  }
}

class _MainBottomNavBar extends ConsumerWidget {
  final bool isPremium;
  const _MainBottomNavBar({required this.isPremium});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(mainScreenIndexProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ClipRect(
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
              border: Border(
                top: BorderSide(
                  color: scheme.onSurface.withOpacity(0.08),
                  width: 1.5,
                ),
              ),
            ),
            child: BottomNavigationBar(
              items: <BottomNavigationBarItem>[
                const BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.list_alt_rounded), label: 'Listas'),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.history_rounded), label: 'Histórico'),
                BottomNavigationBarItem(
                  icon: Icon(
                    isPremium ? Icons.bar_chart_rounded : Icons.lock_outline,
                  ),
                  label: 'Estatísticas',
                ),
              ],
              currentIndex: selectedIndex,
              onTap: (index) {
                if (index == 3 && !isPremium) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funcionalidade Premium!')),
                  );
                  return;
                }

                final user = ref.read(authViewModelProvider.notifier).currentUser;
                if (index == 0 && user != null) {
                  ref.invalidate(dashboardViewModelProvider(user.id));
                }
                ref.read(mainScreenIndexProvider.notifier).state = index;
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