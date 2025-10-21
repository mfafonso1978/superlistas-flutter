// lib/presentation/views/list_items/list_items_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:superlistas/core/errors/exceptions.dart';
import 'package:superlistas/core/ui/widgets/app_background.dart';
import 'package:superlistas/core/ui/widgets/currency_input_formatter.dart';
import 'package:superlistas/core/ui/widgets/glass_dialog.dart';
import 'package:superlistas/core/ui/widgets/shared_widgets.dart';
import 'package:superlistas/domain/entities/category.dart';
import 'package:superlistas/domain/entities/item.dart';
import 'package:superlistas/domain/entities/shopping_list.dart';
import 'package:superlistas/domain/entities/user_product.dart';
import 'package:superlistas/presentation/providers/providers.dart';
import 'package:superlistas/presentation/viewmodels/list_items_viewmodel.dart';
import 'package:superlistas/presentation/views/list_items/list_analysis_screen.dart';
import 'package:superlistas/presentation/views/premium/premium_screen.dart';
import 'package:superlistas/data/models/category_model.dart'; // Import necessário

// Provider de unidades
final unitsProvider = FutureProvider.autoDispose<List<String>>((ref) {
  return ref.watch(shoppingListRepositoryProvider).getAllUnits();
});

// Função para mostrar a tela Premium
void _showPremiumUpsell(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const PremiumScreen()),
  );
}

class ListItemsScreen extends ConsumerWidget {
  final String shoppingListId;

  const ListItemsScreen({super.key, required this.shoppingListId});

  // Função _scanBarcode
  Future<void> _scanBarcode(BuildContext context, WidgetRef ref, ShoppingList shoppingList) async {
    final isPremium = ref.read(remoteConfigServiceProvider).isUserPremium;
    if (!isPremium) {
      _showPremiumUpsell(context);
      return;
    }

    final viewModel = ref.read(listItemsViewModelProvider(shoppingList.id).notifier);
    final items = ref.read(listItemsStreamProvider(shoppingList.id)).value ?? [];
    final double currentTotalCost = items.fold(0.0, (sum, item) => sum + item.subtotal);

    try {
      final String? barcode = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => const _BarcodeScannerScreen(),
        ),
      );

      if (barcode == null || barcode.isEmpty || !context.mounted) return;

      final UserProduct? existingProduct = await viewModel.processBarcode(barcode);

      if (!context.mounted) return;

      final Item itemToOpen;
      final categories = await ref.read(categoriesProvider.future);

      if (!context.mounted) return;

      if (existingProduct != null) {
        final category = categories.firstWhere(
              (c) => c.id == existingProduct.categoryId,
          orElse: () => categories.isNotEmpty ? categories.first : CategoryModel.uncategorized(),
        );
        itemToOpen = Item(
          id: '',
          name: existingProduct.productName,
          category: category,
          price: existingProduct.price ?? 0.0,
          quantity: 1.0,
          unit: existingProduct.unit ?? 'un',
          notes: existingProduct.notes ?? '',
          isChecked: false,
          barcode: existingProduct.barcode,
        );
      } else {
        itemToOpen = Item(
          id: '',
          name: '',
          category: categories.isNotEmpty ? categories.first : CategoryModel.uncategorized(),
          price: 0.0,
          quantity: 1.0,
          unit: 'un',
          notes: '',
          isChecked: false,
          barcode: barcode,
        );
      }

