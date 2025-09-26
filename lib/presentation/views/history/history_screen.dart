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
import 'package:superlistas/presentation/views/main/main_screen.dart';

final historyListItemsProvider =
FutureProvider.autoDispose.family<List<Item>, String>((ref, listId) {
  final repository = ref.watch(shoppingListRepositoryProvider);
  return repository.getItems(listId);
});


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
    final pullToRefreshEnabled = ref.watch(remoteConfigServiceProvider).isHistoryPullToRefreshEnabled;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          AppBackground(),
          RefreshIndicator(
            onRefresh: pullToRefreshEnabled
                ? () => ref.read(historyViewModelProvider(userId).notifier).loadHistory()
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
            scheme.surface.withOpacity(0.6),
            scheme.surface.withOpacity(0.4),
          ]
              : [
            Colors.white.withOpacity(0.7),
            Colors.white.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
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
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color titleColor = isDark ? scheme.onSurface : Colors.white;

    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.menu, color: titleColor),
        onPressed: () {
          ref.read(mainScaffoldKeyProvider).currentState?.openDrawer();
        },
      ),
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? scheme.surface.withAlpha((255 * 0.3).toInt())
                  : Colors.white.withAlpha((255 * 0.2).toInt()),
            ),
            child: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
              title: Text(
                'Histórico de Listas',
                style: TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryListItem extends ConsumerStatefulWidget {
  final ShoppingList list;
  const _HistoryListItem({super.key, required this.list});

  @override
  ConsumerState<_HistoryListItem> createState() => _HistoryListItemState();
}

class _HistoryListItemState extends ConsumerState<_HistoryListItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authViewModelProvider);
    if (currentUser == null) return const SizedBox.shrink();

    final remoteConfig = ref.watch(remoteConfigServiceProvider);
    final viewItemsEnabled = remoteConfig.isHistoryViewItemsEnabled;
    final reuseListEnabled = remoteConfig.isReuseListEnabled;
    final deleteHistoryEnabled = remoteConfig.isDeleteHistoryListEnabled;

    final userId = currentUser.id;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final headerColor = isDark ? Colors.white : scheme.onSurface;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            scheme.surface.withOpacity(0.6),
            scheme.surface.withOpacity(0.4),
          ]
              : [
            Colors.white.withOpacity(0.7),
            Colors.white.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            InkWell(
              onTap: viewItemsEnabled ? () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              } : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: scheme.secondary, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.list.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: headerColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Concluída em: ${DateFormat('dd/MM/yyyy').format(widget.list.creationDate)}\n${widget.list.totalItems} itens',
                            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if(reuseListEnabled || deleteHistoryEnabled)
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: scheme.onSurface),
                        onSelected: (value) async {
                          if (value == 'reuse') {
                            await ref
                                .read(historyViewModelProvider(userId).notifier)
                                .reuseList(widget.list);
                            if (!context.mounted) return;
                            ref.invalidate(shoppingListsViewModelProvider(userId));

                            // Lógica para ir para a aba de listas
                            int listsTabIndex = 1;
                            if (ref.read(remoteConfigServiceProvider).isDashboardScreenEnabled == false) {
                              listsTabIndex = 0;
                            }
                            ref.read(mainScreenIndexProvider.notifier).state = listsTabIndex;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Lista "${widget.list.name}" reutilizada com sucesso!')),
                            );
                          } else if (value == 'delete') {
                            final bool? shouldDelete = await showGlassDialog<bool>(
                              context: context,
                              title: const Text('Confirmar Exclusão'),
                              content: Text(
                                  'Tem certeza de que deseja excluir permanentemente a lista "${widget.list.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Excluir'),
                                ),
                              ],
                            );
                            if (shouldDelete == true) {
                              await ref
                                  .read(historyViewModelProvider(userId).notifier)
                                  .deleteList(widget.list.id);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Lista "${widget.list.name}" excluída.')),
                              );
                            }
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          final List<PopupMenuEntry<String>> items = [];
                          if (reuseListEnabled) {
                            items.add(const PopupMenuItem<String>(
                                value: 'reuse', child: Text('Reutilizar Lista')));
                          }
                          if (deleteHistoryEnabled) {
                            items.add(const PopupMenuItem<String>(
                                value: 'delete', child: Text('Excluir Permanente')));
                          }
                          return items;
                        },
                      ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isExpanded ? _buildExpandedContent() : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    final itemsAsync = ref.watch(historyListItemsProvider(widget.list.id));
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final itemColor = isDark ? Colors.white70 : scheme.onSurface.withOpacity(0.8);
    final subItemColor = isDark ? Colors.white54 : scheme.onSurfaceVariant.withOpacity(0.8);

    return Container(
      color: (isDark ? Colors.black : Colors.white).withOpacity(0.1),
      child: itemsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(child: Text('Erro ao carregar itens.', style: TextStyle(color: itemColor))),
        ),
        data: (items) {
          if(items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: Text('Esta lista não tinha itens.', style: TextStyle(color: itemColor))),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: (isDark ? Colors.white : scheme.primary).withOpacity(0.1),
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                dense: true,
                leading: Icon(
                  item.isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                  color: item.isChecked ? scheme.secondary : itemColor,
                ),
                title: Text(item.name, style: TextStyle(color: itemColor, fontWeight: FontWeight.w500)),
                subtitle: Text('${NumberFormat().format(item.quantity)} ${item.unit}', style: TextStyle(color: subItemColor)),
              );
            },
          );
        },
      ),
    );
  }
}