// lib/presentation/views/list_items/list_items_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:superlistas/core/ui/widgets/app_background.dart';
import 'package:superlistas/core/ui/widgets/currency_input_formatter.dart';
import 'package:superlistas/core/ui/widgets/glass_dialog.dart';
import 'package:superlistas/core/ui/widgets/shared_widgets.dart';
import 'package:superlistas/domain/entities/category.dart';
import 'package:superlistas/domain/entities/item.dart';
import 'package:superlistas/domain/entities/shopping_list.dart';
import 'package:superlistas/presentation/providers/providers.dart';
import 'package:superlistas/presentation/viewmodels/list_items_viewmodel.dart';
import 'package:superlistas/presentation/views/list_items/list_analysis_screen.dart';

final unitsProvider = FutureProvider.autoDispose<List<String>>((ref) {
  return ref.watch(shoppingListRepositoryProvider).getAllUnits();
});

class ListItemsScreen extends ConsumerWidget {
  final String shoppingListId;

  const ListItemsScreen({super.key, required this.shoppingListId});

  void _showItemFormModal(
      BuildContext context,
      ShoppingList shoppingList, {
        required double currentTotalCost,
        Item? item,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color glassColor = (isDark ? theme.colorScheme.surface : Colors.white).withAlpha((255 * 0.85).toInt());

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Map<String, List<Item>> _groupItems(List<Item> items) {
    final Map<String, List<Item>> groupedItems = {};
    for (final item in items) {
      groupedItems.putIfAbsent(item.category.name, () => []);
      groupedItems[item.category.name]!.add(item);
    }
    return groupedItems;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoppingListAsync = ref.watch(singleListProvider(shoppingListId));

    return shoppingListAsync.when(
      loading: () => Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('Erro ao carregar a lista: $err'))),
      data: (shoppingList) {
        final itemsAsync =
        ref.watch(listItemsViewModelProvider(shoppingList.id));
        final viewModel =
        ref.read(listItemsViewModelProvider(shoppingList.id).notifier);

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              AppBackground(),
              itemsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) =>
                    Center(child: Text('Ocorreu um erro: $err')),
                data: (items) {
                  final double totalCost =
                  items.fold(0.0, (sum, item) => sum + item.subtotal);

                  return CustomScrollView(
                    slivers: [
                      _ItemsSliverAppBar(
                        shoppingList: shoppingList,
                        items: items,
                        viewModel: viewModel,
                      ),
                      SliverToBoxAdapter(
                        child: _FinancialSummaryBar(
                            shoppingList: shoppingList, totalCost: totalCost),
                      ),
                      if (items.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Nenhum item na lista. Adicione um!',
                                style:
                                TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ),
                        )
                      else
                        _buildGroupedList(
                            items, viewModel, shoppingList, totalCost),
                      SliverPadding(
                        padding: EdgeInsets.only(
                            bottom:
                            MediaQuery.of(context).viewPadding.bottom + 80),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          floatingActionButton: itemsAsync.when(
            data: (items) {
              final double totalCost =
              items.fold(0.0, (sum, item) => sum + item.subtotal);
              final bool hasBudget =
                  shoppingList.budget != null && shoppingList.budget! > 0;
              final bool budgetExceeded =
                  hasBudget && totalCost >= shoppingList.budget!;
              return Container(
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewPadding.bottom + 80,
                ),
                child: FloatingActionButton(
                  onPressed: budgetExceeded
                      ? null
                      : () => _showItemFormModal(context, shoppingList,
                      currentTotalCost: totalCost),
                  backgroundColor: budgetExceeded
                      ? Colors.grey
                      : Theme.of(context).colorScheme.secondary,
                  child: const Icon(Icons.add),
                ),
              );
            },
            loading: () => Container(
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewPadding.bottom + 80,
              ),
              child: const FloatingActionButton(
                  onPressed: null, backgroundColor: Colors.grey, child: Icon(Icons.add)),
            ),
            error: (_, __) => Container(
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewPadding.bottom + 80,
              ),
              child: const FloatingActionButton(
                  onPressed: null, backgroundColor: Colors.grey, child: Icon(Icons.add)),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildGroupedList(
      List<Item> items,
      ListItemsViewModel viewModel,
      ShoppingList shoppingList,
      double totalCost,
      ) {
    final groupedItems = _groupItems(items);
    final categoryNames = groupedItems.keys.toList();

    return SliverList.builder(
      itemCount: categoryNames.length,
      itemBuilder: (context, index) {
        final categoryName = categoryNames[index];
        final itemsInCategory = groupedItems[categoryName]!;
        final categoryIcon = itemsInCategory.first.category.icon;

        final double categorySubtotal =
        itemsInCategory.fold(0.0, (sum, item) => sum + item.subtotal);
        final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
        final formattedSubtotal = currencyFormat.format(categorySubtotal);

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        final headerColor = isDark ? Colors.white : theme.colorScheme.primary;
        final subHeaderColor = theme.colorScheme.secondary;

        final List<Widget> childrenWithDividers = [];
        for (int i = 0; i < itemsInCategory.length; i++) {
          final item = itemsInCategory[i];
          childrenWithDividers.add(
            Dismissible(
              key: Key(item.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: const Icon(Icons.delete_forever, color: Colors.white),
              ),
              onDismissed: (_) => viewModel.deleteItem(item.id),
              child: _buildItemTile(
                  context, totalCost, item, viewModel, shoppingList),
            ),
          );
          if (i < itemsInCategory.length - 1) {
            childrenWithDividers.add(
              Divider(
                height: 1,
                thickness: 1,
                color: (isDark ? Colors.white : theme.colorScheme.primary).withAlpha((255 * 0.15).toInt()),
                indent: 16,
                endIndent: 16,
              ),
            );
          }
        }

        return GlassCard(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: ExpansionTile(
            iconColor: headerColor,
            collapsedIconColor: headerColor,
            initiallyExpanded: true,
            leading:
            Icon(categoryIcon, color: theme.colorScheme.secondary),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    categoryName,
                    style: TextStyle(
                        color: headerColor, fontWeight: FontWeight.bold),
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
                          color: Colors.black54,
                          blurRadius: 3,
                          offset: Offset(1,1),
                        )
                      ]
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

  Widget _buildItemTile(
      BuildContext context,
      double currentTotalCost,
      Item item,
      ListItemsViewModel viewModel,
      ShoppingList shoppingList,
      ) {
    final currencyFormat =
    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final quantityFormat = NumberFormat();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color primaryColor = scheme.primary;
    final itemTitleColor = isDark ? (item.isChecked ? Colors.white54 : Colors.white) : (item.isChecked ? primaryColor.withAlpha((255 * 0.5).toInt()) : primaryColor);
    final itemSubtitleColor = isDark ? Colors.white70 : primaryColor.withAlpha((255 * 0.7).toInt());
    final itemIconColor = isDark ? Colors.white70 : primaryColor.withAlpha((255 * 0.6).toInt());

    return CheckboxListTile(
      activeColor: scheme.secondary,
      checkColor: scheme.onSecondary,
      controlAffinity: ListTileControlAffinity.leading,
      value: item.isChecked,
      onChanged: (bool? newValue) {
        final updatedItem = item.copyWith(isChecked: newValue ?? false);
        viewModel.updateItem(updatedItem);
      },
      title: Text(
        item.name,
        style: TextStyle(
          decoration:
          item.isChecked ? TextDecoration.lineThrough : TextDecoration.none,
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
        ],
      ),
      secondary: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: itemIconColor),
            onPressed: () {
              _showItemFormModal(context, shoppingList,
                  currentTotalCost: currentTotalCost, item: item);
            },
          ),
        ],
      ),
    );
  }
}

class _ItemsSliverAppBar extends ConsumerWidget {
  final ShoppingList shoppingList;
  final List<Item> items;
  final ListItemsViewModel viewModel;

  const _ItemsSliverAppBar({
    required this.shoppingList,
    required this.items,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final checkedItemsCount = items.where((item) => item.isChecked).length;
    final bool isConcludeEnabled =
        checkedItemsCount > 0 && !shoppingList.isArchived;

    final Color foregroundColor = isDark ? scheme.onSurface : Colors.white;

    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: foregroundColor),
      actionsIconTheme: IconThemeData(color: foregroundColor),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: isDark
                ? scheme.surface.withAlpha((255 * 0.3).toInt())
                : Colors.white.withAlpha((255 * 0.2).toInt()),
          ),
        ),
      ),
      title: Text(
        shoppingList.name,
        style: theme.textTheme.headlineSmall?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w800,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'complete') {
              final bool? confirm = await showGlassDialog<bool>(
                context: context,
                title: const Text('Concluir Compra'),
                content: const Text(
                    'Tem certeza que deseja mover esta lista para o seu histórico?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Sim, Concluir'),
                  ),
                ],
              );