      _showItemFormModal(
        context,
        ref,
        shoppingList,
        currentTotalCost: currentTotalCost,
        item: itemToOpen,
        scannedBarcode: barcode,
      );
    } catch (e) {
      if (context.mounted) {
        await showGlassDialog(
          context: context,
          title: const Text('Erro ao escanear'),
          content: Text('$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      }
    }
  }

  // Função _showItemFormModal
  void _showItemFormModal(
      BuildContext context,
      WidgetRef ref,
      ShoppingList shoppingList, {
        required double currentTotalCost,
        Item? item,
        String? scannedBarcode,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color glassColor = (isDark ? theme.colorScheme.surface : Colors.white).withAlpha((255 * 0.85).toInt());

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha((255 * 0.5).toInt()), // Usa withAlpha
      builder: (sheetContext) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                color: glassColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: _AddItemForm(
                  shoppingList: shoppingList,
                  currentTotalCost: currentTotalCost,
                  item: item,
                  scannedBarcode: scannedBarcode,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Função _groupItems
  Map<String, List<Item>> _groupItems(List<Item> items) {
    final Map<String, List<Item>> groupedItems = {};
    for (final item in items) {
      groupedItems.putIfAbsent(item.category.name, () => []);
      groupedItems[item.category.name]!.add(item);
    }
    groupedItems.forEach((key, value) {
      value.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    });
    final sortedKeys = groupedItems.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return {for (var key in sortedKeys) key: groupedItems[key]!};
  }

  // Método build principal
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListAsync = ref.watch(singleListProvider(shoppingListId));
    final remoteConfig = ref.watch(remoteConfigServiceProvider);
    final addItemEnabled = remoteConfig.isAddItemEnabled;

    return shoppingListAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(appBar: AppBar(), body: Center(child: Text('Erro ao carregar a lista: $err'))),
      data: (shoppingList) {
        final itemsAsync = ref.watch(listItemsStreamProvider(shoppingList.id));
        final viewModel = ref.read(listItemsViewModelProvider(shoppingList.id).notifier);

        final bool isReadOnly = shoppingList.isArchived;

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              const AppBackground(),
              itemsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Ocorreu um erro: $err')),
                data: (items) {
                  final double totalCost = items.fold(0.0, (sum, item) => sum + item.subtotal);

                  return CustomScrollView(
                    slivers: [
                      _ItemsSliverAppBar(
                        shoppingList: shoppingList,
                        items: items,
                        viewModel: viewModel,
                        isReadOnly: isReadOnly,
                        onScanPressed: () => _scanBarcode(context, ref, shoppingList),
                      ),
                      if (items.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyListPlaceholder(
                            isReadOnly: isReadOnly,
                            assetPath: 'assets/images/empty_list.png',
                          ),
                        )
                      else
                        _buildGroupedList(items, viewModel, shoppingList, totalCost, isReadOnly),
                      SliverPadding(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom + 80),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          floatingActionButton: (addItemEnabled && !isReadOnly)
              ? itemsAsync.when(
            data: (items) {
              final double totalCost = items.fold(0.0, (sum, item) => sum + item.subtotal);
              final bool hasBudget = shoppingList.budget != null && shoppingList.budget! > 0;
              final bool budgetExceeded = hasBudget && totalCost >= shoppingList.budget!;

              return FloatingActionButton(
                onPressed: budgetExceeded
                    ? null
                    : () => _showItemFormModal(context, ref, shoppingList, currentTotalCost: totalCost),
                backgroundColor: budgetExceeded ? Colors.grey : Theme.of(context).colorScheme.secondary,
                shape: const CircleBorder(),
                child: const Icon(Icons.add),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  // Função _buildGroupedList
  Widget _buildGroupedList(
      List<Item> items,
      ListItemsViewModel viewModel,
      ShoppingList shoppingList,
      double totalCost,
      bool isReadOnly,
      ) {
    final groupedItems = _groupItems(items);
    final categoryNames = groupedItems.keys.toList();

    return SliverList.builder(
      itemCount: categoryNames.length,
      itemBuilder: (context, index) {
        final categoryName = categoryNames[index];
        final itemsInCategory = groupedItems[categoryName]!;
        final categoryColor = itemsInCategory.first.category.colorValue;
        final categoryIcon = itemsInCategory.first.category.icon;
        final double categorySubtotal = itemsInCategory.fold(0.0, (sum, item) => sum + item.subtotal);

        final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
        final formattedSubtotal = currencyFormat.format(categorySubtotal);

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final headerColor = categoryColor;
        final headerTextColor = headerColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
        final subHeaderColor = theme.colorScheme.secondary;

        final List<Widget> childrenWithDividers = [];
        for (int i = 0; i < itemsInCategory.length; i++) {
          final item = itemsInCategory[i];
          childrenWithDividers.add(
            _buildItemTile(context, totalCost, item, viewModel, shoppingList, isReadOnly),
          );
          if (i < itemsInCategory.length - 1) {
            childrenWithDividers.add(
              Divider(
                height: 1,
                thickness: 1,
                color: (isDark ? Colors.white : theme.colorScheme.primary).withAlpha((255 * 0.15).toInt()), // Usa withAlpha
                indent: 16,
                endIndent: 16,
              ),
            );
          }
        }

        return GlassCard(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: ExpansionTile(
            backgroundColor: headerColor.withAlpha((255 * 0.1).toInt()), // Usa withAlpha
            collapsedBackgroundColor: Colors.transparent,
            iconColor: headerTextColor,
            collapsedIconColor: headerColor,
            initiallyExpanded: true,
            leading: Icon(categoryIcon, color: headerColor),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    categoryName,
                    style: TextStyle(color: headerColor, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  formattedSubtotal,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: subHeaderColor,
                    shadows: const [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 3,
                        offset: Offset(1, 1),
                      )
                    ],
                  ),
                ),
              ],
            ),
            children: childrenWithDividers,
          ),
        );
      },
    );
  }

  // Função _buildItemTile
  Widget _buildItemTile(
      BuildContext context,
      double currentTotalCost,
      Item item,
      ListItemsViewModel viewModel,
      ShoppingList shoppingList,
      bool isReadOnly,
      ) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final quantityFormat = NumberFormat();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color primaryColor = scheme.primary;
    final itemTitleColor = isDark
        ? (item.isChecked ? Colors.white54 : Colors.white)
        : (item.isChecked ? primaryColor.withAlpha((255 * 0.5).toInt()) : primaryColor);
    final itemSubtitleColor = isDark ? Colors.white70 : primaryColor.withAlpha((255 * 0.7).toInt());
    final itemIconColor = isDark ? Colors.white70 : primaryColor.withAlpha((255 * 0.6).toInt());

    return Consumer(builder: (context, ref, child) {
      final remoteConfig = ref.watch(remoteConfigServiceProvider);
      final checkEnabled = remoteConfig.isCheckItemEnabled && !isReadOnly;
      final editEnabled = remoteConfig.isEditItemEnabled && !isReadOnly;
      final deleteEnabled = remoteConfig.isDeleteItemEnabled && !isReadOnly;

      return Dismissible(
        key: Key(item.id),
        direction: deleteEnabled ? DismissDirection.endToStart : DismissDirection.none,
        confirmDismiss: deleteEnabled
            ? (direction) async {
          final bool? shouldDelete = await showGlassDialog<bool>(
            context: context,
            title: const Row(
              children: [
                Icon(Icons.delete_forever_rounded, color: Colors.red),
                SizedBox(width: 12),
                Text('Excluir Item'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      const TextSpan(text: 'Tem certeza que deseja excluir '),
                      TextSpan(
                        text: '"${item.name}"',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: '?'),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Excluir'),
              ),
            ],
          );
          if (shouldDelete == true) {
            await viewModel.deleteItem(item.id);
          }
          return shouldDelete ?? false;
        }
            : null,
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: const Icon(Icons.delete_forever, color: Colors.white),
        ),
        onDismissed: null,
        child: CheckboxListTile(
          activeColor: scheme.secondary,
          checkColor: scheme.onSecondary,
          controlAffinity: ListTileControlAffinity.leading,
          value: item.isChecked,
          onChanged: checkEnabled
              ? (bool? newValue) {
            final updatedItem = item.copyWith(isChecked: newValue ?? false);
            viewModel.updateItem(updatedItem);
          }
              : null,
          title: Text(
            item.name,
            style: TextStyle(
              decoration: item.isChecked ? TextDecoration.lineThrough : TextDecoration.none,
              color: itemTitleColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${quantityFormat.format(item.quantity)} ${item.unit}  •  ${currencyFormat.format(item.price)}/${item.unit}',
                style: TextStyle(color: itemSubtitleColor),
              ),
              Text(
                'Subtotal: ${currencyFormat.format(item.subtotal)}',
                style: TextStyle(color: itemSubtitleColor, fontWeight: FontWeight.w500),
              ),
              if (item.notes != null && item.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Obs: ${item.notes}',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: itemSubtitleColor.withAlpha((255 * 0.8).toInt())), // Usa withAlpha
                  ),
                ),
            ],
          ),
          secondary: editEnabled
              ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit_outlined, color: itemIconColor),
                onPressed: () {
                  _showItemFormModal(context, ref, shoppingList, currentTotalCost: currentTotalCost, item: item);
                },
              ),
            ],
          )
              : null,
        ),
      );
    });
  }
}

