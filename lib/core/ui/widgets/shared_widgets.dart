// lib/core/ui/widgets/shared_widgets.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:superlistas/core/ui/widgets/currency_input_formatter.dart';
import 'package:superlistas/core/ui/widgets/glass_dialog.dart';
import 'package:superlistas/domain/entities/shopping_list.dart';
import 'package:superlistas/presentation/providers/providers.dart';

// --- WIDGET 1: GlassAppBar ---
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  const GlassAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color foregroundColor = isDark ? Colors.white : Colors.black;
    final Color backgroundColor = isDark ? const Color(0xFF344049) : Colors.white;

    // Pega o tamanho da fonte base do tema e aplica a redução
    final baseFontSize = theme.textTheme.titleLarge?.fontSize ?? 22.0;
    final reducedFontSize = baseFontSize * 0.7;

    return AppBar(
      title: title,
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(
        color: foregroundColor,
        fontWeight: FontWeight.w800,
        fontSize: reducedFontSize,
      ),
      iconTheme: IconThemeData(color: foregroundColor),
      backgroundColor: backgroundColor,
      surfaceTintColor: backgroundColor,
      elevation: 1,
      shadowColor: Colors.black.withAlpha(50),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// --- WIDGET 2: GlassCard ---
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  const GlassCard({super.key, required this.child, this.margin});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            scheme.surface.withAlpha((255 * 0.6).toInt()),
            scheme.surface.withAlpha((255 * 0.4).toInt()),
          ]
              : [
            Colors.white.withAlpha((255 * 0.7).toInt()),
            Colors.white.withAlpha((255 * 0.5).toInt()),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withAlpha((255 * 0.2).toInt()),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

// --- WIDGET 3: Indicator ---
class Indicator extends StatelessWidget {
  final Color color;
  final String text;
  const Indicator({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: <Widget>[
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(
                text,
                style: TextStyle(color: onSurface),
                overflow: TextOverflow.ellipsis,
              )),
        ],
      ),
    );
  }
}

void showAddOrEditListDialog(
    {required BuildContext context,
      required WidgetRef ref,
      required String userId,
      ShoppingList? list}) {
  final isEditMode = list != null;
  final nameController = TextEditingController(text: list?.name);

  String initialBudgetText = '';
  if (list != null && list.budget != null) {
    initialBudgetText =
        NumberFormat.currency(locale: 'pt_BR', symbol: '').format(list.budget);
  }
  final budgetController = TextEditingController(text: initialBudgetText);

  showGlassDialog(
    context: context,
    title: Row(
      children: [
        Icon(
          isEditMode ? Icons.edit_note_rounded : Icons.playlist_add_rounded,
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(width: 12),
        Text(isEditMode ? 'Editar Lista' : 'Nova Lista'),
      ],
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome da Lista',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: budgetController,
          decoration: const InputDecoration(
            labelText: 'Orçamento (Opcional)',
            prefixText: 'R\$ ',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            CurrencyInputFormatter(),
          ],
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      ElevatedButton(
        onPressed: () {
          if (nameController.text.isEmpty) return;
          final budgetText =
          budgetController.text.replaceAll('.', '').replaceAll(',', '.');
          final budget = double.tryParse(budgetText);

          if (isEditMode) {
            ref
                .read(shoppingListsViewModelProvider(userId).notifier)
                .updateList(
              list!,
              nameController.text,
              budget: budget,
            );
            ref.invalidate(singleListProvider(list.id));
          } else {
            ref
                .read(shoppingListsViewModelProvider(userId).notifier)
                .addList(
              nameController.text,
              budget: budget,
            );
          }

          ref.invalidate(dashboardViewModelProvider(userId));
          Navigator.of(context).pop();
        },
        child: const Text('Salvar'),
      ),
    ],
  );
}