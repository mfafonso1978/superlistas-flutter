// lib/presentation/views/main/main_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/core/ui/widgets/custom_drawer.dart';
import 'package:superlistas/presentation/providers/providers.dart';
import 'package:superlistas/presentation/views/history/history_screen.dart';
import 'package:superlistas/presentation/views/home/home_screen.dart';
import 'package:superlistas/presentation/views/shopping_lists/shopping_lists_screen.dart';
import 'package:superlistas/presentation/views/stats/stats_screen.dart';

final mainScaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) {
  return GlobalKey<ScaffoldState>();
});

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
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
    switch (index) {
      case 1: // Tela de Minhas Listas
        return Container(
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom + 80,
          ),
          child: FloatingActionButton.extended(
            onPressed: () => showAddOrEditListDialog(
              context,
              ref,
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
  const _MainBottomNavBar();

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
                  scheme.surface.withOpacity(0.80),
                  scheme.surface.withOpacity(0.70),
                ]
                    : [
                  Colors.white.withOpacity(0.6),
                  Colors.white.withOpacity(0.4),
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
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.list_alt_rounded), label: 'Listas'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.history_rounded), label: 'Histórico'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart_rounded), label: 'Estatísticas'),
              ],
              currentIndex: selectedIndex,
              onTap: (index) {
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
              // <<< MUDANÇA AQUI: Cor azul mais escuro para seleção >>>
              selectedItemColor: const Color(0xFF1565C0), // Azul mais escuro
              unselectedItemColor: scheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}