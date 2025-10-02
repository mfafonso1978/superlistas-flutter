// lib/presentation/views/shopping_lists/shopping_lists_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:superlistas/core/ui/theme/app_backgrounds.dart';
import 'package:superlistas/core/ui/widgets/glass_dialog.dart';
import 'package:superlistas/core/ui/widgets/shared_widgets.dart';
import 'package:superlistas/domain/entities/shopping_list.dart';
import 'package:superlistas/presentation/providers/providers.dart';
import 'package:superlistas/presentation/views/list_items/list_items_screen.dart';
import 'package:superlistas/presentation/views/main/main_screen.dart';

class _ShoppingListsBackground extends ConsumerWidget {
  const _ShoppingListsBackground();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedKey = ref.watch(backgroundProvider);
    final background = availableBackgrounds.firstWhere((b) => b.key == selectedKey, orElse: () => availableBackgrounds.first);
    final String imagePath = isDark ? background.darkAssetPath : background.lightAssetPath;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        Positioned.fill(
          child: ColoredBox(
            color: Colors.black.withAlpha((255 * (isDark ? 0.55 : 0.35)).toInt()),
          ),
        ),
      ],
    );
  }
}

class ShoppingListsScreen extends ConsumerWidget {
  const ShoppingListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authViewModelProvider);
    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final userId = currentUser.id;
    final shoppingListsAsync = ref.watch(shoppingListsProvider(userId));
    final pullToRefreshEnabled = ref.watch(remoteConfigServiceProvider).isShoppingListsPullToRefreshEnabled;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: _ShoppingListsBackground()),
          RefreshIndicator(
            onRefresh: !pullToRefreshEnabled
                ? () async {}
                : () async {
              ref.invalidate(shoppingListsProvider(userId));
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                const _ShoppingListsSliverAppBar(),
                ...shoppingListsAsync.when(
                  loading: () => [
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  ],
                  error: (err, stack) => [
                    SliverFillRemaining(
                      child: Center(child: Text('Ocorreu um erro: $err')),
                    )
                  ],
                  data: (lists) => _buildSlivers(context, lists, ref, userId),
                ),
                SliverPadding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewPadding.bottom + 200,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSlivers(
      BuildContext context,
      List<ShoppingList> lists,
      WidgetRef ref,
      String userId,
      ) {
    final activeLists = lists.where((list) => !list.isArchived).toList();

    if (activeLists.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(),
        )
      ];
    } else {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          sliver: SliverList.builder(
            itemCount: activeLists.length,
            itemBuilder: (context, index) {
              final list = activeLists[index];
              return _ShoppingListItem(
                list: list,
                onEdit: () => showAddOrEditListDialog(
                  context: context,
                  ref: ref,
                  userId: userId,
                  list: list,
                ),
              );
            },
          ),
        ),
      ];
    }
  }
}

class _ShoppingListsSliverAppBar extends ConsumerWidget {
  const _ShoppingListsSliverAppBar();

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
      floating: false,
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
        'Minhas Listas',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: titleColor,
          fontSize: reducedFontSize,
        ),
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final addListEnabled = ref.watch(remoteConfigServiceProvider).isAddListEnabled;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.surface.withAlpha((255 * 0.8).toInt()),
                scheme.surface.withAlpha((255 * 0.6).toInt()),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scheme.outline.withAlpha((255 * 0.2).toInt()),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 60, color: scheme.secondary),
              const SizedBox(height: 20),
              Text(
                'Nenhuma lista de compras',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              if (addListEnabled)
                Text(
                  'Crie sua primeira lista clicando no botão "+"',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool?> _showDeleteConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
    ) {
  return showGlassDialog<bool>(
    context: context,
    title: Row(
      children: [
        Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
        const SizedBox(width: 12),
        const Text('Confirmar Exclusão'),
      ],
    ),
    content: Text(
      'Tem certeza que deseja excluir a lista "${list.name}" e todos os seus itens?',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancelar'),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Excluir'),
      ),
    ],
  );
}

class _ShoppingListItem extends ConsumerWidget {
  final ShoppingList list;
  final VoidCallback onEdit;

