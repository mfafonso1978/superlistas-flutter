// lib/presentation/views/stats/stats_screen.dart
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:superlistas/core/ui/theme/app_backgrounds.dart';
import 'package:superlistas/core/ui/widgets/shared_widgets.dart';
import 'package:superlistas/domain/entities/stats_data.dart';
import 'package:superlistas/presentation/providers/providers.dart';
import 'package:superlistas/presentation/views/main/main_screen.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authViewModelProvider);
    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userId = currentUser.id;
    final statsAsync = ref.watch(statsViewModelProvider(userId));
    final remoteConfig = ref.watch(remoteConfigServiceProvider);
    final pullToRefreshEnabled = remoteConfig.isStatsPullToRefreshEnabled;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _StatsBackground(),
          RefreshIndicator(
            onRefresh: pullToRefreshEnabled
                ? () =>
                ref.read(statsViewModelProvider(userId).notifier).loadStats()
                : () async {},
            child: CustomScrollView(
              slivers: [
                const _StatsSliverAppBar(),
                statsAsync.when(
                  loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator())),
                  error: (err, stack) => SliverFillRemaining(
                      child: Center(child: Text('Ocorreu um erro: $err'))),
                  data: (stats) {
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            if (remoteConfig.isStatsMetricsCardEnabled)
                              _buildMetricsCard(context, stats),
                            if (remoteConfig.isStatsMetricsCardEnabled &&
                                remoteConfig.isStatsBarChartEnabled)
                              const SizedBox(height: 24),
                            if (remoteConfig.isStatsBarChartEnabled)
                              _buildBarChartCard(context, stats),
                            if (remoteConfig.isStatsBarChartEnabled &&
                                remoteConfig.isStatsPieChartEnabled)
                              const SizedBox(height: 24),
                            if (remoteConfig.isStatsPieChartEnabled)
                              _buildPieChartCard(context, stats),
                          ],
                        ),
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
}

class _StatsBackground extends ConsumerWidget {
  const _StatsBackground();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedKey = ref.watch(backgroundProvider);
    final background = availableBackgrounds.firstWhere(
            (b) => b.key == selectedKey,
        orElse: () => availableBackgrounds.first);
    final imagePath = isDark ? background.darkAssetPath : background.lightAssetPath;

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

class _StatsSliverAppBar extends ConsumerWidget {
  const _StatsSliverAppBar();

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
        'Estatísticas',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: titleColor,
          fontSize: reducedFontSize,
        ),
      ),
    );
  }
}

Widget _buildMetricsCard(BuildContext context, StatsData stats) {
  final textTheme = Theme.of(context).textTheme;
  final scheme = Theme.of(context).colorScheme;

  return GlassCard(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        runAlignment: WrapAlignment.center,
        spacing: 24,
        runSpacing: 16,
        children: [
          _buildMetricItem(
            context,
            label: 'Itens Comprados',
            value: stats.totalItemsPurchased.toString(),
            icon: Icons.shopping_bag_outlined,
            iconColor: scheme.secondary,
            valueStyle: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
            labelStyle:
            textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          _buildMetricItem(
            context,
            label: 'Listas Concluídas',
            value: stats.completedLists.toString(),
            icon: Icons.check_circle_outline,
            iconColor: scheme.secondary,
            valueStyle: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
            labelStyle:
            textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          _buildMetricItem(
            context,
            label: 'Categoria Top',
            value: stats.topCategory?.name ?? '-',
            icon: stats.topCategory?.icon ?? Icons.help_outline,
            iconColor: scheme.secondary,
            valueStyle: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
            labelStyle:
            textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    ),
  );
}

Widget _buildMetricItem(
    BuildContext context, {
      required String label,
      required String value,
      required IconData icon,
      required Color iconColor,
      TextStyle? valueStyle,
      TextStyle? labelStyle,
    }) {
  final scheme = Theme.of(context).colorScheme;
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: iconColor, size: 28),
      const SizedBox(height: 8),
      Text(value, style: valueStyle ?? TextStyle(color: scheme.onSurface)),
      const SizedBox(height: 4),
      Text(label,
          textAlign: TextAlign.center,
          style: labelStyle ?? TextStyle(color: scheme.onSurfaceVariant)),
    ],
  );
}

Widget _buildBarChartCard(BuildContext context, StatsData stats) {
  final scheme = Theme.of(context).colorScheme;
  final labelStyle =
  Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant);

  final now = DateTime.now();
  final List<MapEntry<String, int>> monthlyData = [];
  for (int i = 5; i >= 0; i--) {
    final month = DateTime(now.year, now.month - i, 1);
    final key = DateFormat('yyyy-MM').format(month);
    monthlyData.add(MapEntry(key, stats.itemsByMonth[key] ?? 0));
  }

  return GlassCard(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Itens Comprados nos Últimos 6 Meses',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= monthlyData.length) {
                          return const SizedBox.shrink();
                        }
                        final key = monthlyData[idx].key;
                        final monthName = DateFormat('MMM', 'pt_BR')
                            .format(DateTime.parse('$key-01'));
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(monthName, style: labelStyle),
                        );
                      },
                    ),
                  ),
                  leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(monthlyData.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: monthlyData[index].value.toDouble(),
                        color: scheme.secondary,
                        width: 20,
                        borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildPieChartCard(BuildContext context, StatsData stats) {
  final scheme = Theme.of(context).colorScheme;
  final brightness = Theme.of(context).brightness;
  final categoryEntries = stats.itemsByCategory.entries.toList();

  final List<Color> pieColors = <Color>[
    scheme.secondary,
    scheme.primary,
    scheme.error,
    (brightness == Brightness.light ? Colors.indigo : scheme.inversePrimary),
    Colors.orange,
    Colors.pink,
    Colors.green,
    Colors.cyan,
    Colors.deepPurple,
    Colors.teal,
  ];

  return GlassCard(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: categoryEntries.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48.0),
          child: Text(
            'Nenhum item comprado para exibir estatísticas.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribuição por Categoria',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                height: 160,
                width: 160,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections:
                    List.generate(categoryEntries.length, (index) {
                      final entry = categoryEntries[index];
                      final percentage = stats.totalItemsPurchased > 0
                          ? (entry.value / stats.totalItemsPurchased) * 100
                          : 0.0;
                      return PieChartSectionData(
                        color: pieColors[index % pieColors.length],
                        value: entry.value.toDouble(),
                        title: '${percentage.toStringAsFixed(0)}%',
                        radius: 52,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                  List.generate(categoryEntries.length, (index) {
                    final entry = categoryEntries[index];
                    return Indicator(
                      color: pieColors[index % pieColors.length],
                      text: entry.key,
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}