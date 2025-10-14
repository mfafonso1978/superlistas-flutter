// lib/presentation/views/history/history_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:superlistas/core/ui/theme/app_backgrounds.dart';
import 'package:superlistas/core/ui/widgets/app_background.dart';
import 'package:superlistas/core/ui/widgets/glass_dialog.dart';
import 'package:superlistas/domain/entities/item.dart';
import 'package:superlistas/domain/entities/shopping_list.dart';
import 'package:superlistas/presentation/providers/providers.dart';
import 'package:superlistas/presentation/views/list_items/list_items_screen.dart';
import 'package:superlistas/presentation/views/main/main_screen.dart';
import 'package:superlistas/presentation/views/premium/premium_screen.dart';

final historyListItemsProvider =
FutureProvider.autoDispose.family<List<Item>, String>((ref, listId) {
  final repository = ref.watch(shoppingListRepositoryProvider);
  return repository.getItems(listId);
});

void _showPremiumUpsell(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const PremiumScreen()),
  );
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authViewModelProvider);
    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final userId = currentUser.id;
    final historyAsync = ref.watch(historyViewModelProvider(userId));
    final scheme = Theme.of(context).colorScheme;
    final pullToRefreshEnabled =
        ref.watch(remoteConfigServiceProvider).isHistoryPullToRefreshEnabled;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          AppBackground(),
          RefreshIndicator(
            onRefresh: pullToRefreshEnabled
                ? () =>
                ref.read(historyViewModelProvider(userId).notifier).loadHistory()
                : () async {},
            child: CustomScrollView(
              slivers: [
                const _HistorySliverAppBar(),
                historyAsync.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => SliverFillRemaining(
                    child: Center(child: Text('Ocorreu um erro: $err')),
                  ),
                  data: (lists) {
                    if (lists.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: _buildEmptyState(context, scheme)),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                      sliver: SliverList.builder(
                        itemCount: lists.length,
                        itemBuilder: (context, index) =>
                            _HistoryListItem(list: lists[index]),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme scheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            scheme.surface.withAlpha((255 * 0.6).toInt()),
            scheme.surface.withAlpha((255 * 0.4).toInt()),
          ]
              : [
            Colors.white.withAlpha((255 * 0.7).toInt()),
            Colors.white.withAlpha((255 * 0.5).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withAlpha((255 * 0.2).toInt()),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 60, color: scheme.secondary),
          const SizedBox(height: 20),
          Text(
            'Histórico Vazio',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: 10),
          Text(
            'Listas concluídas ou arquivadas aparecerão aqui.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _HistorySliverAppBar extends ConsumerWidget {
  const _HistorySliverAppBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color titleColor = isDark ? Colors.white : Colors.black;
    final Color backgroundColor = isDark ? const Color(0xFF344049) : Colors.white;
    final baseFontSize = theme.textTheme.titleLarge?.fontSize ?? 22.0;
    final reducedFontSize = baseFontSize * 0.7;

    return SliverAppBar(
      pinned: true,
      elevation: 1,
      shadowColor: Colors.black.withAlpha(50),
      backgroundColor: backgroundColor,
      surfaceTintColor: backgroundColor,
      leading: IconButton(
        icon: Icon(Icons.menu, color: titleColor),
        onPressed: () {
          ref.read(mainScaffoldKeyProvider).currentState?.openDrawer();
        },
      ),
      title: Text(
        'Histórico de Listas',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: titleColor,
          fontSize: reducedFontSize,
        ),
      ),
    );
  }
}

class _HistoryListItem extends ConsumerWidget {
  final ShoppingList list;
  const _HistoryListItem({required this.list});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authViewModelProvider);
    if (currentUser == null) return const SizedBox.shrink();

    final remoteConfig = ref.watch(remoteConfigServiceProvider);
    final isPremium = remoteConfig.isUserPremium;
    final reuseListEnabled = remoteConfig.isReuseListEnabled;
    final deleteHistoryEnabled = remoteConfig.isDeleteHistoryListEnabled;

    final userId = currentUser.id;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final headerColor = isDark ? Colors.white : scheme.onSurface;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            scheme.surface.withAlpha((255 * 0.6).toInt()),
            scheme.surface.withAlpha((255 * 0.4).toInt()),
          ]
              : [
            Colors.white.withAlpha((255 * 0.7).toInt()),
            Colors.white.withAlpha((255 * 0.5).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withAlpha((255 * 0.2).toInt()),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ListItemsScreen(shoppingListId: list.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: scheme.secondary, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: headerColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Concluída em: ${DateFormat('dd/MM/yyyy').format(list.creationDate)}',
                        style: TextStyle(
                            color: scheme.onSurfaceVariant, fontSize: 12),
                      ),
                      Text(
                        '${list.totalItems} itens • ${currencyFormat.format(list.totalCost)}',
                        style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                if (reuseListEnabled || deleteHistoryEnabled)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: scheme.onSurface),
                    onSelected: (value) async {
                      if (value == 'reuse') {
                        if (isPremium) {
                          await ref
                              .read(historyViewModelProvider(userId)
                              .notifier)
                              .reuseList(list);
                          if (!context.mounted) return;

                          // <<< CORREÇÃO APLICADA AQUI >>>
                          ref.invalidate(shoppingListsStreamProvider(userId));

                          int listsTabIndex = 1;
                          if (ref
                              .read(remoteConfigServiceProvider)
                              .isDashboardScreenEnabled ==
                              false) {
                            listsTabIndex = 0;
                          }
                          ref.read(mainScreenIndexProvider.notifier).state =
                              listsTabIndex;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Lista "${list.name}" reutilizada com sucesso!')),
                          );
                        } else {
                          _showPremiumUpsell(context);
                        }
                      } else if (value == 'delete') {
                        final bool? shouldDelete =
                        await showGlassDialog<bool>(
                          context: context,
                          title: const Text('Confirmar Exclusão'),
                          content: Text(
                              'Tem certeza de que deseja excluir permanentemente a lista "${list.name}"?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () =>
                                  Navigator.of(context).pop(true),
                              child: const Text('Excluir'),
                            ),
                          ],
                        );
                        if (shouldDelete == true) {
                          await ref
                              .read(historyViewModelProvider(userId)
                              .notifier)
                              .deleteList(list.id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Lista "${list.name}" excluída.')),
                          );
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      final theme = Theme.of(context);
                      final iconColor = theme.colorScheme.onSurface
                          .withAlpha((255 * 0.7).toInt());

                      final List<PopupMenuEntry<String>> items = [];
                      if (reuseListEnabled) {
                        items.add(PopupMenuItem<String>(
                            value: 'reuse',
                            child: IconTheme(
                              data: IconThemeData(color: iconColor),
                              child: Row(
                                children: [
                                  Icon(isPremium
                                      ? Icons.copy_all_rounded
                                      : Icons.lock_outline),
                                  const SizedBox(width: 12),
                                  const Text('Reutilizar Lista'),
                                ],
                              ),
                            )));
                      }
                      if (deleteHistoryEnabled) {
                        items.add(PopupMenuItem<String>(
                            value: 'delete',
                            child: const IconTheme(
                              data: IconThemeData(color: Colors.red),
                              child: Row(
                                children: [
                                  Icon(Icons.delete_forever_outlined),
                                  SizedBox(width: 12),
                                  Text('Excluir Permanente'),
                                ],
                              ),
                            )));
                      }
                      return items;
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}