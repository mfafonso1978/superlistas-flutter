// lib/presentation/views/home/home_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:superlistas/core/ui/theme/app_backgrounds.dart';
import 'package:superlistas/core/ui/widgets/shared_widgets.dart';
import 'package:superlistas/domain/entities/dashboard_data.dart';
import 'package:superlistas/domain/entities/shopping_list.dart';
import 'package:superlistas/domain/entities/user.dart';
import 'package:superlistas/presentation/providers/providers.dart';
import 'package:superlistas/presentation/views/list_items/list_items_screen.dart';
import 'package:superlistas/presentation/views/main/main_screen.dart';

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
            color: Colors.black
                .withAlpha((255 * (isDark ? 0.35 : 0.15)).toInt()),
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

    final dashboardDataAsync =
    ref.watch(dashboardViewModelProvider(userId));
    final pullToRefreshEnabled =
        ref.watch(remoteConfigServiceProvider).isDashboardPullToRefreshEnabled;

    // =======================================================================
    // <<< CÓDIGO DE DIAGNÓSTICO ADICIONADO AQUI >>>
    // Este bloco vai capturar o erro exato e imprimir no console.
    // =======================================================================
    List<Widget> slivers;
    try {
      slivers = dashboardDataAsync.when(
        loading: () => _buildLoadingSlivers(context),
        error: (err, stack) {
          // Imprime o erro original no console para depuração
          print(">>>>>> ERRO CAPTURADO NO DASHBOARD VIEW MODEL: $err");
          print(">>>>>> STACK TRACE COMPLETO:");
          print(stack);
          return _buildErrorSlivers('$err');
        },
        data: (data) {
          if (data == null) {
            return _buildErrorSlivers('Os dados do dashboard retornaram nulos.');
          }
          return _buildDataSlivers(
            context: context,
            ref: ref,
            userId: userId,
            data: data,
          );
        },
      );
    } catch (e, s) {
      print(">>>>>> ERRO CRÍTICO CAPTURADO NO WIDGET BUILD: $e");
      print(">>>>>> STACK TRACE COMPLETO:");
      print(s);
      slivers = _buildErrorSlivers('$e');
    }
    // =======================================================================
    // FIM DO CÓDIGO DE DIAGNÓSTICO
    // =======================================================================

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: HomeBackground()),
          RefreshIndicator(
            onRefresh: pullToRefreshEnabled
                ? () => ref
                .read(dashboardViewModelProvider(userId).notifier)
                .loadData()
                : () async {},
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                _DashboardSliverAppBar(user: user),
                ...slivers, // Usando a lista de slivers que foi processada com segurança
                SliverPadding(
                  padding: EdgeInsets.only(
                    bottom: _contentBottomInset(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSliverAppBar extends ConsumerWidget {
  final User user;
  const _DashboardSliverAppBar({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today =
    DateFormat('EEEE, d \'de\' MMMM', 'pt_BR').format(DateTime.now());
    final isDark = theme.brightness == Brightness.dark;

    const double expandedHeight = kToolbarHeight + 64;
    const double collapsedHeight = kToolbarHeight;

    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.menu, color: scheme.onSurface),
        onPressed: () {
          final scaffoldKey = ref.read(mainScaffoldKeyProvider);
          scaffoldKey.currentState?.openDrawer();
        },
        tooltip: 'Menu',
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double statusBarHeight = MediaQuery.of(context).padding.top;
          final double maxHeight = expandedHeight + statusBarHeight;
          final double minHeight = collapsedHeight + statusBarHeight;
          final double currentHeight = constraints.maxHeight;

          final double shrinkProgress =
          ((maxHeight - currentHeight) / (maxHeight - minHeight))
              .clamp(0.0, 1.0);

          final double dateOpacity =
          (1.0 - shrinkProgress).clamp(0.0, 1.0);
          final double topPadding = 8.0 - (shrinkProgress * 6.0);
          final double bottomPadding = 10.0 - (shrinkProgress * 8.0);
          final double textSpacing = 4.0 * (1.0 - shrinkProgress);

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF344049)
                      : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: scheme.onSurface
                          .withAlpha((255 * 0.08).toInt()),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        60, topPadding, 16, bottomPadding),
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.centerLeft,
                              maxHeight: double.infinity,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Olá, ${user.name} 👋',
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: scheme.onSurface,
                                        letterSpacing: -0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.clip,
                                    ),
                                  ),
                                  if (textSpacing > 0.1)
                                    SizedBox(height: textSpacing),
                                  if (dateOpacity > 0.01)
                                    Opacity(
                                      opacity: dateOpacity,
                                      child: Text(
                                        today[0].toUpperCase() +
                                            today.substring(1),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: scheme.onSurface
                                              .withAlpha(
                                              (255 * 0.8).toInt()),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.clip,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: 26,
                          backgroundColor:
                          scheme.secondary.withAlpha(50),
                          child: user.photoUrl == null
                              ? Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : 'U',
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
                              errorBuilder:
                                  (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  color: scheme.secondary,
                                  size: 30,
                                );
                              },
                              loadingBuilder: (context, child,
                                  loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                return Center(
                                  child:
                                  CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: loadingProgress
                                        .expectedTotalBytes !=
                                        null
                                        ? loadingProgress
                                        .cumulativeBytesLoaded /
                                        loadingProgress
                                            .expectedTotalBytes!
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
          );
        },
      ),
    );
  }
}

