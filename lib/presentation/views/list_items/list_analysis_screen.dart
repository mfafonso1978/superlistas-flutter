// lib/presentation/views/list_items/list_analysis_screen.dart
import 'package:auto_size_text/auto_size_text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:superlistas/core/ui/widgets/app_background.dart';
import 'package:superlistas/core/ui/widgets/shared_widgets.dart';
import 'package:superlistas/domain/entities/item.dart';
import 'package:superlistas/domain/entities/shopping_list.dart';
import 'package:superlistas/presentation/providers/providers.dart';

class ListAnalysisScreen extends ConsumerWidget {
  final ShoppingList shoppingList;

  const ListAnalysisScreen({super.key, required this.shoppingList});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // CORREÇÃO APLICADA AQUI: Observando o provider de dados correto.
    final itemsAsync = ref.watch(listItemsStreamProvider(shoppingList.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text(
          'Análise de "${shoppingList.name}"',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Stack(
        children: [
          AppBackground(),
          SafeArea(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Ocorreu um erro: $err')),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'Não há itens nesta lista para analisar.',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  );
                }
                return _buildAnalysisContent(context, items);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisContent(BuildContext context, List<Item> items) {
    final totalCost = items.fold(0.0, (sum, item) => sum + item.subtotal);
    final totalItems = items.length;
    final mostExpensiveItem =
    items.isNotEmpty ? items.reduce((a, b) => a.price > b.price ? a : b) : null;

    final Map<String, double> costByCategory = {};
    for (final item in items) {
      costByCategory.update(
        item.category.name,
            (value) => value + item.subtotal,
        ifAbsent: () => item.subtotal,
      );
    }

    final currencyFormat =
    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionHeader(context, 'Visão Geral'),
        _buildOverviewGrid(
          context,
          totalCost,
          totalItems,
          mostExpensiveItem,
          currencyFormat,
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(context, 'Custo por Categoria'),
        _buildPieChartCard(context, costByCategory, totalCost),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 4.0,
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(1.0, 1.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewGrid(
      BuildContext context,
      double totalCost,
      int totalItems,
      Item? mostExpensiveItem,
      NumberFormat currencyFormat,
      ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildOverviewCard(
          context: context,
          icon: Icons.monetization_on_outlined,
          label: 'Custo Total',
          value: currencyFormat.format(totalCost),
        ),
        _buildOverviewCard(
          context: context,
          icon: Icons.shopping_basket_outlined,
          label: 'Total de Itens',
          value: totalItems.toString(),
        ),
        _buildOverviewCard(
          context: context,
          icon: Icons.arrow_upward,
          label: 'Item Mais Caro',
          value: mostExpensiveItem?.name ?? '-',
        ),
        _buildOverviewCard(
          context: context,
          icon: Icons.attach_money,
          label: 'Preço Mais Alto',
          value: mostExpensiveItem != null
              ? currencyFormat.format(mostExpensiveItem.price)
              : '-',
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.secondary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: AutoSizeText(
                value,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
                maxLines: 3,
                minFontSize: 10,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartCard(
      BuildContext context,
      Map<String, double> costByCategory,
      double totalCost,
      ) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final categoryEntries = costByCategory.entries.toList();

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribuição de Custos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                        final percentage =
                        totalCost > 0 ? (entry.value / totalCost) * 100 : 0;
                        return PieChartSectionData(
                          color: pieColors[index % pieColors.length],
                          value: entry.value,
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
}