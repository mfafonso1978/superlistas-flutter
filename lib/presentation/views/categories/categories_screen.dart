// lib/presentation/views/categories/categories_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/core/constants/category_icons.dart';
import 'package:superlistas/core/ui/widgets/app_background.dart';
import 'package:superlistas/core/ui/widgets/glass_dialog.dart';
import 'package:superlistas/core/ui/widgets/icon_picker_dialog.dart';
import 'package:superlistas/core/ui/widgets/shared_widgets.dart';
import 'package:superlistas/domain/entities/category.dart';
import 'package:superlistas/presentation/providers/providers.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesViewModelProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        title: Text('Categorias'),
      ),
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: categoriesAsync.when(
              loading: () => const _LoadingState(),
              error: (err, stack) => _ErrorState(error: '$err'),
              data: (categories) {
                if (categories.isEmpty) {
                  return _EmptyState(
                    onAdd: () => _showAddOrEditCategoryDialog(context, ref),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(categoriesViewModelProvider.notifier).loadCategories(),
                  child: GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      return _CategoryCard(
                        category: cat,
                        onTap: () => _showEditCategoryDialog(context, ref, cat),
                        onEdit: () => _showEditCategoryDialog(context, ref, cat),
                        onDelete: () => _showDeleteCategoryDialog(context, ref, cat),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditCategoryDialog(context, ref),
        backgroundColor: scheme.secondary,
        foregroundColor: scheme.onSecondary,
        heroTag: 'add_category_fab',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Dialogs =========

  void _showAddOrEditCategoryDialog(BuildContext context, WidgetRef ref, {Category? category}) {
    // Reaproveita o mesmo diálogo para criar/editar
    final formKey = GlobalKey<_CategoryFormContentState>();

    showGlassDialog<void>(
      context: context,
      title: Row(
        children: [
          Icon(
            category != null ? Icons.edit_note_rounded : Icons.category_rounded,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 12),
          Text(category != null ? 'Editar Categoria' : 'Nova Categoria'),
        ],
      ),
      content: _CategoryFormContent(key: formKey, category: category),
      actions: [
        // ATENÇÃO: Na janela de Editar NÃO há botão Excluir
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => formKey.currentState?.save(),
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  void _showEditCategoryDialog(BuildContext context, WidgetRef ref, Category category) {
    _showAddOrEditCategoryDialog(context, ref, category: category);
  }

  Future<void> _showDeleteCategoryDialog(
      BuildContext context, WidgetRef ref, Category category) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final viewModel = ref.read(categoriesViewModelProvider.notifier);

    final bool? confirm = await showGlassDialog<bool>(
      context: context,
      title: Row(
        children: const [
          Icon(Icons.delete_forever_rounded, color: Colors.red),
          SizedBox(width: 12),
          Text('Excluir Categoria'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Tem certeza que deseja excluir "${category.name}"?'),
          const SizedBox(height: 8),
          const Text(
            'Os itens associados serão movidos para "Outros".',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => navigator.pop(false),
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => navigator.pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Excluir'),
        ),
      ],
    );

    if (confirm == true) {
      await viewModel.deleteCategory(category.id);
      HapticFeedback.mediumImpact();
      messenger.showSnackBar(
        SnackBar(content: Text('Categoria "${category.name}" excluída.')),
      );
      // Fecha o diálogo de edição se estiver aberto
      if (navigator.canPop()) navigator.pop();
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = category.colorValue;
    final iconColor = color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return Hero(
      tag: 'category_card_${category.id}',
      child: Material(
        type: MaterialType.transparency,
        child: GlassCard(
          child: Stack(
            children: [
              // Conteúdo clicável central
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onTap();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color.withOpacity(0.8), color],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Icon(
                              category.icon,
                              size: 40,
                              color: iconColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              category.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: scheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Botão de 3 pontinhos no canto superior direito
              Positioned(
                top: 4,
                right: 4,
                child: _CategoryCardMenu(
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCardMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCardMenu({
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<_MenuChoice>(
      tooltip: 'Mais opções',
      position: PopupMenuPosition.under,
      elevation: 2,
      color: Theme.of(context).dialogBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      icon: Icon(Icons.more_vert_rounded, color: scheme.onSurface.withOpacity(0.8)),
      onSelected: (value) {
        switch (value) {
          case _MenuChoice.editar:
            onEdit();
            break;
          case _MenuChoice.excluir:
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<_MenuChoice>(
          value: _MenuChoice.editar,
          child: Row(
            children: [
              Icon(Icons.edit_rounded),
              SizedBox(width: 12),
              Text('Editar'),
            ],
          ),
        ),
        PopupMenuItem<_MenuChoice>(
          value: _MenuChoice.excluir,
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.red),
              SizedBox(width: 12),
              Text('Excluir'),
            ],
          ),
        ),
      ],
    );
  }
}

enum _MenuChoice { editar, excluir }

class _CategoryFormContent extends ConsumerStatefulWidget {
  final Category? category;
  const _CategoryFormContent({super.key, this.category});

  @override
  ConsumerState<_CategoryFormContent> createState() => _CategoryFormContentState();
}

class _CategoryFormContentState extends ConsumerState<_CategoryFormContent> {
  late final TextEditingController _nameController;
  late IconData _selectedIcon;
  final _formKey = GlobalKey<FormState>();

  bool get isEditMode => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
    _selectedIcon = widget.category?.icon ?? CategoryIcons.getDefaultIcon();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Métodos públicos chamados pelas actions do diálogo
  Future<void> save() => _onSave();
  Future<void> delete() => _onDelete();

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final viewModel = ref.read(categoriesViewModelProvider.notifier);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (isEditMode) {
      await viewModel.updateCategory(widget.category!.id, name, _selectedIcon);
    } else {
      await viewModel.addCategory(name, _selectedIcon);
    }

    HapticFeedback.mediumImpact();
    messenger.showSnackBar(
      SnackBar(content: Text('Categoria "$name" salva com sucesso!')),
    );
    navigator.pop();
  }

  Future<void> _onDelete() async {
    if (!isEditMode) return;

    final viewModel = ref.read(categoriesViewModelProvider.notifier);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final bool? confirm = await showGlassDialog<bool>(
      context: context,
      title: const Text('Confirmar Exclusão'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Tem certeza que deseja excluir a categoria "${widget.category!.name}"?'),
          const SizedBox(height: 8),
          const Text(
            'Todos os itens associados a ela serão movidos para "Outros".',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Excluir'),
        )
      ],
    );

    if (confirm == true) {
      await viewModel.deleteCategory(widget.category!.id);
      HapticFeedback.mediumImpact();
      messenger.showSnackBar(
        SnackBar(content: Text('Categoria "${widget.category!.name}" excluída.')),
      );
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome da Categoria'),
            validator: (value) =>
            (value == null || value.trim().isEmpty) ? 'O nome é obrigatório' : null,
            onFieldSubmitted: (_) => _onSave(),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () async {
              HapticFeedback.lightImpact();
              final IconData? newIcon = await showIconPicker(
                context: context,
                selectedIcon: _selectedIcon,
              );
              if (newIcon != null) {
                setState(() => _selectedIcon = newIcon);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Ícone',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(_selectedIcon, color: Theme.of(context).colorScheme.secondary, size: 32),
                  const Text('Toque para alterar'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: GlassCard(
        margin: EdgeInsets.all(32),
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando categorias...'),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 80, color: scheme.secondary.withOpacity(0.5)),
            const SizedBox(height: 20),
            Text(
              'Nenhuma categoria criada',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Crie sua primeira categoria personalizada para organizar seus itens.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Criar Categoria'),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.secondary,
                foregroundColor: scheme.onSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        margin: const EdgeInsets.all(32),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text('Ops! Algo deu errado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
