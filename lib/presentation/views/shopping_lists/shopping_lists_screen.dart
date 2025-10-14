// lib/presentation/views/shopping_lists/shopping_lists_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:superlistas/core/ui/theme/app_backgrounds.dart';
import 'package:superlistas/core/ui/widgets/glass_dialog.dart';
import 'package:superlistas/core/ui/widgets/shared_widgets.dart';
import 'package:superlistas/domain/entities/member.dart';
import 'package:superlistas/domain/entities/shopping_list.dart';
import 'package:superlistas/presentation/providers/providers.dart';
import 'package:superlistas/presentation/views/list_items/list_items_screen.dart';
import 'package:superlistas/presentation/views/shopping_lists/manage_members_screen.dart';

Future<void> _showLeaveListConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
    ) {
  return showGlassDialog(
    context: context,
    title: const Text('Sair da Lista'),
    content: Text('Tem certeza que deseja sair da lista "${list.name}"? Você perderá o acesso a ela.'),
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
        onPressed: () {
          final userId = ref.read(authViewModelProvider)!.id;
          ref
              .read(shoppingListsViewModelProvider(userId).notifier)
              .leaveList(listId: list.id)
              .then((_) => Navigator.of(context).pop(true))
              .catchError((e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao sair da lista: $e'), backgroundColor: Colors.red),
              );
            }
          });
        },
        child: const Text('Sair'),
      ),
    ],
  );
}

Future<void> _showShareListDialog(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
    String currentUserId,
    ) async {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();

  return showGlassDialog(
    context: context,
    title: const Row(
      children: [
        Icon(Icons.group_add_outlined),
        SizedBox(width: 12),
        Text('Compartilhar Lista'),
      ],
    ),
    content: Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Compartilhe "${list.name}" com outros usuários através do e-mail.'),
          const SizedBox(height: 20),
          TextFormField(
            controller: emailController,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mail do colaborador',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Por favor, insira um e-mail.';
              }
              if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                return 'Por favor, insira um e-mail válido.';
              }
              return null;
            },
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      ElevatedButton(
        onPressed: () {
          if (formKey.currentState?.validate() ?? false) {
            final email = emailController.text.trim();
            ref
                .read(shoppingListsViewModelProvider(currentUserId).notifier)
                .shareList(listId: list.id, email: email)
                .then((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Convite enviado!')),
                );
                Navigator.of(context).pop();
              }
            }).catchError((e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao compartilhar: $e'), backgroundColor: Colors.red),
                );
              }
            });
          }
        },
        child: const Text('Convidar'),
      ),
    ],
  );
}

class _ShoppingListsBackground extends ConsumerWidget {
  const _ShoppingListsBackground();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedKey = ref.watch(backgroundProvider);
    final background = availableBackgrounds.firstWhere(
          (b) => b.key == selectedKey,
      orElse: () => availableBackgrounds.first,
    );
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
    final shoppingListsAsync = ref.watch(shoppingListsStreamProvider(userId));
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
              ref.invalidate(shoppingListsStreamProvider(userId));
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyListsPlaceholder(
            assetPath: 'assets/images/empty_shoppinglist.jpg',
          ),
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
      // >>>>>>>>>>>>>>>>>>>>> ALTERAÇÃO PARA ABRIR O DRAWER DO MAIN <<<<<<<<<<<<<<<<<<<<<
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(Icons.menu, color: titleColor),
          onPressed: () {
            // usa a GlobalKey do Scaffold PAI (MainScreen)
            final mainScaffoldKey = ref.read(mainScaffoldKeyProvider);
            if (mainScaffoldKey.currentState != null) {
              mainScaffoldKey.currentState!.openDrawer();
              return;
            }
            // fallback seguro caso a estrutura mude
            Scaffold.maybeOf(ctx)?.openDrawer();
          },
        ),
      ),
      // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
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

