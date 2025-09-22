// lib/presentation/views/home/home_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:superlistas/core/ui/theme/app_backgrounds.dart';
import 'package:superlistas/domain/entities/dashboard_data.dart';
import 'package:superlistas/domain/entities/shopping_list.dart';
import 'package:superlistas/domain/entities/user.dart';
import 'package:superlistas/presentation/providers/providers.dart';
import 'package:superlistas/presentation/views/list_items/list_items_screen.dart';
import 'package:superlistas/presentation/views/shopping_lists/shopping_lists_screen.dart'
    show showAddOrEditListDialog;

const double _kHomeAppBarHeight = kToolbarHeight + 64;

double _contentBottomInset(BuildContext context) =>
    MediaQuery.of(context).viewPadding.bottom + 80;

class HomeBackground extends ConsumerWidget {
  const HomeBackground({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedKey = ref.watch(backgroundProvider);
    final background = availableBackgrounds.firstWhere(
          (b) => b.key == selectedKey,
      orElse: () => availableBackgrounds.first,
    );
    final String imagePath =
    isDark ? background.darkAssetPath : background.lightAssetPath;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        Positioned.fill(
          child: ColoredBox(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.15),
          ),
        ),
      ],
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final userId = user.id;

    ref.listen<AsyncValue<List<ShoppingList>>>(
      shoppingListsViewModelProvider(userId),
          (prev, next) {
        if (next.hasValue || next.hasError) {
          ref.read(dashboardViewModelProvider(userId).notifier).loadData();
        }
      },
    );

    final dashboardDataAsync = ref.watch(dashboardViewModelProvider(userId));

    return Stack(
      children: [
        const Positioned.fill(child: HomeBackground()),
        RefreshIndicator(
          edgeOffset: _kHomeAppBarHeight,
          notificationPredicate: (n) => n.depth == 0,
          onRefresh: () =>
              ref.read(dashboardViewModelProvider(userId).notifier).loadData(),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              _DashboardSliverAppBar(user: user),
              ...dashboardDataAsync.when(
                loading: () => _buildLoadingSlivers(context),
                error: (err, _) => _buildErrorSlivers('$err'),
                data: (data) => _buildDataSlivers(
                  context: context,
                  userId: userId,
                  userName: user.name,
                  data: data,
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.only(bottom: _contentBottomInset(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardSliverAppBar extends StatelessWidget {
  final User user;
  const _DashboardSliverAppBar({required this.user});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today =
    DateFormat('EEEE, d \'de\' MMMM', 'pt_BR').format(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      expandedHeight: _kHomeAppBarHeight,
      collapsedHeight: _kHomeAppBarHeight,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.menu, color: scheme.onSurface),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                  scheme.primary.withOpacity(0.80),
                  scheme.primary.withOpacity(0.70),
                ]
                    : [
                  Colors.white.withOpacity(0.6),
                  Colors.white.withOpacity(0.4),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: scheme.onSurface.withOpacity(0.08),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(60, 8, 16, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Olá, ${user.name} 👋',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              today[0].toUpperCase() + today.substring(1),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurface.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: scheme.secondary.withOpacity(0.2),
                        child: user.photoUrl == null
                            ? Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: scheme.secondary,
                          ),
                        )
                            : ClipOval(
                          child: Image.network(
                            user.photoUrl!,
                            fit: BoxFit.cover,
                            width: 52,
                            height: 52,
                            errorBuilder: (context, error, stackTrace) {
                              print("Erro ao carregar imagem do avatar: $error");
                              return Icon(
                                Icons.person,
                                color: scheme.secondary,
                                size: 30,
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<Widget> _buildDataSlivers({
  required BuildContext context,
  required String userId,
  required String userName,
  required DashboardData data,
}) {
  final recent = data.recentLists;
  final ShoppingList? lastActive =
  recent.where((l) => !l.isCompleted && !l.isArchived).isNotEmpty
      ? recent.firstWhere((l) => !l.isCompleted && !l.isArchived)
      : (recent.isNotEmpty ? recent.first : null);

  return [
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      sliver: SliverGrid.count(
        crossAxisCount: 2,
        childAspectRatio: 1.65,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _MetricCard(
              data: _MetricCardData(
                label: 'Ativas',
                value: '${data.activeListsCount}',
                icon: Icons.rocket_launch_rounded,
                gradient: [Colors.blue.shade400, Colors.blue.shade600],
              )),
          _MetricCard(
              data: _MetricCardData(
                label: 'Pendentes',
                value: '${data.pendingListsCount}',
                icon: Icons.schedule_rounded,
                gradient: [Colors.orange.shade400, Colors.orange.shade600],
              )),
          _MetricCard(
              data: _MetricCardData(
                label: 'Concluídas',
                value: '${data.completedListsCount}',
                icon: Icons.task_alt_rounded,
                gradient: [Colors.green.shade400, Colors.green.shade600],
              )),
          _MetricCard(
              data: _MetricCardData(
                label: 'Vazias',
                value: '${data.emptyListsCount}',
                icon: Icons.inventory_2_outlined,
                gradient: [Colors.grey.shade400, Colors.grey.shade600],
              )),
        ],
      ),
    ),
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
        child: _SectionTitle('Ações Rápidas', icon: Icons.flash_on_rounded),
      ),
    ),
    SliverToBoxAdapter(
      child: _QuickActionsBar(userId: userId, lastActive: lastActive),
    ),
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
        child: _RecentHeader(userId: userId),
      ),
    ),
    if (data.recentLists.isEmpty)
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _EmptyRecent(userId: userId, refetchKey: userId),
        ),
      )
    else
      SliverToBoxAdapter(
        child: _RecentHorizontalList(userId: userId, lists: data.recentLists),
      ),
  ];
}

List<Widget> _buildLoadingSlivers(BuildContext context) {
  return [
    const SliverToBoxAdapter(child: SizedBox(height: 20)),
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid.count(
        crossAxisCount: 2,
        childAspectRatio: 1.65,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: List.generate(4, (_) => const _ShimmerBox(h: 100, r: 20)),
      ),
    ),
    const SliverToBoxAdapter(child: SizedBox(height: 24)),
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverToBoxAdapter(child: const _ShimmerBox(h: 24, r: 8, w: 160)),
    ),
    const SliverToBoxAdapter(child: SizedBox(height: 14)),
    SliverToBoxAdapter(
      child: SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 6,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => const _ShimmerBox(h: 120, r: 20, w: 100),
        ),
      ),
    ),
    const SliverToBoxAdapter(child: SizedBox(height: 24)),
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverToBoxAdapter(child: const _ShimmerBox(h: 24, r: 8, w: 180)),
    ),
    const SliverToBoxAdapter(child: SizedBox(height: 14)),
    SliverToBoxAdapter(
      child: SizedBox(
        height: 200,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (_, __) => const _ShimmerBox(h: 200, r: 24, w: 320),
        ),
      ),
    ),
  ];
}