  const _ShoppingListItem({
    required this.list,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authViewModelProvider)!.id;
    final remoteConfig = ref.watch(remoteConfigServiceProvider);
    final editEnabled = remoteConfig.isEditListEnabled;
    final deleteEnabled = remoteConfig.isDeleteListEnabled;
    final archiveEnabled = remoteConfig.isArchiveListEnabled;

    final scheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final isCompleted = list.isCompleted;
    final hasBudget = list.budget != null && list.budget! > 0;

    double budgetProgress = 0.0;
    Color budgetColor = Colors.green;
    double balance = 0.0;

    if (hasBudget) {
      balance = list.budget! - list.totalCost;
      budgetProgress = (list.totalCost / list.budget!).clamp(0.0, 1.0);
      if (list.totalCost > list.budget!) {
        budgetColor = Colors.red;
      } else if (list.totalCost > list.budget! * 0.8) {
        budgetColor = Colors.orange;
      }
    }

    Widget cardContent = Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surface.withAlpha((255 * 0.8).toInt()),
            scheme.surface.withAlpha((255 * 0.6).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outline.withAlpha((255 * 0.2).toInt()),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ListItemsScreen(
                  shoppingListId: list.id,
                ),
              ),
            ).then((_) {
              ref.invalidate(shoppingListsProvider(userId));
              ref.invalidate(historyViewModelProvider(userId));
              ref.invalidate(dashboardViewModelProvider(userId));
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            list.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? scheme.onSurface.withAlpha((255 * 0.5).toInt()) : scheme.onSurface,
                              decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                              shadows: [
                                Shadow(
                                  blurRadius: 4.0,
                                  color: Colors.black.withAlpha((255 * 0.4).toInt()),
                                  offset: const Offset(1.0, 1.0),
                                ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Criada em: ${DateFormat('dd/MM/yyyy').format(list.creationDate)}',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant.withAlpha((255 * 0.8).toInt()),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (editEnabled || deleteEnabled || archiveEnabled)
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: scheme.onSurface),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            Future.microtask(onEdit);
                          } else if (value == 'delete') {
                            final shouldDelete = await _showDeleteConfirmationDialog(context, ref, list);
                            if (shouldDelete == true) {
                              ref.read(shoppingListsViewModelProvider(userId).notifier).deleteList(list.id);
                              ref.invalidate(historyViewModelProvider(userId));
                            }
                          } else if (value == 'archive') {
                            ref.read(shoppingListsViewModelProvider(userId).notifier).archiveList(list);
                            ref.invalidate(historyViewModelProvider(userId));
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          final List<PopupMenuEntry<String>> items = [];
                          if (editEnabled) {
                            items.add(const PopupMenuItem<String>(value: 'edit', child: Text('Editar')));
                          }
                          if (archiveEnabled) {
                            items.add(const PopupMenuItem<String>(value: 'archive', child: Text('Arquivar')));
                          }
                          if (deleteEnabled) {
                            items.add(const PopupMenuItem<String>(value: 'delete', child: Text('Excluir')));
                          }
                          return items;
                        },
                      ),
                  ],
                ),
                if (hasBudget) const SizedBox(height: 12),
                if (hasBudget)
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Custo: ${currencyFormat.format(list.totalCost)}', style: TextStyle(color: scheme.onSurface)),
                          Text('Orçamento: ${currencyFormat.format(list.budget!)}', style: TextStyle(color: scheme.onSurface)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Saldo:', style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface)),
                          Text(
                            currencyFormat.format(balance),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: balance < 0 ? Colors.red : scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: budgetProgress,
                          backgroundColor: scheme.surfaceContainerHighest.withAlpha((255 * 0.3).toInt()),
                          valueColor: AlwaysStoppedAnimation<Color>(budgetColor),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${list.checkedItems}/${list.totalItems} itens',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!editEnabled && !deleteEnabled) {
      return cardContent;
    }

    return Dismissible(
      key: Key(list.id),
      background: editEnabled
          ? Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: Colors.blue[700], borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.edit, color: Colors.white),
      )
          : Container(color: Colors.transparent),
      secondaryBackground: deleteEnabled
          ? Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: Colors.red[700], borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_forever, color: Colors.white),
      )
          : null,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart && deleteEnabled) {
          final shouldDelete = await _showDeleteConfirmationDialog(context, ref, list);
          return shouldDelete ?? false;
        } else if (direction == DismissDirection.startToEnd && editEnabled) {
          Future.microtask(onEdit);
          return false;
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart && deleteEnabled) {
          ref.read(shoppingListsViewModelProvider(userId).notifier).deleteList(list.id);
          ref.invalidate(historyViewModelProvider(userId));
        }
      },
      child: cardContent,
    );
  }
}