/// ======= PLACEHOLDER VAZIO (imagem + textos em container “glass”) =======
class _EmptyListsPlaceholder extends ConsumerWidget {
  final String assetPath;
  const _EmptyListsPlaceholder({required this.assetPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final addListEnabled = ref.watch(remoteConfigServiceProvider).isAddListEnabled;

    final Color glass = (isDark ? const Color(0xFF2C3A43) : Colors.white).withOpacity(0.85);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                decoration: BoxDecoration(
                  color: glass,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                    width: 1,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [glass, glass.withOpacity(isDark ? 0.78 : 0.9)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: 0.9,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            assetPath,
                            width: 240,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stack) => Column(
                              children: [
                                const Icon(Icons.image_not_supported_outlined, size: 64),
                                const SizedBox(height: 12),
                                Text(
                                  'Não foi possível carregar a ilustração.',
                                  style: theme.textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Nenhuma lista de compras',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (addListEnabled)
                      Text(
                        'Crie sua primeira lista tocando no botão “+”.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 16),
                    if (addListEnabled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.teal.shade900 : Colors.teal.shade50)
                              .withOpacity(isDark ? 0.5 : 1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (isDark ? Colors.tealAccent : Colors.teal).withOpacity(0.35),
                          ),
                        ),
                        child: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.center,
                          children: [
                            const Icon(Icons.lightbulb, size: 16),
                            Text(
                              'Dica: compartilhe listas com sua família usando o menu “⋮”.',
                              softWrap: true,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
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
    final isOwner = list.ownerId == userId;

    final scheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final isCompleted = list.isCompleted;
    final hasBudget = list.budget != null && list.budget! > 0;
    final isShared = list.members.length > 1;

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
              ref.invalidate(shoppingListsStreamProvider(userId));
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
                    if (isOwner)
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: scheme.onSurface),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            Future.microtask(onEdit);
                          } else if (value == 'delete') {
                            final shouldDelete = await _showDeleteConfirmationDialog(context, ref, list);
                            if (shouldDelete == true) {
                              ref.read(shoppingListsViewModelProvider(userId).notifier).deleteList(list.id);
                            }
                          } else if (value == 'archive') {
                            ref.read(shoppingListsViewModelProvider(userId).notifier).archiveList(list);
                          } else if (value == 'share') {
                            _showShareListDialog(context, ref, list, userId);
                          } else if (value == 'manage_members') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ManageMembersScreen(list: list)),
                            );
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          final List<PopupMenuEntry<String>> items = [];
                          items.add(const PopupMenuItem<String>(value: 'share', child: Text('Convidar Membro')));
                          if (isShared) {
                            items.add(const PopupMenuItem<String>(value: 'manage_members', child: Text('Gerenciar Membros')));
                          }
                          if (editEnabled) {
                            items.add(const PopupMenuItem<String>(value: 'edit', child: Text('Editar')));
                          }
                          if (archiveEnabled) {
                            items.add(const PopupMenuItem<String>(value: 'archive', child: Text('Arquivar')));
                          }
                          if (deleteEnabled) {
                            items.add(const PopupMenuDivider());
                            items.add(const PopupMenuItem<String>(value: 'delete', child: Text('Excluir')));
                          }
                          return items;
                        },
                      )
                    else if (isShared)
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: scheme.onSurface),
                        onSelected: (value) async {
                          if (value == 'leave_list') {
                            _showLeaveListConfirmationDialog(context, ref, list);
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            const PopupMenuItem<String>(value: 'leave_list', child: Text('Sair da Lista')),
                          ];
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (isShared) _MembersAvatarRow(members: list.members),
                    if (isShared) const Spacer(),
                    Text(
                      '${list.checkedItems}/${list.totalItems} itens',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!isOwner || (!editEnabled && !deleteEnabled)) {
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
        }
      },
      child: cardContent,
    );
  }
}

class _MembersAvatarRow extends StatelessWidget {
  final List<Member> members;
  const _MembersAvatarRow({required this.members});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const maxAvatars = 4;
    final displayedMembers = members.take(maxAvatars).toList();
    final remainingCount = members.length - maxAvatars;

    return SizedBox(
      height: 30,
      child: Row(
        children: [
          ...List.generate(displayedMembers.length, (index) {
            final member = displayedMembers[index];
            return Align(
              widthFactor: 0.7,
              child: CircleAvatar(
                radius: 15,
                backgroundColor: theme.colorScheme.surface,
                child: CircleAvatar(
                  radius: 13,
                  backgroundImage: member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: member.photoUrl == null
                      ? Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  )
                      : null,
                ),
              ),
            );
          }),
          if (remainingCount > 0)
            Align(
              widthFactor: 0.7,
              child: CircleAvatar(
                radius: 15,
                backgroundColor: theme.colorScheme.surface,
                child: CircleAvatar(
                  radius: 13,
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  child: Text(
                    '+$remainingCount',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
