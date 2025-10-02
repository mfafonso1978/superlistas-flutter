// lib/core/ui/widgets/custom_drawer.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:superlistas/core/ui/widgets/glass_dialog.dart';
import 'package:superlistas/domain/entities/user.dart';
import 'package:superlistas/presentation/providers/providers.dart';
import 'package:superlistas/presentation/views/categories/categories_screen.dart';
import 'package:superlistas/presentation/views/premium/premium_screen.dart';
import 'package:superlistas/presentation/views/settings/settings_screen.dart';

void _showPremiumUpsell(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const PremiumScreen()),
  );
}

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = ref.watch(mainScreenIndexProvider);
    final user = ref.watch(authViewModelProvider);

    final remoteConfig = ref.watch(remoteConfigServiceProvider);
    final isPremium = remoteConfig.isUserPremium;

    final dashboardEnabled = remoteConfig.isDashboardScreenEnabled;
    final listsEnabled = remoteConfig.isShoppingListsScreenEnabled;
    final historyEnabled = remoteConfig.isHistoryScreenEnabled;
    final statsEnabled = remoteConfig.isStatsScreenEnabled;
    final categoriesEnabled = remoteConfig.isCategoriesScreenEnabled;
    final settingsEnabled = remoteConfig.isSettingsScreenEnabled;
    final themeToggleEnabled = remoteConfig.isThemeToggleEnabled;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? scheme.surface.withAlpha((255 * 0.3).toInt())
                  : scheme.surface.withAlpha((255 * 0.4).toInt()),
              border: Border(
                right: BorderSide(
                  color: isDark
                      ? Colors.white.withAlpha((255 * 0.1).toInt())
                      : scheme.outline.withAlpha((255 * 0.2).toInt()),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      _DrawerHeader(user: user),
                      const SizedBox(height: 8),

                      if (dashboardEnabled)
                        _buildDrawerItem(
                          context,
                          icon: Icons.dashboard_rounded,
                          text: 'Dashboard',
                          isSelected: currentIndex == 0,
                          onTap: () => _onItemTapped(context, ref, 0),
                        ),
                      if (listsEnabled)
                        _buildDrawerItem(
                          context,
                          icon: Icons.list_alt_rounded,
                          text: 'Minhas Listas',
                          isSelected: currentIndex == 1,
                          onTap: () => _onItemTapped(context, ref, 1),
                        ),
                      if (historyEnabled)
                        _buildDrawerItem(
                          context,
                          icon: Icons.history_rounded,
                          text: 'Histórico',
                          isSelected: currentIndex == 2,
                          onTap: () => _onItemTapped(context, ref, 2),
                        ),
                      if (statsEnabled)
                        _buildDrawerItem(
                          context,
                          icon: isPremium ? Icons.bar_chart_rounded : Icons.lock_outline,
                          text: 'Estatísticas',
                          isSelected: currentIndex == 3,
                          onTap: () {
                            Navigator.pop(context);
                            if (isPremium) {
                              _onItemTapped(context, ref, 3);
                            } else {
                              _showPremiumUpsell(context);
                            }
                          },
                        ),

                      if (categoriesEnabled || settingsEnabled)
                        Divider(
                            color: scheme.outlineVariant.withAlpha((255 * 0.3).toInt()),
                            height: 16),

                      if (categoriesEnabled)
                        _buildDrawerItem(
                          context,
                          icon: Icons.format_list_bulleted_rounded,
                          text: 'Categorias',
                          onTap: () => _navigateTo(context, const CategoriesScreen()),
                        ),
                      if (settingsEnabled)
                        _buildDrawerItem(
                          context,
                          icon: Icons.settings_rounded,
                          text: 'Configurações',
                          onTap: () => _navigateTo(context, SettingsScreen()),
                        ),

                      const Divider(
                          color: Colors.white24,
                          height: 16),
                      _buildDrawerItem(
                        context,
                        icon: Icons.logout,
                        text: 'Sair',
                        onTap: () async {
                          Navigator.pop(context);
                          final bool? confirm = await showGlassDialog<bool>(
                            context: context,
                            title: Row(
                              children: [
                                Icon(Icons.logout, color: scheme.error),
                                const SizedBox(width: 12),
                                const Text('Confirmar Saída'),
                              ],
                            ),
                            content: const Text('Tem certeza que deseja sair da sua conta?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: scheme.error,
                                  foregroundColor: scheme.onError,
                                ),
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Sair'),
                              ),
                            ],
                          );
                          if (confirm == true) {
                            ref.read(authViewModelProvider.notifier).signOut();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                if (themeToggleEnabled) _ThemeToggle(isDark: isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onItemTapped(BuildContext context, WidgetRef ref, int index) {
    ref.read(mainScreenIndexProvider.notifier).state = index;
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String text,
        required GestureTapCallback onTap,
        bool isSelected = false,
      }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const selectedColor = Color(0xFF1565C0);

    return ListTile(
      leading: Icon(
          icon,
          color: isSelected
              ? selectedColor
              : (isDark ? scheme.onSurfaceVariant : scheme.onSurface.withAlpha((255 * 0.8).toInt()))
      ),
      selected: isSelected,
      selectedTileColor: selectedColor.withAlpha((255 * 0.15).toInt()),
      title: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: isSelected
              ? selectedColor
              : (isDark ? scheme.onSurface : scheme.onSurface.withAlpha((255 * 0.9).toInt())),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final User? user;
  const _DrawerHeader({this.user});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final userName = user?.name ?? 'Superlistas';
    final userEmail = user?.email ?? 'Suas compras, simplificadas';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withAlpha((255 * 0.7).toInt()),
            scheme.primary.withAlpha((255 * 0.5).toInt()),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: scheme.secondary,
            backgroundImage:
            (user?.photoUrl != null) ? NetworkImage(user!.photoUrl!) : null,
            child: (user?.photoUrl == null)
                ? Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
              style: const TextStyle(fontSize: 32, color: Colors.white),
            )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: TextStyle(
                    color: scheme.onPrimary.withAlpha((255 * 0.8).toInt()),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeToggle extends ConsumerWidget {
  final bool isDark;
  const _ThemeToggle({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final scheme = Theme.of(context).colorScheme;

    final String label = isDark ? 'Modo Escuro' : 'Modo Claro';

    final Color iconColor = isDark ? Colors.white : Colors.amber;
    final Color activeSwitchColor = isDark ? Colors.white : Colors.amber;

    return SafeArea(
      top: false,
      child: SwitchListTile(
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: isDark ? scheme.onSurface : scheme.onSurface.withAlpha((255 * 0.9).toInt()),
            fontWeight: FontWeight.w500,
          ),
        ),
        secondary: Icon(
          isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
          color: iconColor,
        ),
        value: themeMode == ThemeMode.dark,
        onChanged: (isDarkValue) {
          final newMode = isDarkValue ? ThemeMode.dark : ThemeMode.light;
          ref.read(themeModeProvider.notifier).setMode(newMode);
        },
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return activeSwitchColor;
          }
          return isDark
              ? Colors.grey[300]
              : Colors.grey[600];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return activeSwitchColor.withAlpha((255 * 0.3).toInt());
          }
          return isDark
              ? Colors.grey[700]
              : Colors.grey[300];
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          return isDark
              ? Colors.grey[600]
              : Colors.grey[400];
        }),
      ),
    );
  }
}