              if (confirm == true) {
                await viewModel.archiveList(shoppingList);
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Lista movida para o Histórico!')),
                );
              }
            } else if (value == 'edit') {
              showAddOrEditListDialog(
                context: context,
                ref: ref,
                userId: shoppingList.userId,
                list: shoppingList,
              );
            } else if (value == 'analysis') {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ListAnalysisScreen(shoppingList: shoppingList)),
              );
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'complete',
              enabled: isConcludeEnabled,
              child: const Text('Concluir compra'),
            ),
            const PopupMenuItem<String>(
              value: 'edit',
              child: Text('Editar Lista'),
            ),
            const PopupMenuItem<String>(
                value: 'analysis', child: Text('Análise da Lista')),
          ],
        ),
      ],
    );
  }
}

class _FinancialSummaryBar extends StatelessWidget {
  final ShoppingList shoppingList;
  final double totalCost;

  const _FinancialSummaryBar({
    required this.shoppingList,
    required this.totalCost,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currencyFormat =
    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final bool hasBudget =
        shoppingList.budget != null && shoppingList.budget! > 0;
    final double balance = hasBudget ? shoppingList.budget! - totalCost : 0.0;

    const Color valueColor = Colors.white;
    const Color labelColor = Colors.white70;
    final Color balanceColor = balance >= 0
        ? Colors.greenAccent.shade200
        : Colors.redAccent.shade100;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha((255 * (isDark ? 0.2 : 0.1)).toInt()),
            border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total',
                      style: TextStyle(fontSize: 12, color: labelColor)),
                  const SizedBox(height: 2),
                  Text(
                    currencyFormat.format(totalCost),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: valueColor),
                  ),
                ],
              ),
              if (hasBudget)
                Column(
                  children: [
                    const Text('Limite',
                        style: TextStyle(fontSize: 12, color: labelColor)),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormat.format(shoppingList.budget),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: valueColor),
                    ),
                  ],
                ),
              if (hasBudget)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Saldo',
                        style: TextStyle(fontSize: 12, color: labelColor)),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormat.format(balance),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: balanceColor,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddItemForm extends ConsumerStatefulWidget {
  final ShoppingList shoppingList;
  final double currentTotalCost;
  final Item? item;

  const _AddItemForm(
      {required this.shoppingList,
        required this.currentTotalCost,
        this.item});

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
    _quantityController =
        TextEditingController(text: item != null ? item.quantity.toString() : '1');
    _notesController = TextEditingController(text: item?.notes);
    _selectedCategory = item?.category;
    _selectedUnit = item?.unit ?? 'un';
    _isPurchased = item?.isChecked ?? false;

    final initialPrice = item != null
        ? NumberFormat("#,##0.00", "pt_BR").format(item.price)
        : '';
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

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      final priceText =
      _priceController.text.replaceAll('.', '').replaceAll(',', '.');
      final quantityText = _quantityController.text.replaceAll(',', '.');

      final newItem = Item(
        id: widget.item?.id ?? '',
        name: _nameController.text,
        category: _selectedCategory!,
        price: double.tryParse(priceText) ?? 0.0,
        quantity: double.tryParse(quantityText) ?? 1.0,
        unit: _selectedUnit,
        isChecked: _isPurchased,
        notes: _notesController.text,
        completionDate: widget.item?.completionDate,
      );

      final budget = widget.shoppingList.budget;
      if (budget != null && budget > 0) {
        double costDifference = newItem.subtotal;
        if (widget.item != null) {
          costDifference -= widget.item!.subtotal;
        }

        if (widget.currentTotalCost + costDifference > budget) {
          showGlassDialog(
            context: context,
            title: const Text('Orçamento Excedido'),
            content: const Text(
                'A adição ou edição deste item ultrapassará o orçamento da lista. Exclua ou edite outros itens para continuar.'),
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

      final viewModel =
      ref.read(listItemsViewModelProvider(widget.shoppingList.id).notifier);
      if (widget.item == null) {
        viewModel.addItem(newItem);
      } else {
        viewModel.updateItem(newItem);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final unitsAsync = ref.watch(unitsProvider);
    final isEditMode = widget.item != null;

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
                Icon(isEditMode ? Icons.edit : Icons.add_shopping_cart,
                    color: Colors.tealAccent),
                const SizedBox(width: 10),
                Text(isEditMode ? 'Editar Item' : 'Adicionar Item',
                    style: Theme.of(context).textTheme.headlineSmall),
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
                    validator: (value) =>
                    value!.isEmpty ? 'Por favor, insira um nome' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration:
                          const InputDecoration(labelText: 'Preço', prefixText: 'R\$ '),
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
                          keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,3}'))
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
                      if (isEditMode && !units.contains(_selectedUnit)) {
                        units.insert(0, _selectedUnit);
                      }
                      return DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        decoration: const InputDecoration(labelText: 'Unidade'),
                        items: units
                            .map((unit) =>
                            DropdownMenuItem(value: unit, child: Text(unit)))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedUnit = value!),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  categoriesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) =>
                    const Text('Erro ao carregar categorias'),
                    data: (categories) {
                      if (isEditMode &&
                          _selectedCategory != null &&
                          !categories.any((c) => c.id == _selectedCategory!.id)) {
                        categories.add(_selectedCategory!);
                      }
                      return DropdownButtonFormField<Category>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(labelText: 'Categoria'),
                        isExpanded: true,
                        items: categories.map((category) {
                          return DropdownMenuItem(
                              value: category, child: Text(category.name));
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedCategory = value),
                        validator: (value) =>
                        value == null ? 'Por favor, selecione uma categoria' : null,
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