// Widget _BarcodeScannerScreen
class _BarcodeScannerScreen extends StatefulWidget {
  const _BarcodeScannerScreen();

  @override
  State<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool isFlashOn = false;
  CameraFacing currentFacing = CameraFacing.back;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código de Barras'),
        actions: [
          IconButton(
            icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off, color: isFlashOn ? Colors.yellow : Colors.white),
            onPressed: () {
              controller.toggleTorch();
              setState(() {
                isFlashOn = !isFlashOn;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () {
              controller.switchCamera();
              setState(() {
                currentFacing = (currentFacing == CameraFacing.back) ? CameraFacing.front : CameraFacing.back;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (BarcodeCapture capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null && code.isNotEmpty) {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context, code);
                }
              }
            },
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 250,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                  child: const Text(
                    'Posicione o código de barras na área',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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

// Widget _ItemsSliverAppBar
class _ItemsSliverAppBar extends ConsumerWidget {
  final ShoppingList shoppingList;
  final List<Item> items;
  final ListItemsViewModel viewModel;
  final bool isReadOnly;
  final VoidCallback onScanPressed;

  const _ItemsSliverAppBar({
    required this.shoppingList,
    required this.items,
    required this.viewModel,
    required this.isReadOnly,
    required this.onScanPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final remoteConfig = ref.watch(remoteConfigServiceProvider);
    final isPremium = remoteConfig.isUserPremium;
    final archiveEnabled = remoteConfig.isArchiveListEnabled && !isReadOnly;
    final editListEnabled = remoteConfig.isEditListEnabled && !isReadOnly;
    final analysisEnabled = remoteConfig.isListAnalysisScreenEnabled;
    final reuseListEnabled = remoteConfig.isReuseListEnabled && isReadOnly;
    final financialSummaryEnabled = remoteConfig.isFinancialSummaryBarEnabled;
    final scannerEnabled = !isReadOnly;

    final checkedItemsCount = items.where((item) => item.isChecked).length;
    final bool isConcludeEnabled = archiveEnabled && checkedItemsCount > 0 && !shoppingList.isArchived;

    final Color foregroundColor = isDark ? Colors.white : Colors.black;
    final Color backgroundColor = isDark ? const Color(0xFF344049) : Colors.white;

    final baseFontSize = theme.textTheme.headlineSmall?.fontSize ?? 24.0;
    final reducedFontSize = baseFontSize * 0.7;

    final double totalCost = items.fold(0.0, (sum, item) => sum + item.subtotal);
    final double purchasedTotal = items.where((item) => item.isChecked).fold(0.0, (sum, item) => sum + item.subtotal);

    return SliverAppBar(
      pinned: true,
      elevation: 1,
      shadowColor: Colors.black.withAlpha(50), // Usa withAlpha
      iconTheme: IconThemeData(color: foregroundColor),
      actionsIconTheme: IconThemeData(color: foregroundColor),
      backgroundColor: backgroundColor,
      surfaceTintColor: backgroundColor,
      title: Row(
        children: [
          Expanded(
            child: Text(
              shoppingList.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w800,
                fontSize: reducedFontSize,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isReadOnly)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha((255 * 0.2).toInt()), // Usa withAlpha
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange, width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: Colors.orange),
                  SizedBox(width: 4),
                  Text(
                    'Somente Leitura',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        // <<< ÍCONE CORRIGIDO PARA SER SEMPRE O SCANNER >>>
        if (scannerEnabled)
          IconButton(
            icon: const Icon(Icons.qr_code_scanner), // Sempre mostra o ícone do scanner
            onPressed: isPremium ? onScanPressed : () => _showPremiumUpsell(context),
            tooltip: isPremium ? 'Escanear código de barras' : 'Funcionalidade Premium',
          ),
        if (archiveEnabled || editListEnabled || analysisEnabled || reuseListEnabled)
          PopupMenuButton<String>(
            onSelected: (value) async {
              // Lógica onSelected (sem alteração)
              if (value == 'complete') {
                final bool? confirm = await showGlassDialog<bool>(
                  context: context,
                  title: const Text('Concluir Compra'),
                  content: const Text('Tem certeza que deseja mover esta lista para o seu histórico?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Sim, Concluir'),
                    ),
                  ],
                );
                if (confirm == true) {
                  await ref.read(shoppingListsViewModelProvider(shoppingList.ownerId).notifier).archiveList(shoppingList);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lista movida para o Histórico!')),
                  );
                }
              } else if (value == 'edit') {
                showAddOrEditListDialog(
                  context: context,
                  ref: ref,
                  userId: shoppingList.ownerId,
                  list: shoppingList,
                );
              } else if (value == 'analysis') {
                if (isPremium) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ListAnalysisScreen(shoppingList: shoppingList)),
                  );
                } else {
                  _showPremiumUpsell(context);
                }
              } else if (value == 'reuse') {
                if (isPremium) {
                  await ref.read(historyViewModelProvider(shoppingList.ownerId).notifier).reuseList(shoppingList);
                  if (!context.mounted) return;
                  ref.invalidate(shoppingListsStreamProvider(shoppingList.ownerId));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lista "${shoppingList.name}" reutilizada com sucesso!')),
                  );
                } else {
                  _showPremiumUpsell(context);
                }
              }
            },
            itemBuilder: (BuildContext context) {
              final theme = Theme.of(context);
              final iconColor = theme.colorScheme.onSurface.withAlpha((255 * 0.7).toInt()); // Usa withAlpha

              final List<PopupMenuEntry<String>> menuItems = [];

              if (reuseListEnabled) {
                menuItems.add(
                  PopupMenuItem<String>(
                    value: 'reuse',
                    child: IconTheme(
                      data: IconThemeData(color: iconColor),
                      child: Row(
                        children: [
                          Icon(isPremium ? Icons.copy_all_rounded : Icons.lock_outline),
                          const SizedBox(width: 12),
                          const Text('Reutilizar Lista'),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (archiveEnabled) {
                menuItems.add(
                  PopupMenuItem<String>(
                    value: 'complete',
                    enabled: isConcludeEnabled,
                    child: IconTheme(
                      data: IconThemeData(color: iconColor),
                      child: const Row(
                        children: [
                          Icon(Icons.archive_outlined),
                          SizedBox(width: 12),
                          Text('Concluir compra'),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (editListEnabled) {
                menuItems.add(
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: IconTheme(
                      data: IconThemeData(color: iconColor),
                      child: const Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 12),
                          Text('Editar Lista'),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (analysisEnabled) {
                menuItems.add(
                  PopupMenuItem<String>(
                    value: 'analysis',
                    child: IconTheme(
                      data: IconThemeData(color: iconColor),
                      child: Row(
                        children: [
                          Icon(isPremium ? Icons.analytics_outlined : Icons.lock_outline),
                          const SizedBox(width: 12),
                          const Text('Análise da Lista'),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return menuItems;
            },
          ),
      ],
      bottom: financialSummaryEnabled
          ? PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: _FinancialSummaryBar(
          shoppingList: shoppingList,
          totalCost: totalCost,
          purchasedTotal: purchasedTotal,
          backgroundColor: backgroundColor,
        ),
      )
          : null,
    );
  }
}

// ... (Restante do código: _FinancialSummaryBar, _FinancialInfoCard, _AddItemForm, _AddItemFormState, _EmptyListPlaceholder) ...
// Widget _FinancialSummaryBar (sem alteração)
class _FinancialSummaryBar extends StatelessWidget {
  final ShoppingList shoppingList;
  final double totalCost;
  final double purchasedTotal;
  final Color backgroundColor;

  const _FinancialSummaryBar({
    required this.shoppingList,
    required this.totalCost,
    required this.purchasedTotal,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final bool hasBudget = shoppingList.budget != null && shoppingList.budget! > 0;
    final double balance = hasBudget ? shoppingList.budget! - totalCost : 0.0;

    final Color totalBgColor = isDark ? Colors.blue.shade900.withAlpha((255 * 0.3).toInt()) : Colors.blue.shade50;
    final Color purchasedBgColor = isDark ? Colors.teal.shade900.withAlpha((255 * 0.3).toInt()) : Colors.teal.shade50;
    final Color budgetBgColor = isDark ? Colors.purple.shade900.withAlpha((255 * 0.3).toInt()) : Colors.purple.shade50;

    Color balanceBgColor;
    if (balance < 0) {
      balanceBgColor = isDark ? Colors.red.shade900.withAlpha((255 * 0.3).toInt()) : Colors.red.shade50;
    } else if (hasBudget && shoppingList.budget! > 0 && balance <= shoppingList.budget! * 0.10) {
      balanceBgColor = isDark ? Colors.orange.shade900.withAlpha((255 * 0.3).toInt()) : Colors.orange.shade50;
    } else {
      balanceBgColor = isDark ? Colors.green.shade900.withAlpha((255 * 0.3).toInt()) : Colors.green.shade50;
    }

    final Color labelColor = isDark ? Colors.white70 : Colors.black54;
    final Color valueColor = isDark ? Colors.white : Colors.black87;

    Color balanceValueColor;
    if (balance < 0) {
      balanceValueColor = Colors.red.shade700;
    } else if (hasBudget && shoppingList.budget! > 0 && balance <= shoppingList.budget! * 0.10) {
      balanceValueColor = Colors.orange.shade700;
    } else {
      balanceValueColor = Colors.green.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey.withAlpha(80))),
      ),
      child: hasBudget
          ? Row(
        children: [
          Expanded(
            child: _FinancialInfoCard(
              backgroundColor: totalBgColor,
              icon: Icons.functions,
              label: 'Total',
              value: currencyFormat.format(totalCost),
              labelColor: labelColor,
              valueColor: valueColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FinancialInfoCard(
              backgroundColor: purchasedBgColor,
              icon: Icons.shopping_cart_checkout,
              label: 'Comprado',
              value: currencyFormat.format(purchasedTotal),
              labelColor: labelColor,
              valueColor: Colors.teal.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FinancialInfoCard(
              backgroundColor: budgetBgColor,
              icon: Icons.credit_card_outlined,
              label: 'Limite',
              value: currencyFormat.format(shoppingList.budget),
              labelColor: labelColor,
              valueColor: valueColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FinancialInfoCard(
              backgroundColor: balanceBgColor,
              icon: Icons.wallet_outlined,
              label: 'Saldo',
              value: currencyFormat.format(balance),
              labelColor: labelColor,
              valueColor: balanceValueColor,
            ),
          ),
        ],
      )
          : Row(
        children: [
          Expanded(
            child: _FinancialInfoCard(
              backgroundColor: totalBgColor,
              icon: Icons.functions,
              label: 'Total',
              value: currencyFormat.format(totalCost),
              labelColor: labelColor,
              valueColor: valueColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _FinancialInfoCard(
              backgroundColor: purchasedBgColor,
              icon: Icons.shopping_cart_checkout,
              label: 'Comprado',
              value: currencyFormat.format(purchasedTotal),
              labelColor: labelColor,
              valueColor: Colors.teal.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget _FinancialInfoCard (sem alteração)
class _FinancialInfoCard extends StatelessWidget {
  final Color backgroundColor;
  final IconData icon;
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  const _FinancialInfoCard({
    required this.backgroundColor,
    required this.icon,
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: labelColor.withAlpha((255 * 0.2).toInt()),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: labelColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 10, color: labelColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: valueColor,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Widget _AddItemForm (sem alteração)
class _AddItemForm extends ConsumerStatefulWidget {
  final ShoppingList shoppingList;
  final double currentTotalCost;
  final Item? item;
  final String? scannedBarcode;

  const _AddItemForm({
    required this.shoppingList,
    required this.currentTotalCost,
    this.item,
    this.scannedBarcode,
  });

  @override
  ConsumerState<_AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends ConsumerState<_AddItemForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _notesController;
  Category? _selectedCategory;
  String _selectedUnit = 'un';
  bool _isPurchased = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name);
    _quantityController = TextEditingController(text: item != null ? item.quantity.toString() : '1');
    _notesController = TextEditingController(text: item?.notes);
    _selectedCategory = item?.category;
    _selectedUnit = item?.unit ?? 'un';
    _isPurchased = item?.isChecked ?? false;

    final initialPrice = item != null ? NumberFormat("#,##0.00", "pt_BR").format(item.price) : '';
    _priceController = TextEditingController(text: initialPrice);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      if (!mounted) return;
      await showGlassDialog(
        context: context,
        title: const Text('Selecione uma categoria'),
        content: const Text('Por favor, escolha uma categoria para o item.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
      return;
    }

    final priceText = _priceController.text.replaceAll('.', '').replaceAll(',', '.').trim();
    final quantityText = _quantityController.text.replaceAll(',', '.').trim();
    final double price = double.tryParse(priceText) ?? 0.0;
    final double quantity = double.tryParse(quantityText) ?? 1.0;

    final newItem = Item(
      id: widget.item?.id ?? '',
      name: _nameController.text.trim(),
      category: _selectedCategory!,
      price: price,
      quantity: quantity,
      unit: (_selectedUnit.isNotEmpty ? _selectedUnit : 'un'),
      isChecked: _isPurchased,
      notes: _notesController.text.trim(),
      completionDate: widget.item?.completionDate,
      barcode: widget.item?.barcode ?? widget.scannedBarcode,
    );

    final budget = widget.shoppingList.budget;
    if (budget != null && budget > 0) {
      double diff = newItem.subtotal;
      if (widget.item != null) diff -= widget.item!.subtotal;
      if (widget.currentTotalCost + diff > budget) {
        if (!mounted) return;
        await showGlassDialog(
          context: context,
          title: const Text('Orçamento excedido'),
          content: const Text(
            'A adição/edição deste item ultrapassa o orçamento da lista. '
                'Edite ou remova outros itens para continuar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
        return;
      }
    }

    final viewModel = ref.read(listItemsViewModelProvider(widget.shoppingList.id).notifier);

    try {
      if (widget.item == null || widget.item!.id.isEmpty) {
        await viewModel.addItem(newItem, scannedBarcode: widget.scannedBarcode);
      } else {
        await viewModel.updateItem(newItem);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } on DuplicateItemException catch (e) {
      if (!mounted) return;
      await showGlassDialog(
        context: context,
        title: const Text('Item duplicado'),
        content: Text(e.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    } catch (e) {
      if (!mounted) return;
      await showGlassDialog(
        context: context,
        title: const Text('Erro ao salvar'),
        content: Text('Ocorreu um erro ao salvar o item:\n$e'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final unitsAsync = ref.watch(unitsProvider);
    final isEditMode = widget.item?.id.isNotEmpty == true;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Row(
              children: [
                Icon(isEditMode ? Icons.edit : Icons.add_shopping_cart, color: Colors.tealAccent),
                const SizedBox(width: 10),
                Text(isEditMode ? 'Editar Item' : 'Adicionar Item', style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nome do Item'),
                    validator: (value) => value!.isEmpty ? 'Por favor, insira um nome' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(labelText: 'Preço', prefixText: 'R\$ '),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CurrencyInputFormatter(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          decoration: const InputDecoration(labelText: 'Quantidade'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,3}')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  unitsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    error: (err, _) => const Text('Erro ao carregar unidades'),
                    data: (units) {
                      String? currentUnitValue = units.contains(_selectedUnit) ? _selectedUnit : (units.isNotEmpty ? units.first : null);
                      if (!isEditMode && _selectedUnit.isEmpty && units.isNotEmpty) {
                        currentUnitValue = units.first;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _selectedUnit = currentUnitValue!);
                        });
                      }

                      return DropdownButtonFormField<String>(
                        initialValue: currentUnitValue,
                        decoration: const InputDecoration(labelText: 'Unidade'),
                        items: units.map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(),
                        onChanged: (value) => setState(() => _selectedUnit = value!),
                        validator: (value) => (value == null && units.isNotEmpty) ? 'Selecione uma unidade' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  categoriesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => const Text('Erro ao carregar categorias'),
                    data: (categories) {
                      Category? initialCategory = _selectedCategory;
                      if (initialCategory != null && !categories.any((c) => c.id == initialCategory!.id)) {
                        initialCategory = categories.isNotEmpty ? categories.first : null;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _selectedCategory = initialCategory);
                        });
                      } else if (!isEditMode && initialCategory == null && categories.isNotEmpty) {
                        initialCategory = categories.first;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _selectedCategory = initialCategory);
                        });
                      }

                      return DropdownButtonFormField<Category>(
                        initialValue: initialCategory,
                        decoration: const InputDecoration(labelText: 'Categoria'),
                        isExpanded: true,
                        items: categories
                            .map((category) => DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Icon(category.icon, color: category.colorValue, size: 20),
                                const SizedBox(width: 10),
                                Expanded(child: Text(category.name, overflow: TextOverflow.ellipsis)),
                              ],
                            )))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedCategory = value),
                        validator: (value) => value == null ? 'Por favor, selecione uma categoria' : null,
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Observações'),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Item já comprado?'),
                    value: _isPurchased,
                    onChanged: (value) => setState(() => _isPurchased = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancelar'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _saveItem,
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget _EmptyListPlaceholder
class _EmptyListPlaceholder extends StatelessWidget {
  final bool isReadOnly;
  final String assetPath;

  const _EmptyListPlaceholder({
    required this.isReadOnly,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color glass = (isDark ? const Color(0xFF2C3A43) : Colors.white).withAlpha((255 * 0.85).toInt());

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
                    color: (isDark ? Colors.white : Colors.black).withAlpha((255 * 0.06).toInt()),
                    width: 1,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [glass, glass.withAlpha(isDark ? (255 * 0.78).toInt() : (255 * 0.9).toInt())],
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
                    Opacity(
                      opacity: 0.9,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha((255 * 0.15).toInt()),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            assetPath,
                            width: 220,
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
                      isReadOnly ? 'Esta lista está vazia' : 'Sua lista está vazia',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isReadOnly ? 'Nenhum item foi adicionado a esta lista.' : 'Adicione seu primeiro item tocando no botão “+”.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!isReadOnly) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.teal.shade900 : Colors.teal.shade50).withAlpha(isDark ? (255 * 0.5).toInt() : 255),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (isDark ? Colors.tealAccent : Colors.teal).withAlpha((255 * 0.35).toInt()),
                          ),
                        ),
                        child: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.center,
                          children: [
                            const Icon(Icons.lightbulb, size: 16),
                            Text(
                              'Dica: defina preço e unidade para ver o subtotal.',
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