List<Widget> _buildErrorSlivers(String err) {
  return [
    SliverFillRemaining(
      hasScrollBody: false,
      child: _DashboardError(err: err),
    ),
  ];
}

class _ShimmerBox extends StatelessWidget {
  final double h, r, w;
  const _ShimmerBox({this.h = 16, this.r = 12, this.w = double.infinity});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
            scheme.surfaceContainerHighest.withOpacity(0.5),
            scheme.surfaceContainerHighest.withOpacity(0.3),
            scheme.surfaceContainerHighest.withOpacity(0.5),
          ]
              : [
            Colors.grey.shade200,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
        ),
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }
}

class _MetricCardData {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _MetricCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricCardData data;
  const _MetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            scheme.surface.withOpacity(0.8),
            scheme.surface.withOpacity(0.6),
          ]
              : [
            Colors.white.withOpacity(0.75),
            Colors.white.withOpacity(0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? scheme.outline.withOpacity(0.2)
              : scheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: data.gradient[0].withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: data.gradient),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: data.gradient[0].withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(data.icon, color: Colors.white, size: 18),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          data.value,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final IconData? icon;

  const _SectionTitle(this.text, {this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: scheme.onSecondary, size: 18),
          ),
          const SizedBox(width: 12),
        ],
        Text(
          text,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
            shadows: [
              Shadow(
                blurRadius: 6.0,
                color: Colors.black.withOpacity(0.4),
                offset: const Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionsBar extends ConsumerWidget {
  final String userId;
  final ShoppingList? lastActive;

  const _QuickActionsBar({required this.userId, required this.lastActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(shoppingListsViewModelProvider(userId).notifier);
    final scheme = Theme.of(context).colorScheme;

    void openListById(String listId, {ShoppingList? known}) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ListItemsScreen(
            shoppingListId: listId,
            onEditList: known == null
                ? null
                : () => showAddOrEditListDialog(
              context,
              ref,
              userId: userId,
              list: known,
            ),
          ),
        ),
      ).then((_) => ref.invalidate(dashboardViewModelProvider(userId)));
    }

    void duplicateLast() {
      final messenger = ScaffoldMessenger.of(context);
      if (lastActive == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Não há lista para duplicar.')),
        );
        return;
      }
      HapticFeedback.lightImpact();
      vm.duplicateListById(lastActive!.id, cloneItems: true).then((newId) {
        if (newId.isNotEmpty) {
          messenger.showSnackBar(
            SnackBar(content: Text('Lista duplicada: ${lastActive!.name}')),
          );
          openListById(newId);
        }
      });
    }

    Future<void> archiveCompleted() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Arquivar concluídas'),
          content: const Text('Arquivar todas as listas concluídas?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child:
              const Text('Arquivar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      final messenger = ScaffoldMessenger.of(context);
      final count = await vm.archiveCompletedLists();
      ref.invalidate(dashboardViewModelProvider(userId));
      messenger.showSnackBar(
        SnackBar(content: Text('Arquivadas $count lista(s).')),
      );
    }

    void openTemplates() {
      final messenger = ScaffoldMessenger.of(context);
      HapticFeedback.lightImpact();
      _showTemplatePicker(context, (template) async {
        final newId = await vm.createFromTemplate(
          name: template.name,
          budget: template.suggestedBudget,
          items: const [],
        );
        if (newId.isNotEmpty) {
          messenger.showSnackBar(
            SnackBar(content: Text('Lista criada: ${template.name}')),
          );
          openListById(newId);
        }
      });
    }

    void openAll() {
      ref.read(mainScreenIndexProvider.notifier).state = 1;
    }

    final actions = [
      _QuickAction(
        icon: Icons.add_circle_rounded,
        label: 'Nova lista',
        onTap: () {
          HapticFeedback.lightImpact();
          showAddOrEditListDialog(context, ref, userId: userId);
        },
        isPrimary: true,
      ),
      _QuickAction(
        icon: Icons.play_circle_rounded,
        label: 'Continuar',
        enabled: lastActive != null,
        onTap: lastActive == null
            ? null
            : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ListItemsScreen(
                shoppingListId: lastActive!.id,
                onEditList: () => showAddOrEditListDialog(context, ref,
                    userId: userId, list: lastActive),
              ),
            ),
          ).then(
                  (_) => ref.invalidate(dashboardViewModelProvider(userId)));
        },
      ),
      _QuickAction(
        icon: Icons.content_copy_rounded,
        label: 'Duplicar',
        onTap: duplicateLast,
      ),
      _QuickAction(
        icon: Icons.dashboard_rounded,
        label: 'Modelos',
        onTap: openTemplates,
      ),
      _QuickAction(
        icon: Icons.archive_rounded,
        label: 'Arquivar',
        onTap: archiveCompleted,
      ),
      _QuickAction(
        icon: Icons.list_alt_rounded,
        label: 'Ver todas',
        onTap: openAll,
      ),
    ];

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _QuickActionCard(action: actions[i]),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isPrimary;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.isPrimary = false,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabled = !action.enabled || action.onTap == null;

    return AnimatedOpacity(
      opacity: disabled ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          gradient: action.isPrimary
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.secondary,
              scheme.secondary.withOpacity(0.8),
            ],
          )
              : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              scheme.surface.withOpacity(0.8),
              scheme.surface.withOpacity(0.6),
            ]
                : [
              Colors.white.withOpacity(0.75),
              Colors.white.withOpacity(0.55),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: action.isPrimary
                ? Colors.transparent
                : isDark
                ? scheme.outline.withOpacity(0.2)
                : scheme.outline.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: action.isPrimary
                  ? scheme.secondary.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: disabled ? null : action.onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: action.isPrimary
                          ? Colors.white.withOpacity(0.2)
                          : scheme.secondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      action.icon,
                      color:
                      action.isPrimary ? Colors.white : scheme.onSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: action.isPrimary
                          ? Colors.white
                          : scheme.onSurface,
                      fontWeight: FontWeight.w700,
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

class _RecentHeader extends ConsumerWidget {
  final String userId;
  const _RecentHeader({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        const _SectionTitle('Listas Recentes', icon: Icons.history_rounded),
        const Spacer(),
        TextButton.icon(
          onPressed: () {
            ref.read(mainScreenIndexProvider.notifier).state = 1;
          },
          style: TextButton.styleFrom(
            foregroundColor: scheme.secondary,
          ),
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: Text(
            'Ver todas',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyRecent extends ConsumerWidget {
  final String userId;
  final String refetchKey;

  const _EmptyRecent({required this.userId, required this.refetchKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            scheme.surface.withOpacity(0.8),
            scheme.surface.withOpacity(0.6),
          ]
              : [
            Colors.white.withOpacity(0.75),
            Colors.white.withOpacity(0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? scheme.outline.withOpacity(0.2)
              : scheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                color: scheme.secondary,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhuma lista criada ainda',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Comece criando sua primeira lista de compras',
              style: TextStyle(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                showAddOrEditListDialog(context, ref, userId: userId);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Criar primeira lista'),
              style: FilledButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: scheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentHorizontalList extends StatelessWidget {
  final String userId;
  final List<ShoppingList> lists;

  const _RecentHorizontalList({required this.userId, required this.lists});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: lists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (ctx, i) =>
            _RecentListCard(userId: userId, list: lists[i]),
      ),
    );
  }
}

class _RecentListCard extends ConsumerWidget {
  final String userId;
  final ShoppingList list;

  const _RecentListCard({required this.userId, required this.list});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = list.isArchived;
    final statusText = isCompleted ? 'Concluída' : 'Pendente';
    final statusColor =
    isCompleted ? Colors.green : Theme.of(context).colorScheme.secondary;

    final budgetStr = list.budget == null
        ? null
        : NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
        .format(list.budget);

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 320,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              scheme.surface.withOpacity(0.8),
              scheme.surface.withOpacity(0.6),
            ]
                : [
              Colors.white.withOpacity(0.75),
              Colors.white.withOpacity(0.55),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? scheme.outline.withOpacity(0.2)
                : scheme.outline.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ListItemsScreen(
                    shoppingListId: list.id,
                    onEditList: () => showAddOrEditListDialog(context, ref,
                        userId: userId, list: list),
                  ),
                ),
              ).then((_) => ref.invalidate(dashboardViewModelProvider(userId)));
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shopping_basket_rounded,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('dd/MM/yyyy')
                                  .format(list.creationDate),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(text: statusText, color: statusColor),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progresso',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${(list.progress * 100).toInt()}%',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: list.progress,
                          minHeight: 8,
                          backgroundColor:
                          scheme.surfaceContainerHigh.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${list.checkedItems} de ${list.totalItems} itens',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          if (budgetStr != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? scheme.secondary.withOpacity(0.2)
                                    : scheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                budgetStr,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                  color: isDark
                                      ? scheme.secondary
                                      : scheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
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

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final String err;
  const _DashboardError({required this.err});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: scheme.errorContainer.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.error.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: scheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Ops! Algo deu errado',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                err,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showTemplatePicker(
    BuildContext context,
    Future<void> Function(_ListTemplate template) onSelect,
    ) {
  final templates = <_ListTemplate>[
    const _ListTemplate(
      key: 'compra_do_mes',
      name: 'Compra do mês',
      icon: Icons.calendar_month_rounded,
      suggestedBudget: 600.00,
    ),
    const _ListTemplate(
      key: 'churrasco',
      name: 'Churrasco',
      icon: Icons.outdoor_grill_rounded,
      suggestedBudget: 250.00,
    ),
    const _ListTemplate(
      key: 'cafe_da_manha',
      name: 'Café da manhã',
      icon: Icons.free_breakfast_rounded,
      suggestedBudget: 80.00,
    ),
    const _ListTemplate(
      key: 'limpeza_da_casa',
      name: 'Limpeza da casa',
      icon: Icons.cleaning_services_rounded,
      suggestedBudget: 120.00,
    ),
    const _ListTemplate(
      key: 'pet_shop',
      name: 'Pet Shop',
      icon: Icons.pets_rounded,
      suggestedBudget: 150.00,
    ),
  ];

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      final scheme = Theme.of(context).colorScheme;
      return SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: templates.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: scheme.outlineVariant),
          itemBuilder: (ctx, i) {
            final t = templates[i];
            final budgetText = t.suggestedBudget != null
                ? 'Sugestão: R\$ ${t.suggestedBudget!.toStringAsFixed(2)}'
                : '';
            return ListTile(
              leading: Icon(t.icon, color: scheme.secondary),
              title: Text(t.name, style: TextStyle(color: scheme.onSurface)),
              subtitle: budgetText.isEmpty
                  ? null
                  : Text(
                budgetText,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await onSelect(t);
              },
            );
          },
        ),
      );
    },
  );
}

class _ListTemplate {
  final String key;
  final String name;
  final IconData icon;
  final double? suggestedBudget;

  const _ListTemplate({
    required this.key,
    required this.name,
    required this.icon,
    this.suggestedBudget,
  });
}