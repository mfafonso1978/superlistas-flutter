// lib/presentation/views/shopping_lists/shopping_lists_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:superlistas/core/ui/widgets/glass_dialog.dart';
import 'package:superlistas/core/ui/widgets/shared_widgets.dart'; // <<< IMPORT ATUALIZADO
import 'package:superlistas/domain/entities/shopping_list.dart';
import 'package:superlistas/presentation/providers/providers.dart';
import 'package:superlistas/presentation/views/list_items/list_items_screen.dart';

const double _kListsAppBarHeight = kToolbarHeight;

class _ShoppingListsBackground extends StatelessWidget {
  _ShoppingListsBackground();

  final String _kListsBgAssetLight = 'assets/images/bg_home.jpg';
  final String _kListsBgAssetDark = 'assets/images/bg_home_black.jpg';


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String imagePath = isDark ? _kListsBgAssetDark : _kListsBgAssetLight;

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
            color: Colors.black.withOpacity(isDark ? 0.55 : 0.35),
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
    ref.watch(authViewModelProvider);
    final currentUser = ref.read(authViewModelProvider.notifier).currentUser;

    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final userId = currentUser.id;
    final shoppingListsAsync = ref.watch(shoppingListsViewModelProvider(userId));

    return Stack(
      children: [
        Positioned.fill(child: _ShoppingListsBackground()),
        RefreshIndicator(
          edgeOffset: kToolbarHeight,
          onRefresh: () =>
              ref.read(shoppingListsViewModelProvider(userId).notifier).loadLists(),
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
    );
  }

  List<Widget> _buildSlivers(
      BuildContext context,
      List<ShoppingList> lists,
      WidgetRef ref,
      String userId,
      ) {
    if (lists.isEmpty) {
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
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
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

class _ShoppingListsSliverAppBar extends StatelessWidget {
  const _ShoppingListsSliverAppBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color titleColor = isDark ? scheme.onSurface : Colors.white;

    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: kToolbarHeight,
      collapsedHeight: kToolbarHeight,
      backgroundColor: Colors.transparent,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(Icons.menu, color: titleColor),
          onPressed: () {
            Scaffold.maybeOf(ctx)?.openDrawer();
          },
        ),
      ),
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                bottom: BorderSide(
                  color: scheme.onSurface.withOpacity(0.08),
                  width: 1.5,
                ),
              ),
            ),
            child: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsetsDirectional.only(start: 60.0, bottom: 16.0),
              title: Text(
                'Minhas Listas',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                scheme.surface.withOpacity(0.8),
                scheme.surface.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined,
                  size: 60, color: scheme.secondary),
              const SizedBox(height: 20),
              Text(
                'Nenhuma lista de compras',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Crie sua primeira lista clicando no botão "+"',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: scheme.onSurfaceVariant),
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
        Icon(Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error),
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
    final currentUser = ref.watch(authViewModelProvider.notifier).currentUser;
    if (currentUser == null) return const SizedBox.shrink();
    final userId = currentUser.id;

    final scheme = Theme.of(context).colorScheme;
    final currencyFormat =
    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final bool isCompleted = list.isCompleted;

    final bool hasBudget = list.budget != null && list.budget! > 0;
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

    return Dismissible(
      key: Key(list.id),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue[700],
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red[700],
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_forever, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          final shouldDelete =
          await _showDeleteConfirmationDialog(context, ref, list);
          return shouldDelete ?? false;
        } else {
          Future.microtask(onEdit);
          return false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          ref
              .read(shoppingListsViewModelProvider(userId).notifier)
              .deleteList(list.id);
          ref.invalidate(historyViewModelProvider(userId));
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surface.withOpacity(0.8),
              scheme.surface.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.outline.withOpacity(0.2),
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
                ref.invalidate(shoppingListsViewModelProvider(userId));
                ref.invalidate(historyViewModelProvider(userId));
                ref.invalidate(dashboardViewModelProvider(userId));
              });
            },
            child: Padding(
              padding:
              const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
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
                                color: isCompleted
                                    ? scheme.onSurface.withOpacity(0.5)
                                    : scheme.onSurface,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4.0,
                                    color: Colors.black.withOpacity(0.4),
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
                                color: scheme.onSurfaceVariant
                                    .withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: scheme.onSurface),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            Future.microtask(onEdit);
                          } else if (value == 'delete') {
                            final shouldDelete =
                            await _showDeleteConfirmationDialog(
                                context, ref, list);
                            if (shouldDelete == true) {
                              ref
                                  .read(shoppingListsViewModelProvider(userId)
                                  .notifier)
                                  .deleteList(list.id);
                              ref.invalidate(historyViewModelProvider(userId));
                            }
                          } else if (value == 'archive') {
                            ref
                                .read(shoppingListsViewModelProvider(userId)
                                .notifier)
                                .archiveList(list);
                            ref.invalidate(historyViewModelProvider(userId));
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                              value: 'edit', child: Text('Editar')),
                          const PopupMenuItem<String>(
                              value: 'archive', child: Text('Arquivar')),
                          const PopupMenuItem<String>(
                              value: 'delete', child: Text('Excluir')),
                        ],
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
                            Text('Custo: ${currencyFormat.format(list.totalCost)}',
                                style: TextStyle(color: scheme.onSurface)),
                            Text('Orçamento: ${currencyFormat.format(list.budget!)}',
                                style: TextStyle(color: scheme.onSurface)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Saldo:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: scheme.onSurface)),
                            Text(
                              currencyFormat.format(balance),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: balance < 0
                                    ? Colors.red
                                    : scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: budgetProgress,
                            backgroundColor: scheme.surfaceContainerHighest
                                .withOpacity(0.3),
                            valueColor:
                            AlwaysStoppedAnimation<Color>(budgetColor),
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
      ),
    );
  }
}