List<Widget> _buildDataSlivers({
  required BuildContext context,
  required WidgetRef ref,
  required String userId,
  required DashboardData data,
}) {
  final remoteConfig = ref.watch(remoteConfigServiceProvider);
  final metricsEnabled = remoteConfig.isDashboardMetricsEnabled;
  final quickActionsEnabled =
      remoteConfig.isDashboardQuickActionsEnabled;
  final recentListsEnabled =
      remoteConfig.isDashboardRecentListsEnabled;

  final recent = data.recentLists;
  final ShoppingList? lastActive = recent
      .where((l) => !l.isCompleted && !l.isArchived)
      .isNotEmpty
      ? recent.firstWhere(
        (l) => !l.isCompleted && !l.isArchived,
  )
      : (recent.isNotEmpty ? recent.first : null);

  return [
    if (metricsEnabled) ...[
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
    ],
    if (quickActionsEnabled) ...[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
          child: const _SectionTitle('Ações Rápidas',
              icon: Icons.flash_on_rounded),
        ),
      ),
      SliverToBoxAdapter(
        child: _QuickActionsBar(userId: userId, lastActive: lastActive),
      ),
    ],
    if (recentListsEnabled) ...[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
          child: _RecentHeader(userId: userId),
        ),
      ),
      if (data.recentLists.isEmpty)
        SliverToBoxAdapter(
          child: _EmptyShoppingListHome(
            assetPath: 'assets/images/cesta.jpg',
            userId: userId,
          ),
        )
      else
        SliverToBoxAdapter(
          child: _RecentHorizontalList(
            userId: userId,
            lists: data.recentLists,
          ),
        ),
    ],
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
        children:
        List.generate(4, (_) => const _ShimmerBox(h: 100, r: 20)),
      ),
    ),
    const SliverToBoxAdapter(child: SizedBox(height: 24)),
    const SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverToBoxAdapter(
          child: _ShimmerBox(h: 24, r: 8, w: 160)),
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
          itemBuilder: (_, __) =>
          const _ShimmerBox(h: 120, r: 20, w: 100),
        ),
      ),
    ),
    const SliverToBoxAdapter(child: SizedBox(height: 24)),
    const SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverToBoxAdapter(
          child: _ShimmerBox(h: 24, r: 8, w: 180)),
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
          itemBuilder: (_, __) =>
          const _ShimmerBox(h: 200, r: 24, w: 320),
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
            scheme.surfaceContainerHighest
                .withAlpha((255 * 0.5).toInt()),
            scheme.surfaceContainerHighest
                .withAlpha((255 * 0.3).toInt()),
            scheme.surfaceContainerHighest
                .withAlpha((255 * 0.5).toInt()),
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
            scheme.surface.withAlpha((255 * 0.8).toInt()),
            scheme.surface.withAlpha((255 * 0.6).toInt()),
          ]
              : [
            Colors.white.withAlpha((255 * 0.75).toInt()),
            Colors.white.withAlpha((255 * 0.55).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? scheme.outline.withAlpha((255 * 0.2).toInt())
              : scheme.outline.withAlpha((255 * 0.1).toInt()),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: data.gradient[0].withAlpha((255 * 0.1).toInt()),
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
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: data.gradient),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: data.gradient[0]
                                .withAlpha((255 * 0.3).toInt()),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(data.icon,
                          color: Colors.white, size: 18),
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
                  style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
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
              const Shadow(
                blurRadius: 6.0,
                color: Colors.black45,
                offset: Offset(2.0, 2.0),
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

  const _QuickActionsBar(
      {required this.userId, required this.lastActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm =
    ref.read(shoppingListsViewModelProvider(userId).notifier);

    final remoteConfig = ref.watch(remoteConfigServiceProvider);
    final addListEnabled = remoteConfig.isAddListEnabled;
    final duplicateListEnabled = remoteConfig.isDuplicateListEnabled;
    final templatesEnabled = remoteConfig.isTemplatesEnabled;
    final archiveEnabled = remoteConfig.isArchiveListEnabled;
    final viewAllEnabled =
        ref.watch(remoteConfigServiceProvider).isShoppingListsScreenEnabled;

    void openListById(String listId, {ShoppingList? known}) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ListItemsScreen(
            shoppingListId: listId,
          ),
        ),
      ).then((_) =>
          ref.invalidate(dashboardViewModelProvider(userId)));
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
          content:
          const Text('Arquivar todas as listas concluídas?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Arquivar',
                  style: TextStyle(color: Colors.white)),
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
      final listsTabIndex = ref
          .read(remoteConfigServiceProvider)
          .isDashboardScreenEnabled
          ? 1
          : 0;
      ref.read(mainScreenIndexProvider.notifier).state = listsTabIndex;
    }

    final List<_QuickAction> actions = [
      if (addListEnabled)
        _QuickAction(
          icon: Icons.add_circle_rounded,
          label: 'Nova lista',
          onTap: () {
            HapticFeedback.lightImpact();
            showAddOrEditListDialog(
                context: context, ref: ref, userId: userId);
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
              ),
            ),
          ).then((_) =>
              ref.invalidate(dashboardViewModelProvider(userId)));
        },
      ),
      if (duplicateListEnabled)
        _QuickAction(
          icon: Icons.content_copy_rounded,
          label: 'Duplicar',
          onTap: duplicateLast,
        ),
      if (templatesEnabled)
        _QuickAction(
          icon: Icons.dashboard_rounded,
          label: 'Modelos',
          onTap: openTemplates,
        ),
      if (archiveEnabled)
        _QuickAction(
          icon: Icons.archive_rounded,
          label: 'Arquivar',
          onTap: archiveCompleted,
        ),
      if (viewAllEnabled)
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
        itemBuilder: (_, i) =>
            _QuickActionCard(action: actions[i]),
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
              scheme.secondary
                  .withAlpha((255 * 0.8).toInt()),
            ],
          )
              : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              scheme.surface
                  .withAlpha((255 * 0.8).toInt()),
              scheme.surface
                  .withAlpha((255 * 0.6).toInt()),
            ]
                : [
              Colors.white
                  .withAlpha((255 * 0.75).toInt()),
              Colors.white
                  .withAlpha((255 * 0.55).toInt()),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: action.isPrimary
                ? Colors.transparent
                : isDark
                ? scheme.outline
                .withAlpha((255 * 0.2).toInt())
                : scheme.outline
                .withAlpha((255 * 0.1).toInt()),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: action.isPrimary
                  ? scheme.secondary
                  .withAlpha((255 * 0.3).toInt())
                  : Colors.black
                  .withAlpha((255 * 0.05).toInt()),
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
                          ? Colors.white
                          .withAlpha((255 * 0.2).toInt())
                          : scheme.secondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      action.icon,
                      color: action.isPrimary
                          ? Colors.white
                          : scheme.onSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style:
                    Theme.of(context).textTheme.labelMedium?.copyWith(
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
        const _SectionTitle('Listas Recentes',
            icon: Icons.history_rounded),
        const Spacer(),
        if (ref
            .watch(remoteConfigServiceProvider)
            .isShoppingListsScreenEnabled)
          TextButton.icon(
            onPressed: () {
              final listsTabIndex = ref
                  .read(remoteConfigServiceProvider)
                  .isDashboardScreenEnabled
                  ? 1
                  : 0;
              ref.read(mainScreenIndexProvider.notifier).state =
                  listsTabIndex;
            },
            style: TextButton.styleFrom(
              foregroundColor: scheme.secondary,
            ),
            icon:
            const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text(
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

class _RecentHorizontalList extends StatelessWidget {
  final String userId;
  final List<ShoppingList> lists;

  const _RecentHorizontalList(
      {required this.userId, required this.lists});

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
    final statusColor = isCompleted
        ? Colors.green
        : Theme.of(context).colorScheme.secondary;

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
              scheme.surface.withAlpha((255 * 0.8).toInt()),
              scheme.surface.withAlpha((255 * 0.6).toInt()),
            ]
                : [
              Colors.white.withAlpha((255 * 0.75).toInt()),
              Colors.white.withAlpha((255 * 0.55).toInt()),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? scheme.outline.withAlpha((255 * 0.2).toInt())
                : scheme.outline.withAlpha((255 * 0.1).toInt()),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withAlpha((255 * 0.05).toInt()),
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
                  ),
                ),
              ).then((_) =>
                  ref.invalidate(dashboardViewModelProvider(userId)));
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
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
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
                                color:
                                scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(
                          text: statusText, color: statusColor),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progresso',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                              color:
                              scheme.onSurfaceVariant,
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
                          backgroundColor: scheme
                              .surfaceContainerHigh
                              .withAlpha((255 * 0.3).toInt()),
                          valueColor:
                          AlwaysStoppedAnimation<Color>(
                              statusColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${list.checkedItems} de ${list.totalItems} itens',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              color:
                              scheme.onSurfaceVariant,
                            ),
                          ),
                          if (budgetStr != null)
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? scheme.secondary
                                    .withAlpha(
                                    (255 * 0.2).toInt())
                                    : scheme.primary.withAlpha(
                                    (255 * 0.1).toInt()),
                                borderRadius:
                                BorderRadius.circular(8),
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
                                  fontWeight:
                                  FontWeight.w700,
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
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            color: scheme.errorContainer
                .withAlpha((255 * 0.1).toInt()),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: scheme.error
                    .withAlpha((255 * 0.3).toInt())),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: scheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Ops! Algo deu errado',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                err,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: scheme.onSurfaceVariant),
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
              title: Text(t.name,
                  style: TextStyle(color: scheme.onSurface)),
              subtitle: budgetText.isEmpty
                  ? null
                  : Text(
                budgetText,
                style: TextStyle(
                    color: scheme.onSurfaceVariant),
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

class _EmptyShoppingListHome extends ConsumerWidget {
  final String assetPath;
  final String userId;

  const _EmptyShoppingListHome({
    required this.assetPath,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canCreateList =
        ref.watch(remoteConfigServiceProvider).isAddListEnabled;
    final colorScheme = theme.colorScheme;

    final Color glassColor = (isDark ? const Color(0xFF2C3A43) : Colors.white)
        .withAlpha((255 * 0.85).toInt());

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: glassColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withAlpha((255 * 0.06).toInt()),
                  width: 1,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    glassColor,
                    glassColor.withAlpha(isDark
                        ? (255 * 0.75).toInt()
                        : (255 * 0.9).toInt()),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((255 * 0.18).toInt()),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((255 * 0.15).toInt()),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        assetPath,
                        width: 240,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (context, error, stack) =>
                        const Icon(Icons.image_not_supported_outlined, size: 80),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Nenhuma lista de compras criada',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Crie sua primeira lista e comece a planejar suas compras com praticidade!',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (canCreateList)
                    FilledButton.icon(
                      onPressed: () {
                        showAddOrEditListDialog(
                          context: context,
                          ref: ref,
                          userId: userId,
                        );
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Criar nova lista'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                      ),
                    ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: (isDark
                          ? Colors.teal.shade900
                          : Colors.teal.shade50)
                          .withAlpha(isDark ? (255 * 0.6).toInt() : 255),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isDark
                            ? Colors.tealAccent
                            : Colors.teal)
                            .withAlpha((255 * 0.35).toInt()),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Dica: use modelos prontos ou duplique uma lista anterior!',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
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
    );
  }
}